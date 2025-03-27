import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:akashic_records/models/novel.dart';
import 'package:akashic_records/models/chapter.dart';

import 'package:akashic_records/models/novel_status.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class CentralNovel {
  final String id = 'CentralNovel';
  final String name = 'Central Novel';
  final String baseURL = 'https://centralnovel.com';
  final String imageURL =
      'https://centralnovel.com/wp-content/uploads/2021/06/CENTRAL-NOVEL-LOGO-DARK-.png';
  final String version = '1.0.1';

  static const String defaultCover =
      'https://via.placeholder.com/150x200?text=No+Cover';

  CentralNovel() {
    HttpOverrides.global = MyHttpOverrides();
  }

  Future<String> _fetchApi(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Falha ao carregar dados de: $url');
    }
  }

  String _shrinkURL(String url) {
    return url.replaceAll(RegExp(r'^.+centralnovel\.com'), '');
  }

  String _expandURL(String path) {
    return baseURL + path;
  }

  Future<List<Novel>> _parseList(String url) async {
    final body = await _fetchApi(url);
    final document = parse(body);
    final novelElements = document.querySelectorAll(
      'div.listupd div.mdthumb a.tip',
    );

    List<Novel> novels = [];
    for (var element in novelElements) {
      final imgElement = element.querySelector('img');
      final title = imgElement?.attributes['title'] ?? '';
      final cover =
          imgElement?.attributes['src']?.replaceAll(
            RegExp(r'e=\d+,\d+'),
            'e=370,500',
          ) ??
          defaultCover;
      final link = _shrinkURL(element.attributes['href'] ?? '');

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
          ),
        );
      }
    }
    return novels;
  }

  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    String url = createFilterUrl(filters, "popular", pageNo);
    return await _parseList(url);
  }

  Future<List<Novel>> recentNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    String url = createFilterUrl(filters, "update", pageNo);
    return await _parseList(url);
  }

  Future<Novel> parseNovel(String novelPath) async {
    final body = await _fetchApi(_expandURL(novelPath));
    final document = parse(body);

    final img = document.querySelector('div.thumb > img');
    final info = document.querySelector('div.ninfo > div.info-content');

    final novel = Novel(
      id: novelPath,
      title: img?.attributes['title'] ?? 'Sem título',
      coverImageUrl: img?.attributes['src'] ?? defaultCover,
      description:
          document.querySelector('div.entry-content')?.text.trim() ?? '',
      genres:
          info
              ?.querySelectorAll('div.genxed > a')
              .map((v) => v.text.trim())
              .toList() ??
          [],
      chapters: [],
      artist: '',
      statusString: '',
      author: '',
    );
    final statusElement = document.querySelector('div.spe > span');
    final statusString = statusElement?.text.replaceAll('Status:', '').trim();

    switch (statusString) {
      case 'Em andamento':
        novel.status = NovelStatus.Ongoing;
        break;
      case 'Completo':
        novel.status = NovelStatus.Completed;
        break;
      case 'Hiato':
        novel.status = NovelStatus.OnHiatus;
        break;
      default:
        novel.status = NovelStatus.Unknown;
    }

    final chapterElements = document.querySelectorAll('div.eplister li > a');
    int count = chapterElements.length;
    for (var el in chapterElements) {
      final num = el.querySelector('div.epl-num')?.text.trim() ?? '';
      final title = el.querySelector('div.epl-title')?.text.trim() ?? '';
      final chapterName = '$num $title';

      final chapterPath = _shrinkURL(el.attributes['href'] ?? '');
      if (chapterPath.isNotEmpty && chapterName.isNotEmpty) {
        novel.chapters.add(
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

    return novel;
  }

  Future<String> parseChapter(String chapterPath) async {
    final body = await _fetchApi(_expandURL(chapterPath));
    final document = parse(body);
    final title =
        document.querySelector('div.epheader > div.cat-series')?.text.trim() ??
        '';
    final text = document.querySelector('div.epcontent');

    text?.querySelectorAll('p').forEach((element) {
      if (element.text.trim().isEmpty) {
        element.remove();
      }
    });
    text?.querySelectorAll('img').forEach((img) {
      img.attributes['style'] = 'max-width: 100%; height: auto;';
    });

    final chapterContent = '<h1>$title</h1>${text?.innerHtml ?? ''}';
    return chapterContent;
  }

  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    filters ??= {};
    filters['query'] = searchTerm;
    String url = createFilterUrl(filters, "", pageNo);
    return await _parseList(url);
  }

  String createFilterUrl(
    Map<String, dynamic>? filters,
    String order,
    int page,
  ) {
    final query = {'page': page.toString()};

    if (filters?['query'] != null) {
      query['s'] = filters!['query'];
    }

    if (order.isNotEmpty) {
      query['order'] = order;
    }

    final genres = <String>[];
    final types = <String>[];

    if (filters != null) {
      for (final key in filters.keys) {
        final value = filters[key]?['value'];

        if (value != null && value is String && value.isNotEmpty) {
          if (key == 'order') {
            query['order'] = getOrderByValue(value);
          } else if (key == 'status') {
            query['status'] = getStatusValue(value);
          }
        } else if (value != null && value is List) {
          if (key == "genres") {
            for (final genreValue in value) {
              if (genreValue is String && genreValue.isNotEmpty) {
                genres.add(getGenreValue(genreValue));
              }
            }
          } else if (key == "types") {
            for (final typeValue in value) {
              if (typeValue is String && typeValue.isNotEmpty) {
                types.add(getTypeValue(typeValue));
              }
            }
          }
        }
      }

      if (genres.isNotEmpty) {
        query['genre[]'] = genres.join(',');
      }
      if (types.isNotEmpty) {
        query['type[]'] = types.join(',');
      }
    }
    final uri = Uri(
      scheme: 'https',
      host: 'centralnovel.com',
      path: '/series/',
      queryParameters: query,
    );

    return uri.toString();
  }

  String getOrderByValue(String key) {
    const filterOrderbyValues = {
      'default': '',
      'a-z': 'title',
      'z-a': 'titlereverse',
      'latest-update': 'update',
      'latest-added': 'latest',
      'popular': 'popular',
    };
    return filterOrderbyValues[key] ?? '';
  }

  String getStatusValue(String key) {
    const filterStatusValues = {
      'all': '',
      'ongoing': 'em andamento',
      'on-hiatus': 'hiato',
      'completed': 'completo',
    };
    return filterStatusValues[key] ?? '';
  }

  String getGenreValue(String key) {
    const filterGenresValues = {
      'acao': 'acao',
      'adulto': 'adulto',
      'adventure': 'adventure',
      'artes-marciais': 'artes-marciais',
      'aventura': 'aventura',
      'comedia': 'comedia',
      'comedy': 'comedy',
      'cotidiano': 'cotidiano',
      'cultivo': 'cultivo',
      'drama': 'drama',
      'ecchi': 'ecchi',
      'escolar': 'escolar',
      'esportes': 'esportes',
      'fantasia': 'fantasia',
      'ficcao-cientifica': 'ficcao-cientifica',
      'harem': 'harem',
      'isekai': 'isekai',
      'magia': 'magia',
      'mecha': 'mecha',
      'medieval': 'medieval',
      'misterio': 'misterio',
      'mitologia': 'mitologia',
      'monstros': 'monstros',
      'pet': 'pet',
      'protagonista-feminina': 'protagonista-feminina',
      'protagonista-maligno': 'protagonista-maligno',
      'psicologico': 'psicologico',
      'reencarnacao': 'reencarnacao',
      'romance': 'romance',
      'seinen': 'seinen',
      'shounen': 'shounen',
      'sistema': 'sistema',
      'sistema-de-jogo': 'sistema-de-jogo',
      'slice-of-life': 'slice-of-life',
      'sobrenatural': 'sobrenatural',
      'supernatural': 'supernatural',
      'tragedia': 'tragedia',
      'vida-escolar': 'vida-escolar',
      'vrmmo': 'vrmmo',
      'xianxia': 'xianxia',
      'xuanhuan': 'xuanhuan',
    };
    return filterGenresValues[key] ?? key;
  }

  String getTypeValue(String key) {
    const filterTypesValues = {
      'light-novel': 'light-novel',
      'novel-chinesa': 'novel-chinesa',
      'novel-coreana': 'novel-coreana',
      'novel-japonesa': 'novel-japonesa',
      'novel-ocidental': 'novel-ocidental',
      'webnovel': 'webnovel',
    };
    return filterTypesValues[key] ?? key;
  }

  Map<String, dynamic> get filters => {
    'order': {
      'label': 'Ordenar por',
      'value': 'default',
      'options': [
        {'label': 'Padrão', 'value': 'default'},
        {'label': 'A-Z', 'value': 'a-z'},
        {'label': 'Z-A', 'value': 'z-a'},
        {'label': 'Últ. Att', 'value': 'latest-update'},
        {'label': 'Últ. Add', 'value': 'latest-added'},
        {'label': 'Populares', 'value': 'popular'},
      ],
    },
    'status': {
      'label': 'Status',
      'value': 'all',
      'options': [
        {'label': 'Todos', 'value': 'all'},
        {'label': 'Em andamento', 'value': 'ongoing'},
        {'label': 'Hiato', 'value': 'on-hiatus'},
        {'label': 'Completo', 'value': 'completed'},
      ],
    },
    'types': {
      'label': 'Tipos',
      'value': [],
      'options': [
        {'label': 'Light Novel', 'value': 'light-novel'},
        {'label': 'Novel Chinesa', 'value': 'novel-chinesa'},
        {'label': 'Novel Coreana', 'value': 'novel-coreana'},
        {'label': 'Novel Japonesa', 'value': 'novel-japonesa'},
        {'label': 'Novel Ocidental', 'value': 'novel-ocidental'},
        {'label': 'Webnovel', 'value': 'webnovel'},
      ],
    },
    'genres': {
      'label': 'Gêneros',
      'value': [],
      'options': [
        {'label': 'Ação', 'value': 'acao'},
        {'label': 'Adulto', 'value': 'adulto'},
        {'label': 'Adventure', 'value': 'adventure'},
        {'label': 'Artes Marciais', 'value': 'artes-marciais'},
        {'label': 'Aventura', 'value': 'aventura'},
        {'label': 'Comédia', 'value': 'comedia'},
        {'label': 'Comedy', 'value': 'comedy'},
        {'label': 'Cotidiano', 'value': 'cotidiano'},
        {'label': 'Cultivo', 'value': 'cultivo'},
        {'label': 'Drama', 'value': 'drama'},
        {'label': 'Ecchi', 'value': 'ecchi'},
        {'label': 'Escolar', 'value': 'escolar'},
        {'label': 'Esportes', 'value': 'esportes'},
        {'label': 'Fantasia', 'value': 'fantasia'},
        {'label': 'Ficção Científica', 'value': 'ficcao-cientifica'},
        {'label': 'Harém', 'value': 'harem'},
        {'label': 'Isekai', 'value': 'isekai'},
        {'label': 'Magia', 'value': 'magia'},
        {'label': 'Mecha', 'value': 'mecha'},
        {'label': 'Medieval', 'value': 'medieval'},
        {'label': 'Mistério', 'value': 'misterio'},
        {'label': 'Mitologia', 'value': 'mitologia'},
        {'label': 'Monstros', 'value': 'monstros'},
        {'label': 'Pet', 'value': 'pet'},
        {'label': 'Protagonista Feminina', 'value': 'protagonista-feminina'},
        {'label': 'Protagonista Maligno', 'value': 'protagonista-maligno'},
        {'label': 'Psicológico', 'value': 'psicologico'},
        {'label': 'Reencarnação', 'value': 'reencarnacao'},
        {'label': 'Romance', 'value': 'romance'},
        {'label': 'Seinen', 'value': 'seinen'},
        {'label': 'Shounen', 'value': 'shounen'},
        {'label': 'Sistema', 'value': 'sistema'},
        {'label': 'Sistema de Jogo', 'value': 'sistema-de-jogo'},
        {'label': 'Slice of Life', 'value': 'slice-of-life'},
        {'label': 'Sobrenatural', 'value': 'sobrenatural'},
        {'label': 'Supernatural', 'value': 'supernatural'},
        {'label': 'Tragédia', 'value': 'tragedia'},
        {'label': 'Vida Escolar', 'value': 'vida-escolar'},
        {'label': 'VRMMO', 'value': 'vrmmo'},
        {'label': 'Xianxia', 'value': 'xianxia'},
        {'label': 'Xuanhuan', 'value': 'xuanhuan'},
      ],
    },
  };
}
