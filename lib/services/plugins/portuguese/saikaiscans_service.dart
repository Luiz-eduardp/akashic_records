import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'dart:convert';
import 'package:html/parser.dart' show parse;

class SaikaiScans implements PluginService {
  @override
  String get name => 'Saikai Scans';

  String get id => 'saikaiscans.net';

  String get version => '1.0.0';

  @override
  Map<String, dynamic> get filters => {
    'genres': {
      'value': '',
      'label': 'Gêneros',
      'options': [
        {'label': 'Todos', 'value': ''},
        {'label': 'Ação', 'value': '1'},
        {'label': 'Aventura', 'value': '2'},
        {'label': 'Fantasia', 'value': '3'},
        {'label': 'Horror', 'value': '27'},
        {'label': 'Militar', 'value': '76'},
        {'label': 'Misterio', 'value': '57'},
        {'label': 'Horror', 'value': '82'},
      ],
    },
    'status': {
      'value': '',
      'label': 'Status',
      'options': [
        {'label': 'Todos', 'value': ''},
        {'label': 'Ativo', 'value': '1'},
        {'label': 'Completo', 'value': '2'},
        {'label': 'Pausado', 'value': '3'},
        {'label': 'Dropado', 'value': '4'},
        {'label': 'Em Breve', 'value': '5'},
        {'label': 'Hiato', 'value': '6'},
      ],
    },
    'country': {
      'value': '',
      'label': 'País',
      'options': [
        {'label': 'Todos', 'value': ''},
        {'label': 'Brasil', 'value': '32'},
        {'label': 'Coreia', 'value': '115'},
      ],
    },
    'ordem': {
      'label': 'Ordenar Por',
      'value': 'title',
      'options': [
        {'label': 'Título', 'value': 'title'},
        {'label': 'Views', 'value': 'views'},
        {'label': 'Lançamento', 'value': 'release'},
      ],
    },
    'direction': {
      'label': 'Direção',
      'value': 'asc',
      'options': [
        {'label': 'Ascendente', 'value': 'asc'},
        {'label': 'Descendente', 'value': 'desc'},
      ],
    },
  };

  final String baseURL = 'https://saikaiscan.com.br';
  final String apiUrl = 'https://api.saikaiscans.net/api/stories';
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
        try {
          return jsonDecode(response.body);
        } catch (e) {
          print('Erro ao decodificar JSON (retornando HTML): $e');
          return response.body;
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
    String url = '$apiUrl?format=1&page=$pageNo&per_page=12';

    if (filters != null) {
      url += '&genres=${filters['genres']?['value'] ?? ''}';
      url += '&status=${filters['status']?['value'] ?? ''}';
      url += '&country=${filters['country']?['value'] ?? ''}';
      url += '&sortProperty=${filters['ordem']?['value'] ?? 'title'}';
      url += '&sortDirection=${filters['direction']?['value'] ?? 'asc'}';
    }

    try {
      dynamic body = await _fetchApi(url);
      if (body is String) {
        print('PopularNovels retornando HTML em vez de JSON');
        return [];
      }

      if (body == null) {
        print('PopularNovels body nulo!');
        return [];
      }

      final List<dynamic> data = body['data'];

      List<Novel> novels =
          data.map((item) {
            return Novel(
              id: item['slug'],
              title: item['title'],
              coverImageUrl:
                  'https://s3-alpha.saikaiscans.net/${item['image']}',
              author:
                  item['authors'].isNotEmpty
                      ? item['authors'][0]['name']
                      : 'Desconhecido',
              description: item['resume'],
              genres:
                  (item['genres'] as List<dynamic>)
                      .map((genre) => genre['name'].toString())
                      .toList(),
              chapters: [],
              artist: '',
              statusString: '',
              pluginId: name,
            );
          }).toList();

      return novels;
    } catch (e) {
      print('Error fetching or parsing popular novels: $e');
      return [];
    }
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    String url = '$apiUrl?format=1&q=$searchTerm&page=$pageNo&per_page=12';

    try {
      dynamic body = await _fetchApi(url);

      if (body is String) {
        print('searchNovels retornando HTML em vez de JSON');
        return [];
      }

      if (body == null) {
        print('searchNovels body nulo!');
        return [];
      }

      final List<dynamic> data = body['data'];

      List<Novel> novels =
          data.map((item) {
            return Novel(
              id: item['slug'],
              title: item['title'],
              coverImageUrl:
                  'https://s3-alpha.saikaiscans.net/${item['image']}',
              author:
                  item['authors'].isNotEmpty
                      ? item['authors'][0]['name']
                      : 'Desconhecido',
              description: item['resume'],
              genres:
                  (item['genres'] as List<dynamic>)
                      .map((genre) => genre['name'].toString())
                      .toList(),
              chapters: [],
              artist: '',
              statusString: '',
              pluginId: name,
            );
          }).toList();

      return novels;
    } catch (e) {
      print('Error fetching or parsing search novels: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchNovelData(String novelSlug) async {
    final chapterListUrl = '$baseURL/series/$novelSlug';
    dynamic body = await _fetchApi(chapterListUrl);

    if (body is String) {
      final document = parse(body);

      final scriptElements = document.querySelectorAll('script');
      for (var element in scriptElements) {
        final textContent = element.text;
        if (textContent.contains('window.__DATA__ = ')) {
          String jsonData = textContent
              .replaceAll('window.__DATA__ = ', '')
              .replaceAll(';', '');
          return jsonDecode(jsonData)[0];
        }
      }
    }
    return null;
  }

  @override
  Future<Novel> parseNovel(String novelSlug) async {
    print('parseNovel: Inciando parse do novel $novelSlug');
    final novelData = await _fetchNovelData(novelSlug);
    if (novelData == null) {
      print(
        'parseNovel: Nenhuma informação encontrada para o novel $novelSlug',
      );
      return Novel(
        id: novelSlug,
        title: 'Erro ao carregar',
        coverImageUrl: defaultCover,
        description: 'Não foi possível carregar os dados do novel.',
        genres: [],
        chapters: [],
        artist: '',
        statusString: '',
        pluginId: name,
        author: 'Desconhecido',
      );
    }

    String imageLink = novelData['cover'] ?? defaultCover;

    Novel novel = Novel(
      id: novelData['title'],
      title: novelData['title'],
      coverImageUrl: imageLink,
      author: _extractAuthor(novelData['sinopse']),
      description: novelData['sinopse'],
      genres: _extractGenres(novelData['sinopse']),
      chapters: [],
      artist: '',
      statusString: 'Unknown',
      pluginId: name,
    );
    print('parseNovel: Criado os dados basicos para o novel:  $novelSlug');

    final chapters = await _getChapters(novelSlug);

    novel.chapters = chapters;

    print('parseNovel: Carregado os capitulos para o novel:  $novelSlug');
    print('parseNovel: Finalizado o parse para o novel: $novelSlug');
    return novel;
  }

  Future<List<Chapter>> _getChapters(String novelSlug) async {
    final chapterListUrl = '$baseURL/series/$novelSlug';
    dynamic body = await _fetchApi(chapterListUrl);

    if (body is String) {
      final document = parse(body);
      final chapterListContainer = document.querySelector(
        '#page-novel > div.__body > div > div',
      );

      if (chapterListContainer == null) {
        print('Chapter list container not found!');
        return [];
      }

      final chapterElements = chapterListContainer.querySelectorAll(
        'div.__right > ul.__chapters > li > a',
      );

      List<Chapter> chapters = [];
      for (var element in chapterElements) {
        final chapterTitle = element.text.trim();
        final chapterPath = element.attributes['href'] ?? '';
        chapters.add(
          Chapter(id: chapterPath, title: chapterTitle, content: '', order: 0),
        );
      }
      return chapters;
    }

    return [];
  }

  String _extractAuthor(String sinopse) {
    final authorRegex = RegExp(r'Autor\n(.*?)\n');
    final match = authorRegex.firstMatch(sinopse);
    return match?.group(1) ?? 'Desconhecido';
  }

  List<String> _extractGenres(String sinopse) {
    final genresRegex = RegExp(
      r'Gêneros\n(.*?)(?=\nTags|\nAvaliações)',
      dotAll: true,
    );
    final match = genresRegex.firstMatch(sinopse);
    if (match != null) {
      return match.group(1)!.split('\n').map((s) => s.trim()).toList();
    } else {
      return [];
    }
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    try {
      final body = await _fetchApi(chapterPath);
      if (body is String) {
        final document = parse(body);
        final scriptElements = document.querySelectorAll('script');

        for (var element in scriptElements) {
          final textContent = element.text;
          if (textContent.contains('window.__DATA__ = ')) {
            String jsonData = textContent
                .replaceAll('window.__DATA__ = ', '')
                .replaceAll(';', '');
            dynamic json = jsonDecode(jsonData);
            dynamic chapterData = json[0];
            return chapterData['chaptercontent'] ?? 'Conteúdo não encontrado';
          }
        }
      }
      return 'Conteúdo não encontrado';
    } catch (e) {
      print('Error fetching or parsing chapter: $e');
      return 'Conteúdo não encontrado';
    }
  }
}
