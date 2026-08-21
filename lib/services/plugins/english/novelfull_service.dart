import 'package:html/parser.dart' as html_parser;
import 'package:flutter/src/widgets/framework.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/services/core/proxy_client.dart';

class NovelFull implements PluginService {
  @override
  String get name => 'NovelFull';

  @override
  String get lang => 'en';

  @override
  String get siteUrl => 'https://novelfull.com';

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
    final url = '$siteUrl/most-popular?page=$page';
    try {
      final res = await _client.get(Uri.parse(url));
      final document = html_parser.parse(res.body);
      final list = <Novel>[];

      final items = document.querySelectorAll('.list-truyen .row');
      for (final item in items) {
        final titleEl = item.querySelector('.truyen-title a');
        final title = titleEl?.text.trim() ?? '';
        final path = titleEl?.attributes['href'] ?? '';
        final img = item.querySelector('.cover')?.attributes['src'] ?? '';
        final author = item.querySelector('.author')?.text.trim() ?? 'NovelFull';

        if (title.isNotEmpty && path.isNotEmpty) {
          list.add(Novel(
            id: path.startsWith('http') ? path : '$siteUrl$path',
            title: title,
            coverImageUrl: img.startsWith('http') ? img : '$siteUrl$img',
            author: author,
            description: '',
            chapters: [],
            pluginId: name,
            genres: ['NovelFull'],
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
    final url = '$siteUrl/search?keyword=${Uri.encodeComponent(searchTerm)}&page=$pageNo';
    try {
      final res = await _client.get(Uri.parse(url));
      final document = html_parser.parse(res.body);
      final list = <Novel>[];

      final items = document.querySelectorAll('.list-truyen .row');
      for (final item in items) {
        final titleEl = item.querySelector('.truyen-title a');
        final title = titleEl?.text.trim() ?? '';
        final path = titleEl?.attributes['href'] ?? '';
        final img = item.querySelector('.cover')?.attributes['src'] ?? '';
        final author = item.querySelector('.author')?.text.trim() ?? 'NovelFull';

        if (title.isNotEmpty && path.isNotEmpty) {
          list.add(Novel(
            id: path.startsWith('http') ? path : '$siteUrl$path',
            title: title,
            coverImageUrl: img.startsWith('http') ? img : '$siteUrl$img',
            author: author,
            description: '',
            chapters: [],
            pluginId: name,
            genres: ['NovelFull'],
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

    final title = document.querySelector('h3.title')?.text.trim() ?? 'NovelFull Title';
    final cover = document.querySelector('.book img')?.attributes['src'] ?? '';
    final author = document.querySelector('.info a[href*="/author/"]')?.text.trim() ?? 'NovelFull Author';
    final summary = document.querySelector('.desc-text')?.text.trim() ?? '';

    final chapters = <Chapter>[];
    final chapterEls = document.querySelectorAll('#list-chapter ul.list-chapter li a');
    for (int i = 0; i < chapterEls.length; i++) {
      final el = chapterEls[i];
      final cTitle = el.attributes['title'] ?? el.text.trim();
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
      author: author,
      description: summary,
      chapters: chapters,
      pluginId: name,
      genres: ['NovelFull'],
    );
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final url = chapterPath.startsWith('http') ? chapterPath : '$siteUrl$chapterPath';
    final res = await _client.get(Uri.parse(url));
    final document = html_parser.parse(res.body);

    final contentEl = document.querySelector('#chapter-content');
    return contentEl?.innerHtml ?? '<p>Failed to load chapter content.</p>';
  }
}
