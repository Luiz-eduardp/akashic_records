import 'dart:convert';
import 'package:akashic_records/services/plugins/english/novelonline_service.dart';
import 'package:akashic_records/services/plugins/english/reapersscan_service.dart';
import 'package:akashic_records/services/plugins/english/royalroad_service.dart';
import 'package:akashic_records/services/plugins/english/webnovel_servce.dart';
import 'package:akashic_records/services/plugins/portuguese/blogdoamonnovels_service.dart';
import 'package:akashic_records/services/plugins/portuguese/lightnovelbrasil_service.dart';
import 'package:akashic_records/services/plugins/portuguese/mtl_service.dart';
import 'package:akashic_records/services/plugins/portuguese/saikaiscans_service.dart';
import 'package:akashic_records/services/plugins/spanish/skynovels_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/services/plugins/portuguese/novelmania_service.dart';
import 'package:akashic_records/services/plugins/portuguese/tsundoku_service.dart';
import 'package:akashic_records/services/plugins/portuguese/centralnovel_service.dart';

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
    this.theme = ReaderTheme.dark,
    this.fontSize = 30.0,
    this.fontFamily = 'Courier New',
    this.lineHeight = 1.5,
    this.textAlign = TextAlign.justify,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.fontWeight = FontWeight.w900,
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
  String use;
  bool enabled;
  int priority;

  CustomPlugin({
    required this.name,
    required this.code,
    required this.use,
    this.enabled = true,
    this.priority = 0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'use': use,
    'enabled': enabled,
    'priority': priority,
  };

  factory CustomPlugin.fromJson(Map<String, dynamic> json) => CustomPlugin(
    name: json['name'],
    code: json['code'],
    use: json['use'],
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

  final List<CustomPlugin> _defaultPlugins = [
    CustomPlugin(
      name: 'Focus Mode',
      use: 'Duplo toque no texto para ativar e desativar o modo de foco',
      code: '''
     (() => {
  function loadScript(src, callback) {
    const script = document.createElement("script");
    script.src = src;
    script.onload = callback;
    document.head.appendChild(script);
  }

  function createStyle() {
    const style = document.createElement("style");
    style.innerHTML = `
      .focus-overlay {
        position: fixed;
        top: -10px;
        left: -2px;
        right: -2px;
        height: var(--focus-area-height, 30%);
        background: rgba(0, 0, 0, 0.5);
        pointer-events: none;
        z-index: 9999;
        filter: blur(1px);
        transition: opacity 0.3s ease;
      }
      .focus-overlay-bottom {
        position: fixed;
        bottom: -10px;
        left: -2px;
        right: -2px;
        height: var(--focus-area-height, 30%);
        background: rgba(0, 0, 0, 0.5);
        pointer-events: none;
        z-index: 9999;
        filter: blur(1px);
        transition: opacity 0.3s ease;
      }
      .toast {
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background-color: rgba(0, 0, 0, 0.7);
        color: white;
        padding: 8px 15px;
        border-radius: 5px;
        font-size: 14px;
        z-index: 9999;
        display: none;
      }
    `;
    document.head.appendChild(style);
  }

  function createFocusOverlays() {
    const focusOverlayTop = document.createElement("div");
    focusOverlayTop.className = "focus-overlay";

    const focusOverlayBottom = document.createElement("div");
    focusOverlayBottom.className = "focus-overlay-bottom";

    return { focusOverlayTop, focusOverlayBottom };
  }

  function createToast() {
    const toast = document.createElement("div");
    toast.className = "toast";
    document.body.appendChild(toast); 
    return toast;
  }

  let staticFocusMode = false;
  const focusAreaHeight = 30;
  const { focusOverlayTop, focusOverlayBottom } = createFocusOverlays();
  const toast = createToast();

  function toggleStaticFocusMode() {
    staticFocusMode = !staticFocusMode;

    if (staticFocusMode) {
      document.documentElement.style.setProperty(
        "--focus-area-height",
        `30%`
      );
      document.body.appendChild(focusOverlayTop);
      document.body.appendChild(focusOverlayBottom);
      showToast("Focus Mode Activated");
      adjustOverlayOpacity();
    } else {
      if (focusOverlayTop.parentNode) {
        focusOverlayTop.parentNode.removeChild(focusOverlayTop);
      }
      if (focusOverlayBottom.parentNode) {
        focusOverlayBottom.parentNode.removeChild(focusOverlayBottom);
      }
      showToast("Focus Mode Disabled");
    }
  }

  function adjustOverlayOpacity() {
    const scrollTop = window.scrollY || document.documentElement.scrollTop;
    const windowHeight = window.innerHeight;
    const docHeight = document.documentElement.scrollHeight;
    const scrollPosition = scrollTop + windowHeight;

    const topOffset = Math.min(scrollTop / 100, 1);
    const distanceFromBottom = docHeight - scrollPosition;
    const bottomOffset = Math.max(distanceFromBottom / 100, 0);

    focusOverlayTop.style.opacity = topOffset.toString();
    focusOverlayBottom.style.opacity = bottomOffset.toString();
  }

  function showToast(message) {
    toast.textContent = message;
    toast.style.display = "block";

    setTimeout(() => {
      toast.style.display = "none";
    }, 1000);
  }

  function handleTripleClick(event) {
    if (event.detail === 3) {
      toggleStaticFocusMode();
    }
  }

  function handleScroll() {
    if (staticFocusMode) {
      adjustOverlayOpacity();
    }
  }

  createStyle();
  document.addEventListener("click", handleTripleClick);
  window.addEventListener("scroll", handleScroll);
  toggleStaticFocusMode();
})();
      ''',
      enabled: true,
      priority: 1,
    ),
  ];

  AppState() {
    _pluginServices['NovelMania'] = NovelMania();
    _pluginServices['Tsundoku'] = Tsundoku();
    _pluginServices['CentralNovel'] = CentralNovel();
    _pluginServices['MtlNovelPt'] = MtlNovelPt();
    _pluginServices['NovelsOnline'] = NovelsOnline();
    _pluginServices['RoyalRoad'] = RoyalRoad();
    _pluginServices['LightNovelBrasil'] = LightNovelBrasil();
    _pluginServices['BlogDoAmonNovels'] = BlogDoAmonNovels();
    _pluginServices['SkyNovels'] = SkyNovels();
    _pluginServices['SaikaiScans'] = SaikaiScans();
    _pluginServices['Webnovel'] = Webnovel();
    _pluginServices['ReaperScans'] = ReaperScans();
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
      if (customPluginsJson != null && customPluginsJson.isNotEmpty) {
        _customPlugins =
            customPluginsJson
                .map((json) => CustomPlugin.fromJson(jsonDecode(json)))
                .toList();
      } else {
        _customPlugins = _defaultPlugins;
        _saveCustomPlugins();
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
