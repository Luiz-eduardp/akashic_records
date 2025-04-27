import 'dart:async';
import 'dart:convert';

import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

class SkyNovels implements PluginService {
  @override
  String get name => 'SkyNovels';

  String get id => 'SkyNovels';

  String get version => '1.0.0';

  @override
  Map<String, dynamic> get filters => {};

  final String baseURL = 'https://www.skynovels.net/';
  final String apiURL = 'https://api.skynovels.net/api/';
  final String icon = 'src/es/skynovels/icon.png';

  static const String defaultCover =
      'https://placehold.co/400x450.png?text=Sem%20Capa';

  Future<dynamic> _fetchApi(String url) async {
    try {
      final response = await http
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
          try {
            parse(body);
            print(
              'Recebido HTML em vez de JSON, indicando uma página de erro.',
            );
            return null;
          } catch (htmlError) {
            print(
              'Erro ao decodificar JSON: $jsonError, Erro ao parsear HTML: $htmlError',
            );
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
  }) async {
    final url = '${apiURL}novels?&q';
    final apiResult = await _fetchApi(url);

    if (apiResult == null || apiResult is String) {
      print("apiResult is null or String, returning empty list");
      return [];
    }

    final novels = <Novel>[];

    if (apiResult is Map && apiResult['novels'] is List) {
      final novelList = apiResult['novels'] as List<dynamic>;
      for (final novelData in novelList) {
        final title = novelData['nvl_title'] as String;
        final cover = '${apiURL}get-image/${novelData['image']}/novels/false';
        final path = 'novelas/${novelData['id']}/${novelData['nvl_name']}/';

        novels.add(
          Novel(
            id: path,
            title: title,
            coverImageUrl: cover,
            description: '',
            genres: [],
            chapters: [],
            artist: '',
            statusString: '',
            pluginId: id,
            author: '',
          ),
        );
      }
    } else {
      print('Formato de resposta da API inesperado para popularNovels');
    }

    return novels;
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final parts = novelPath.split('/');
    final novelId = parts[1];

    final url = '${apiURL}novel/$novelId/reading?&q';
    final apiResult = await _fetchApi(url);

    if (apiResult == null || apiResult is String) {
      print("apiResult is null or String, returning default Novel");
      return Novel(
        id: novelPath,
        title: 'Erro ao carregar',
        coverImageUrl: defaultCover,
        description: 'Não foi possível carregar os dados do novel.',
        genres: [],
        chapters: [],
        artist: '',
        statusString: '',
        pluginId: id,
        author: '',
      );
    }

    if (apiResult is Map && apiResult['novel'] is List) {
      final novelData = (apiResult['novel'] as List)
          .cast<Map<String, dynamic>?>()
          .firstWhere((element) => element != null, orElse: () => null);

      if (novelData != null) {
        final novel = Novel(
          id: novelPath,
          title: novelData['nvl_title'] as String? ?? 'Untitled',
          coverImageUrl:
              '${apiURL}get-image/${novelData['image']}/novels/false',
          description: novelData['nvl_content'] as String? ?? '',
          genres:
              (novelData['genres'] as List<dynamic>?)
                  ?.map(
                    (genre) =>
                        (genre as Map<String, dynamic>)['genre_name'] as String,
                  )
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

        if (chapterApiResult != null &&
            chapterApiResult is Map &&
            chapterApiResult['novel'] is List) {
          final novelDetails =
              chapterApiResult['novel'][0] as Map<String, dynamic>;
          final chapterList = novelDetails['chapters'] as List<dynamic>?;

          if (chapterList != null) {
            int chapterNumber = 1;
            for (final chapter in chapterList) {
              final chapterId = chapter['id'];
              final chapterPath =
                  '$novelPath/$chapterId/${chapter['chp_name']}';
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
        }

        novel.chapters = chapters;
        return novel;
      }
    }

    print("Unexpected format for novel data, returning default Novel");
    return Novel(
      id: novelPath,
      title: 'Erro ao carregar',
      coverImageUrl: defaultCover,
      description: 'Não foi possível carregar os dados do novel.',
      genres: [],
      chapters: [],
      artist: '',
      statusString: '',
      pluginId: id,
      author: '',
    );
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final parts = chapterPath.split('/');
    final chapterId = parts[2];

    try {
      final response = await http.get(
        Uri.parse('$apiURL/novel-chapter/$chapterId'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Referer': baseURL,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData != null &&
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
      final response = await http.get(
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
          print('Script tag with id "serverApp-state" not found');
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
    final searchTermLower = searchTerm.toLowerCase();
    final url = '${apiURL}novels?&q';

    print('searchNovels: searchTerm = $searchTerm');
    print('searchNovels: searchTermLower = $searchTermLower');

    final apiResult = await _fetchApi(url);

    print('searchNovels: apiResult = $apiResult');

    if (apiResult == null || apiResult is String) {
      print('searchNovels: apiResult is null');
      return [];
    }

    final novels = <Novel>[];

    if (apiResult is Map && apiResult['novels'] is List) {
      final novelList = apiResult['novels'] as List<dynamic>;

      final filteredNovels =
          novelList.where((novel) {
            if (novel is Map<String, dynamic>) {
              final title =
                  (novel['nvl_title'] as String?)?.toLowerCase() ?? '';
              print('searchNovels: title = $title');

              if (searchTermLower.isNotEmpty &&
                  title.contains(searchTermLower)) {
                return true;
              }
            }
            return false;
          }).toList();

      print('searchNovels: filteredNovels.length = ${filteredNovels.length}');

      for (final dynamic novelData in filteredNovels) {
        if (novelData is Map<String, dynamic>) {
          try {
            final title = novelData['nvl_title'] as String;
            final cover =
                '${apiURL}get-image/${novelData['image']}/novels/false';
            final novelId = novelData['id'];
            final novelName = novelData['nvl_name'];
            final path = 'novelas/$novelId/$novelName/';

            novels.add(
              Novel(
                id: path,
                title: title,
                coverImageUrl: cover,
                description: novelData['nvl_content'] as String? ?? '',
                genres:
                    (novelData['genres'] as List<dynamic>?)
                        ?.map<String>(
                          (genre) =>
                              (genre as Map<String, dynamic>)['genre_name']
                                  as String,
                        )
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
            print(
              'searchNovels: Error processing novel data: $e - novelData: $novelData - searchTerm: $searchTerm - url: $url',
            );
          }
        } else {
          print(
            'searchNovels: Unexpected data type in novel list: ${novelData.runtimeType}',
          );
        }
      }
    } else {
      print('searchNovels: Formato de resposta da API inesperado.');
    }

    return novels;
  }
}
