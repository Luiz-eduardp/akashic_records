import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

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
    currentLocate = defaultLocale;
    supportedLocales = supportLocales ?? supportedLocales;
    await _loadLocale(currentLocate);
  }

  static Future<void> _loadLocale(Locale locale) async {
    try {
      final data = await rootBundle.loadString(
        'lib/assets/i18n/locale/${locale.languageCode}.json',
      );
      _translations = json.decode(data) as Map<String, dynamic>;
      currentLocate = locale;
    } catch (e) {
      _translations = {};
    }
  }

  static Future<void> updateLocate(Locale locale) async {
    await _loadLocale(locale);
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
