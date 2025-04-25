import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class BoxNovel implements PluginService {
  @override
  String get name => 'BoxNovel';

  @override
  Map<String, dynamic> get filters => {
    "genre[]": {
      "type": "Checkbox",
      "label": "Genre",
      "value": [],
      "options": [
        {"label": "Action", "value": "action"},
        {"label": "Adventure", "value": "adventure"},
        {"label": "Comedy", "value": "comedy"},
        {"label": "Drama", "value": "drama"},
        {"label": "Eastern", "value": "eastern"},
        {"label": "Ecchi", "value": "ecchi"},
        {"label": "Fantasy", "value": "fantasy"},
        {"label": "Gender Bender", "value": "gender-bender"},
        {"label": "Harem", "value": "harem"},
        {"label": "Historical", "value": "historical"},
        {"label": "Horror", "value": "horror"},
        {"label": "Josei", "value": "josei"},
        {"label": "Martial Arts", "value": "martial-arts"},
        {"label": "Mature", "value": "mature"},
        {"label": "Mecha", "value": "mecha"},
        {"label": "Mystery", "value": "mystery"},
        {"label": "Psychological", "value": "psychological"},
        {"label": "Romance", "value": "romance"},
        {"label": "School Life", "value": "school-life"},
        {"label": "Sci-fi", "value": "sci-fi"},
        {"label": "Seinen", "value": "seinen"},
        {"label": "Shoujo", "value": "shoujo"},
        {"label": "Shounen", "value": "shounen"},
        {"label": "Slice of Life", "value": "slice-of-life"},
        {"label": "Smut", "value": "smut"},
        {"label": "Sports", "value": "sports"},
        {"label": "Supernatural", "value": "supernatural"},
        {"label": "Tragedy", "value": "tragedy"},
        {"label": "Wuxia", "value": "wuxia"},
        {"label": "Xianxia", "value": "xianxia"},
        {"label": "Xuanhuan", "value": "xuanhuan"},
        {"label": "Yaoi", "value": "yaoi"},
      ],
    },
    "op": {
      "type": "Switch",
      "label": "having all selected genres",
      "value": false,
    },
    "author": {"type": "Text", "label": "Author", "value": ""},
    "artist": {"type": "Text", "label": "Artist", "value": ""},
    "release": {"type": "Text", "label": "Year of Released", "value": ""},
    "adult": {
      "type": "Picker",
      "label": "Adult content",
      "value": "",
      "options": [
        {"label": "All", "value": ""},
        {"label": "None adult content", "value": "0"},
        {"label": "Only adult content", "value": "1"},
      ],
    },
    "status[]": {
      "type": "Checkbox",
      "label": "Status",
      "value": [],
      "options": [
        {"label": "OnGoing", "value": "on-going"},
        {"label": "Completa", "value": "end"},
        {"label": "Canceled", "value": "canceled"},
        {"label": "On Hold", "value": "on-hold"},
        {"label": "Upcoming", "value": "upcoming"},
      ],
    },
    "m_orderby": {
      "type": "Picker",
      "label": "Order by",
      "value": "",
      "options": [
        {"label": "Relevance", "value": ""},
        {"label": "Latest", "value": "latest"},
        {"label": "A-Z", "value": "alphabet"},
        {"label": "Rating", "value": "rating"},
        {"label": "Trending", "value": "trending"},
        {"label": "Most Views", "value": "views"},
        {"label": "New", "value": "new-manga"},
      ],
    },
  };

  final String id = 'BoxNovel';
  final String nameService = 'BoxNovel';
  final String site = 'https://novgo.co/';
  final String version = '1.0.13';
  final String icon = 'src/en/webnovel/icon.png';
  final Map<String, String> headers = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    'Referer': 'https://novgo.co/',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  CookieJar? cookieJar;

  BoxNovel() {
    _initCookieJar();
  }

  Future<void> _initCookieJar() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    cookieJar = PersistCookieJar(storage: FileStorage("$appDocPath/.cookies/"));
  }

  Future<http.Response> safeFetch(
    String url, {
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = {...this.headers};
    mergedHeaders['User-Agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    if (headers != null) {
      mergedHeaders.addAll(headers);
    }
    final uri = Uri.parse(url);

    final request = http.Request('GET', uri);
    mergedHeaders.forEach((key, value) {
      request.headers[key] = value;
    });

    if (cookieJar != null) {
      final cookies = await cookieJar!.loadForRequest(uri);
      request.headers['Cookie'] = cookies
          .map((c) => '${c.name}=${c.value}')
          .join('; ');
    }

    final streamedResponse = await http.Client().send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      if (cookieJar != null) {
        await cookieJar!.saveFromResponse(
          uri,
          response.headers['set-cookie']
                  ?.split(',')
                  .map((s) => Cookie.fromSetCookieValue(s))
                  .toList() ??
              [],
        );
      }
      return response;
    } else {
      throw Exception(
        'Could not reach site (${response.statusCode}) try to open in webview.',
      );
    }
  }

  List<Novel> parseNovels(dom.Document e) {
    List<Novel> novels = [];
    e.querySelectorAll(".page-item-detail, .c-tabs-item__content").forEach((r) {
      final name = r.querySelector(".post-title")?.text.trim() ?? '';
      final o =
          r
              .querySelector(".post-title")
              ?.querySelector("a")
              ?.attributes['href'] ??
          '';
      if (name.isNotEmpty && o.isNotEmpty) {
        final l = r.querySelector("img");
        final novel = Novel(
          pluginId: nameService,
          id: o.replaceAll(RegExp(r'https?:\/\/.*?\//'), "/"),
          title: name,
          coverImageUrl:
              l?.attributes['data-src'] ??
              l?.attributes['src'] ??
              l?.attributes['data-lazy-srcset'] ??
              'https://placehold.co/400x450.png?text=Sem%20Capa',
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
  }

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    Map<String, dynamic>? filters,
    bool showLatestNovels = false,
  }) async {
    String url = '$site/page/$page/?s=&post_type=wp-manga';

    if (filters != null) {
      filters.forEach((key, value) {
        if (key == 'genre[]') {
          if (value is List) {
            for (var v in value) {
              url += '&$key=$v';
            }
          }
        } else if (key == 'op' && value == true) {
          url += '&$key=1';
        } else if (value is String && value.isNotEmpty) {
          url += '&$key=$value';
        }
      });
    }

    if (showLatestNovels == true) {
      url += '&m_orderby=latest';
    }

    try {
      final data = await safeFetch(url).then((res) => res.body);
      final dom.Document $ = parser.parse(data);
      return parseNovels($);
    } catch (e) {
      print('Erro ao carregar popular novels: $e');
      return [];
    }
  }

  Future<List<Chapter>> parseChapters(String novelPath) async {
    final url = '$site${novelPath}ajax/chapters/';
    try {
      final data = await safeFetch(url).then((res) => res.body);
      final dom.Document $ = parser.parse(data);

      List<Chapter> chapters = [];
      int chapterNumber = 1;

      $.querySelectorAll('.wp-manga-chapter a').forEach((a) {
        final chapterName = a.text.trim();
        final chapterPath = a.attributes['href'];
        if (chapterPath != null) {
          chapters.add(
            Chapter(
              id: chapterPath.replaceAll(RegExp(r'https?:\/\/.*?\//'), "/"),
              title: chapterName,
              content: '',
              chapterNumber: chapterNumber,
            ),
          );
          chapterNumber++;
        }
      });

      return chapters.reversed.toList();
    } catch (e) {
      print('Erro ao carregar capítulos: $e');
      return [];
    }
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final url = '$site$novelPath';
    try {
      final data = await safeFetch(url).then((res) => res.body);
      final dom.Document $ = parser.parse(data);

      final novel = Novel(
        pluginId: nameService,
        id: novelPath,
        title:
            $.querySelector('.post-title h1')?.text.trim() ??
            $.querySelector('#manga-title h1')?.text.trim() ??
            'Untitled',
        coverImageUrl:
            $
                .querySelector('.summary_image > a > img')
                ?.attributes['data-lazy-src'] ??
            $.querySelector('.summary_image > a > img')?.attributes['src'] ??
            'https://placehold.co/400x450.png?text=Sem%20Capa',
        description:
            $.querySelector('div.summary__content > p')?.text.trim() ?? '',
        chapters: [],
        author: $.querySelector('.manga-authors')?.text.trim() ?? '',
        genres: [],
        artist: '',
        statusString: '',
      );

      $.querySelectorAll('.post-content_item, .post-content').forEach((item) {
        final title = item.querySelector('h5')?.text.trim();
        final content = item.querySelector('.summary-content')?.text.trim();
        switch (title) {
          case 'Genre(s)':
          case 'Genre':
          case 'Tags(s)':
          case 'Tag(s)':
          case 'Tags':
          case 'Género(s)':
            novel.genres = item
                .querySelectorAll('a')
                .map((a) => a.text.trim())
                .join(', ');
            break;
          case 'Author(s)':
          case 'Author':
          case 'Autor(es)':
            novel.author = content ?? '';
            break;
          case 'Status':
          case 'Novel':
            break;
        }
      });

      List<Chapter> chapters = await parseChapters(novelPath);
      novel.chapters = chapters;
      return novel;
    } catch (e) {
      print('Erro ao carregar detalhes da novel: $e');
      rethrow;
    }
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    try {
      final url = '$site$chapterPath';
      final data = await safeFetch(url).then((res) => res.body);
      final dom.Document $ = parser.parse(data);

      $.querySelectorAll('div:has(a)').forEach((e) => e.remove());

      return $.querySelector('.text-left')?.innerHtml ??
          $.querySelector('.text-right')?.innerHtml ??
          $.querySelector('.entry-content')?.innerHtml ??
          $.querySelector('.c-blog-post > div > div:nth-child(2)')?.innerHtml ??
          '';
    } catch (e) {
      print('Erro ao carregar capítulo: $e');
      return 'Erro ao carregar capítulo';
    }
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int page, {
    Map<String, dynamic>? filters,
  }) async {
    final encodedSearchTerm = Uri.encodeComponent(searchTerm);
    final url = '$site/page/$page/?s=$encodedSearchTerm&post_type=wp-manga';

    try {
      final data = await safeFetch(url).then((res) => res.body);
      final dom.Document $ = parser.parse(data);

      return parseNovels($);
    } catch (e) {
      print('Erro ao pesquisar novels: $e');
      return [];
    }
  }
}
