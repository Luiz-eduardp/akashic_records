import 'package:html/parser.dart' as html_parser;
import 'package:flutter/src/widgets/framework.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/services/core/proxy_client.dart';

class BoxNovel implements PluginService {
  @override
  String get name => 'BoxNovel';

  @override
  String get lang => 'en';

  @override
  String get siteUrl => 'https://boxnovel.com';

  @override
  String get version => '2.0.0';

  @override
  Map<String, dynamic> get filters => {};

  final ProxyClient _client = ProxyClient();

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    final url = '$siteUrl/novel/page/$page/?m_orderby=rating';
    try {
      final res = await _client.get(Uri.parse(url));
      final document = html_parser.parse(res.body);
      final list = <Novel>[];

      final items = document.querySelectorAll('.page-item-detail');
      for (final item in items) {
        final titleEl = item.querySelector('.post-title a');
        final title = titleEl?.text.trim() ?? '';
        final path = titleEl?.attributes['href'] ?? '';
        final img = item.querySelector('img')?.attributes['src'] ?? '';

        if (title.isNotEmpty && path.isNotEmpty) {
          list.add(Novel(
            id: path.startsWith('http') ? path : '$siteUrl$path',
            title: title,
            coverImageUrl: img.startsWith('http') ? img : '$siteUrl$img',
            author: 'BoxNovel',
            description: '',
            chapters: [],
            pluginId: name,
            genres: ['BoxNovel'],
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
    final url = '$siteUrl/?s=${Uri.encodeComponent(searchTerm)}&post_type=wp-manga';
    try {
      final res = await _client.get(Uri.parse(url));
      final document = html_parser.parse(res.body);
      final list = <Novel>[];

      final items = document.querySelectorAll('.c-tabs-item__content');
      for (final item in items) {
        final titleEl = item.querySelector('.post-title a');
        final title = titleEl?.text.trim() ?? '';
        final path = titleEl?.attributes['href'] ?? '';
        final img = item.querySelector('img')?.attributes['src'] ?? '';

        if (title.isNotEmpty && path.isNotEmpty) {
          list.add(Novel(
            id: path.startsWith('http') ? path : '$siteUrl$path',
            title: title,
            coverImageUrl: img.startsWith('http') ? img : '$siteUrl$img',
            author: 'BoxNovel',
            description: '',
            chapters: [],
            pluginId: name,
            genres: ['BoxNovel'],
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

    final title = document.querySelector('.post-title h1')?.text.trim() ?? 'BoxNovel Title';
    final cover = document.querySelector('.summary_image img')?.attributes['src'] ?? '';
    final summary = document.querySelector('.description-summary')?.text.trim() ?? '';

    final chapters = <Chapter>[];
    final chapterEls = document.querySelectorAll('.wp-manga-chapter a');
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
      author: 'BoxNovel',
      description: summary,
      chapters: chapters,
      pluginId: name,
      genres: ['BoxNovel'],
    );
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final url = chapterPath.startsWith('http') ? chapterPath : '$siteUrl$chapterPath';
    final res = await _client.get(Uri.parse(url));
    final document = html_parser.parse(res.body);

    final contentEl = document.querySelector('.reading-content') ?? document.querySelector('.text-left');
    return contentEl?.innerHtml ?? '<p>Failed to load chapter content.</p>';
  }
}
