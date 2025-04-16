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

        final chapters = <Chapter>[];
        final volumes = novelData['volumes'] as List<dynamic>?;
        if (volumes != null) {
          int chapterNumber = 1;

          for (final volume in volumes) {
            final chapterList = volume['chapters'] as List<dynamic>?;
            if (chapterList != null) {
              for (final chapter in chapterList) {
                final chapterPath =
                    '$novelPath${chapter['id']}/${chapter['chp_name']}';
                chapters.add(
                  Chapter(
                    id: chapterPath,
                    title: chapter['chp_index_title'] as String? ?? '',
                    content: '',
                    order: chapter['chp_index'] as int? ?? 0,
                    chapterNumber: chapterNumber,
                  ),
                );
                chapterNumber++;
              }
            }
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
    final chapterId = parts[3];

    final url = '${apiURL}novel-chapter/$chapterId';
    final apiResult = await _fetchApi(url);

    if (apiResult == null || apiResult is String) {
      print('apiResult is null for parseChapter');
      return '404';
    }

    if (apiResult is Map && apiResult['chapter'] is List) {
      final chapterData = (apiResult['chapter'] as List)
          .cast<Map<String, dynamic>?>()
          .firstWhere((element) => element != null, orElse: () => null);

      if (chapterData != null) {
        return chapterData['chp_content'] as String? ?? '404';
      }
    }

    print('Unexpected format for chapter data, returning 404');
    return '404';
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final searchTermLower = searchTerm.toLowerCase();
    final url = '${apiURL}novels?&q';
    final apiResult = await _fetchApi(url);

    if (apiResult == null || apiResult is String) {
      print('apiResult is null for searchNovels');
      return [];
    }

    final novels = <Novel>[];

    if (apiResult is Map && apiResult['novels'] is List) {
      final novelList = apiResult['novels'] as List<dynamic>;
      final filteredNovels =
          novelList
              .where(
                (novel) =>
                    ((novel as Map<String, dynamic>)['nvl_title'] as String)
                        .toLowerCase()
                        .contains(searchTermLower),
              )
              .toList();

      for (final novelData in filteredNovels) {
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
      print('Formato de resposta da API inesperado para searchNovels');
    }

    return novels;
  }
}
