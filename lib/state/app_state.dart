import 'package:flutter/material.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'dart:convert';
import 'package:akashic_records/i18n/i18n.dart';

class AppState extends ChangeNotifier {
  late NovelDatabase _db;
  Locale currentLocale = const Locale('en');
  ThemeMode themeMode = ThemeMode.system;
  Color accentColor = const Color(0xFFD1973A);
  bool showChangelog = true;
  Map<String, dynamic> readerPrefs = {};
  String? latestReleaseTag;
  String? latestReleaseUrl;
  bool navAlwaysVisible = false;
  double navScrollThreshold = 6.0;
  int navAnimationMs = 250;
  String? customDns;
  String? customUserAgent;

  List<Novel> _localNovels = [];

  List<Novel> get localNovels => List.unmodifiable(_localNovels);

  List<Novel> get favoriteNovels =>
      _localNovels.where((n) => n.isFavorite == true).toList();

  Future<void> initialize() async {
    _db = await NovelDatabase.getInstance();
    _localNovels = await _db.getAllNovels();
    try {
      final saved = await _db.getSetting('app_locale');
      if (saved != null && saved.isNotEmpty) {
        final parts = saved.split('_');
        currentLocale =
            parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
      }
    } catch (_) {}

    try {
      currentLocale = I18n.currentLocate;
    } catch (_) {}
    final tm = await _db.getSetting('theme_mode');
    if (tm != null) {
      switch (tm) {
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'dark':
          themeMode = ThemeMode.dark;
          break;
        default:
          themeMode = ThemeMode.system;
      }
    }
    final accentVal = await _db.getSetting('accent_color');
    if (accentVal != null) {
      try {
        accentColor = Color(int.parse(accentVal));
      } catch (_) {}
    }
    try {
      final navAlways = await _db.getSetting('nav_always_visible');
      if (navAlways != null) navAlwaysVisible = navAlways == 'true';
    } catch (_) {}
    try {
      final thr = await _db.getSetting('nav_scroll_threshold');
      if (thr != null)
        navScrollThreshold = double.tryParse(thr) ?? navScrollThreshold;
    } catch (_) {}
    try {
      final ms = await _db.getSetting('nav_animation_ms');
      if (ms != null) navAnimationMs = int.tryParse(ms) ?? navAnimationMs;
    } catch (_) {}
    try {
      final dns = await _db.getSetting('custom_dns');
      if (dns != null) customDns = dns;
    } catch (_) {}
    try {
      final ua = await _db.getSetting('custom_user_agent');
      if (ua != null) customUserAgent = ua;
    } catch (_) {}
    try {
      final rp = await _db.getSetting('reader_prefs');
      if (rp != null && rp.isNotEmpty) {
        readerPrefs = json.decode(rp) as Map<String, dynamic>;
      } else {
        readerPrefs = {
          'presetIndex': 0,
          'fontSize': 18.0,
          'lineHeight': 1.6,
          'fontFamily': 'serif',
          'padding': 12.0,
          'fullscreen': false,
          'align': 'left',
          'focusMode': false,
          'focusBlur': 6,
          'textBrightness': 1.0,
          'fontColor': null,
          'bgColor': null,
        };
      }
    } catch (_) {
      readerPrefs = {
        'presetIndex': 0,
        'fontSize': 18.0,
        'lineHeight': 1.6,
        'fontFamily': 'serif',
        'padding': 12.0,
        'fullscreen': false,
        'align': 'left',
        'focusMode': false,
        'focusBlur': 6,
        'textBrightness': 1.0,
        'fontColor': null,
        'bgColor': null,
      };
    }
    try {
      final dns = await _db.getSetting('custom_dns');
      if (dns != null && dns.isNotEmpty) customDns = dns;
    } catch (_) {}
    try {
      final ua = await _db.getSetting('custom_user_agent');
      if (ua != null && ua.isNotEmpty) customUserAgent = ua;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadLatestReleaseInfo() async {
    try {
      latestReleaseTag = await _db.getSetting('latest_release_tag');
      latestReleaseUrl = await _db.getSetting('latest_release_url');
      _lastShownReleaseTag = await _db.getSetting('last_shown_release_tag');
      final d = await _db.getSetting('last_shown_release_date');
      if (d != null && d.isNotEmpty) {
        try {
          _lastShownDate = DateTime.parse(d);
        } catch (_) {
          _lastShownDate = null;
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> saveLatestReleaseInfo(String tag, String url) async {
    latestReleaseTag = tag;
    latestReleaseUrl = url;
    try {
      await _db.setSetting('latest_release_tag', tag);
      await _db.setSetting('latest_release_url', url);
    } catch (_) {}
    notifyListeners();
  }

  String? _lastShownReleaseTag;
  DateTime? _lastShownDate;

  bool shouldShowReleaseNotes(String tag) {
    if (_lastShownReleaseTag == null) return true;
    if (_lastShownReleaseTag != tag) return true;
    if (_lastShownDate == null) return true;
    final now = DateTime.now();
    return !_isSameDay(now, _lastShownDate!);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> markReleaseNotesShown(String tag) async {
    _lastShownReleaseTag = tag;
    _lastShownDate = DateTime.now();
    try {
      await _db.setSetting('last_shown_release_tag', tag);
      await _db.setSetting(
        'last_shown_release_date',
        _lastShownDate!.toIso8601String(),
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setNavAlwaysVisible(bool v) async {
    navAlwaysVisible = v;
    try {
      await _db.setSetting('nav_always_visible', v ? 'true' : 'false');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setNavScrollThreshold(double value) async {
    navScrollThreshold = value;
    try {
      await _db.setSetting('nav_scroll_threshold', value.toString());
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setNavAnimationMs(int ms) async {
    navAnimationMs = ms;
    try {
      await _db.setSetting('nav_animation_ms', ms.toString());
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    currentLocale = locale;
    try {
      await I18n.updateLocate(locale);
    } catch (_) {}
    try {
      await _db.setSetting(
        'app_locale',
        locale.countryCode != null && locale.countryCode!.isNotEmpty
            ? '${locale.languageCode}_${locale.countryCode}'
            : locale.languageCode,
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setReaderPrefs(Map<String, dynamic> prefs) async {
    readerPrefs = Map<String, dynamic>.from(prefs);
    final db = await NovelDatabase.getInstance();
    await db.setSetting('reader_prefs', json.encode(readerPrefs));
    notifyListeners();
  }

  Map<String, dynamic> getReaderPrefs() =>
      Map<String, dynamic>.from(readerPrefs);

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _db.setSetting(
      'theme_mode',
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
          ? 'dark'
          : 'system',
    );
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    accentColor = color;
    await _db.setSetting('accent_color', color.value.toString());
    notifyListeners();
  }

  Future<void> setPluginPrefs(String id, Map<String, dynamic> prefs) async {
    await _db.setPluginPrefs(id, prefs);
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getPluginPrefs(String id) async {
    return await _db.getPluginPrefs(id);
  }

  Future<bool> getPluginState(String id) async {
    final map = await _db.getAllPluginStates();
    return map[id] ?? true;
  }

  Future<void> setPluginState(String id, bool enabled) async {
    await _db.setPluginEnabled(id, enabled);
    notifyListeners();
  }

  Future<void> addOrUpdateNovel(Novel novel) async {
    await _db.upsertNovel(novel);
    try {
      print(
        'addOrUpdateNovel: saving novel ${novel.id} fav=${novel.isFavorite}',
      );
    } catch (_) {}
    await refreshLocalNovels();
  }

  Future<void> toggleFavorite(String id, {bool? value}) async {
    final idx = _localNovels.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    final novel = _localNovels[idx];
    novel.isFavorite = value ?? !novel.isFavorite;
    await _db.upsertNovel(novel);
    try {
      print('toggleFavorite: toggled ${novel.id} -> ${novel.isFavorite}');
    } catch (_) {}
    await refreshLocalNovels();
  }

  Future<void> refreshLocalNovels() async {
    _localNovels = await _db.getAllNovels();
    notifyListeners();
  }

  Future<void> setChapterRead(
    String novelId,
    String chapterId,
    bool read,
  ) async {
    final db = await NovelDatabase.getInstance();
    await db.setChapterRead(novelId, chapterId, read);
    await refreshLocalNovels();
  }

  Future<Map<String, int>> checkForUpdates() async {
    final Map<String, int> updates = {};
    final favorites = favoriteNovels;

    const int maxConcurrent = 4;
    final queue = List<Novel>.from(favorites);
    final List<Future<void>> workers = [];

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final novel = queue.removeAt(0);
        final PluginService? service = PluginRegistry.get(novel.pluginId);
        if (service == null) continue;
        try {
          final enabled = await getPluginState(service.name);
          if (!enabled) continue;
          final latest = await service
              .parseNovel(novel.id)
              .timeout(const Duration(seconds: 15));
          final latestCount = latest.chapters.length;
          final known = novel.lastKnownChapterCount;
          if (latestCount > known) {
            final newChapters = latest.chapters.sublist(known);
            final db = await NovelDatabase.getInstance();
            final readSet = await db.getReadChaptersForNovel(novel.id);
            int newUnread = 0;
            for (final ch in newChapters) {
              if (!readSet.contains(ch.id)) newUnread++;
            }
            updates[novel.id] = newUnread > 0 ? newUnread : 0;
            novel.lastKnownChapterCount = latestCount;
          }
          novel.lastChecked = DateTime.now().toIso8601String();
          await _db.upsertNovel(novel);
        } catch (e) {
          print('Error checking updates for ${novel.id}: $e');
        }
      }
    }

    for (int i = 0; i < maxConcurrent; i++) {
      workers.add(worker());
    }

    await Future.wait(workers);

    _localNovels = await _db.getAllNovels();
    notifyListeners();
    return updates;
  }

  Future<void> removeNovel(String id) async {
    await _db.deleteNovel(id);
    _localNovels = await _db.getAllNovels();
    notifyListeners();
  }

  void markChangelogAsShown() {
    showChangelog = false;
    notifyListeners();
  }

  Future<void> setCustomDns(String? dns) async {
    customDns = dns!;
    try {
      await _db.setSetting('custom_dns', dns);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setCustomUserAgent(String? ua) async {
    customUserAgent = ua!;
    try {
      await _db.setSetting('custom_user_agent', ua);
    } catch (_) {}
    notifyListeners();
  }
}
