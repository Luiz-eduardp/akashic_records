import 'dart:async';
import 'dart:convert';

import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;

class MtlNovelMulti implements PluginService {
  @override
  String get name => 'MtlNovelMulti';

  @override
  String get lang => _lang;
  String _lang = 'en';

  set lang(String newLang) {
    _lang = newLang;
  }

  String get site {
    switch (lang) {
      case 'en':
        return 'https://www.mtlnovels.com/';
      case 'es':
        return 'https://es.mtlnovels.com/';
      case 'id':
        return 'https://id.mtlnovels.com/';
      case 'fr':
        return 'https://fr.mtlnovels.com/';
      case 'pt':
        return 'https://pt.mtlnovels.com/';
      case 'ru':
        return 'https://ru.mtlnovels.com/';
      default:
        return 'https://www.mtlnovels.com/';
    }
  }

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

  final String id = 'MtlNovelMulti';
  final String nameService = 'MtlNovelMulti';
  final String mainUrl = 'https://www.mtlnovels.com/';
  @override
  final String version = '1.2.9';

  final http.Client client = http.Client();

  Future<http.Response> safeFetch(
    String url, {
    Map<String, String>? headers,
  }) async {
    final defaultHeaders = {'Alt-Used': 'www.mtlnovels.com'};
    final mergedHeaders = {...defaultHeaders, ...?headers};

    try {
      final response = await client.get(Uri.parse(url), headers: mergedHeaders);
      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception(
          'Could not reach site (${response.statusCode}) try to open in webview.',
        );
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      rethrow;
    }
  }

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    return _fetchNovels(page, filters: filters);
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

    final labels = _getLocalizedLabels();

    $.querySelectorAll('tr').forEach((el) {
      final label = el.querySelector('td')?.text.trim();
      final value = el.querySelector('td:nth-child(3)')?.text.trim();

      if (label == labels['genre'] ||
          label == 'Tags' ||
          label == 'Mots Clés' ||
          label == 'Label' ||
          label == 'Tag' ||
          label == 'Теги') {
        novel.genres = novel.genres != null ? '${novel.genres}, $value' : value;
      } else if (label == labels['author'] ||
          label == 'Auteur' ||
          label == 'Autor(a)' ||
          label == 'Автор') {
        novel.author = value ?? '';
      } else if (label == labels['status'] ||
          label == 'Statut' ||
          label == 'Estado' ||
          label == 'Положение дел') {
        if (value == 'Hiatus') {
          novel.status = NovelStatus.Pausada;
        }
      }
    });

    final chapterListUrl = '$site${novelPath}chapter-list/';
    novel.chapters = await _getChapters(chapterListUrl, headers);

    if (novel.genres != null) {
      novel.genres = _formatGenres(novel.genres);
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
    if (page != 1) {
      return [];
    }

    final encodedSearchTerm = Uri.encodeComponent(searchTerm);
    final url =
        '${site}wp-admin/admin-ajax.php?action=autosuggest&q=$encodedSearchTerm';

    try {
      final data = await safeFetch(url).then((res) => res.body);
      final jsonResponse = json.decode(data);
      return _parseSearchNovels(jsonResponse);
    } catch (e) {
      print('Erro ao pesquisar novels: $e');
      return [];
    }
  }

  @override
  Future<List<Novel>> getAllNovels({
    BuildContext? context,
    int pageNo = 1,
  }) async {
    String url = '${site}novel-list/?pg=$pageNo';
    return _fetchNovels(pageNo, url: url, filters: filters);
  }

  Future<List<Novel>> _fetchNovels(
    int page, {
    String? url,
    Map<String, dynamic>? filters,
  }) async {
    String novelsUrl = url ?? '${site}novel-list/?';
    if (filters != null) {
      novelsUrl += 'orderby=${filters['order']?['value']}';
      novelsUrl += '&order=${filters['sort']?['value']}';
      novelsUrl += '&status=${filters['storyStatus']?['value']}';
    }

    try {
      novelsUrl += '&pg=$page';
      final data = await safeFetch(novelsUrl).then((res) => res.body);
      final dom.Document $ = parser.parse(data);
      final List<Novel> novels = _parseNovelList($, nameService);
      return novels;
    } catch (e) {
      print('Error fetching novels: $e');
      return [];
    }
  }

  Map<String, String> _getLocalizedLabels() {
    switch (lang) {
      case 'es':
        return {'genre': 'Género', 'author': 'Autor', 'status': 'Estado'};
      case 'id':
        return {'genre': 'Genre', 'author': 'Author', 'status': 'Status'};
      case 'fr':
        return {'genre': 'Genre', 'author': 'Auteur', 'status': 'Statut'};
      case 'pt':
        return {'genre': 'Gênero', 'author': 'Autor(a)', 'status': 'Estado'};
      case 'ru':
        return {'genre': 'Теги', 'author': 'Автор', 'status': 'Положение дел'};
      default:
        return {'genre': 'Genre', 'author': 'Author', 'status': 'Status'};
    }
  }

  String _formatGenres(String genres) {
    List<String> genresArray = genres.split(', ');
    genresArray.removeLast();
    return genresArray.join(', ');
  }

  Future<List<Chapter>> _getChapters(
    String chapterListUrl,
    Map<String, String> headers,
  ) async {
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

  List<Novel> _parseNovelList(dom.Document $, String nameService) {
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

  List<Novel> _parseSearchNovels(Map<String, dynamic> jsonResponse) {
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
  }

  void dispose() {
    client.close();
  }
}
