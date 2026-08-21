import 'package:html/parser.dart' as html_parser;
import 'package:flutter/src/widgets/framework.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/services/core/proxy_client.dart';

class Rulate implements PluginService {
  @override
  String get name => 'Rulate (Ранобэ)';

  @override
  String get lang => 'ru';

  @override
  String get siteUrl => 'https://tl.rulate.ru';

  @override
  String get version => '1.0.0';

  @override
  Map<String, dynamic> get filters => {};

  final ProxyClient _client = ProxyClient();

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    final url = '$siteUrl/search?t=&cat=0&sort=5&page=$page';
    try {
      final res = await _client.get(Uri.parse(url));
      final document = html_parser.parse(res.body);
      final list = <Novel>[];

      final items = document.querySelectorAll('.search-results tr, .book-list li');
      for (final item in items) {
        final titleEl = item.querySelector('a[href*="/book/"]');
        final title = titleEl?.text.trim() ?? '';
        final path = titleEl?.attributes['href'] ?? '';
        final img = item.querySelector('img')?.attributes['src'] ?? '';

        if (title.isNotEmpty && path.isNotEmpty) {
          list.add(Novel(
            id: path.startsWith('http') ? path : '$siteUrl$path',
            title: title,
            coverImageUrl: img.startsWith('http') ? img : '$siteUrl$img',
            author: 'Rulate',
            description: '',
            chapters: [],
            pluginId: name,
            genres: ['Ранобэ на русском', 'Rulate'],
          ));
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final url = '$siteUrl/search?t=${Uri.encodeComponent(searchTerm)}&page=$pageNo';
    try {
      final res = await _client.get(Uri.parse(url));
      final document = html_parser.parse(res.body);
      final list = <Novel>[];

      final items = document.querySelectorAll('.search-results tr, .book-list li');
      for (final item in items) {
        final titleEl = item.querySelector('a[href*="/book/"]');
        final title = titleEl?.text.trim() ?? '';
        final path = titleEl?.attributes['href'] ?? '';
        final img = item.querySelector('img')?.attributes['src'] ?? '';

        if (title.isNotEmpty && path.isNotEmpty) {
          list.add(Novel(
            id: path.startsWith('http') ? path : '$siteUrl$path',
            title: title,
            coverImageUrl: img.startsWith('http') ? img : '$siteUrl$img',
            author: 'Rulate',
            description: '',
            chapters: [],
            pluginId: name,
            genres: ['Ранобэ на русском', 'Rulate'],
          ));
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Novel>> getAllNovels({BuildContext? context}) async {
    return popularNovels(1, context: context);
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final url = novelPath.startsWith('http') ? novelPath : '$siteUrl$novelPath';
    final res = await _client.get(Uri.parse(url));
    final document = html_parser.parse(res.body);

    final title = document.querySelector('h1')?.text.trim() ?? 'Rulate Book';
    final cover = document.querySelector('.images img')?.attributes['src'] ?? '';
    final summary = document.querySelector('.description')?.text.trim() ?? '';

    final chapters = <Chapter>[];
    final chapterEls = document.querySelectorAll('tr.chapter_row a[href*="/chapter/"]');
    for (int i = 0; i < chapterEls.length; i++) {
      final el = chapterEls[i];
      final cTitle = el.text.trim();
      final cPath = el.attributes['href'] ?? '';
      if (cPath.isNotEmpty) {
        chapters.add(Chapter(
          id: cPath.startsWith('http') ? cPath : '$siteUrl$cPath',
          title: cTitle,
          releaseDate: '',
        ));
      }
    }

    return Novel(
      id: url,
      title: title,
      coverImageUrl: cover.startsWith('http') ? cover : '$siteUrl$cover',
      author: 'Rulate',
      description: summary,
      chapters: chapters,
      pluginId: name,
      genres: ['Ранобэ на русском', 'Rulate'],
    );
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final url = chapterPath.startsWith('http') ? chapterPath : '$siteUrl$chapterPath';
    final res = await _client.get(Uri.parse(url));
    final document = html_parser.parse(res.body);

    final contentEl = document.querySelector('.content-text') ?? document.querySelector('.chapter-text');
    return contentEl?.innerHtml ?? '<p>Failed to load chapter content.</p>';
  }
}
