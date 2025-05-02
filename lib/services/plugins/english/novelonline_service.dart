import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/material.dart';

class NovelsOnline implements PluginService {
  @override
  String get name => 'NovelsOnline';

  @override
  Map<String, dynamic> get filters => {
    'sort': {
      'value': 'top_rated',
      'label': 'Sort by',
      'options': [
        {'label': 'Top Rated', 'value': 'top_rated'},
        {'label': 'Most Viewed', 'value': 'view'},
      ],
      'type': 'Picker',
    },
    'genre': {
      'value': '',
      'label': 'Category',
      'options': [
        {'label': 'None', 'value': ''},
        {'label': 'Action', 'value': 'action'},
        {'label': 'Adventure', 'value': 'adventure'},
        {'label': 'Celebrity', 'value': 'celebrity'},
        {'label': 'Comedy', 'value': 'comedy'},
        {'label': 'Drama', 'value': 'drama'},
        {'label': 'Ecchi', 'value': 'ecchi'},
        {'label': 'Fantasy', 'value': 'fantasy'},
        {'label': 'Gender Bender', 'value': 'gender-bender'},
        {'label': 'Harem', 'value': 'harem'},
        {'label': 'Historical', 'value': 'historical'},
        {'label': 'Horror', 'value': 'horror'},
        {'label': 'Josei', 'value': 'josei'},
        {'label': 'Martial Arts', 'value': 'martial-arts'},
        {'label': 'Mature', 'value': 'mature'},
        {'label': 'Mecha', 'value': 'mecha'},
        {'label': 'Mystery', 'value': 'mystery'},
        {'label': 'Psychological', 'value': 'psychological'},
        {'label': 'Romance', 'value': 'romance'},
        {'label': 'School Life', 'value': 'school-life'},
        {'label': 'Sci-fi', 'value': 'sci-fi'},
        {'label': 'Seinen', 'value': 'seinen'},
        {'label': 'Shotacon', 'value': 'shotacon'},
        {'label': 'Shoujo', 'value': 'shoujo'},
        {'label': 'Shoujo Ai', 'value': 'shoujo-ai'},
        {'label': 'Shounen', 'value': 'shounen'},
        {'label': 'Shounen Ai', 'value': 'shounen-ai'},
        {'label': 'Slice of Life', 'value': 'slice-of-life'},
        {'label': 'Sports', 'value': 'sports'},
        {'label': 'Supernatural', 'value': 'supernatural'},
        {'label': 'Tragedy', 'value': 'tragedy'},
        {'label': 'Wuxia', 'value': 'wuxia'},
        {'label': 'Xianxia', 'value': 'xianxia'},
        {'label': 'Xuanhuan', 'value': 'xuanhuan'},
        {'label': 'Yaoi', 'value': 'yaoi'},
        {'label': 'Yuri', 'value': 'yuri'},
      ],
      'type': 'Picker',
    },
  };

  final String id = 'NovelsOnline';
  final String nameService = 'NovelsOnline';
  final String site = 'https://novelsonline.org';
  final String icon = 'src/en/novelsonline/icon.png';
  final String version = '1.0.0';

  Future<http.Response> safeFetch(
    String url, {
    BuildContext? context,
    required Map<String, String> headers,
  }) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 || response.statusCode == 404) {
        return response;
      } else if (response.statusCode == 403 && context != null) {
        return safeFetch(url, context: context, headers: {});
      } else {
        throw Exception(
          'Could not reach site (${response.statusCode}) try to open in webview.',
        );
      }
    } catch (e) {
      print('Erro no safeFetch: $e');
      rethrow;
    }
  }

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    String url = site;
    if (filters?['genre']?['value'] != null &&
        filters?['genre']?['value'].isNotEmpty) {
      url += '/category/${filters!['genre']!['value']}/';
    } else {
      url += '/top-novel/';
    }
    url += '$page';
    url += '?change_type=${filters?['sort']?['value']}';

    try {
      final data = await safeFetch(
        url,
        context: context,
        headers: {},
      ).then((res) => res.body);
      final dom.Document $ = parser.parse(data);
      List<Novel> novels = [];
      $.querySelectorAll(".top-novel-block").forEach((e) {
        final name = e.querySelector("h2")?.text ?? '';
        final cover =
            e.querySelector(".top-novel-cover img")?.attributes['src'] ?? '';
        final path = e.querySelector("h2 a")?.attributes['href'] ?? '';
        if (path.isNotEmpty) {
          final novel = Novel(
            pluginId: name,
            id: path.replaceAll(site, ''),
            title: name,
            coverImageUrl: cover,
            author: '',
            description: '',
            genres: [],
            chapters: [],
            artist: '',
            statusString: '',
          );
          novels.add(novel);
        }
      });
      return novels;
    } catch (e) {
      print('Erro ao carregar popular novels: $e');
      return [];
    }
  }

  @override
  Future<Novel> parseNovel(String novelPath, {BuildContext? context}) async {
    final url = '$site$novelPath';
    try {
      final data = await safeFetch(
        url,
        context: context,
        headers: {},
      ).then((res) => res.body);
      final dom.Document $ = parser.parse(data);

      final novel = Novel(
        pluginId: name,
        id: novelPath,
        title: $.querySelector('h1')?.text ?? 'Untitled',
        coverImageUrl:
            $
                .querySelector('.novel-cover')
                ?.querySelector('a > img')
                ?.attributes['src'] ??
            'https://placehold.co/400x450.png?text=Sem%20Capa',
        description: '',
        chapters: [],
        author: '',
        genres: [],
        artist: '',
        statusString: '',
      );

      $.querySelectorAll('.novel-detail-item').forEach((e) {
        final a = e.querySelector('h6')?.text;
        final n = e.querySelector('.novel-detail-body');
        switch (a) {
          case 'Description':
            novel.description = n?.text ?? '';
            break;
          case 'Genre':
            novel.genres =
                n?.querySelectorAll('li').map((e) => e.text).toList() ?? [];
            break;
          case 'Author(s)':
            novel.author =
                n?.querySelectorAll('li').map((e) => e.text).join(', ') ?? '';
            break;
        }
      });

      int chapterNumber = 1;
      novel.chapters =
          $.querySelectorAll('ul.chapter-chs > li > a').map((e) {
            final a = e.attributes['href'];
            final chapter = Chapter(
              id: a?.replaceAll(site, '') ?? '',
              title: e.text,
              content: '',
              chapterNumber: chapterNumber,
            );
            chapterNumber++;
            return chapter;
          }).toList();

      return novel;
    } catch (e) {
      print('Erro ao carregar detalhes da novel: $e');
      rethrow;
    }
  }

  @override
  Future<String> parseChapter(
    String chapterPath, {
    BuildContext? context,
  }) async {
    final url = '$site$chapterPath';
    try {
      final data = await safeFetch(
        url,
        context: context,
        headers: {},
      ).then((res) => res.body);
      final dom.Document $ = parser.parse(data);
      return $.querySelector('#contentall')?.innerHtml ?? '';
    } catch (e) {
      print('Erro ao carregar capítulo: $e');
      return 'Erro ao carregar capítulo';
    }
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    final url = '$site/sResults.php';
    final searchUrl = '$url?story=${searchTerm.replaceAll(' ', '+')}';
    try {
      final response = await safeFetch(
        searchUrl,
        context: context,
        headers: {
          'Accept': '*/*',
          'Accept-Language': 'pl,en-US;q=0.7,en;q=0.3',
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        },
      ).then((res) => res.body);
      final dom.Document $ = parser.parse(response);
      List<Novel> novels = [];
      $.querySelectorAll("li").forEach((e) {
        final a = e.text;
        final n = e.querySelector("a")?.attributes['href'];
        final r = e.querySelector("img")?.attributes['src'];
        if (n != null) {
          final novel = Novel(
            pluginId: name,
            id: n.replaceAll(site, ''),
            title: a,
            coverImageUrl: r ?? '',
            author: '',
            description: '',
            genres: [],
            chapters: [],
            artist: '',
            statusString: '',
          );
          novels.add(novel);
        }
      });
      return novels;
    } catch (e) {
      print('Erro ao pesquisar novels: $e');
      return [];
    }
  }

  @override
  Future<List<Novel>> getAllNovels({BuildContext? context}) async {
    List<Novel> allNovels = [];
    for (String letter in [
      '#',
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
    ]) {
      try {
        final novels = await _getNovelsByLetter(letter, context: context);
        allNovels.addAll(novels);
      } catch (e) {
        print('Erro ao carregar novels da letra $letter: $e');
      }
    }
    return allNovels;
  }

  Future<List<Novel>> _getNovelsByLetter(
    String letter, {
    BuildContext? context,
  }) async {
    final url = '$site/novel-list?l=$letter';
    try {
      final data = await safeFetch(
        url,
        context: context,
        headers: {},
      ).then((res) => res.body);
      final dom.Document $ = parser.parse(data);
      List<Novel> novels = [];
      for (final e in $.querySelectorAll('.list-by-word-body > ul > li > a')) {
        final name = e.text;
        final path = e.attributes['href'] ?? '';
        String coverImageUrl = '';

        final popoverId =
            e.attributes['data-toggle'] == 'popover'
                ? e.attributes['data-wrapper']
                : null;

        if (popoverId != null) {
          final coverSelector =
              '$popoverId > div.popover-content > div > div.pop-container > div.pop-body > div.pop-cover > img';
          try {
            coverImageUrl =
                $.querySelector(coverSelector)?.attributes['src'] ?? '';
          } catch (e) {
            print('Erro ao obter a URL da capa: $e');
          }
        }

        if (path.isNotEmpty) {
          final novel = Novel(
            pluginId: this.name,
            id: path.replaceAll(site, ''),
            title: name,
            coverImageUrl: coverImageUrl,
            author: '',
            description: '',
            genres: [],
            chapters: [],
            artist: '',
            statusString: '',
          );
          novels.add(novel);
        }
      }
      return novels;
    } catch (e) {
      print('Erro ao carregar novels da letra $letter: $e');
      return [];
    }
  }
}
