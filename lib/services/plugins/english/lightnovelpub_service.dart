import 'package:html/parser.dart' as html_parser;
import 'package:flutter/src/widgets/framework.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/services/core/proxy_client.dart';

class LightNovelPub implements PluginService {
  @override
  String get name => 'LightNovelPUB';

  @override
  String get lang => 'en';

  @override
  String get siteUrl => 'https://www.lightnovelpub.com';

  @override
  String get version => '2.1.0';

  @override
  Map<String, dynamic> get filters => {};

  final ProxyClient _client = ProxyClient();

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    final url = '$siteUrl/browse/all/popular/all/$page';
    try {
      final res = await _client.get(Uri.parse(url));
      final document = html_parser.parse(res.body);
      final list = <Novel>[];

      final items = document.querySelectorAll('.novel-item');
      for (final item in items) {
        final titleEl = item.querySelector('.novel-title a');
        final title = titleEl?.text.trim() ?? '';
        final path = titleEl?.attributes['href'] ?? '';
        final img = item.querySelector('img')?.attributes['data-src'] ?? item.querySelector('img')?.attributes['src'] ?? '';

        if (title.isNotEmpty && path.isNotEmpty) {
          list.add(Novel(
            id: path.startsWith('http') ? path : '$siteUrl$path',
            title: title,
            coverImageUrl: img,
            author: 'LightNovelPUB',
            description: '',
            chapters: [],
            pluginId: name,
            genres: ['LightNovelPUB'],
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
    final url = '$siteUrl/search?keyword=${Uri.encodeComponent(searchTerm)}';
    try {
      final res = await _client.get(Uri.parse(url));
      final document = html_parser.parse(res.body);
      final list = <Novel>[];

      final items = document.querySelectorAll('.novel-item');
      for (final item in items) {
        final titleEl = item.querySelector('.novel-title a');
        final title = titleEl?.text.trim() ?? '';
        final path = titleEl?.attributes['href'] ?? '';
        final img = item.querySelector('img')?.attributes['data-src'] ?? item.querySelector('img')?.attributes['src'] ?? '';

        if (title.isNotEmpty && path.isNotEmpty) {
          list.add(Novel(
            id: path.startsWith('http') ? path : '$siteUrl$path',
            title: title,
            coverImageUrl: img,
            author: 'LightNovelPUB',
            description: '',
            chapters: [],
            pluginId: name,
            genres: ['LightNovelPUB'],
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

    final title = document.querySelector('h1.novel-title')?.text.trim() ?? 'LightNovelPUB Novel';
    final cover = document.querySelector('.cover img')?.attributes['data-src'] ?? document.querySelector('.cover img')?.attributes['src'] ?? '';
    final author = document.querySelector('.author a span')?.text.trim() ?? 'Unknown Author';
    final summary = document.querySelector('.summary .content')?.text.trim() ?? '';

    final chapters = <Chapter>[];
    final chapterEls = document.querySelectorAll('.chapter-list li a');
    for (int i = 0; i < chapterEls.length; i++) {
      final el = chapterEls[i];
      final cTitle = el.querySelector('.chapter-title')?.text.trim() ?? 'Chapter ${i + 1}';
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
      coverImageUrl: cover,
      author: author,
      description: summary,
      chapters: chapters,
      pluginId: name,
      genres: ['LightNovelPUB'],
    );
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final url = chapterPath.startsWith('http') ? chapterPath : '$siteUrl$chapterPath';
    final res = await _client.get(Uri.parse(url));
    final document = html_parser.parse(res.body);

    final contentEl = document.querySelector('#chapter-container') ?? document.querySelector('.chapter-content');
    return contentEl?.innerHtml ?? '<p>Failed to load chapter content.</p>';
  }
}
