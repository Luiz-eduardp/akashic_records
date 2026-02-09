import 'package:flutter/material.dart';
import 'package:akashic_records/db/novel_database.dart';

class UiSettingsManager {
  final NovelDatabase _db;

  Locale _currentLocale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.dark;
  Color _accentColor = const Color(0xFFD1973A);
  bool _navAlwaysVisible = false;
  double _navScrollThreshold = 6.0;
  int _navAnimationMs = 250;

  UiSettingsManager(this._db);

  Locale get currentLocale => _currentLocale;
  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get navAlwaysVisible => _navAlwaysVisible;
  double get navScrollThreshold => _navScrollThreshold;
  int get navAnimationMs => _navAnimationMs;

  Future<void> initialize() async {
    await _loadLocale();
    await _loadThemeMode();
    await _loadAccentColor();
    await _loadNavSettings();
  }

  Future<void> _loadLocale() async {
    try {
      final saved = await _db.settings.getSetting('app_locale');
      if (saved != null && saved.isNotEmpty) {
        final parts = saved.split('_');
        _currentLocale =
            parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
      }
    } catch (_) {}
  }

  Future<void> _loadThemeMode() async {
    try {
      final tm = await _db.settings.getSetting('theme_mode');
      switch (tm) {
        case 'light':
          _themeMode = ThemeMode.light;
        case 'dark':
          _themeMode = ThemeMode.dark;
        default:
          _themeMode = ThemeMode.dark;
      }
    } catch (_) {}
  }

  Future<void> _loadAccentColor() async {
    try {
      final accentVal = await _db.settings.getSetting('accent_color');
      if (accentVal != null) {
        _accentColor = Color(int.parse(accentVal));
      }
    } catch (_) {}
  }

  Future<void> _loadNavSettings() async {
    try {
      final navAlways = await _db.settings.getSetting('nav_always_visible');
      if (navAlways != null) _navAlwaysVisible = navAlways == 'true';
    } catch (_) {}

    try {
      final thr = await _db.settings.getSetting('nav_scroll_threshold');
      if (thr != null) {
        _navScrollThreshold = double.tryParse(thr) ?? _navScrollThreshold;
      }
    } catch (_) {}

    try {
      final ms = await _db.settings.getSetting('nav_animation_ms');
      if (ms != null) _navAnimationMs = int.tryParse(ms) ?? _navAnimationMs;
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    try {
      await _db.settings.setSetting(
        'app_locale',
        locale.countryCode != null && locale.countryCode!.isNotEmpty
            ? '${locale.languageCode}_${locale.countryCode}'
            : locale.languageCode,
      );
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final modeStr =
        mode == ThemeMode.light
            ? 'light'
            : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await _db.settings.setSetting('theme_mode', modeStr);
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    await _db.settings.setSetting('accent_color', color.value.toString());
  }

  Future<void> setNavAlwaysVisible(bool value) async {
    _navAlwaysVisible = value;
    await _db.settings.setSetting(
      'nav_always_visible',
      value ? 'true' : 'false',
    );
  }

  Future<void> setNavScrollThreshold(double value) async {
    _navScrollThreshold = value;
    await _db.settings.setSetting('nav_scroll_threshold', value.toString());
  }

  Future<void> setNavAnimationMs(int ms) async {
    _navAnimationMs = ms;
    await _db.settings.setSetting('nav_animation_ms', ms.toString());
  }
}
