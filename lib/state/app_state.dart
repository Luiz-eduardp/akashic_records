import 'dart:convert';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/services/plugins/spanish/novelsligera_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:akashic_records/services/plugins/english/novelbin_service.dart';
import 'package:akashic_records/services/plugins/english/novelonline_service.dart';
import 'package:akashic_records/services/plugins/english/reapersscan_service.dart';
import 'package:akashic_records/services/plugins/english/royalroad_service.dart';
import 'package:akashic_records/services/plugins/english/webnovel_service.dart';
import 'package:akashic_records/services/plugins/portuguese/blogdoamonnovels_service.dart';
import 'package:akashic_records/services/plugins/portuguese/lightnovelbrasil_service.dart';
import 'package:akashic_records/services/plugins/portuguese/mtl_service.dart';
import 'package:akashic_records/services/plugins/portuguese/saikaiscans_service.dart';
import 'package:akashic_records/services/plugins/spanish/skynovels_service.dart';
import 'package:akashic_records/services/plugins/portuguese/novelmania_service.dart';
import 'package:akashic_records/services/plugins/portuguese/tsundoku_service.dart';
import 'package:akashic_records/services/plugins/portuguese/centralnovel_service.dart';

import 'package:akashic_records/models/favorite_list.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/i18n/i18n.dart';

enum ReaderTheme {
  amber,
  amethyst,
  blueGrey,
  brown,
  cadetBlue,
  calmingBlue,
  coal,
  coral,
  cyberpunk,
  cyan,
  dark,
  darkCyan,
  darkGreen,
  darkOpaque,
  darkSlateGray,
  deepOrange,
  deepPurple,
  dracula,
  forest,
  grey,
  gruvboxDark,
  gruvboxLight,
  highContrast,
  indigo,
  khaki,
  lavender,
  light,
  lightSeaGreen,
  lime,
  materialDark,
  materialLight,
  mediumTurquoise,
  midnight,
  midnightBlue,
  mint,
  monokai,
  night,
  nord,
  obsidian,
  ocean,
  oliveDrab,
  peru,
  roseQuartz,
  rosyBrown,
  royalBlue,
  sand,
  sepia,
  slateGray,
  solarized,
  solarizedDark,
  solarizedLight,
  steelBlue,
  sunset,
  teal,
  translucent,
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
    this.fontSize = 18.0,
    this.fontFamily = 'Roboto',
    this.lineHeight = 1.5,
    this.textAlign = TextAlign.justify,
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
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
      theme: ReaderTheme.values[map['theme'] ?? ReaderTheme.dark.index],
      fontSize: (map['fontSize'] ?? 18.0).toDouble(),
      fontFamily: map['fontFamily'] ?? 'Roboto',
      lineHeight: (map['lineHeight'] ?? 1.5).toDouble(),
      textAlign: TextAlign.values[map['textAlign'] ?? TextAlign.justify.index],
      backgroundColor: Color(map['backgroundColor'] ?? Colors.black.value),
      textColor: Color(map['textColor'] ?? Colors.white.value),
      fontWeight:
          FontWeight.values[map['fontWeight'] ?? FontWeight.normal.index],
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
  List<String> _scriptUrls = [
    'https://api.npoint.io/bcd94c36fa7f3bf3b1e6/scripts/',
  ];
  List<FavoriteList> _favoriteLists = [];

  final Map<String, PluginService> _pluginServices = {};
  final _uuid = const Uuid();
  static const String _novelCachePrefix = 'novel_cache_';

  final List<CustomPlugin> _defaultPlugins = [
    CustomPlugin(
      name: 'Focus Mode',
      use: 'Duplo toque no texto para ativar e desativar o modo de foco',
      code:
          '''(() => { function loadScript(src, callback) { const script = document.createElement("script"); script.src = src; script.onload = callback; document.head.appendChild(script); } function createStyle() { const style = document.createElement("style"); style.innerHTML = ` .focus-overlay { position: fixed; top: -10px; left: -2px; right: -2px; height: var(--focus-area-height, 30%); background: rgba(0, 0, 0, 0.5); pointer-events: none; z-index: 9999; filter: blur(1px); transition: opacity 0.3s ease; } .focus-overlay-bottom { position: fixed; bottom: -10px; left: -2px; right: -2px; height: var(--focus-area-height, 30%); background: rgba(0, 0, 0, 0.5); pointer-events: none; z-index: 9999; filter: blur(1px); transition: opacity 0.3s ease; } .toast { position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); background-color: rgba(0, 0, 0, 0.7); color: white; padding: 8px 15px; border-radius: 5px; font-size: 14px; z-index: 9999; display: none; } `; document.head.appendChild(style); } function createFocusOverlays() { const focusOverlayTop = document.createElement("div"); focusOverlayTop.className = "focus-overlay"; const focusOverlayBottom = document.createElement("div"); focusOverlayBottom.className = "focus-overlay-bottom"; return { focusOverlayTop, focusOverlayBottom }; } function createToast() { const toast = document.createElement("div"); toast.className = "toast"; document.body.appendChild(toast); return toast; } let staticFocusMode = false; const focusAreaHeight = 30; const { focusOverlayTop, focusOverlayBottom } = createFocusOverlays(); const toast = createToast(); function toggleStaticFocusMode() { staticFocusMode = !staticFocusMode; if (staticFocusMode) { document.documentElement.style.setProperty( "--focus-area-height", `30%` ); document.body.appendChild(focusOverlayTop); document.body.appendChild(focusOverlayBottom); showToast("Focus Mode Activated"); adjustOverlayOpacity(); } else { if (focusOverlayTop.parentNode) { focusOverlayTop.parentNode.removeChild(focusOverlayTop); } if (focusOverlayBottom.parentNode) { focusOverlayBottom.parentNode.removeChild(focusOverlayBottom); } showToast("Focus Mode Disabled"); } } function adjustOverlayOpacity() { const scrollTop = window.scrollY || document.documentElement.scrollTop; const windowHeight = window.innerHeight; const docHeight = document.documentElement.scrollHeight; const scrollPosition = scrollTop + windowHeight; const topOffset = Math.min(scrollTop / 100, 1); const distanceFromBottom = docHeight - scrollPosition; const bottomOffset = Math.max(distanceFromBottom / 100); focusOverlayTop.style.opacity = topOffset.toString(); focusOverlayBottom.style.opacity = bottomOffset.toString(); } function showToast(message) { toast.textContent = message; toast.style.display = "block"; setTimeout(() => { toast.style.display = "none"; }, 1000); } function handleTripleClick(event) { if (event.detail === 3) { toggleStaticFocusMode(); } } function handleScroll() { if (staticFocusMode) { adjustOverlayOpacity(); } } createStyle(); document.addEventListener("click", handleTripleClick); window.addEventListener("scroll", handleScroll); toggleStaticFocusMode(); })();''',
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
    _pluginServices['NovelBin'] = NovelBin();
    _pluginServices['NovelasLigera'] = NovelasLigera();
  }

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get settingsLoaded => _settingsLoaded;
  Set<String> get selectedPlugins => _selectedPlugins;
  ReaderSettings get readerSettings => _readerSettings;
  List<CustomPlugin> get customPlugins => _customPlugins;
  List<String> get scriptUrls => _scriptUrls;
  Map<String, PluginService> get pluginServices => _pluginServices;
  List<FavoriteList> get favoriteLists => _favoriteLists;

  void setThemeMode(ThemeMode newThemeMode) {
    if (_themeMode != newThemeMode) {
      _themeMode = newThemeMode;
      _saveThemeSettings();
      notifyListeners();
    }
  }

  void setAccentColor(Color newAccentColor) {
    if (_accentColor != newAccentColor) {
      _accentColor = newAccentColor;
      _saveThemeSettings();
      notifyListeners();
    }
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
    if (index >= 0 && index < _customPlugins.length) {
      _customPlugins[index] = plugin;
      _saveCustomPlugins();
      notifyListeners();
    }
  }

  void removeCustomPlugin(int index) {
    if (index >= 0 && index < _customPlugins.length) {
      _customPlugins.removeAt(index);
      _saveCustomPlugins();
      notifyListeners();
    }
  }

  void setCustomPlugins(List<CustomPlugin> plugins) {
    _customPlugins = plugins;
    _saveCustomPlugins();
    notifyListeners();
  }

  void addPluginsFromJson(String jsonString) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<CustomPlugin> newPlugins =
          jsonList
              .map(
                (json) => CustomPlugin.fromJson(json as Map<String, dynamic>),
              )
              .toList();
      _customPlugins.addAll(newPlugins);
      _saveCustomPlugins();
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao decodificar ou adicionar plugins do JSON: $e");
    }
  }

  void addScriptUrl(String url) {
    if (url.trim().isNotEmpty && !_scriptUrls.contains(url.trim())) {
      _scriptUrls.add(url.trim());
      _saveScriptUrls();
      notifyListeners();
    }
  }

  void removeScriptUrl(int index) {
    if (index >= 0 && index < _scriptUrls.length) {
      _scriptUrls.removeAt(index);
      _saveScriptUrls();
      notifyListeners();
    }
  }

  void setScriptUrls(List<String> urls) {
    _scriptUrls = urls;
    _saveScriptUrls();
    notifyListeners();
  }

  Future<void> addFavoriteList(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    if (_favoriteLists.any(
      (list) => list.name.toLowerCase() == trimmedName.toLowerCase(),
    )) {
      debugPrint("List with name '$trimmedName' already exists.");
      throw Exception(
        "List with name '$trimmedName' already exists.".translate,
      );
    }

    final newList = FavoriteList(id: _uuid.v4(), name: trimmedName);
    _favoriteLists.add(newList);
    await _saveFavoriteLists();
    notifyListeners();
  }

  Future<void> renameFavoriteList(String listId, String newName) async {
    final trimmedNewName = newName.trim();
    if (trimmedNewName.isEmpty) return;

    if (_favoriteLists.any(
      (list) =>
          list.id != listId &&
          list.name.toLowerCase() == trimmedNewName.toLowerCase(),
    )) {
      debugPrint("Another list with name '$trimmedNewName' already exists.");
      throw Exception(
        "Another list with name '$trimmedNewName' already exists.".translate,
      );
    }

    final index = _favoriteLists.indexWhere((list) => list.id == listId);
    if (index != -1) {
      _favoriteLists[index].name = trimmedNewName;
      await _saveFavoriteLists();
      notifyListeners();
    }
  }

  Future<void> removeFavoriteList(String listId) async {
    final removed =
        _favoriteLists.removeWhere((list) => list.id == listId) as int;
    if (removed > 0) {
      await _saveFavoriteLists();
      notifyListeners();
    }
  }

  Future<void> addNovelToList(String listId, Novel novel) async {
    final index = _favoriteLists.indexWhere((list) => list.id == listId);
    if (index != -1) {
      final compositeKey = FavoriteList.novelToCompositeKey(
        novel.pluginId,
        novel.id,
      );
      if (!_favoriteLists[index].novelIds.contains(compositeKey)) {
        _favoriteLists[index].novelIds.add(compositeKey);
        await _saveFavoriteLists();
        await saveNovelCache(novel);
        notifyListeners();
      }
    }
  }

  Future<void> removeNovelFromList(String listId, Novel novel) async {
    final index = _favoriteLists.indexWhere((list) => list.id == listId);
    if (index != -1) {
      final compositeKey = FavoriteList.novelToCompositeKey(
        novel.pluginId,
        novel.id,
      );
      final removed = _favoriteLists[index].novelIds.remove(compositeKey);
      if (removed) {
        await _saveFavoriteLists();
        if (!isNovelFavorite(novel)) {
          await removeNovelCache(novel.pluginId, novel.id);
        }
        notifyListeners();
      }
    }
  }

  Future<void> removeNovelFromAllLists(Novel novel) async {
    final compositeKey = FavoriteList.novelToCompositeKey(
      novel.pluginId,
      novel.id,
    );
    bool changed = false;
    for (var list in _favoriteLists) {
      if (list.novelIds.remove(compositeKey)) {
        changed = true;
      }
    }
    if (changed) {
      await _saveFavoriteLists();
      await removeNovelCache(novel.pluginId, novel.id);
      notifyListeners();
    }
  }

  bool isNovelInList(String listId, Novel novel) {
    final index = _favoriteLists.indexWhere((list) => list.id == listId);
    if (index != -1) {
      final compositeKey = FavoriteList.novelToCompositeKey(
        novel.pluginId,
        novel.id,
      );
      return _favoriteLists[index].novelIds.contains(compositeKey);
    }
    return false;
  }

  List<String> getListsContainingNovel(Novel novel) {
    final compositeKey = FavoriteList.novelToCompositeKey(
      novel.pluginId,
      novel.id,
    );
    return _favoriteLists
        .where((list) => list.novelIds.contains(compositeKey))
        .map((list) => list.id)
        .toList();
  }

  bool isNovelFavorite(Novel novel) {
    final compositeKey = FavoriteList.novelToCompositeKey(
      novel.pluginId,
      novel.id,
    );
    return _favoriteLists.any((list) => list.novelIds.contains(compositeKey));
  }

  Set<String> getAllFavoriteNovelKeys() {
    final Set<String> keys = {};
    for (final list in _favoriteLists) {
      keys.addAll(list.novelIds);
    }
    return keys;
  }

  String getNovelCacheKey(String pluginId, String novelId) {
    return '$_novelCachePrefix${FavoriteList.novelToCompositeKey(pluginId, novelId)}';
  }

  Future<void> saveNovelCache(Novel novel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = getNovelCacheKey(novel.pluginId, novel.id);
      final cacheData = jsonEncode({
        'id': novel.id,
        'pluginId': novel.pluginId,
        'title': novel.title,
        'coverImageUrl': novel.coverImageUrl,
        'author': novel.author,
      });
      await prefs.setString(cacheKey, cacheData);
      debugPrint("Saved cache for ${novel.pluginId}/${novel.id}");
    } catch (e) {
      debugPrint(
        "Error saving novel cache for ${novel.pluginId}/${novel.id}: $e",
      );
    }
  }

  Future<Novel?> getNovelFromCache(String pluginId, String novelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = getNovelCacheKey(pluginId, novelId);
      final cacheData = prefs.getString(cacheKey);

      if (cacheData != null) {
        final Map<String, dynamic> map = jsonDecode(cacheData);
        return Novel(
          id: map['id'] as String,
          pluginId: map['pluginId'] as String,
          title: map['title'] as String? ?? 'Unknown Title'.translate,
          coverImageUrl: map['coverImageUrl'] as String? ?? '',
          author: map['author'] as String? ?? '',
          description: '',
          chapters: [],
          statusString: '',
          artist: '',
          genres: [],
        );
      }
    } catch (e) {
      debugPrint("Error reading novel cache for $pluginId/$novelId: $e");
    }
    return null;
  }

  Future<void> removeNovelCache(String pluginId, String novelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = getNovelCacheKey(pluginId, novelId);
      await prefs.remove(cacheKey);
      debugPrint("Removed cache for $pluginId/$novelId");
    } catch (e) {
      debugPrint("Error removing novel cache for $pluginId/$novelId: $e");
    }
  }

  Future<void> initialize() async {
    await _loadSettings();
    _settingsLoaded = true;
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();

      final themeModeIndex =
          prefs.getInt('themeMode') ?? ThemeMode.system.index;
      _themeMode = ThemeMode.values[themeModeIndex];
      _accentColor = Color(prefs.getInt('accentColor') ?? Colors.blue.value);

      final plugins = prefs.getStringList('selectedPlugins');
      _selectedPlugins =
          plugins?.isNotEmpty == true ? Set<String>.from(plugins!) : {};

      final readerSettingsMap = <String, dynamic>{};
      prefs.getKeys().where((key) => key.startsWith('reader_')).forEach((key) {
        readerSettingsMap[key.substring(7)] = prefs.get(key);
      });
      _readerSettings = ReaderSettings.fromMap(readerSettingsMap);

      final customPluginsJson = prefs.getStringList('customPlugins');
      if (customPluginsJson != null && customPluginsJson.isNotEmpty) {
        _customPlugins =
            customPluginsJson
                .map((json) => CustomPlugin.fromJson(jsonDecode(json)))
                .toList();
      } else {
        _customPlugins = List.from(_defaultPlugins);
        await _saveCustomPlugins(prefs);
      }

      _scriptUrls = prefs.getStringList('scriptUrls') ?? [_scriptUrls.first];

      final favoriteListsJson = prefs.getStringList('favoriteLists');
      if (favoriteListsJson != null) {
        _favoriteLists =
            favoriteListsJson
                .map(
                  (jsonString) => FavoriteList.fromJson(jsonDecode(jsonString)),
                )
                .toList();
        await _createDefaultFavoriteListIfNeeded(prefs);
      } else {
        await _createDefaultFavoriteListIfNeeded(prefs);
      }
    } catch (e) {
      debugPrint("Erro CRÍTICO ao carregar configurações: $e");
      _themeMode = ThemeMode.system;
      _accentColor = Colors.blue;
      _selectedPlugins = {};
      _readerSettings = ReaderSettings();
      _customPlugins = List.from(_defaultPlugins);
      _favoriteLists = [];
      _scriptUrls = ['https://api.npoint.io/bcd94c36fa7f3bf3b1e6/scripts/'];
      try {
        prefs = await SharedPreferences.getInstance();
        await _createDefaultFavoriteListIfNeeded(prefs);
      } catch (prefError) {
        debugPrint(
          "Could not create default list after settings load error: $prefError",
        );
      }
    }
  }

  Future<void> _createDefaultFavoriteListIfNeeded(
    SharedPreferences prefsInstance,
  ) async {
    if (_favoriteLists.isEmpty) {
      debugPrint(
        "No favorite lists found or loaded, creating default 'Favorites' list.",
      );
      final defaultListName = "Favoritos".translate;
      final defaultList = FavoriteList(id: _uuid.v4(), name: defaultListName);
      _favoriteLists.add(defaultList);
      await _saveFavoriteLists(prefsInstance);
    }
  }

  Future<void> _saveThemeSettings([SharedPreferences? prefsInstance]) async {
    try {
      final prefs = prefsInstance ?? await SharedPreferences.getInstance();
      await prefs.setInt('themeMode', _themeMode.index);
      await prefs.setInt('accentColor', _accentColor.value);
    } catch (e) {
      debugPrint("Erro ao salvar configurações do tema: $e");
    }
  }

  Future<void> _saveSelectedPlugins([SharedPreferences? prefsInstance]) async {
    try {
      final prefs = prefsInstance ?? await SharedPreferences.getInstance();
      await prefs.setStringList('selectedPlugins', _selectedPlugins.toList());
    } catch (e) {
      debugPrint("Erro ao salvar plugins selecionados: $e");
    }
  }

  Future<void> _saveReaderSettings([SharedPreferences? prefsInstance]) async {
    try {
      final prefs = prefsInstance ?? await SharedPreferences.getInstance();
      final settingsMap = _readerSettings.toMap();
      for (final entry in settingsMap.entries) {
        final prefsKey = 'reader_${entry.key}';
        final value = entry.value;
        if (value is int) {
          await prefs.setInt(prefsKey, value);
        } else if (value is double)
          await prefs.setDouble(prefsKey, value);
        else if (value is String)
          await prefs.setString(prefsKey, value);
        else if (value is bool)
          await prefs.setBool(prefsKey, value);
        else if (value == null)
          await prefs.remove(prefsKey);
      }
    } catch (e) {
      debugPrint("Erro ao salvar configurações do leitor: $e");
    }
  }

  Future<void> _saveCustomPlugins([SharedPreferences? prefsInstance]) async {
    try {
      final prefs = prefsInstance ?? await SharedPreferences.getInstance();
      final customPluginsJson =
          _customPlugins.map((plugin) => jsonEncode(plugin.toJson())).toList();
      await prefs.setStringList('customPlugins', customPluginsJson);
    } catch (e) {
      debugPrint("Erro ao salvar plugins customizados: $e");
    }
  }

  Future<void> _saveScriptUrls([SharedPreferences? prefsInstance]) async {
    try {
      final prefs = prefsInstance ?? await SharedPreferences.getInstance();
      await prefs.setStringList('scriptUrls', _scriptUrls);
    } catch (e) {
      debugPrint("Erro ao salvar URLs de script: $e");
    }
  }

  Future<void> _saveFavoriteLists([SharedPreferences? prefsInstance]) async {
    try {
      final prefs = prefsInstance ?? await SharedPreferences.getInstance();
      final favoriteListsJson =
          _favoriteLists.map((list) => jsonEncode(list.toJson())).toList();
      await prefs.setStringList('favoriteLists', favoriteListsJson);
    } catch (e) {
      debugPrint("Erro ao salvar listas de favoritos: $e");
    }
  }
}
