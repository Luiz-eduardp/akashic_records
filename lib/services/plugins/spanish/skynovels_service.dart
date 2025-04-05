import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'dart:convert';
import 'package:html/parser.dart' show parse;

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
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Referer': baseURL,
        },
      );

      if (response.statusCode == 200) {
        String body = response.body;
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
      } else if (response.statusCode == 403) {
        print('Erro 403: Acesso proibido para a URL: $url');
        return null;
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
    String url = '${apiURL}novels?&q';
    dynamic apiResult = await _fetchApi(url);

    if (apiResult == null) {
      print("apiResult is null, returning empty list");
      return [];
    }

    if (apiResult is String) {
      print("apiResult is String, returning empty list");
      return [];
    }

    List<Novel> novels = [];

    if (apiResult is Map && apiResult['novels'] is List) {
      List<dynamic> novelList = apiResult['novels'];
      for (var novelData in novelList) {
        String title = novelData['nvl_title'];
        String cover =
            '${apiURL}get-image/' + novelData['image'] + '/novels/false';
        String path =
            'novelas/${novelData['id']}/' + novelData['nvl_name'] + '/';

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
    List<String> parts = novelPath.split('/');
    String novelId = parts[1];

    String url = '${apiURL}novel/$novelId/reading?&q';
    dynamic apiResult = await _fetchApi(url);

    if (apiResult == null) {
      print("apiResult is null, returning default Novel");
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

    if (apiResult is String) {
      print("apiResult is String, returning default Novel");
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
      Map<String, dynamic>? novelData =
          (apiResult['novel'] as List).isNotEmpty
              ? apiResult['novel'][0]
              : null;

      if (novelData != null) {
        Novel novel = Novel(
          id: novelPath,
          title: novelData['nvl_title'] ?? 'Untitled',
          coverImageUrl:
              '${apiURL}get-image/' + novelData['image'] + '/novels/false',
          description: novelData['nvl_content'] ?? '',
          genres:
              (novelData['genres'] as List<dynamic>?)
                  ?.map<String>((genre) => genre['genre_name'].toString())
                  .toList() ??
              [],
          chapters: [],
          artist: '',
          statusString: novelData['nvl_status'] ?? '',
          author: novelData['nvl_writer'] ?? '',
          pluginId: id,
        );

        List<Chapter> chapters = [];
        List<dynamic>? volumes = (novelData['volumes'] as List<dynamic>?);
        if (volumes != null) {
          for (var volume in volumes) {
            List<dynamic>? chapterList = (volume['chapters'] as List<dynamic>?);
            if (chapterList != null) {
              for (var chapter in chapterList) {
                String chapterPath =
                    '$novelPath${chapter['id']}/' + chapter['chp_name'];
                chapters.add(
                  Chapter(
                    id: chapterPath,
                    title: chapter['chp_index_title'],
                    content: '',
                    order: chapter['chp_index'] ?? 0,
                  ),
                );
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
    List<String> parts = chapterPath.split('/');
    String chapterId = parts[3];

    String url = '${apiURL}novel-chapter/$chapterId';
    dynamic apiResult = await _fetchApi(url);

    if (apiResult == null) {
      print('apiResult is null for parseChapter');
      return '404';
    }

    if (apiResult is String) {
      print("apiResult is String for parseChapter, returning 404");
      return '404';
    }

    if (apiResult is Map && apiResult['chapter'] is List) {
      Map<String, dynamic>? chapterData =
          (apiResult['chapter'] as List).isNotEmpty
              ? apiResult['chapter'][0]
              : null;

      if (chapterData != null) {
        return chapterData['chp_content'] ?? '404';
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
    String searchTermLower = searchTerm.toLowerCase();
    String url = '${apiURL}novels?&q';
    dynamic apiResult = await _fetchApi(url);

    if (apiResult == null) {
      print('apiResult is null for searchNovels');
      return [];
    }

    if (apiResult is String) {
      print("apiResult is String for searchNovels, returning empty list");
      return [];
    }

    List<Novel> novels = [];

    if (apiResult is Map && apiResult['novels'] is List) {
      List<dynamic> novelList = apiResult['novels'];
      List<dynamic>? filteredNovels =
          novelList
              .where(
                (novel) => (novel['nvl_title'] as String)
                    .toLowerCase()
                    .contains(searchTermLower),
              )
              .toList();
      if (filteredNovels != null) {
        for (var novelData in filteredNovels) {
          String title = novelData['nvl_title'];
          String cover =
              '${apiURL}get-image/' + novelData['image'] + '/novels/false';
          String path =
              'novelas/${novelData['id']}/' + novelData['nvl_name'] + '/';

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
      }
    } else {
      print('Formato de resposta da API inesperado para searchNovels');
    }

    return novels;
  }
}
