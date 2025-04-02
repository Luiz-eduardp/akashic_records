import 'dart:convert';
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
  CustomColors? customColors;
  String? customJs;
  String? customCss;

  ReaderSettings({
    this.theme = ReaderTheme.light,
    this.fontSize = 30.0,
    this.fontFamily = 'Courier New',
    this.lineHeight = 1.5,
    this.textAlign = TextAlign.justify,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.fontWeight = FontWeight.normal,
    this.customColors,
    this.customJs,
    this.customCss,
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
      'customBackgroundColor': customColors?.backgroundColor?.value,
      'customTextColor': customColors?.textColor?.value,
      'customJs': customJs,
      'customCss': customCss,
    };
  }

  static ReaderSettings fromMap(Map<String, dynamic> map) {
    return ReaderSettings(
      theme: ReaderTheme.values[map['theme'] ?? 0],
      fontSize: (map['fontSize'] ?? 18.0).toDouble(),
      fontFamily: map['fontFamily'] ?? 'Roboto',
      lineHeight: (map['lineHeight'] ?? 1.5).toDouble(),
      textAlign: TextAlign.values[map['textAlign'] ?? 3],
      backgroundColor: Color(map['backgroundColor'] ?? Colors.white.value),
      textColor: Color(map['textColor'] ?? Colors.black.value),
      fontWeight: FontWeight.values[map['fontWeight'] ?? 4],
      customColors:
          map['customBackgroundColor'] != null || map['customTextColor'] != null
              ? CustomColors(
                backgroundColor:
                    map['customBackgroundColor'] != null
                        ? Color(map['customBackgroundColor'])
                        : null,
                textColor:
                    map['customTextColor'] != null
                        ? Color(map['customTextColor'])
                        : null,
              )
              : null,
      customJs: map['customJs'],
      customCss: map['customCss'],
    );
  }
}

class CustomPlugin {
  String name;
  String code;
  bool enabled;
  int priority;

  CustomPlugin({
    required this.name,
    required this.code,
    this.enabled = true,
    this.priority = 0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'enabled': enabled,
    'priority': priority,
  };

  factory CustomPlugin.fromJson(Map<String, dynamic> json) => CustomPlugin(
    name: json['name'],
    code: json['code'],
    enabled: json['enabled'] ?? true,
    priority: json['priority'] ?? 0,
  );
}

class AppState with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = Colors.blue;
  bool _settingsLoaded = false;
  Set<String> _selectedPlugins = {};
  ReaderSettings _readerSettings = ReaderSettings();
  List<CustomPlugin> _customPlugins = [];

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
  List<CustomPlugin> get customPlugins => _customPlugins;

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

  void addCustomPlugin(CustomPlugin plugin) {
    _customPlugins.add(plugin);
    _saveCustomPlugins();
    notifyListeners();
  }

  void updateCustomPlugin(int index, CustomPlugin plugin) {
    _customPlugins[index] = plugin;
    _saveCustomPlugins();
    notifyListeners();
  }

  void removeCustomPlugin(int index) {
    _customPlugins.removeAt(index);
    _saveCustomPlugins();
    notifyListeners();
  }

  void setCustomPlugins(List<CustomPlugin> plugins) {
    _customPlugins = plugins;
    _saveCustomPlugins();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final plugins = prefs.getStringList('selectedPlugins');
      _selectedPlugins =
          plugins?.isNotEmpty == true ? Set<String>.from(plugins!) : {};

      final themeModeIndex =
          prefs.getInt('themeMode') ?? ThemeMode.system.index;
      _themeMode = ThemeMode.values[themeModeIndex];
      _accentColor = Color(prefs.getInt('accentColor') ?? Colors.blue.value);

      final readerSettingsMap = <String, dynamic>{};
      for (final key in prefs.getKeys()) {
        if (key.startsWith('reader_')) {
          final value = prefs.get(key);
          readerSettingsMap[key.substring(7)] = value;
        }
      }
      if (readerSettingsMap.isNotEmpty) {
        _readerSettings = ReaderSettings.fromMap(readerSettingsMap);
      }

      final customPluginsJson = prefs.getStringList('customPlugins');
      if (customPluginsJson != null) {
        _customPlugins =
            customPluginsJson
                .map((json) => CustomPlugin.fromJson(jsonDecode(json)))
                .toList();
      }

      _settingsLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao carregar configurações: $e");
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
      debugPrint("Erro ao salvar plugins selecionados: $e");
    }
  }

  Future<void> _saveThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('themeMode', _themeMode.index);
      await prefs.setInt('accentColor', _accentColor.value);
    } catch (e) {
      debugPrint("Erro ao salvar configurações do tema: $e");
    }
  }

  Future<void> _saveReaderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsMap = _readerSettings.toMap();
      for (final key in settingsMap.keys) {
        final value = settingsMap[key];
        final prefsKey = 'reader_$key';

        if (value is int) {
          await prefs.setInt(prefsKey, value);
        } else if (value is double) {
          await prefs.setDouble(prefsKey, value);
        } else if (value is String) {
          await prefs.setString(prefsKey, value);
        } else if (value is bool) {
          await prefs.setBool(prefsKey, value);
        } else if (value == null) {
          await prefs.remove(prefsKey);
        }
      }
    } catch (e) {
      debugPrint("Erro ao salvar configurações do leitor: $e");
    }
  }

  Future<void> _saveCustomPlugins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPluginsJson =
          _customPlugins.map((plugin) => jsonEncode(plugin.toJson())).toList();
      await prefs.setStringList('customPlugins', customPluginsJson);
    } catch (e) {
      debugPrint("Erro ao salvar plugins customizados: $e");
    }
  }
}
