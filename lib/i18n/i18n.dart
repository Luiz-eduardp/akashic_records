import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

const _PATH = 'lib/assets/i18n/locale';

const _DEFAULT_LOCALE = Locale('en');

class I18n {
  static final I18n _instance = I18n._internal([_DEFAULT_LOCALE]);

  late Locale _locate;

  late List<Locale> _supportLocales;

  late Map<dynamic, dynamic> _values;

  I18n._internal(this._supportLocales) {
    _setCurrentLocate(_DEFAULT_LOCALE);
  }

  Future<I18n> load() async {
    var code = _locate.languageCode;
    String data = await rootBundle.loadString(
      _PATH + '/i18n_' + code + '.json',
    );
    _values = json.decode(data);
    return _instance;
  }

  void _setCurrentLocate(Locale locale) => _locate = locale;

  void _setSupportLocales(List<Locale> supportLocales) =>
      _supportLocales = supportLocales;

  String _getValue(String key) => _values[key] ?? '** ' + key + ' not found';

  static Locale get currentLocate => _instance._locate;

  static List<Locale> get supportedLocales => _instance._supportLocales;

  static String getValue(String key) => _instance._getValue(key);

  static Future<I18n> updateLocate(Locale locale) {
    _instance._setCurrentLocate(locale);
    return _instance.load();
  }

  static Future<I18n> initialize({
    required Locale defaultLocale,
    List<Locale>? supportLocales,
  }) async {
    _instance._setCurrentLocate(defaultLocale);
    _instance._setSupportLocales(supportLocales ?? [_DEFAULT_LOCALE]);
    return await _instance.load();
  }
}

class I18nDelegate extends LocalizationsDelegate<I18n> {
  const I18nDelegate();

  @override
  bool isSupported(Locale locale) => I18n._instance._supportLocales
      .map((locale) => locale.languageCode)
      .contains(locale.languageCode);

  @override
  Future<I18n> load(Locale locale) async => I18n.updateLocate(locale);

  @override
  bool shouldReload(I18nDelegate old) => false;
}

extension StringEx on String {
  String get translate => I18n.getValue(this);
}
