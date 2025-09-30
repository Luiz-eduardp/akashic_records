import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class I18n {
  static Locale currentLocate = const Locale('en');
  static List<Locale> supportedLocales = const [
    Locale('en'),
    Locale('pt', 'BR'),
    Locale('es'),
    Locale('ja'),
    Locale('ar'),
    Locale('it'),
    Locale('fr'),
  ];

  static Map<String, dynamic> _translations = {};

  static Future<void> initialize({
    required Locale defaultLocale,
    List<Locale>? supportLocales,
  }) async {
    supportedLocales = supportLocales ?? supportedLocales;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('locale');
      if (saved != null && saved.isNotEmpty) {
        final parts = saved.split('_');
        final loc =
            parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
        currentLocate = loc;
        await _loadLocale(currentLocate);
        return;
      }
    } catch (_) {}

    currentLocate = defaultLocale;
    await _loadLocale(currentLocate);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key =
          currentLocate.countryCode != null &&
                  currentLocate.countryCode!.isNotEmpty
              ? '${currentLocate.languageCode}_${currentLocate.countryCode}'
              : currentLocate.languageCode;
      await prefs.setString('locale', key);
    } catch (_) {}
  }

  static Future<void> _loadLocale(Locale locale) async {
    try {
      String? data;
      if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
        try {
          data = await rootBundle.loadString(
            'lib/assets/i18n/locale/${locale.languageCode}_${locale.countryCode}.json',
          );
        } catch (_) {
          data = null;
        }
      }
      if (data == null) {
        try {
          data = await rootBundle.loadString(
            'lib/assets/i18n/locale/${locale.languageCode}.json',
          );
        } catch (_) {
          data = null;
        }
      }

      if (data != null) {
        _translations = json.decode(data) as Map<String, dynamic>;
        currentLocate = locale;
      } else {
        _translations = {};
      }
    } catch (e) {
      _translations = {};
    }
  }

  static Future<void> updateLocate(Locale locale) async {
    await _loadLocale(locale);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key =
          locale.countryCode != null && locale.countryCode!.isNotEmpty
              ? '${locale.languageCode}_${locale.countryCode}'
              : locale.languageCode;
      await prefs.setString('locale', key);
    } catch (_) {}
  }
}

extension TranslateExt on String {
  String get translate {
    return I18n._translations[this] as String? ?? this;
  }
}

class I18nDelegate extends LocalizationsDelegate<dynamic> {
  const I18nDelegate();

  @override
  bool isSupported(Locale locale) =>
      I18n.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<dynamic> load(Locale locale) async {
    await I18n.updateLocate(locale);
    return SynchronousFuture(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
