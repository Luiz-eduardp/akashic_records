import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:akashic_records/services/core/proxy_client.dart';

class NovelBin implements PluginService {
  String get id => 'NovelBin';

  @override
  String get name => 'NovelBin';
  @override
  String get lang => 'en';
  @override
  String get version => '1.0.7';
  @override
  String get siteUrl => baseURL;

  final String baseURL = 'https://novelbin.me/';
  final String catalogURL = 'https://novelbin.me/sort/novelbin-popular';
  final String iconURL = 'https://novelbin.me/img/logo.png';

  @override
  Map<String, dynamic> get filters => {};

  late final ProxyClient _client = ProxyClient();

  Future<String> _fetchApi(String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load data from: $url');
    }
  }

  List<Novel> _parseBookResults(dom.Document document) {
    final novels = <Novel>[];

    final elements = document.querySelectorAll(
      '#list-page div.list-novel .row',
    );

    for (final el in elements) {
      try {
        final link = el.querySelector('div.col-xs-7 a');
        if (link == null) continue;

        final bookCover =
            el
                .querySelector('div.col-xs-3 > div > img')
                ?.attributes['data-src'] ??
            '';

        final novel = Novel(
          id: link.attributes['href'] ?? '',
          title: link.attributes['title'] ?? '',
          coverImageUrl: bookCover,
          author: '',
          description: '',
          genres: [],
          chapters: [],
          artist: '',
          statusString: '',
          pluginId: 'NovelBin',
        );

        novels.add(novel);
      } catch (e) {
        print('Error parsing book result: $e');
      }
    }

    return novels;
  }

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    bool showLatestNovels = false,
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    final url = catalogURL + '?page=$page';
    final body = await _fetchApi(url);
    final document = parse(body);
    return _parseBookResults(document);
  }

  @override
  Future<Novel> parseNovel(String bookUrl) async {
    final body = await _fetchApi(bookUrl);
    final document = parse(body);

    final novel = Novel(
      id: bookUrl,
      title:
          document
              .querySelector('meta[property="og:title"]')
              ?.attributes['content'] ??
          'Untitled',
      coverImageUrl:
          document
              .querySelector('meta[itemprop="image"]')
              ?.attributes['content'] ??
          '',
      description: document.querySelector('div.desc-text')?.text.trim() ?? '',
      author: '',
      genres: [],
      chapters: [],
      artist: '',
      statusString: '',
      pluginId: 'NovelBin',
    );

    final infoElements = document.querySelectorAll('ul.info > li > h3');
    for (final element in infoElements) {
      final detailName = element.text;
      final detail = element.nextElementSibling?.text.trim() ?? '';

      switch (detailName) {
        case 'Author:':
          novel.author = detail;
          break;
        case 'Status:':
          novel.status = _parseNovelStatus(detail);
          break;
        case 'Genre:':
          novel.genres = detail.split(',').toList();
          break;
      }
    }

    List<Chapter> chapterList = await _getChapterList(bookUrl);
    int chapterNumber = 1;

    for (var chapter in chapterList) {
      chapter.chapterNumber = chapterNumber;
      chapterNumber++;
    }

    novel.chapters = chapterList;

    return novel;
  }

  NovelStatus _parseNovelStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'ongoing':
        return NovelStatus.Andamento;
      case 'completed':
        return NovelStatus.Completa;
      default:
        return NovelStatus.Desconhecido;
    }
  }

  Future<List<Chapter>> _getChapterList(String bookUrl) async {
    final document = parse(await _fetchApi(bookUrl));
    String? keyId =
        document
            .querySelector('meta[property="og:url"]')
            ?.attributes['content'];

    if (keyId == null) {
      print('Could not extract keyId from og:url meta tag');
      return [];
    }

    keyId = Uri.parse(keyId).pathSegments.last;

    final chapterListURL = baseURL + 'ajax/chapter-archive?novelId=$keyId';

    try {
      final body = await _fetchApi(chapterListURL);
      final chapterDocument = parse(body);

      final chapterElements = chapterDocument.querySelectorAll(
        'ul.list-chapter li a',
      );

      List<Chapter> chapterList = [];

      for (final chapterElement in chapterElements) {
        final chapterTitle = chapterElement.attributes['title'];
        final chapterURL = chapterElement.attributes['href'];

        if (chapterTitle != null && chapterURL != null) {
          chapterList.add(
            Chapter(id: chapterURL, title: chapterTitle, content: ''),
          );
        }
      }
      return chapterList;
    } catch (e) {
      print('Error getting chapter list: $e');
      return [];
    }
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final url = chapterPath;
    final body = await _fetchApi(url);
    final document = parse(body);

    document
        .querySelectorAll('#chr-content > div,h6,p[style="display: none;"]')
        .forEach((element) {
          element.remove();
        });

    return document.querySelector('#chr-content')?.innerHtml ?? '';
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final searchURL =
        baseURL +
        'search/?keyword=${Uri.encodeComponent(searchTerm)}&page=$pageNo';
    final body = await _fetchApi(searchURL);
    final document = parse(body);
    return _parseBookResults(document);
  }

  @override
  Future<List<Novel>> getAllNovels({
    BuildContext? context,
    int pageNo = 1,
  }) async {
    final url = catalogURL + '?page=$pageNo';
    final body = await _fetchApi(url);
    final document = parse(body);
    return _parseBookResults(document);
  }
}

enum FilterTypes { picker, toggle }
