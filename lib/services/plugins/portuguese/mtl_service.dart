import 'package:flutter/src/widgets/framework.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'dart:convert';

class MtlNovelPt implements PluginService {
  @override
  String get name => 'MtlNovelPt';
  @override
  String get lang =>  'pt-BR';
  @override
  Map<String, dynamic> get filters => {
    'order': {
      'value': 'view',
      'label': 'Order by',
      'options': [
        {'label': 'Date', 'value': 'date'},
        {'label': 'Name', 'value': 'name'},
        {'label': 'Rating', 'value': 'rating'},
        {'label': 'View', 'value': 'view'},
      ],
      'type': 'Picker',
    },
    'sort': {
      'value': 'desc',
      'label': 'Sort by',
      'options': [
        {'label': 'Descending', 'value': 'desc'},
        {'label': 'Ascending', 'value': 'asc'},
      ],
      'type': 'Picker',
    },
    'storyStatus': {
      'value': 'all',
      'label': 'Status',
      'options': [
        {'label': 'All', 'value': 'all'},
        {'label': 'Andamento', 'value': 'ongoing'},
        {'label': 'Complete', 'value': 'completed'},
      ],
      'type': 'Picker',
    },
  };

  final String id = 'MtlNovelPt';
  final String nameService = 'MtlNovelPt';
  final String site = 'https://pt.mtlnovels.com/';
  final String mainUrl = 'https://www.mtlnovels.com/';
  @override
  final String version = '1.1.3';

  Future<http.Response> safeFetch(
    String url, {
    Map<String, String>? headers,
  }) async {
    final defaultHeaders = {'Alt-Used': 'www.mtlnovels.com'};
    final mergedHeaders = {...defaultHeaders, ...?headers};

    final response = await http.get(Uri.parse(url), headers: mergedHeaders);
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception(
        'Could not reach site (${response.statusCode}) try to open in webview.',
      );
    }
  }

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    Map<String, dynamic>? filters,
  }) async {
    String url = '${site}novel-list/?';
    if (filters != null) {
      url += 'orderby=${filters['order']?['value']}';
      url += '&order=${filters['sort']?['value']}';
      url += '&status=${filters['storyStatus']?['value']}';
    }
    url += '&pg=$page';

    final data = await safeFetch(url).then((res) => res.body);
    final dom.Document $ = parser.parse(data);
    final List<Novel> novels = [];

    $.querySelectorAll('div.box.wide').forEach((el) {
      final name = el.querySelector('a.list-title')?.text.trim() ?? '';
      String cover = el.querySelector('amp-img')?.attributes['src'] ?? '';
      if (cover.isNotEmpty &&
          cover == 'https://www.mtlnovel.net/no-image.jpg.webp') {
        cover = 'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed';
      }
      final path = el.querySelector('a.list-title')?.attributes['href'];
      if (path != null) {
        final novel = Novel(
          pluginId: nameService,
          id: path.replaceAll(mainUrl, '').replaceAll(site, ''),
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
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final headers = {'Referer': '${site}novel-list/'};
    final data = await safeFetch(
      site + novelPath,
      headers: headers,
    ).then((res) => res.body);
    final dom.Document $ = parser.parse(data);

    final novel = Novel(
      pluginId: nameService,
      id: novelPath,
      title: $.querySelector('h1.entry-title')?.text.trim() ?? 'Untitled',
      coverImageUrl:
          $.querySelector('.nov-head > amp-img')?.attributes['src'] ??
          'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed',
      description:
          $.querySelector('div.desc > h2')?.nextElementSibling?.text.trim() ??
          '',
      chapters: [],
      author: '',
      genres: [],
      artist: '',
      statusString: '',
    );

    $.querySelectorAll('tr').forEach((el) {
      final label = el.querySelector('td')?.text.trim();
      final value = el.querySelector('td:nth-child(3)')?.text.trim();
      switch (label) {
        case 'Genre':
        case 'Tags':
        case 'Mots Clés':
        case 'Género':
        case 'Label':
        case 'Gênero':
        case 'Tag':
        case 'Теги':
          novel.genres =
              novel.genres != null ? '${novel.genres}, $value' : value;
          break;
        case 'Author':
        case 'Auteur':
        case 'Autor(a)':
        case 'Autor':
        case 'Автор':
          novel.author = value ?? '';
          break;
        case 'Status':
        case 'Statut':
        case 'Estado':
        case 'Положение дел':
          if (value == 'Hiatus') {
            novel.status = NovelStatus.Pausada;
          }
          break;
      }
    });

    final chapterListUrl = '$site${novelPath}chapter-list/';
    Future<List<Chapter>> getChapters() async {
      final data = await safeFetch(
        chapterListUrl,
        headers: headers,
      ).then((res) => res.body);
      final dom.Document $ = parser.parse(data);
      final List<Chapter> chapters = [];
      int chapterNumber = 1;

      $.querySelectorAll('a.ch-link').forEach((el) {
        final name = el.text.replaceFirst('~ ', '');
        final path = el.attributes['href'];
        if (path != null) {
          chapters.add(
            Chapter(
              id: path.replaceAll(mainUrl, '').replaceAll(site, ''),
              title: name,
              content: '',
              chapterNumber: chapterNumber,
            ),
          );
          chapterNumber++;
        }
      });
      return chapters.reversed.toList();
    }

    novel.chapters = await getChapters();
    if (novel.genres != null) {
      List<String> genresArray = novel.genres.split(', ');
      genresArray.removeLast();
      novel.genres = genresArray.join(', ');
    }

    return novel;
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final data = await safeFetch(site + chapterPath).then((res) => res.body);
    final dom.Document $ = parser.parse(data);
    return $.querySelector('div.par')?.innerHtml ?? '';
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int page, {
    Map<String, dynamic>? filters,
  }) async {
    final encodedSearchTerm = Uri.encodeComponent(searchTerm);
    final url =
        '${site}wp-admin/admin-ajax.php?action=autosuggest&q=$encodedSearchTerm';

    if (page != 1) {
      return Future.value(<Novel>[]);
    }

    try {
      final data = await safeFetch(url).then((res) => res.body);
      final Map<String, dynamic> jsonResponse = json.decode(data);
      final List<Novel> novels = [];

      if (jsonResponse['items'] != null && jsonResponse['items'].isNotEmpty) {
        final List<dynamic> results = jsonResponse['items'][0]['results'];
        for (var e in results) {
          final novel = Novel(
            pluginId: nameService,
            id: e['permalink']
                .toString()
                .replaceAll(mainUrl, '')
                .replaceAll(site, ''),
            title: e['title'].toString().replaceAll(RegExp(r'<\/?strong>'), ''),
            coverImageUrl: e['thumbnail'].toString(),
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
      print('Erro ao pesquisar novels: $e');
      return [];
    }
  }

  @override
  Future<List<Novel>> getAllNovels({BuildContext? context}) async {
    List<Novel> allNovels = [];
    int page = 1;
    bool hasNextPage = true;
    Map<String, dynamic> filters = {
      'order': {'value': 'date'},
      'sort': {'value': 'desc'},
      'storyStatus': {'value': 'all'},
    };

    while (hasNextPage) {
      String pageUrl = '${site}novel-list/?';
      if (filters != null) {
        pageUrl += 'orderby=${filters['order']?['value']}';
        pageUrl += '&order=${filters['sort']?['value']}';
        pageUrl += '&status=${filters['storyStatus']?['value']}';
      }
      pageUrl += '&pg=$page';
      try {
        final data = await safeFetch(pageUrl).then((res) => res.body);
        final dom.Document $ = parser.parse(data);
        List<Novel> novels = [];

        $.querySelectorAll('div.box.wide').forEach((el) {
          final name = el.querySelector('a.list-title')?.text.trim() ?? '';
          String cover = el.querySelector('amp-img')?.attributes['src'] ?? '';
          if (cover.isNotEmpty &&
              cover == 'https://www.mtlnovel.net/no-image.jpg.webp') {
            cover =
                'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed';
          }
          final path = el.querySelector('a.list-title')?.attributes['href'];
          if (path != null) {
            final novel = Novel(
              pluginId: nameService,
              id: path.replaceAll(mainUrl, '').replaceAll(site, ''),
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
        if (novels.isEmpty) {
          hasNextPage = false;
        } else {
          allNovels.addAll(novels);
          page++;
        }
      } catch (e) {
        print('Erro ao carregar novels da página $page: $e');
        hasNextPage = false;
      }
    }

    return allNovels;
  }
}
