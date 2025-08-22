import 'package:flutter/src/widgets/framework.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';

class Tsundoku implements PluginService {
  @override
  String get name => 'Tsundoku';
  @override
  String get lang => 'pt-BR';
  @override
  String get siteUrl => site; // Implementando siteUrl
  @override
  Map<String, dynamic> get filters => {
    'order': {
      'label': 'Ordenar por',
      'value': '',
      'options': [
        {'label': 'Padrão', 'value': ''},
        {'label': 'A-Z', 'value': 'title'},
        {'label': 'Z-A', 'value': 'titlereverse'},
        {'label': 'Atualizar', 'value': 'update'},
        {'label': 'Adicionar', 'value': 'latest'},
        {'label': 'Popular', 'value': 'popular'},
      ],
      'type': 'Picker',
    },
    'genre': {
      'label': 'Gênero',
      'value': [],
      'options': [
        {'label': 'Ação', 'value': '328'},
        {'label': 'Adult', 'value': '343'},
        {'label': 'Anatomia', 'value': '408'},
        {'label': 'Artes Marciais', 'value': '340'},
        {'label': 'Aventura', 'value': '315'},
        {'label': 'Ciência', 'value': '398'},
        {'label': 'Comédia', 'value': '322'},
        {'label': 'Comédia Romântica', 'value': '378'},
        {'label': 'Cotidiano', 'value': '399'},
        {'label': 'Drama', 'value': '311'},
        {'label': 'Ecchi', 'value': '329'},
        {'label': 'Fantasia', 'value': '316'},
        {'label': 'Feminismo', 'value': '362'},
        {'label': 'Gender Bender', 'value': '417'},
        {'label': 'Guerra', 'value': '368'},
        {'label': 'Harém', 'value': '350'},
        {'label': 'Hentai', 'value': '344'},
        {'label': 'História', 'value': '400'},
        {'label': 'Histórico', 'value': '380'},
        {'label': 'Horror', 'value': '317'},
        {'label': 'Humor Negro', 'value': '363'},
        {'label': 'Isekai', 'value': '318'},
        {'label': 'Josei', 'value': '356'},
        {'label': 'Joshikousei', 'value': '364'},
        {'label': 'LitRPG', 'value': '387'},
        {'label': 'Maduro', 'value': '351'},
        {'label': 'Mágia', 'value': '372'},
        {'label': 'Mecha', 'value': '335'},
        {'label': 'Militar', 'value': '414'},
        {'label': 'Mistério', 'value': '319'},
        {'label': 'Otaku', 'value': '365'},
        {'label': 'Psicológico', 'value': '320'},
        {'label': 'Reencarnação', 'value': '358'},
        {'label': 'Romance', 'value': '312'},
        {'label': 'RPG', 'value': '366'},
        {'label': 'Sátira', 'value': '367'},
        {'label': 'Sci-fi', 'value': '371'},
        {'label': 'Seinen', 'value': '326'},
        {'label': 'Sexo Explícito', 'value': '345'},
        {'label': 'Shoujo', 'value': '323'},
        {'label': 'Shounen', 'value': '341'},
        {'label': 'Slice-of-Life', 'value': '324'},
        {'label': 'Sobrenatural', 'value': '359'},
        {'label': 'Supernatural', 'value': '401'},
        {'label': 'Suspense', 'value': '407'},
        {'label': 'Thriller', 'value': '410'},
        {'label': 'Tragédia', 'value': '352'},
        {'label': 'Vida Escolar', 'value': '331'},
        {'label': 'Webtoon', 'value': '381'},
        {'label': 'Xianxia', 'value': '357'},
        {'label': 'Xuanhuan', 'value': '395'},
        {'label': 'Yuri', 'value': '313'},
      ],
      'type': 'CheckboxGroup',
    },
  };

  final String id = 'tsundoku.com.br';
  final String nameService = 'Tsundoku Traduções';
  final String site = 'https://tsundoku.com.br';
  @override
  final String version = '1.0.7';
  static const String defaultCover =
      'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed';

  Future<String> _fetchApi(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Falha ao carregar dados de: $url');
    }
  }

  String parseDate(String date) {
    const monthMapping = {
      'janeiro': 1,
      'fevereiro': 2,
      'marco': 3,
      'abril': 4,
      'maio': 5,
      'junho': 6,
      'julho': 7,
      'agosto': 8,
      'setembro': 9,
      'outubro': 10,
      'novembro': 11,
      'dezembro': 12,
    };
    final parts = date.split(RegExp(r',?\s+'));
    final monthName = parts[0].replaceAll(RegExp(r'[\u0300-\u036f]'), '');
    final month = monthMapping[monthName.toLowerCase()]?.toString() ?? '1';
    final day = parts[1];
    final year = parts[2];
    return '$year-$month-$day';
  }

  List<Novel> _parseNovels(dom.Document document) {
    List<Novel> novels = [];
    final novelElements = document.querySelectorAll('.listupd .bsx');

    for (var element in novelElements) {
      final name = element.querySelector('.tt')?.text.trim() ?? '';
      final path =
          element
              .querySelector('a')
              ?.attributes['href']
              ?.replaceAll(site, '') ??
          '';
      final cover =
          element.querySelector('img')?.attributes['src'] ?? defaultCover;

      if (name.isNotEmpty && path.isNotEmpty) {
        novels.add(
          Novel(
            id: path,
            title: name,
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
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,  
      BuildContext? context,
  }) async {
    return _fetchNovels(pageNo, filters: filters);
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final body = await _fetchApi('$site$novelPath');
    final document = parse(body);

    final title = document.querySelector('h1.entry-title')?.text ?? 'Untitled';
    final cover =
        document.querySelector('.main-info .thumb img')?.attributes['src'] ??
        defaultCover;
    final summary =
        document
            .querySelector(
              '.entry-content.entry-content-single div:nth-child(1)',
            )
            ?.text
            .trim() ??
        '';

    final allTsInfo = document.querySelectorAll('.tsinfo .imptdt');
    String author = '';
    for (final element in allTsInfo) {
      if (element.text.contains('Autor')) {
        author = element.text.replaceFirst('Autor ', '').trim();
      }
    }

    final artist = '';

    String status = '';
    for (final element in allTsInfo) {
      if (element.text.contains('Status')) {
        status = element.text.replaceFirst('Status ', '').trim();
      }
    }

    final genres =
        document.querySelectorAll('.mgen a').map((e) => e.text).toList();

    Novel novel = Novel(
      id: novelPath,
      title: title,
      coverImageUrl: cover,
      description: summary,
      author: author,
      artist: artist,
      statusString: status,
      genres: genres,
      chapters: [],
      pluginId: name,
    );

    List<Chapter> chapters = [];
    final chapterElements = document.querySelectorAll('#chapterlist ul > li');
    int chapterNumber = 1;

    for (var element in chapterElements) {
      final chapterName =
          element.querySelector('.chapternum')?.text.trim() ?? '';
      final chapterPath =
          element
              .querySelector('a')
              ?.attributes['href']
              ?.replaceAll(site, '') ??
          '';
      final releaseDate = element.querySelector('.chapterdate')?.text ?? '';

      if (chapterName.isNotEmpty && chapterPath.isNotEmpty) {
        chapters.add(
          Chapter(
            id: chapterPath,
            title: chapterName,
            releaseDate: parseDate(releaseDate),
            chapterNumber: chapterNumber,
            content: '',
          ),
        );
        chapterNumber++;
      }
    }

    chapters = chapters.reversed.toList();
    for (int i = 0; i < chapters.length; i++) {
      chapters[i].title = '${chapters[i].title} - Ch. ${i + 1}';
      chapters[i].chapterNumber = i + 1;
    }

    novel.chapters = chapters;

    return novel;
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final body = await _fetchApi('$site$chapterPath');
    final document = parse(body);

    final chapterTitle =
        document.querySelector('.headpost .entry-title')?.text ?? '';
    final novelTitle = document.querySelector('.headpost a')?.text ?? '';
    final title =
        chapterTitle
            .replaceFirst(novelTitle, '')
            .replaceFirst(RegExp(r'^\W+'), '')
            .trim();

    final spoilerContent =
        document
            .querySelector('#readerarea .collapseomatic_content')
            ?.innerHtml;
    if (spoilerContent != null) {
      return '<h1>$title</h1>\n$spoilerContent';
    }

    final readerArea = document.querySelector('#readerarea');
    if (readerArea != null) {
      readerArea
          .querySelectorAll('img.wp-image-15656')
          .forEach((element) => element.remove());

      readerArea.querySelectorAll('p').forEach((element) {
        if (element.text.trim().isEmpty) {
          element.remove();
        }
      });

      readerArea.querySelectorAll('img').forEach((img) {
        img.attributes['style'] = 'max-width: 100%; height: auto;';
      });

      String chapterText = readerArea.innerHtml;
      List<String> parts = chapterText.split(RegExp(r'<hr ?\/?>'));
      if (parts.isNotEmpty) {
        String lastPart = parts.last;
        if (parts.length > 1 && lastPart.contains('https://discord')) {
          parts.removeLast();
        }
      }
      return '<h1>$title</h1>\n${parts.join('<hr />')}';
    }
    return '';
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    return _fetchNovels(pageNo, searchTerm: searchTerm, filters: filters);
  }

  @override
  Future<List<Novel>> getAllNovels({
    BuildContext? context,
    int pageNo = 1,
  }) async {
    return _fetchNovels(pageNo, searchTerm: '');
  }

  Future<List<Novel>> _fetchNovels(
    int pageNo, {
    String searchTerm = '',
    Map<String, dynamic>? filters,
  }) async {
    String url = '$site/manga/?type=novel';
    if (pageNo > 1) {
      url += '&page=$pageNo';
    }
    if (searchTerm.isNotEmpty) {
      url += '&s=$searchTerm';
    }

    if (filters != null) {
      if (filters['genre'] != null && filters['genre']['value'] is List) {
        for (var value in filters['genre']['value']) {
          url += '&genre[]=$value';
        }
      }
      if (filters['order'] != null && filters['order']['value'].isNotEmpty) {
        url += '&order=${filters['order']['value']}';
      }
    }

    final body = await _fetchApi(url);
    final document = parse(body);
    return _parseNovels(document);
  }
}
