import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:akashic_records/models/novel.dart';
import 'package:akashic_records/models/chapter.dart';
import 'dart:convert';

enum NovelStatus { Ongoing, Completed, OnHiatus, Unknown }

class SaikaiScans {
  final String id = 'saikaiscans.net';
  final String name = 'Saikai Scans';
  final String icon = 'src/saikaiscans/icon.png';
  final String site = 'https://saikaiscans.net';
  final String apiUrl = 'https://api.saikaiscans.net/api/stories';
  final String version = '1.0.0';
  static const String defaultCover =
      'https://via.placeholder.com/150x200?text=No+Cover';

  Future<String> _fetchApi(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Falha ao carregar dados de: $url');
    }
  }

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
      final body = await _fetchApi(url);
      final json = jsonDecode(body);
      final List<dynamic> data = json['data'];

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
            );
          }).toList();

      return novels;
    } catch (e) {
      print('Error fetching or parsing popular novels: $e');
      return [];
    }
  }

  Future<List<Novel>> searchNovels(String searchTerm, int pageNo) async {
    final url = '$apiUrl?format=1&q=$searchTerm&page=$pageNo&per_page=12';

    try {
      final body = await _fetchApi(url);
      final json = jsonDecode(body);
      final List<dynamic> data = json['data'];

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
            );
          }).toList();

      return novels;
    } catch (e) {
      print('Error fetching or parsing search novels: $e');
      return [];
    }
  }

  Future<Novel> parseNovel(String novelSlug) async {
    final chapterListUrl = '$site/series/$novelSlug';
    print('parseNovel: Fetching HTML from $chapterListUrl');

    try {
      final body = await _fetchApi(chapterListUrl);
      print('parseNovel: HTML body received');

      final document = parse(body);
      print('parseNovel: HTML parsed');

      final scriptElements = document.querySelectorAll('script');
      print('parseNovel: Found ${scriptElements.length} script elements');

      String jsonData = "";

      for (var element in scriptElements) {
        final textContent = element.text;
        if (textContent.contains('window.__DATA__ = ')) {
          jsonData = textContent
              .replaceAll('window.__DATA__ = ', '')
              .replaceAll(';', '');
          print('parseNovel: Found JSON data');
          break;
        }
      }

      if (jsonData == null || jsonData.isEmpty) {
        print('parseNovel: JSON data not found in the HTML');
        throw Exception('JSON data not found in the HTML');
      }

      final json = jsonDecode(jsonData);
      print('parseNovel: JSON decoded');
      final dynamic novelData = json[0];
      print('parseNovel: Novel data: $novelData');

      final novel = Novel(
        id: novelData['title'],
        title: novelData['title'],
        coverImageUrl: novelData['cover'],
        author: _extractAuthor(novelData['sinopse']),
        description: novelData['sinopse'],
        genres: _extractGenres(novelData['sinopse']),
        chapters: await _getChapters(novelSlug),
        artist: '',
        statusString: '',
      );
      print('parseNovel: Novel created');

      return novel;
    } catch (e) {
      print('Error fetching or parsing novel: $e');
      rethrow;
    }
  }

  Future<List<Chapter>> _getChapters(String novelSlug) async {
    final chapterListUrl = '$site/series/$novelSlug';
    try {
      final body = await _fetchApi(chapterListUrl);
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

      List<Chapter> chapters =
          chapterElements.map((element) {
            final chapterTitle = element.text.trim();
            final chapterPath = element.attributes['href'] ?? '';
            return Chapter(
              id: chapterPath,
              title: chapterTitle,
              content: '',
              order: null,
            );
          }).toList();
      return chapters;
    } catch (e) {
      print('Error fetching chapter list: $e');
      return [];
    }
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

  Future<String> parseChapter(String chapterPath) async {
    try {
      final body = await _fetchApi(chapterPath);
      final document = parse(body);

      final scriptElements = document.querySelectorAll('script');

      String jsonData = "";

      for (var element in scriptElements) {
        final textContent = element.text;
        if (textContent.contains('window.__DATA__ = ')) {
          jsonData = textContent
              .replaceAll('window.__DATA__ = ', '')
              .replaceAll(';', '');
          break;
        }
      }

      if (jsonData == null || jsonData.isEmpty) {
        throw Exception('JSON data not found in the HTML');
      }

      final json = jsonDecode(jsonData);
      final chapterData = json[0];

      return chapterData['chaptercontent'] ?? '';
    } catch (e) {
      print('Error fetching or parsing chapter: $e');
      return '';
    }
  }

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
}
