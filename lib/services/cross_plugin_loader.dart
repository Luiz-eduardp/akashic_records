import 'package:akashic_records/models/cross_plugin_model.dart';
import 'package:akashic_records/services/cross_plugin_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class CrossPluginLoader {
  static final CrossPluginLoader _instance = CrossPluginLoader._internal();

  factory CrossPluginLoader() {
    return _instance;
  }

  CrossPluginLoader._internal();

  final Map<String, CrossPluginService> _loadedPlugins = {};

  Future<List<CrossPluginItem>> loadPluginList(String listUrl) async {
    try {
      developer.log('Loading plugin list from: $listUrl');

      final response = await http.get(Uri.parse(listUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load plugin list: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as List<dynamic>;
      final plugins =
          json
              .map((p) => CrossPluginItem.fromJson(p as Map<String, dynamic>))
              .toList();

      developer.log('Loaded ${plugins.length} plugins');
      return plugins;
    } catch (e) {
      developer.log('Error loading plugin list: $e');
      rethrow;
    }
  }

  Future<CrossPluginService> loadPlugin(
    CrossPluginItem item,
    String listUrl,
  ) async {
    try {
      if (_loadedPlugins.containsKey(item.id)) {
        return _loadedPlugins[item.id]!;
      }

      developer.log('Loading plugin: ${item.id}');

      final codeResponse = await http.get(Uri.parse(item.url));
      if (codeResponse.statusCode != 200) {
        throw Exception(
          'Failed to load plugin code: ${codeResponse.statusCode}',
        );
      }

      final config = CrossPluginConfig(
        id: item.id,
        name: item.name,
        site: item.site,
        lang: item.lang,
        version: item.version,
        iconUrl: item.iconUrl,
        pluginCode: item.url,
        listUrl: listUrl,
        customCSS: item.customCSS,
      );

      final service = CrossPluginService(config: config);

      _loadedPlugins[item.id] = service;

      developer.log('Plugin loaded: ${item.id}');
      return service;
    } catch (e) {
      developer.log('Error loading plugin ${item.id}: $e');
      rethrow;
    }
  }

  CrossPluginService createPluginMetadata(
    CrossPluginItem item,
    String listUrl,
  ) {
    developer.log('Creating plugin metadata: ${item.name}');

    final config = CrossPluginConfig(
      id: item.id,
      name: item.name,
      site: item.site,
      lang: item.lang,
      version: item.version,
      iconUrl: item.iconUrl,
      pluginCode: item.url,
      listUrl: listUrl,
      customCSS: item.customCSS,
    );

    return CrossPluginService(config: config);
  }

  CrossPluginService? getLoadedPlugin(String pluginId) {
    return _loadedPlugins[pluginId];
  }

  void unloadPlugin(String pluginId) {
    _loadedPlugins.remove(pluginId);
    developer.log('Plugin unloaded: $pluginId');
  }

  void clearCache() {
    _loadedPlugins.clear();
    developer.log('All plugins unloaded');
  }

  int get loadedPluginsCount => _loadedPlugins.length;

  List<String> get loadedPluginIds => _loadedPlugins.keys.toList();
}

class CrossPluginSourceManager {
  static const defaultSources = [
    'https://raw.githubusercontent.com/lnreader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json',
  ];

  static final Map<String, String> _customSources = {
    'lnreader':
        'https://raw.githubusercontent.com/lnreader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json',
  };

  static String getSourceUrl(String sourceName) {
    return _customSources[sourceName] ?? sourceName;
  }

  static void addCustomSource(String name, String url) {
    _customSources[name] = url;
  }

  static void removeCustomSource(String name) {
    _customSources.remove(name);
  }

  static Map<String, String> getAllSources() {
    return {..._customSources};
  }
}
