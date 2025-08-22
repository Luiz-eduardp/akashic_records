import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/widgets.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;

class IndoWebNovel implements PluginService {
  String get id => 'IndoWebNovel';

  @override
  String get name => 'IndoWebNovel';

  @override
  String get lang => 'id';

  @override
  String get version => '1.0.1';

  final String site = 'https://indowebnovel.id/';

  @override
  String get siteUrl => site; 
  @override
  Map<String, dynamic> get filters => {};

  Future<String> _fetchApi(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load data from: $url');
    }
  }

  Future<List<Novel>> _parseNovels(String html) async {
    final novels = <Novel>[];
    final document = parse(html);

    final flexboxItems = document.querySelectorAll('.flexbox2-item');

    for (final element in flexboxItems) {
      final novelNameElement = element.querySelector('.flexbox2-title span');
      final novelCoverElement = element.querySelector('img');
      final novelUrlElement = element.querySelector('.flexbox2-content > a');

      if (novelUrlElement == null) continue;

      final novelName = novelNameElement?.text.trim() ?? 'Untitled';
      final novelCover = novelCoverElement?.attributes['src'] ?? '';
      final novelPath =
          novelUrlElement.attributes['href']?.replaceFirst(site, '') ?? '';

      novels.add(
        Novel(
          id: novelPath,
          title: novelName,
          coverImageUrl: novelCover,
          author: '',
          description: '',
          genres: [],
          chapters: [],
          artist: '',
          statusString: '',
          pluginId: id,
        ),
      );
    }

    return novels;
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
    bool showLatestNovels = true,
  }) async {
    final link = '$site/page/$pageNo/?s';
    final body = await _fetchApi(link);
    return _parseNovels(body);
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final result = await _fetchApi(site + novelPath);
    final body = result;
    final document = parse(body);

    document.querySelectorAll('.series-synops div').forEach((element) {
      element.remove();
    });

    final novel = Novel(
      id: novelPath,
      title:
          document.querySelector('.series-title h2')?.text.trim() ?? 'Untitled',
      coverImageUrl:
          document.querySelector('.series-thumb img')?.attributes['src'] ?? '',
      author: _extractAuthor(document),
      description: document.querySelector('.series-synops')?.text.trim() ?? '',
      genres:
          document
              .querySelectorAll('.series-genres a')
              .map((e) => e.text.trim())
              .toList(),
      chapters: [],
      artist: '',
      statusString: '',
      pluginId: id,
    );

    final statusText = document.querySelector('.status')?.text.trim() ?? '';
    novel.status = _parseNovelStatus(statusText);

    novel.genres =
        document
            .querySelectorAll('.series-genres a')
            .map((e) => e.text.trim())
            .toList();

    final chapterElements = document.querySelectorAll('.series-chapterlist li');
    final chapters = <Chapter>[];

    for (final element in chapterElements) {
      final chapterName = element.querySelector('a')?.text.trim() ?? '';
      final chapterUrl =
          element
              .querySelector('a')
              ?.attributes['href']
              ?.replaceFirst(site, '') ??
          '';

      chapters.add(
        Chapter(
          id: chapterUrl,
          title: chapterName,
          content: '',
          order: chapters.length,
          chapterNumber: chapters.length + 1,
        ),
      );
    }

    novel.chapters = chapters.reversed.toList();

    return novel;
  }

  String _extractAuthor(dom.Document document) {
    String author = '';
    final listItems = document.querySelectorAll('.series-infolist li');
    for (final item in listItems) {
      if (item.text.contains('Author')) {
        author = item.querySelector('span')?.text.trim() ?? '';
        break;
      }
    }
    return author;
  }

  NovelStatus _parseNovelStatus(String statusText) {
    switch (statusText) {
      case 'Completed':
        return NovelStatus.Completa;
      case 'Ongoing':
        return NovelStatus.Andamento;
      default:
        return NovelStatus.Desconhecido;
    }
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final result = await _fetchApi(site + chapterPath);
    final body = result;
    final document = parse(body);

    final chapterContentElement = document.querySelector('.adsads');
    String chapterText = chapterContentElement?.innerHtml ?? '';

    return chapterText;
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final link = '$site/page/$pageNo/?s=$searchTerm';
    final body = await _fetchApi(link);
    return _parseNovels(body);
  }

  @override
  Future<List<Novel>> getAllNovels({
    BuildContext? context,
    int pageNo = 1,
  }) async {
    final link = '$site/page/$pageNo/?s';
    final body = await _fetchApi(link);
    return _parseNovels(body);
  }
}
