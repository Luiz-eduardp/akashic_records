import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/cross_plugin_model.dart';
import 'package:akashic_records/services/cross_plugin_executor.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'dart:convert';

class CrossPluginService extends PluginService {
  late CrossPluginConfig _config;
  late CrossPluginExecutor _executor;

  @override
  String get name => _config.name;

  @override
  String get version => _config.version;

  @override
  String get lang => _config.lang;

  @override
  String get siteUrl => _config.site;

  @override
  Map<String, dynamic> get filters => {};

  CrossPluginService({required CrossPluginConfig config}) {
    _config = config;
    _executor = CrossPluginExecutor(siteUrl: _config.site);
  }

  Future<void> _initializeIfNeeded() async {
    if (CrossPluginCodeCache.has(_config.id)) {
      return;
    }

    try {
      final response = await http.get(Uri.parse(_config.pluginCode));
      if (response.statusCode == 200) {
        CrossPluginCodeCache.set(_config.id, response.body);
        await _executor.initializePlugin(response.body);
        developer.log('CrossPlugin initialized: ${_config.id}');
      }
    } catch (e) {
      developer.log('Error initializing cross plugin: $e');
      rethrow;
    }
  }

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    Map<String, dynamic> filters = const {},
    BuildContext? context,
  }) async {
    await _initializeIfNeeded();

    try {
      return await _fetchNovelsFromPlugin(
        method: 'popularNovels',
        pageNo: page,
      );
    } catch (e) {
      developer.log('Error fetching popular novels: $e');
      return [];
    }
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic> filters = const {},
  }) async {
    await _initializeIfNeeded();

    try {
      return await _fetchNovelsFromPlugin(
        method: 'searchNovels',
        searchTerm: searchTerm,
        pageNo: pageNo,
      );
    } catch (e) {
      developer.log('Error searching novels: $e');
      return [];
    }
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    await _initializeIfNeeded();

    try {
      final result = await _executor.executeFunction(
        'parseNovel',
        args: [novelPath],
        sourceCode: CrossPluginCodeCache.get(_config.id),
      );

      if (result is Map) {
        return Novel(
          id: novelPath,
          title:
              (result['novelName'] ?? result['title'] ?? 'Unknown').toString(),
          coverImageUrl:
              (result['novelCover'] ?? result['image'] ?? '').toString(),
          author: (result['author'] ?? 'Unknown').toString(),
          description:
              (result['novelSummary'] ?? result['description'] ?? '')
                  .toString(),
          chapters: [],
          pluginId: _config.id,
          genres: [],
        );
      }

      throw Exception('Invalid plugin result');
    } catch (e) {
      developer.log('Error parsing novel: $e');
      rethrow;
    }
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    await _initializeIfNeeded();

    try {
      final result = await _executor.executeFunction(
        'parseChapter',
        args: [chapterPath],
        sourceCode: CrossPluginCodeCache.get(_config.id),
      );

      if (result is String) {
        return result;
      } else if (result is Map && result.containsKey('html')) {
        return result['html'].toString();
      }

      return result.toString();
    } catch (e) {
      developer.log('Error parsing chapter: $e');
      rethrow;
    }
  }

  @override
  Future<List<Novel>> getAllNovels({BuildContext? context}) async {
    await _initializeIfNeeded();

    try {
      final novels = <Novel>[];
      for (int page = 1; page <= 5; page++) {
        final pageNovels = await popularNovels(page, context: context);
        novels.addAll(pageNovels);
      }
      return novels;
    } catch (e) {
      developer.log('Error fetching all novels: $e');
      return [];
    }
  }

  Future<List<Novel>> _fetchNovelsFromPlugin({
    required String method,
    String? searchTerm,
    int pageNo = 1,
  }) async {
    try {
      final args = method == 'searchNovels' ? [searchTerm, pageNo] : [pageNo];

      final result = await _executor.executeFunction(
        method,
        args: args,
        sourceCode: CrossPluginCodeCache.get(_config.id),
      );

      developer.log('Plugin returned: ${result.runtimeType}');

      if (result is List) {
        return _parseNovelsFromPluginResult(result);
      } else if (result is Map && result.containsKey('error')) {
        developer.log('Plugin error: ${result['error']}');
        return [];
      }

      return [];
    } catch (e) {
      developer.log('Error fetching novels from plugin: $e');
      return [];
    }
  }

  List<Novel> _parseNovelsFromPluginResult(dynamic pluginResult) {
    try {
      final novels = <Novel>[];

      if (pluginResult is String) {
        try {
          pluginResult = jsonDecode(pluginResult);
        } catch (e) {
          developer.log(
            'Could not decode plugin result as JSON: $pluginResult',
          );
          return [];
        }
      }

      late List<dynamic> novelsList;

      if (pluginResult is List) {
        novelsList = pluginResult;
      } else if (pluginResult is Map) {
        if (pluginResult.containsKey('novels')) {
          novelsList = pluginResult['novels'] as List;
        } else if (pluginResult.containsKey('results')) {
          novelsList = pluginResult['results'] as List;
        } else if (pluginResult.containsKey('data')) {
          novelsList = pluginResult['data'] as List;
        } else {
          developer.log('Unknown plugin result format: $pluginResult');
          return [];
        }
      } else {
        developer.log(
          'Invalid plugin result type: ${pluginResult.runtimeType}',
        );
        return [];
      }

      for (final item in novelsList) {
        if (item is Map) {
          try {
            novels.add(
              Novel(
                id:
                    (item['novelUrl'] ?? item['url'] ?? item['id'] ?? '')
                        .toString(),
                title:
                    (item['novelName'] ??
                            item['name'] ??
                            item['title'] ??
                            'Unknown')
                        .toString(),
                coverImageUrl:
                    (item['novelCover'] ?? item['cover'] ?? item['image'] ?? '')
                        .toString(),
                author: (item['author'] ?? 'Unknown').toString(),
                description:
                    (item['novelSummary'] ??
                            item['summary'] ??
                            item['description'] ??
                            '')
                        .toString(),
                chapters: [],
                pluginId: _config.id,
                genres: [],
              ),
            );
          } catch (e) {
            developer.log('Error parsing novel item: $e');
            continue;
          }
        }
      }

      developer.log('Parsed ${novels.length} novels from plugin result');
      return novels;
    } catch (e) {
      developer.log('Error parsing plugin result: $e');
      return [];
    }
  }
}
