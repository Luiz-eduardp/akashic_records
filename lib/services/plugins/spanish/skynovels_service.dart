import 'dart:async';
import 'dart:convert';

import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:akashic_records/services/core/proxy_client.dart';
import 'package:html/parser.dart' show parse;

class SkyNovels implements PluginService {
  @override
  String get name => 'SkyNovels';
  @override
  String get lang => 'es';
  String get id => 'SkyNovels';
  @override
  String get version => '1.0.5';
  @override
  String get siteUrl => baseURL;
  @override
  Map<String, dynamic> get filters => {};

  final String baseURL = 'https://www.skynovels.net/';
  final String apiURL = 'https://api.skynovels.net/api/';
  final String icon = 'src/es/skynovels/icon.png';

  static const String defaultCover =
      'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed';
  late final ProxyClient _client = ProxyClient();

  Future<dynamic> _fetchApi(String url) async {
    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              'Referer': baseURL,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        try {
          return jsonDecode(body);
        } catch (jsonError) {
          print('Erro ao decodificar JSON: $jsonError');
          try {
            parse(body);
            print(
              'Recebido HTML em vez de JSON, indicando uma página de erro.',
            );
            return null;
          } catch (htmlError) {
            print('Erro ao parsear HTML: $htmlError');
            return null;
          }
        }
      } else {
        print(
          'Falha ao carregar dados de: $url - Status code: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      return null;
    }
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    return _fetchNovels(pageNo, filters: filters);
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final parts = novelPath.split('/');
    final novelId = parts.length > 2 ? parts[1] : null;

    if (novelId == null) {
      print('Invalid novelPath: $novelPath');
      return _createDefaultNovel(novelPath, 'Invalid Novel Path');
    }

    final url = '${apiURL}novel/$novelId/reading?&q';
    final apiResult = await _fetchApi(url);

    if (apiResult == null) {
      print("apiResult is null, returning default Novel");
      return _createDefaultNovel(novelPath, 'Erro ao carregar');
    }

    if (apiResult is! Map || apiResult['novel'] is! List) {
      print("Unexpected format for novel data, returning default Novel");
      return _createDefaultNovel(novelPath, 'Erro ao carregar');
    }

    final novelData = (apiResult['novel'] as List)
        .cast<Map<String, dynamic>?>()
        .firstWhere((element) => element != null, orElse: () => null);

    if (novelData == null) {
      print("No valid novel data found, returning default Novel");
      return _createDefaultNovel(novelPath, 'Erro ao carregar');
    }

    try {
      final title = novelData['nvl_title'] as String? ?? 'Untitled';
      final coverImageUrl =
          novelData['image'] != null
              ? '${apiURL}get-image/${novelData['image']}/novels/false'
              : defaultCover;

      final novel = Novel(
        id: novelPath,
        title: title,
        coverImageUrl: coverImageUrl,
        description: novelData['nvl_content'] as String? ?? '',
        genres:
            (novelData['genres'] as List<dynamic>?)
                ?.map<String>((genre) {
                  if (genre is Map<String, dynamic>) {
                    return genre['genre_name'] as String? ?? '';
                  }
                  print('Unexpected data type in genres: ${genre.runtimeType}');
                  return '';
                })
                .where((genre) => genre.isNotEmpty)
                .toList() ??
            [],
        chapters: [],
        artist: '',
        statusString: novelData['nvl_status'] as String? ?? '',
        author: novelData['nvl_writer'] as String? ?? '',
        pluginId: id,
      );

      final chapterApiUrl = '${apiURL}novel-chapters/$novelId';
      final chapterApiResult = await _fetchApi(chapterApiUrl);

      final chapters = <Chapter>[];

      if (chapterApiResult is Map && chapterApiResult['novel'] is List) {
        final novelDetails =
            chapterApiResult['novel'][0] as Map<String, dynamic>?;
        if (novelDetails != null) {
          final chapterList = novelDetails['chapters'] as List<dynamic>?;

          if (chapterList != null) {
            int chapterNumber = 1;
            for (final chapter in chapterList) {
              if (chapter is! Map<String, dynamic>) {
                print(
                  'Unexpected data type in chapterList: ${chapter.runtimeType}',
                );
                continue;
              }

              final chapterId = chapter['id'];
              final chpName = chapter['chp_name'];
              final chapterPath =
                  chapterId != null && chpName != null
                      ? '$novelPath/$chapterId/$chpName'
                      : null;
              if (chapterPath == null) {
                print(
                  'Invalid chapterId or chpName: chapterId=$chapterId, chpName=$chpName',
                );
                continue;
              }

              chapters.add(
                Chapter(
                  id: chapterPath,
                  title: chapter['chp_index_title'] as String? ?? '',
                  content: '',
                  order: chapter['chp_number'] as int? ?? 0,
                  chapterNumber: chapterNumber,
                ),
              );
              chapterNumber++;
            }
          } else {
            print('Failed to load chapters from API or unexpected format.');
          }
        } else {
          print('Novel details is null.');
        }
      } else {
        print('Chapter API result is not a Map or novel is not a List.');
      }

      novel.chapters = chapters;
      return novel;
    } catch (e) {
      print("Error parsing novel data: $e, returning default Novel");
      return _createDefaultNovel(novelPath, 'Erro ao carregar');
    }
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final parts = chapterPath.split('/');
    final chapterId = parts.length > 2 ? parts[2] : null;
    if (chapterId == null) {
      print('Invalid chapterPath: $chapterPath');
      return '404';
    }

    try {
      final response = await _client.get(
        Uri.parse('$apiURL/novel-chapter/$chapterId'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Referer': baseURL,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is Map &&
            jsonData['chapter'] is List &&
            jsonData['chapter'].isNotEmpty) {
          final chapterContent =
              jsonData['chapter'][0]['chp_content'] as String?;
          if (chapterContent != null) {
            return chapterContent;
          }
        }
      }
      print('API request failed, falling back to HTML parsing.');
    } catch (e) {
      print('API request failed: $e, falling back to HTML parsing.');
    }
    try {
      final response = await _client.get(
        Uri.parse(baseURL + chapterPath.replaceAll('//', '/')),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Referer': baseURL,
        },
      );

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final script = document.querySelector('markdown');

        if (script != null) {
          return script.innerHtml;
        } else {
          print('Script tag with id "markdown" not found');
          return '404';
        }
      } else {
        print('Failed to load page, status code: ${response.statusCode}');
        return '404';
      }
    } catch (e) {
      print('Error parsing chapter from HTML: $e');
      return '404';
    }
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final url = '${apiURL}novels?&q=$searchTerm&page=$pageNo';
    return await _fetchNovels(pageNo, url: url, filters: filters);
  }

  @override
  Future<List<Novel>> getAllNovels({
    BuildContext? context,
    int pageNo = 1,
  }) async {
    final url = '${apiURL}novels?&q&page=$pageNo';
    return await _fetchNovels(pageNo, url: url, filters: filters);
  }

  Future<List<Novel>> _fetchNovels(
    int pageNo, {
    String? url,
    Map<String, dynamic>? filters,
  }) async {
    url ??= '${apiURL}novels?&q&page=$pageNo';
    final apiResult = await _fetchApi(url);

    if (apiResult == null) {
      print("apiResult is null, returning empty list");
      return [];
    }

    if (apiResult is! Map || apiResult['novels'] is! List) {
      print('Formato de resposta da API inesperado para popularNovels');
      return [];
    }

    final novelList = apiResult['novels'] as List<dynamic>;
    final novels = <Novel>[];

    for (final novelData in novelList) {
      if (novelData is! Map<String, dynamic>) {
        print('Unexpected data type in novelList: ${novelData.runtimeType}');
        continue;
      }

      try {
        final title = novelData['nvl_title'] as String? ?? 'Untitled';
        final cover =
            novelData['image'] != null
                ? '${apiURL}get-image/${novelData['image']}/novels/false'
                : defaultCover;
        final novelId = novelData['id'];
        final novelName = novelData['nvl_name'];
        final path =
            novelId != null && novelName != null
                ? 'novelas/$novelId/$novelName/'
                : null;
        if (path == null) {
          print(
            'Invalid novelId or novelName: novelId=$novelId, novelName=$novelName',
          );
          continue;
        }
        novels.add(
          Novel(
            id: path,
            title: title,
            coverImageUrl: cover,
            description: novelData['nvl_content'] as String? ?? '',
            genres:
                (novelData['genres'] as List<dynamic>?)
                    ?.map<String>((genre) {
                      if (genre is Map<String, dynamic>) {
                        return genre['genre_name'] as String? ?? '';
                      }
                      print(
                        'Unexpected data type in genres: ${genre.runtimeType}',
                      );
                      return '';
                    })
                    .where((genre) => genre.isNotEmpty)
                    .toList() ??
                [],
            chapters: [],
            artist: '',
            statusString: novelData['nvl_status'] as String? ?? '',
            pluginId: id,
            author: novelData['nvl_writer'] as String? ?? '',
          ),
        );
      } catch (e) {
        print('Erro ao processar dados do novel: $e, data: $novelData');
      }
    }

    return novels;
  }

  Novel _createDefaultNovel(String novelPath, String errorMessage) {
    return Novel(
      id: novelPath,
      title: 'Erro ao carregar',
      coverImageUrl: defaultCover,
      description: errorMessage,
      genres: [],
      chapters: [],
      artist: '',
      statusString: '',
      pluginId: id,
      author: '',
    );
  }
}
