import 'package:akashic_records/services/plugins/english/boxnovel_service.dart';
import 'package:akashic_records/services/plugins/english/novelonline_service.dart';
import 'package:akashic_records/services/plugins/ptbr/mtl_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/services/plugins/ptbr/novelmania_service.dart';
import 'package:akashic_records/services/plugins/ptbr/tsundoku_service.dart';
import 'package:akashic_records/services/plugins/ptbr/centralnovel_service.dart';

enum ReaderTheme {
  light,
  dark,
  sepia,
  darkGreen,
  amoledDark,
  grey,
  solarizedLight,
  solarizedDark,
}

class CustomColors {
  final Color? backgroundColor;
  final Color? textColor;

  CustomColors({this.backgroundColor, this.textColor});
}

class ReaderSettings {
  ReaderTheme theme;
  double fontSize;
  String fontFamily;
  double lineHeight;
  TextAlign textAlign;
  Color backgroundColor;
  Color textColor;
  FontWeight fontWeight;
  bool bionicReading;
  CustomColors? customColors;

  ReaderSettings({
    this.theme = ReaderTheme.light,
    this.fontSize = 18.0,
    this.fontFamily = 'Roboto',
    this.lineHeight = 1.5,
    this.textAlign = TextAlign.justify,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.fontWeight = FontWeight.normal,
    this.bionicReading = false,
    this.customColors,
  });

  Map<String, dynamic> toMap() {
    return {
      'theme': theme.index,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'lineHeight': lineHeight,
      'textAlign': textAlign.index,
      'backgroundColor': backgroundColor.value,
      'textColor': textColor.value,
      'fontWeight': fontWeight.index,
      'bionicReading': bionicReading,
      'customBackgroundColor': customColors?.backgroundColor?.value,
      'customTextColor': customColors?.textColor?.value,
    };
  }

  static ReaderSettings fromMap(Map<String, dynamic> map) {
    return ReaderSettings(
      theme: ReaderTheme.values[map['theme'] ?? 0],
      fontSize: map['fontSize'] ?? 18.0,
      fontFamily: map['fontFamily'] ?? 'Roboto',
      lineHeight: map['lineHeight'] ?? 1.5,
      textAlign: TextAlign.values[map['textAlign'] ?? 3],
      backgroundColor: Color(map['backgroundColor'] ?? Colors.white.value),
      textColor: Color(map['textColor'] ?? Colors.black.value),
      fontWeight: FontWeight.values[map['fontWeight'] ?? 4],
      bionicReading: map['bionicReading'] ?? false,
      customColors: CustomColors(
        backgroundColor:
            map['customBackgroundColor'] != null
                ? Color(map['customBackgroundColor'])
                : null,
        textColor:
            map['customTextColor'] != null
                ? Color(map['customTextColor'])
                : null,
      ),
    );
  }
}

class AppState with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = Colors.blue;
  bool _settingsLoaded = false;
  Set<String> _selectedPlugins = {};
  ReaderSettings _readerSettings = ReaderSettings();

  final Map<String, PluginService> _pluginServices = {};

  AppState() {
    _pluginServices['NovelMania'] = NovelMania();
    _pluginServices['Tsundoku'] = Tsundoku();
    _pluginServices['CentralNovel'] = CentralNovel();
    _pluginServices['MtlNovelPt'] = MtlNovelPt();
    _pluginServices['BoxNovel'] = BoxNovel();
    _pluginServices['NovelsOnline'] = NovelsOnline();
  }

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get settingsLoaded => _settingsLoaded;
  Set<String> get selectedPlugins => _selectedPlugins;
  ReaderSettings get readerSettings => _readerSettings;

  Map<String, PluginService> get pluginServices => _pluginServices;

  void setThemeMode(ThemeMode newThemeMode) {
    _themeMode = newThemeMode;
    _saveThemeSettings();
    notifyListeners();
  }

  void setAccentColor(Color newAccentColor) {
    _accentColor = newAccentColor;
    _saveThemeSettings();
    notifyListeners();
  }

  void setSelectedPlugins(Set<String> newPlugins) {
    _selectedPlugins = newPlugins;
    _saveSelectedPlugins();
    notifyListeners();
  }

  void setReaderSettings(ReaderSettings newSettings) {
    _readerSettings = newSettings;
    _saveReaderSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plugins = prefs.getStringList('selectedPlugins');

      Set<String> savedPlugins =
          (plugins?.isNotEmpty == true ? Set<String>.from(plugins!) : {});

      _selectedPlugins = savedPlugins;

      _themeMode =
          ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
      _accentColor = Color(prefs.getInt('accentColor') ?? Colors.blue.value);
      final settingsMap = prefs.getKeys().fold<Map<String, dynamic>>(
        {},
        (previousValue, key) => {
          ...previousValue,
          if (key.startsWith('reader_')) key.substring(7): prefs.get(key),
        },
      );

      if (settingsMap.isNotEmpty) {
        _readerSettings = ReaderSettings.fromMap(settingsMap);
      }
      _settingsLoaded = true;
      notifyListeners();
    } catch (e) {
      print("Erro ao carregar configurações: $e");
    }
  }

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _saveSelectedPlugins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selectedPlugins', _selectedPlugins.toList());
    } catch (e) {
      print("Erro ao salvar plugins selecionados: $e");
    }
  }

  Future<void> _saveThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setInt('accentColor', _accentColor.value);
  }

  Future<void> _saveReaderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsMap = _readerSettings.toMap();
    settingsMap.forEach((key, value) async {
      if (value is int) {
        await prefs.setInt('reader_$key', value);
      } else if (value is double) {
        await prefs.setDouble('reader_$key', value);
      } else if (value is String) {
        await prefs.setString('reader_$key', value);
      } else if (value is bool) {
        await prefs.setBool('reader_$key', value);
      } else if (value is int?) {
        if (value != null) {
          await prefs.setInt('reader_$key', value);
        }
      }
    });
  }
}
