import 'dart:async';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';

class LightNovelBrasil implements PluginService {
  @override
  String get name => 'LightNovelBrasil';

  @override
  Map<String, dynamic> get filters => {
    'genre[]': {
      'type': 'Checkbox',
      'label': 'Genre',
      'value': [],
      'options': [
        {'label': '+18', 'value': '18'},
        {'label': 'Ação', 'value': 'acao'},
        {'label': 'Artes Marciais', 'value': 'artes-marciais'},
        {'label': 'Aventura', 'value': 'aventura'},
        {'label': 'Comédia', 'value': 'comedia'},
        {'label': 'Cultivo', 'value': 'cultivo'},
        {'label': 'Cyberpunk', 'value': 'cyberpunk'},
        {'label': 'Drama', 'value': 'drama'},
        {'label': 'Ecchi', 'value': 'ecchi'},
        {'label': 'Esportes', 'value': 'esportes'},
        {'label': 'Fanfiction', 'value': 'fanfiction'},
        {'label': 'Fantasia', 'value': 'fantasia'},
        {'label': 'Ficção Científica', 'value': 'ficcao-cientifica'},
        {'label': 'Games', 'value': 'games'},
        {'label': 'Harem', 'value': 'harem'},
        {'label': 'Horror', 'value': 'horror'},
        {'label': 'Isekai', 'value': 'isekai'},
        {'label': 'Magia', 'value': 'magia'},
        {'label': 'Mecha', 'value': 'mecha'},
        {'label': 'Militar', 'value': 'militar'},
        {'label': 'Mistério', 'value': 'misterio'},
        {'label': 'Novel Nacional', 'value': 'novel-nacional'},
        {'label': 'Psicológico', 'value': 'psicologico'},
        {'label': 'Romance', 'value': 'romance'},
        {'label': 'Sci-fi', 'value': 'sci-fi'},
        {'label': 'Seinen', 'value': 'seinen'},
        {'label': 'Shoujo', 'value': 'shoujo'},
        {'label': 'Shounen', 'value': 'shounen'},
        {'label': 'Shounen BL', 'value': 'shounen-bl'},
        {'label': 'Slice of Life', 'value': 'slice-of-life'},
        {'label': 'Sobrenatural', 'value': 'sobrenatural'},
        {'label': 'Terror', 'value': 'terror'},
        {'label': 'Tragédia', 'value': 'tragedia'},
        {'label': 'Vida Escolar', 'value': 'vida-escolar'},
        {'label': 'Wuxia', 'value': 'wuxia'},
        {'label': 'Xianxia', 'value': 'xianxia'},
        {'label': 'Xuanhuan', 'value': 'xuanhuan'},
        {'label': 'Yaoi', 'value': 'yaoi'},
        {'label': 'Yuri', 'value': 'yuri'},
      ],
    },
    'type[]': {
      'type': 'Checkbox',
      'label': 'Tipo',
      'value': [],
      'options': [
        {'label': 'Light Novel', 'value': 'light-novel'},
        {'label': 'Livro', 'value': 'livro'},
        {'label': 'One-Shot', 'value': 'one-shot'},
        {'label': 'Web Novel', 'value': 'web-novel'},
      ],
    },
    'status': {
      'type': 'Picker',
      'label': 'Status',
      'value': '',
      'options': [
        {'label': 'Tudo', 'value': ''},
        {'label': 'Ongoing', 'value': 'ongoing'},
        {'label': 'Hiatus', 'value': 'hiatus'},
        {'label': 'Completed', 'value': 'completed'},
      ],
    },
    'order': {
      'type': 'Picker',
      'label': 'Ordenar por',
      'value': '',
      'options': [
        {'label': 'Padrão', 'value': ''},
        {'label': 'A-Z', 'value': 'title'},
        {'label': 'Z-A', 'value': 'titlereverse'},
        {'label': 'Últimos Lançamentos', 'value': 'update'},
        {'label': 'Última Adição', 'value': 'latest'},
        {'label': 'Popular', 'value': 'popular'},
      ],
    },
  };

  final String id = 'lightnovelbrasil';
  final String nameService = 'Light Novel Brasil';
  final String baseURL = 'https://lightnovelbrasil.com/';
  final String imageURL = 'multisrc/lightnovelwp/lightnovelbrasil/icon.png';
  final String version = '1.1.8';
  final bool reverseChapters = true;
  final String seriesPath = "/series/";

  static const String defaultCover =
      'https://placehold.co/400x450.png?text=Sem%20Capa';

  Future<String> _fetchApi(String url) async {
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
        return response.body;
      } else if (response.statusCode == 403) {
        print('Erro 403: Acesso proibido para a URL: $url');
        return '';
      } else {
        throw Exception(
          'Falha ao carregar dados de: $url - Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      return '';
    }
  }

  String _shrinkURL(String url) {
    return url.replaceAll(RegExp(r'^.+lightnovelbrasil\.com'), '');
  }

  String _expandURL(String path) {
    return baseURL + path;
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    String url = createFilterUrl(filters, false, pageNo);
    final body = await _fetchApi(url);
    if (body.isEmpty) {
      return [];
    }
    return await _parseList(body);
  }

  Future<List<Novel>> recentNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    String url = createFilterUrl(filters, true, pageNo);
    final body = await _fetchApi(url);
    if (body.isEmpty) {
      return [];
    }
    return await _parseList(body);
  }

  Future<List<Novel>> _parseList(String body) async {
    if (body.isEmpty) {
      return [];
    }

    final document = parse(body);
    final novelElements = document.querySelectorAll('article');

    List<Novel> novels = [];
    for (var element in novelElements) {
      final aElement = element.querySelector('a');
      final imgElement = element.querySelector('img');

      final link = _shrinkURL(aElement?.attributes['href'] ?? '');
      final title = aElement?.attributes['title'] ?? '';
      final cover =
          imgElement?.attributes['data-src'] ??
          imgElement?.attributes['src'] ??
          defaultCover;

      if (title.isNotEmpty && link.isNotEmpty) {
        novels.add(
          Novel(
            id: link,
            title: title,
            coverImageUrl: cover,
            author: '',
            description: '',
            genres: [],
            chapters: [],
            artist: '',
            statusString: '',
            pluginId: name,
          ),
        );
      }
    }
    return novels;
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final body = await _fetchApi(_expandURL(novelPath));
    if (body.isEmpty) {
      return Novel(
        id: novelPath,
        title: 'Erro ao carregar',
        coverImageUrl: defaultCover,
        description: 'Não foi possível carregar os dados do novel.',
        genres: [],
        chapters: [],
        artist: '',
        statusString: '',
        author: '',
        pluginId: name,
        status: NovelStatus.Unknown,
      );
    }
    final document = parse(body);

    final img = document.querySelector('div.ts-post-image > a > img');
    final descriptionElement = document.querySelector('div.entry-content');
    final genresElements = document.querySelectorAll('div.genxed > a');
    final authorElement = document.querySelector('div.spe > span');

    final statusElement = document.querySelector('div.sertostat > span');
    NovelStatus status = NovelStatus.Unknown;
    if (statusElement != null) {
      final statusText = statusElement.text.toLowerCase();
      if (statusText.contains('completo') || statusText.contains('completed')) {
        status = NovelStatus.Completed;
      } else if (statusText.contains('andamento') ||
          statusText.contains('ongoing')) {
        status = NovelStatus.Ongoing;
      } else if (statusText.contains('hiato')) {
        status = NovelStatus.OnHiatus;
      }
    }
    String description = '';
    if (descriptionElement != null) {
      description = descriptionElement.text.trim();
    }

    final chapterElements = document.querySelectorAll('div.eplister li > a');
    List<Chapter> chapters = [];
    int count = chapterElements.length;
    for (var el in chapterElements) {
      final num = el.querySelector('div.epl-num')?.text.trim() ?? '';
      final title = el.querySelector('div.epl-title')?.text.trim() ?? '';
      final chapterName = '$num $title';

      final chapterPath = _shrinkURL(el.attributes['href'] ?? '');
      if (chapterPath.isNotEmpty && chapterName.isNotEmpty) {
        chapters.add(
          Chapter(
            id: chapterPath,
            title: chapterName,
            content: '',
            order: count,
          ),
        );
        count--;
      }
    }

    if (reverseChapters) {
      chapters = chapters.reversed.toList();
    }

    final novel = Novel(
      id: novelPath,
      title: img?.attributes['title'] ?? 'Sem título',
      coverImageUrl: img?.attributes['src'] ?? defaultCover,
      description: description,
      genres: genresElements.map((v) => v.text.trim()).toList(),
      chapters: chapters,
      artist: '',
      statusString: statusElement?.text.trim() ?? '',
      author: authorElement?.text.trim() ?? '',
      pluginId: name,
      status: status,
    );

    return novel;
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final body = await _fetchApi(_expandURL(chapterPath));
    if (body.isEmpty) {
      return 'Não foi possível carregar o conteúdo do capítulo.';
    }
    final document = parse(body);
    final contentElement = document.querySelector('div.epcontent');

    contentElement?.querySelectorAll('div').forEach((element) {
      if (element.text.trim().isEmpty) {
        element.remove();
      }
    });

    final chapterContent = contentElement?.innerHtml ?? '';
    return chapterContent;
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final String url =
        '$baseURL/page/$pageNo/?s=${Uri.encodeComponent(searchTerm)}';
    final body = await _fetchApi(url);
    if (body.isEmpty) {
      return [];
    }
    return await _parseList(body);
  }

  String createFilterUrl(
    Map<String, dynamic>? filters,
    bool showLatestNovels,
    int page,
  ) {
    String url = '$baseURL$seriesPath?page=$page';

    if (showLatestNovels) {
      url += '&order=latest';
    }

    if (filters != null) {
      filters.forEach((key, value) {
        if (value['value'] is String && (value['value'] as String).isNotEmpty) {
          url += '&$key=${value['value']}';
        } else if (value['value'] is List &&
            (value['value'] as List).isNotEmpty) {
          for (var v in (value['value'] as List)) {
            url += '&$key=$v';
          }
        }
      });
    }
    return url;
  }
}
