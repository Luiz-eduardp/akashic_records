import 'dart:convert';
import 'dart:io';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/screens/settings/appearance_settings.dart';
import 'package:akashic_records/services/local/local_service.dart';
import 'package:akashic_records/services/plugins/arabic/sunovels_service.dart';
import 'package:akashic_records/services/plugins/english/projectgutenberg_service.dart';
import 'package:akashic_records/services/plugins/french/chireads_service.dart';
import 'package:akashic_records/services/plugins/indonesean/indowebnovel_service.dart';
import 'package:akashic_records/services/plugins/japanese/kakuyomu_service.dart';
import 'package:akashic_records/services/plugins/japanese/syosetu_service.dart';
import 'package:akashic_records/services/plugins/spanish/novelsligera_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:akashic_records/services/plugins/english/novelbin_service.dart';
import 'package:akashic_records/services/plugins/english/novelonline_service.dart';
import 'package:akashic_records/services/plugins/english/reapersscan_service.dart';
import 'package:akashic_records/services/plugins/english/royalroad_service.dart';
import 'package:akashic_records/services/plugins/english/webnovel_service.dart';
import 'package:akashic_records/services/plugins/portuguese/blogdoamonnovels_service.dart';
import 'package:akashic_records/services/plugins/portuguese/lightnovelbrasil_service.dart';
import 'package:akashic_records/services/plugins/portuguese/mtl_service.dart';
import 'package:akashic_records/services/plugins/spanish/skynovels_service.dart';
import 'package:akashic_records/services/plugins/portuguese/novelmania_service.dart';
import 'package:akashic_records/services/plugins/portuguese/tsundoku_service.dart';
import 'package:akashic_records/services/plugins/portuguese/centralnovel_service.dart';

import 'package:akashic_records/models/favorite_list.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/i18n/i18n.dart';

enum PluginLanguage { Local, ptBr, en, es, ja, id, fr, ar }

class PluginInfo {
  final String name;
  final PluginLanguage language;

  PluginInfo({required this.name, required this.language});
}

enum ReaderTheme {
  Akashic,
  light,
  dark,
  sepia,
  darkGreen,
  grey,
  solarizedLight,
  solarizedDark,
  translucent,
  midnightBlue,
  lavender,
  mint,
  sand,
  coral,
  cyberpunk,
  highContrast,
  materialLight,
  materialDark,
  nord,
  roseQuartz,
  amethyst,
  forest,
  ocean,
  sunset,
  dracula,
  gruvboxLight,
  gruvboxDark,
  monokai,
  solarized,
  calmingBlue,
  darkOpaque,
  lime,
  teal,
  amber,
  deepOrange,
  brown,
  blueGrey,
  indigo,
  cyan,
  khaki,
  slateGray,
  rosyBrown,
  oliveDrab,
  peru,
  darkSlateGray,
  cadetBlue,
  mediumTurquoise,
  lightSeaGreen,
  darkCyan,
  steelBlue,
  royalBlue,
  night,
  coal,
  obsidian,
  deepPurple,
  midnight,
  kindleClassic,
  kindleEInk,
  kindlePaperwhite,
  kindleOasis,
  kindleVoyage,
  kindleBasic,
  kindleFire,
  kindleDX,
  kindleKids,
  kindleScribe,
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

@HiveType(typeId: 0)
class CustomPlugin extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  String code;
  @HiveField(2)
  String use;
  @HiveField(3)
  bool enabled;
  @HiveField(4)
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

@HiveType(typeId: 1)
class CachedNovel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String pluginId;
  @HiveField(2)
  String title;
  @HiveField(3)
  String coverImageUrl;
  @HiveField(4)
  String author;

  CachedNovel({
    required this.id,
    required this.pluginId,
    required this.title,
    required this.coverImageUrl,
    required this.author,
  });

  factory CachedNovel.fromNovel(Novel novel) {
    return CachedNovel(
      id: novel.id,
      pluginId: novel.pluginId,
      title: novel.title,
      coverImageUrl: novel.coverImageUrl,
      author: novel.author,
    );
  }

  Novel toNovel() {
    return Novel(
      id: id,
      pluginId: pluginId,
      title: title,
      coverImageUrl: coverImageUrl,
      author: author,
      description: '',
      chapters: [],
      statusString: '',
      artist: '',
      genres: [],
    );
  }
}

@HiveType(typeId: 2)
class FavoriteListHive extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  List<String> novelIds;

  FavoriteListHive({
    required this.id,
    required this.name,
    required this.novelIds,
  });

  FavoriteList toFavoriteList() {
    return FavoriteList(id: id, name: name, novelIds: novelIds.toList());
  }

  factory FavoriteListHive.fromFavoriteList(FavoriteList list) {
    return FavoriteListHive(
      id: list.id,
      name: list.name,
      novelIds: list.novelIds.toList(),
    );
  }
}

class AppState with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = AkashicColors.bronze;
  bool _settingsLoaded = false;
  Set<String> _selectedPlugins = {};
  ReaderSettings _readerSettings = ReaderSettings();
  List<CustomPlugin> _customPlugins = [];
  List<String> _scriptUrls = [
    'https://api.npoint.io/bcd94c36fa7f3bf3b1e6/scripts/',
  ];
  List<FavoriteList> _favoriteLists = [];
  int _novelCount = 0;
  List<Novel> _localNovels = [];
  bool _showChangelog = false;
  String? _lastShownChangelogVersion;
  String? _currentAppVersion;

  final Map<String, PluginService> _pluginServices = {};
  final Map<String, PluginInfo> _pluginInfo = {};
  final _uuid = const Uuid();
  static const String _novelCachePrefix = 'novel_cache_';

  final List<CustomPlugin> _defaultPlugins = [];

  late Box<CustomPlugin> _customPluginsBox;
  late Box<CachedNovel> _novelCacheBox;
  late Box<FavoriteListHive> _favoriteListsBox;

  AppState() {
    _pluginServices['Dispositivo'] = Dispositivo();
    _pluginInfo['Dispositivo'] = PluginInfo(
      name: 'Dispositivo',
      language: PluginLanguage.Local,
    );
    _pluginServices['NovelMania'] = NovelMania();
    _pluginInfo['NovelMania'] = PluginInfo(
      name: 'NovelMania',
      language: PluginLanguage.ptBr,
    );

    _pluginServices['Tsundoku'] = Tsundoku();
    _pluginInfo['Tsundoku'] = PluginInfo(
      name: 'Tsundoku',
      language: PluginLanguage.ptBr,
    );

    _pluginServices['CentralNovel'] = CentralNovel();
    _pluginInfo['CentralNovel'] = PluginInfo(
      name: 'CentralNovel',
      language: PluginLanguage.ptBr,
    );

    _pluginServices['MtlNovelPt'] = MtlNovelPt();
    _pluginInfo['MtlNovelPt'] = PluginInfo(
      name: 'MtlNovelPt',
      language: PluginLanguage.ptBr,
    );

    _pluginServices['LightNovelBrasil'] = LightNovelBrasil();
    _pluginInfo['LightNovelBrasil'] = PluginInfo(
      name: 'LightNovelBrasil',
      language: PluginLanguage.ptBr,
    );

    _pluginServices['BlogDoAmonNovels'] = BlogDoAmonNovels();
    _pluginInfo['BlogDoAmonNovels'] = PluginInfo(
      name: 'BlogDoAmonNovels',
      language: PluginLanguage.ptBr,
    );

    _pluginServices['NovelsOnline'] = NovelsOnline();
    _pluginInfo['NovelsOnline'] = PluginInfo(
      name: 'NovelsOnline',
      language: PluginLanguage.en,
    );

    _pluginServices['RoyalRoad'] = RoyalRoad();
    _pluginInfo['RoyalRoad'] = PluginInfo(
      name: 'RoyalRoad',
      language: PluginLanguage.en,
    );

    _pluginServices['ProjectGutenberg'] = ProjectGutenberg();
    _pluginInfo['ProjectGutenberg'] = PluginInfo(
      name: 'ProjectGutenberg',
      language: PluginLanguage.en,
    );

    _pluginServices['Webnovel'] = Webnovel();
    _pluginInfo['Webnovel'] = PluginInfo(
      name: 'Webnovel',
      language: PluginLanguage.en,
    );

    _pluginServices['ReaperScans'] = ReaperScans();
    _pluginInfo['ReaperScans'] = PluginInfo(
      name: 'ReaperScans',
      language: PluginLanguage.en,
    );

    _pluginServices['NovelBin'] = NovelBin();
    _pluginInfo['NovelBin'] = PluginInfo(
      name: 'NovelBin',
      language: PluginLanguage.en,
    );

    _pluginServices['SkyNovels'] = SkyNovels();
    _pluginInfo['SkyNovels'] = PluginInfo(
      name: 'SkyNovels',
      language: PluginLanguage.es,
    );

    _pluginServices['NovelasLigera'] = NovelasLigera();
    _pluginInfo['NovelasLigera'] = PluginInfo(
      name: 'NovelasLigera',
      language: PluginLanguage.es,
    );

    _pluginServices['Kakuyomu'] = Kakuyomu();
    _pluginInfo['Kakuyomu'] = PluginInfo(
      name: 'Kakuyomu',
      language: PluginLanguage.ja,
    );
    _pluginServices['Syosetu'] = Syosetu();
    _pluginInfo['Syosetu'] = PluginInfo(
      name: 'Syosetu',
      language: PluginLanguage.ja,
    );

    _pluginServices['IndoWebNovel'] = IndoWebNovel();
    _pluginInfo['IndoWebNovel'] = PluginInfo(
      name: 'IndoWebNovel',
      language: PluginLanguage.id,
    );
    _pluginServices['Chireads'] = Chireads();
    _pluginInfo['Chireads'] = PluginInfo(
      name: 'Chireads',
      language: PluginLanguage.fr,
    );
    _pluginServices['Sunovels'] = Sunovels();
    _pluginInfo['Sunovels'] = PluginInfo(
      name: 'Sunovels',
      language: PluginLanguage.ar,
    );
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
  int get novelCount => _novelCount;
  List<Novel> get localNovels => _localNovels;
  bool get showChangelog => _showChangelog;

  get pluginInfo => _pluginInfo;

  get novelCacheBox => null;

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }

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
    final pluginsToRemove = _selectedPlugins.difference(
      _pluginServices.keys.toSet(),
    );

    if (pluginsToRemove.isNotEmpty) {
      final mutableSelectedPlugins = Set<String>.from(_selectedPlugins);
      mutableSelectedPlugins.removeAll(pluginsToRemove);
      _selectedPlugins = mutableSelectedPlugins;

      debugPrint(
        "Removed plugins from selectedPlugins that are not in _pluginServices: $pluginsToRemove",
      );
    }

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
    _insertCustomPluginToHive(plugin);
    notifyListeners();
  }

  void updateCustomPlugin(int index, CustomPlugin plugin) {
    if (index >= 0 && index < _customPlugins.length) {
      _customPlugins[index] = plugin;
      _saveCustomPlugins();
      _updateCustomPluginInHive(plugin);
      notifyListeners();
    }
  }

  void removeCustomPlugin(int index) {
    if (index >= 0 && index < _customPlugins.length) {
      final pluginToRemove = _customPlugins.removeAt(index);
      _saveCustomPlugins();
      _deleteCustomPluginFromHive(pluginToRemove);
      notifyListeners();
    }
  }

  void setCustomPlugins(List<CustomPlugin> plugins) {
    _customPlugins = plugins;
    _saveCustomPlugins();
    _syncCustomPluginsToHive(plugins);
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
      _syncCustomPluginsToHive(_customPlugins);
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
      final cachedNovel = CachedNovel.fromNovel(novel);
      await _novelCacheBox.put(
        getNovelCacheKey(novel.pluginId, novel.id),
        cachedNovel,
      );
      debugPrint("Saved cache for ${novel.pluginId}/${novel.id} in Hive");
    } catch (e) {
      debugPrint(
        "Error saving novel cache for ${novel.pluginId}/${novel.id} in Hive: $e",
      );
    }
  }

  Future<Novel?> getNovelFromCache(String pluginId, String novelId) async {
    try {
      final cachedNovel = _novelCacheBox.get(
        getNovelCacheKey(pluginId, novelId),
      );
      if (cachedNovel != null) {
        debugPrint("Retrieved cache for $pluginId/$novelId from Hive");
        return cachedNovel.toNovel();
      }
    } catch (e) {
      debugPrint(
        "Error reading novel cache for $pluginId/$novelId from Hive: $e",
      );
    }
    return null;
  }

  Future<void> removeNovelCache(String pluginId, String novelId) async {
    try {
      await _novelCacheBox.delete(getNovelCacheKey(pluginId, novelId));
      debugPrint("Removed cache for $pluginId/$novelId from Hive");
    } catch (e) {
      debugPrint(
        "Error removing novel cache for $pluginId/$novelId from Hive: $e",
      );
    }
  }

  void setShowChangelog(bool value) {
    if (_showChangelog != value) {
      _showChangelog = value;
      _saveShowChangelog(value);
      notifyListeners();
    }
  }

  bool shouldShowChangelog() {
    return _showChangelog;
  }

  Future<void> initialize() async {
    await _initHive();
    await _loadSettings();
    _settingsLoaded = true;
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CustomPluginAdapter());
    Hive.registerAdapter(CachedNovelAdapter());
    Hive.registerAdapter(FavoriteListHiveAdapter());

    _customPluginsBox = await Hive.openBox<CustomPlugin>('customPlugins');
    _novelCacheBox = await Hive.openBox<CachedNovel>('novelCache');
    _favoriteListsBox = await Hive.openBox<FavoriteListHive>(
      'favoriteListsBox',
    );

    debugPrint("Hive initialized.");
  }

  Future<void> _insertCustomPluginToHive(CustomPlugin plugin) async {
    await _customPluginsBox.put(plugin.name, plugin);
    debugPrint("Custom plugin '${plugin.name}' inserted into Hive.");
  }

  Future<void> _updateCustomPluginInHive(CustomPlugin plugin) async {
    await _customPluginsBox.put(plugin.name, plugin);
    debugPrint("Custom plugin '${plugin.name}' updated in Hive.");
  }

  Future<void> _deleteCustomPluginFromHive(CustomPlugin plugin) async {
    await _customPluginsBox.delete(plugin.name);
    debugPrint("Custom plugin '${plugin.name}' deleted from Hive.");
  }

  Future<void> _syncCustomPluginsToHive(List<CustomPlugin> plugins) async {
    await _customPluginsBox.clear();
    final Map<String, CustomPlugin> pluginMap = {
      for (var plugin in plugins) plugin.name: plugin,
    };
    await _customPluginsBox.putAll(pluginMap);
    debugPrint("Custom plugins synced to Hive.");
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();

      final themeModeIndex =
          prefs.getInt('themeMode') ?? ThemeMode.system.index;
      _themeMode = ThemeMode.values[themeModeIndex];
      _accentColor = Color(
        prefs.getInt('accentColor') ?? AkashicColors.gold.value,
      );

      final plugins = prefs.getStringList('selectedPlugins');
      _selectedPlugins =
          plugins?.isNotEmpty == true ? Set<String>.from(plugins!) : {};

      final invalidPlugins = _selectedPlugins.difference(
        _pluginServices.keys.toSet(),
      );
      if (invalidPlugins.isNotEmpty) {
        debugPrint(
          "Removing invalid plugins from selectedPlugins: $invalidPlugins",
        );
        _selectedPlugins.removeAll(invalidPlugins);
        await _saveSelectedPlugins(prefs);
      }

      final readerSettingsMap = <String, dynamic>{};
      prefs.getKeys().where((key) => key.startsWith('reader_')).forEach((key) {
        readerSettingsMap[key.substring(7)] = prefs.get(key);
      });
      _readerSettings = ReaderSettings.fromMap(readerSettingsMap);

      _customPlugins = await _getCustomPluginsFromHive();

      _scriptUrls = prefs.getStringList('scriptUrls') ?? [_scriptUrls.first];

      _favoriteLists = await _getFavoriteListsFromHive();
      _localNovels = await _getLocalNovelsFromHive();

      await _createDefaultFavoriteListIfNeeded();

      _lastShownChangelogVersion = prefs.getString('lastShownChangelogVersion');

      final packageInfo = await PackageInfo.fromPlatform();
      _currentAppVersion = packageInfo.version;

      _showChangelog =
          _lastShownChangelogVersion == null ||
          _currentAppVersion != _lastShownChangelogVersion;
    } catch (e) {
      debugPrint("Erro CRÍTICO ao carregar configurações: $e");
      _themeMode = ThemeMode.system;
      _accentColor = Colors.blue;
      _selectedPlugins = {};
      _readerSettings = ReaderSettings();
      _customPlugins = List.from(_defaultPlugins);
      _favoriteLists = [];
      _scriptUrls = ['https://api.npoint.io/bcd94c36fa7f3bf3b1e6/scripts/'];
      _localNovels = [];
      _showChangelog = true;

      try {
        prefs = await SharedPreferences.getInstance();
        await _createDefaultFavoriteListIfNeeded();
      } catch (prefError) {
        debugPrint(
          "Could not create default list after settings load error: $prefError",
        );
      }
    }
  }

  Future<List<FavoriteList>> _getFavoriteListsFromHive() async {
    return _favoriteListsBox.values
        .map((hiveList) => hiveList.toFavoriteList())
        .toList();
  }

  Future<List<CustomPlugin>> _getCustomPluginsFromHive() async {
    return _customPluginsBox.values.toList();
  }

  Future<List<Novel>> _getLocalNovelsFromHive() async {
    List<Novel> novels = [];
    try {
      debugPrint("Iniciando o carregamento de novels locais do Hive...");
      for (var key in _novelCacheBox.keys) {
        if (key.toString().startsWith('local_novel_')) {
          CachedNovel? cachedNovel = _novelCacheBox.get(key);

          if (cachedNovel != null) {
            final file = File(cachedNovel.id);
            if (await file.exists()) {
              debugPrint("Novel encontrada no Hive: ${cachedNovel.title}");
              novels.add(cachedNovel.toNovel());
            } else {
              debugPrint(
                "Arquivo não existe mais: ${cachedNovel.title}. Removendo do Hive.",
              );
              await _novelCacheBox.delete(key);
            }
          } else {
            debugPrint("Erro: Novel cacheada nula para a chave: $key");
          }
        }
      }
      debugPrint(
        "Carregamento de novels locais do Hive concluído. Total: ${novels.length}",
      );
    } catch (e) {
      debugPrint("Erro ao carregar novels locais do Hive: $e");
    }
    return novels;
  }

  Future<void> _createDefaultFavoriteListIfNeeded() async {
    if (_favoriteLists.isEmpty) {
      debugPrint(
        "No favorite lists found or loaded, creating default 'Favorites' list.",
      );
      final defaultListName = "Favoritos".translate;
      final defaultList = FavoriteList(id: _uuid.v4(), name: defaultListName);
      _favoriteLists.add(defaultList);
      await _saveFavoriteLists();
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
      final settingsMap = readerSettings.toMap();
      for (final entry in settingsMap.entries) {
        final prefsKey = 'reader${entry.key}';
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

  Future<void> _saveFavoriteLists() async {
    try {
      await _favoriteListsBox.clear();
      final Map<String, FavoriteListHive> listMap = {
        for (var list in _favoriteLists)
          list.id: FavoriteListHive.fromFavoriteList(list),
      };
      await _favoriteListsBox.putAll(listMap);
      debugPrint("Favorite lists saved to Hive.");
    } catch (e) {
      debugPrint("Erro ao salvar listas de favoritos no Hive: $e");
    }
    notifyListeners();
  }

  Future<void> _saveShowChangelog(
    bool value, [
    SharedPreferences? prefsInstance,
  ]) async {
    try {
      final prefs = prefsInstance ?? await SharedPreferences.getInstance();
      await prefs.setBool('showChangelog', value);
    } catch (e) {
      debugPrint("Erro ao salvar o estado de 'showChangelog': $e");
    }
  }

  Future<void> _saveLastShownChangelogVersion(
    String version, [
    SharedPreferences? prefsInstance,
  ]) async {
    try {
      final prefs = prefsInstance ?? await SharedPreferences.getInstance();
      await prefs.setString('lastShownChangelogVersion', version);
    } catch (e) {
      debugPrint("Erro ao salvar a versão do changelog mostrada: $e");
    }
  }

  Future<void> markChangelogAsShown() async {
    if (_currentAppVersion != null) {
      setShowChangelog(false);
      await _saveLastShownChangelogVersion(_currentAppVersion!);
      _lastShownChangelogVersion = _currentAppVersion;
      notifyListeners();
    }
  }

  void updateNovelCount(int count) {
    _novelCount = count;
    notifyListeners();
  }

  Future<void> addLocalNovels(List<Novel> novels) async {
    _localNovels.addAll(novels);

    for (final novel in novels) {
      await saveLocalNovelToHive(novel);
    }
    notifyListeners();
  }

  Future<void> saveLocalNovelToHive(Novel novel) async {
    try {
      final cachedNovel = CachedNovel.fromNovel(novel);
      String key = 'local_novel${novel.id}';
      await _novelCacheBox.put(key, cachedNovel);
      debugPrint("Saved local novel ${novel.title} to Hive with key: $key");
    } catch (e) {
      debugPrint("Error saving local novel ${novel.title} to Hive: $e");
    }
  }
}

class CustomPluginAdapter extends TypeAdapter<CustomPlugin> {
  @override
  final typeId = 0;

  @override
  CustomPlugin read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomPlugin(
      name: fields[0] as String,
      code: fields[1] as String,
      use: fields[2] as String,
      enabled: fields[3] as bool,
      priority: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CustomPlugin obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.use)
      ..writeByte(3)
      ..write(obj.enabled)
      ..writeByte(4)
      ..write(obj.priority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomPluginAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedNovelAdapter extends TypeAdapter<CachedNovel> {
  @override
  final typeId = 1;

  @override
  CachedNovel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedNovel(
      id: fields[0] as String,
      pluginId: fields[1] as String,
      title: fields[2] as String,
      coverImageUrl: fields[3] as String,
      author: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedNovel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.pluginId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.coverImageUrl)
      ..writeByte(4)
      ..write(obj.author);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedNovelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FavoriteListHiveAdapter extends TypeAdapter<FavoriteListHive> {
  @override
  final typeId = 2;

  @override
  FavoriteListHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavoriteListHive(
      id: fields[0] as String,
      name: fields[1] as String,
      novelIds: (fields[2] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, FavoriteListHive obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.novelIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteListHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
