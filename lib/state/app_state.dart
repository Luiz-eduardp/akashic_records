import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/services/backup_service.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:akashic_records/models/model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/services/download_queue_service.dart';
import 'managers/novel_manager.dart';
import 'managers/chapter_manager.dart';
import 'managers/plugin_manager.dart';
import 'managers/ui_settings_manager.dart';
import 'managers/network_settings_manager.dart';
import 'managers/reader_preferences_manager.dart';

class AppState extends ChangeNotifier {
  late NovelDatabase _db;
  late NovelManager _novelManager;
  late ChapterManager _chapterManager;
  late PluginManager _pluginManager;
  late UiSettingsManager _uiSettings;
  late NetworkSettingsManager _networkSettings;
  late ReaderPreferencesManager _readerPrefs;

  bool isOnline = true;
  bool isBusy = false;
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  late DownloadQueueService _downloadQueue;
  VoidCallback? _onQueueUpdated;

  Timer? _cleanupTimer;
  Timer? _healthCheckTimer;

  List<Novel> get localNovels => _novelManager.localNovels;
  List<Novel> get favoriteNovels => _novelManager.favoriteNovels;

  Locale get currentLocale => _uiSettings.currentLocale;
  ThemeMode get themeMode => _uiSettings.themeMode;
  Color get accentColor => _uiSettings.accentColor;
  bool get navAlwaysVisible => _uiSettings.navAlwaysVisible;
  double get navScrollThreshold => _uiSettings.navScrollThreshold;
  int get navAnimationMs => _uiSettings.navAnimationMs;

  String? get customDns => _networkSettings.customDns;
  String? get customUserAgent => _networkSettings.customUserAgent;

  Map<String, dynamic> get readerPrefs => _readerPrefs.prefs;

  DownloadQueueService get downloadQueue => _downloadQueue;
  NovelDatabase get database => _db;

  Future<void> initialize() async {
    try {
      isBusy = true;
      _db = await NovelDatabase.getInstance();
      _initializeManagers();
      _initializeConnectivity();
      _downloadQueue = DownloadQueueService();

      await Future.wait([
        _novelManager.initialize(),
        _uiSettings.initialize(),
        _networkSettings.initialize(),
        _readerPrefs.initialize(),
      ], eagerError: false);

      await _setupLocale();

      try {
        final backupSvc = BackupService();
        await backupSvc.performDailyBackup();
      } catch (_) {}

      _startCleanupTimer();
      _startHealthCheckTimer();

      isBusy = false;
      notifyListeners();
    } catch (e) {
      isBusy = false;
      if (kDebugMode) print('Error initializing AppState: $e');
      notifyListeners();
    }
  }

  void _initializeManagers() {
    _novelManager = NovelManager(_db);
    _chapterManager = ChapterManager(_db);
    _pluginManager = PluginManager(_db);
    _uiSettings = UiSettingsManager(_db);
    _networkSettings = NetworkSettingsManager(_db);
    _readerPrefs = ReaderPreferencesManager(_db);
  }

  Future<void> _setupLocale() async {
    try {
      if (currentLocale.languageCode != I18n.currentLocate.languageCode) {
        await I18n.updateLocate(currentLocale);
      }
    } catch (_) {}
  }

  void _initializeConnectivity() {
    final conn = Connectivity();
    try {
      conn
          .checkConnectivity()
          .then((r) {
            isOnline = r != ConnectivityResult.none;
            notifyListeners();
          })
          .catchError((_) {
            isOnline = true;
            notifyListeners();
          });
    } catch (_) {
      isOnline = true;
    }

    try {
      _connectivitySub = conn.onConnectivityChanged.listen((r) {
        final newVal = r != ConnectivityResult.none;
        if (newVal != isOnline) {
          isOnline = newVal;
          notifyListeners();
        }
      });
    } catch (_) {}
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 30), (_) async {
      try {
        if (!isBusy) {
          await _performCleanup();
        }
      } catch (e) {
        if (kDebugMode) print('Cleanup error: $e');
      }
    });
  }

  Future<void> _performCleanup() async {
    try {
      await _db.pruneOldData();
      await _db.optimize();
      if (kDebugMode) print('Database cleanup completed');
    } catch (e) {
      if (kDebugMode) print('Database cleanup failed: $e');
    }
  }

  void _startHealthCheckTimer() {
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_db.isHealthy) {
        if (kDebugMode) print('Database health issue: ${_db.lastHealthError}');
        _attemptRecovery();
      }
    });
  }

  Future<void> _attemptRecovery() async {
    try {
      if (kDebugMode) print('Attempting database recovery...');
      await _db.optimize();
      await refreshLocalNovels(notify: false);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Recovery failed: $e');
    }
  }

  Future<void> addOrUpdateNovel(Novel novel) async {
    try {
      await _safeOperation(() => _novelManager.addOrUpdateNovel(novel));
      notifyListeners();
    } catch (e) {
      _handleError('addOrUpdateNovel', e);
    }
  }

  Future<void> toggleFavorite(String id, {bool? value}) async {
    try {
      await _safeOperation(
        () => _novelManager.toggleFavorite(id, value: value),
      );
      notifyListeners();
    } catch (e) {
      _handleError('toggleFavorite', e);
    }
  }

  Future<void> removeNovel(String id) async {
    try {
      await _safeOperation(() => _novelManager.removeNovel(id));
      notifyListeners();
    } catch (e) {
      _handleError('removeNovel', e);
    }
  }

  Future<void> refreshLocalNovels({bool notify = true}) async {
    try {
      await _safeOperation(() => _novelManager.refreshLocalNovels());
      if (notify) notifyListeners();
    } catch (e) {
      _handleError('refreshLocalNovels', e);
    }
  }

  Novel? getNovelById(String id) {
    try {
      return _novelManager.getNovelById(id);
    } catch (e) {
      _handleError('getNovelById', e);
      return null;
    }
  }

  Future<void> setChapterRead(
    String novelId,
    String chapterId,
    bool read,
  ) async {
    try {
      await _safeOperation(
        () => _chapterManager.setChapterRead(novelId, chapterId, read),
      );
      await refreshLocalNovels(notify: false);
    } catch (e) {
      _handleError('setChapterRead', e);
    }
  }

  Future<void> saveChapterOffline(String novelId, Chapter chapter) async {
    try {
      await _safeOperation(
        () => _chapterManager.saveChapterOffline(novelId, chapter),
      );
      notifyListeners();
    } catch (e) {
      _handleError('saveChapterOffline', e);
    }
  }

  Future<void> deleteSavedChapter(String novelId, String chapterId) async {
    try {
      await _safeOperation(
        () => _chapterManager.deleteSavedChapter(novelId, chapterId),
      );
      notifyListeners();
    } catch (e) {
      _handleError('deleteSavedChapter', e);
    }
  }

  Future<bool> isChapterSaved(String novelId, String chapterId) async {
    try {
      return await _chapterManager.isChapterSaved(novelId, chapterId);
    } catch (e) {
      _handleError('isChapterSaved', e);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSavedChaptersForNovel(
    String novelId,
  ) async {
    try {
      return await _chapterManager.getSavedChaptersForNovel(novelId);
    } catch (e) {
      _handleError('getSavedChaptersForNovel', e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSavedChapter(
    String novelId,
    String chapterId,
  ) async {
    try {
      return await _chapterManager.getSavedChapter(novelId, chapterId);
    } catch (e) {
      _handleError('getSavedChapter', e);
      return null;
    }
  }

  Future<bool> getPluginState(String id) async {
    try {
      return await _pluginManager.getPluginState(id);
    } catch (e) {
      _handleError('getPluginState', e);
      return true;
    }
  }

  Future<void> setPluginState(String id, bool enabled) async {
    try {
      await _safeOperation(() => _pluginManager.setPluginState(id, enabled));
      notifyListeners();
    } catch (e) {
      _handleError('setPluginState', e);
    }
  }

  Future<void> setPluginPrefs(String id, Map<String, dynamic> prefs) async {
    try {
      await _safeOperation(() => _pluginManager.setPluginPrefs(id, prefs));
    } catch (e) {
      _handleError('setPluginPrefs', e);
    }
  }

  Future<Map<String, dynamic>?> getPluginPrefs(String id) async {
    try {
      return await _pluginManager.getPluginPrefs(id);
    } catch (e) {
      _handleError('getPluginPrefs', e);
      return null;
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      await _safeOperation(() => _uiSettings.setLocale(locale));
      try {
        await I18n.updateLocate(locale);
      } catch (_) {}
      notifyListeners();
    } catch (e) {
      _handleError('setLocale', e);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      await _safeOperation(() => _uiSettings.setThemeMode(mode));
      notifyListeners();
    } catch (e) {
      _handleError('setThemeMode', e);
    }
  }

  Future<void> setAccentColor(Color color) async {
    try {
      await _safeOperation(() => _uiSettings.setAccentColor(color));
      notifyListeners();
    } catch (e) {
      _handleError('setAccentColor', e);
    }
  }

  Future<void> setNavAlwaysVisible(bool value) async {
    try {
      await _safeOperation(() => _uiSettings.setNavAlwaysVisible(value));
      notifyListeners();
    } catch (e) {
      _handleError('setNavAlwaysVisible', e);
    }
  }

  Future<void> setNavScrollThreshold(double value) async {
    try {
      await _safeOperation(() => _uiSettings.setNavScrollThreshold(value));
      notifyListeners();
    } catch (e) {
      _handleError('setNavScrollThreshold', e);
    }
  }

  Future<void> setNavAnimationMs(int ms) async {
    try {
      await _safeOperation(() => _uiSettings.setNavAnimationMs(ms));
      notifyListeners();
    } catch (e) {
      _handleError('setNavAnimationMs', e);
    }
  }

  Future<void> setCustomDns(String? dns) async {
    try {
      await _safeOperation(() => _networkSettings.setCustomDns(dns));
      notifyListeners();
    } catch (e) {
      _handleError('setCustomDns', e);
    }
  }

  Future<void> setCustomUserAgent(String? ua) async {
    try {
      await _safeOperation(() => _networkSettings.setCustomUserAgent(ua));
      notifyListeners();
    } catch (e) {
      _handleError('setCustomUserAgent', e);
    }
  }

  Future<void> setReaderPrefs(Map<String, dynamic> prefs) async {
    try {
      await _safeOperation(() => _readerPrefs.setPreferences(prefs));
      notifyListeners();
    } catch (e) {
      _handleError('setReaderPrefs', e);
    }
  }

  Map<String, dynamic> getReaderPrefs() => _readerPrefs.getPreferences();


  void setOnQueueUpdated(VoidCallback? callback) {
    _onQueueUpdated = callback;
  }

  Future<void> addChapterToDownloadQueue(
    String novelId,
    Chapter chapter,
  ) async {
    try {
      _downloadQueue.addToQueue(novelId, chapter);
      _notifyQueueUpdated();
      await _processDownloadQueue();
    } catch (e) {
      _handleError('addChapterToDownloadQueue', e);
    }
  }

  Future<void> removeFromDownloadQueue(String novelId, String chapterId) async {
    try {
      _downloadQueue.removeFromQueue(novelId, chapterId);
      _notifyQueueUpdated();
    } catch (e) {
      _handleError('removeFromDownloadQueue', e);
    }
  }

  Future<void> _processDownloadQueue() async {
    try {
      await _downloadQueue.processQueue((novelId) {
        return getNovelById(novelId) ??
            Novel(
              id: novelId,
              title: '',
              coverImageUrl: '',
              author: '',
              description: '',
              chapters: [],
              pluginId: '',
              genres: [],
            );
      });
    } catch (_) {}
    _notifyQueueUpdated();
  }

  void _notifyQueueUpdated() {
    _onQueueUpdated?.call();
    notifyListeners();
  }

  Future<Map<String, int>> checkForUpdates() async {
    final Map<String, int> updates = {};
    final favorites = favoriteNovels;
    const int maxConcurrent = 4;

    final chunks = List<List<Novel>>.generate(maxConcurrent, (_) => []);
    for (int i = 0; i < favorites.length; i++) {
      chunks[i % maxConcurrent].add(favorites[i]);
    }

    await Future.wait(
      chunks.map((chunk) async {
        for (final novel in chunk) {
          await _checkNovelUpdates(novel, updates);
        }
      }),
    );

    await refreshLocalNovels(notify: false);
    return updates;
  }

  Future<void> _checkNovelUpdates(Novel novel, Map<String, int> updates) async {
    final service = PluginRegistry.get(novel.pluginId);
    if (service == null) return;

    try {
      final enabled = await _pluginManager.getPluginState(service.name);
      if (!enabled) return;

      final latest = await service
          .parseNovel(novel.id)
          .timeout(const Duration(seconds: 15));

      final latestCount = latest.chapters.length;
      final known = novel.lastKnownChapterCount;

      if (latestCount > known) {
        final newChapters = latest.chapters.sublist(known);
        final readSet = await _chapterManager.getReadChaptersForNovel(novel.id);
        int newUnread =
            newChapters.where((ch) => !readSet.contains(ch.id)).length;
        updates[novel.id] = newUnread;
        novel.lastKnownChapterCount = latestCount;
      }

      novel.lastChecked = DateTime.now().toIso8601String();
      await _novelManager.addOrUpdateNovel(novel);
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao verificar ${novel.id}: $e');
    }
  }


  Future<T> _safeOperation<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      isBusy = true;
      notifyListeners();

      return await operation().timeout(timeout);
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Operation timeout');
      }
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void _handleError(String operation, dynamic error) {
    final message = 'Error in $operation: $error';
    if (error is TimeoutException) {
      if (kDebugMode) print('[TIMEOUT] $message');
    } else {
      if (kDebugMode) print('[ERROR] $message');
    }
  }

  Future<void> ensureDataPersistence() async {
    try {
      if (kDebugMode) print('[AppState] Ensuring data persistence...');

      if (isBusy) {
        if (kDebugMode) print('[AppState] Waiting for pending operations...');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (kDebugMode) print('[AppState] Data persistence complete');
    } catch (e) {
      if (kDebugMode) print('[AppState] Error during data persistence: $e');
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _cleanupTimer?.cancel();
    _healthCheckTimer?.cancel();
    _db.dispose();
    super.dispose();
  }
}
