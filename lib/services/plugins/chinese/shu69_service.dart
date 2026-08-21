import 'package:html/parser.dart' as html_parser;
import 'package:flutter/src/widgets/framework.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/services/core/proxy_client.dart';

class Shu69 implements PluginService {
  @override
  String get name => '69书吧 (69Shu)';

  @override
  String get lang => 'zh';

  @override
  String get siteUrl => 'https://www.69shu.xyz';

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
    final url = '$siteUrl/top/allvisit/$page.html';
    try {
      final res = await _client.get(Uri.parse(url));
      final document = html_parser.parse(res.body);
      final list = <Novel>[];

      final items = document.querySelectorAll('.newgrid ul li');
      for (final item in items) {
        final titleEl = item.querySelector('.servicetitle a');
        final title = titleEl?.text.trim() ?? '';
        final path = titleEl?.attributes['href'] ?? '';
        final img = item.querySelector('img')?.attributes['src'] ?? '';

        if (title.isNotEmpty && path.isNotEmpty) {
          list.add(Novel(
            id: path.startsWith('http') ? path : '$siteUrl$path',
            title: title,
            coverImageUrl: img.startsWith('http') ? img : '$siteUrl$img',
            author: '69书吧',
            description: '',
            chapters: [],
            pluginId: name,
            genres: ['Chinese Novel', '69Shu'],
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
    final url = '$siteUrl/modules/article/search.php';
    try {
      final res = await _client.post(
        Uri.parse(url),
        body: {'searchkey': searchTerm},
      );
      final document = html_parser.parse(res.body);
      final list = <Novel>[];

      final items = document.querySelectorAll('.newgrid ul li');
      for (final item in items) {
        final titleEl = item.querySelector('.servicetitle a');
        final title = titleEl?.text.trim() ?? '';
        final path = titleEl?.attributes['href'] ?? '';
        final img = item.querySelector('img')?.attributes['src'] ?? '';

        if (title.isNotEmpty && path.isNotEmpty) {
          list.add(Novel(
            id: path.startsWith('http') ? path : '$siteUrl$path',
            title: title,
            coverImageUrl: img.startsWith('http') ? img : '$siteUrl$img',
            author: '69书吧',
            description: '',
            chapters: [],
            pluginId: name,
            genres: ['Chinese Novel', '69Shu'],
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

    final title = document.querySelector('h1')?.text.trim() ?? '69Shu Novel';
    final cover = document.querySelector('.bookbox img')?.attributes['src'] ?? '';
    final author = document.querySelector('.bookbox .author')?.text.trim() ?? '69书吧';
    final summary = document.querySelector('.navtxt')?.text.trim() ?? '';

    final chapters = <Chapter>[];
    final chapterEls = document.querySelectorAll('.catalog ul li a');
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
      author: author,
      description: summary,
      chapters: chapters,
      pluginId: name,
      genres: ['Chinese Novel', '69Shu'],
    );
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final url = chapterPath.startsWith('http') ? chapterPath : '$siteUrl$chapterPath';
    final res = await _client.get(Uri.parse(url));
    final document = html_parser.parse(res.body);

    final contentEl = document.querySelector('.txtnav');
    return contentEl?.innerHtml ?? '<p>Failed to load chapter content.</p>';
  }
}
