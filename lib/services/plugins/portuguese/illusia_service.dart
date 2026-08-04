import 'dart:io';
import 'package:flutter/src/widgets/framework.dart';
import 'package:akashic_records/services/core/proxy_client.dart';
import 'package:html/parser.dart' show parse;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';

class IllusiaHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class Illusia implements PluginService {
  @override
  String get name => 'Illusia';
  @override
  String get lang => 'pt-BR';
  @override
  String get siteUrl => site;
  @override
  Map<String, dynamic> get filters => {};

  final String id = 'illusia';
  final String nameService = 'Illusia';
  final String site = 'https://illusia.com.br';
  @override
  final String version = '1.0.1';

  static const String defaultCover =
      'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed';

  late final ProxyClient _client;

  Illusia() {
    HttpOverrides.global = IllusiaHttpOverrides();
    _client = ProxyClient();
  }

  Future<String> _fetchApi(String url) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
      },
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Falha ao carregar dados de: $url');
    }
  }

  String _shrinkURL(String url) {
    return url
        .replaceAll(RegExp(r'^https?://illusia\.com\.br'), '')
        .replaceAll(RegExp(r'^/'), '');
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    final showLatestNovels = filters?['showLatestNovels'] == true;
    final orderBy = showLatestNovels ? 'modified' : 'comment_count';
    final page = pageNo == 1 ? '' : 'page/$pageNo/';
    final url =
        '$site/$page?s=&post_type=fcn_story&sentence=0&orderby=$orderBy&order=desc&age_rating=Any&story_status=Any&miw=0&maw=0&genres=&fandoms=&characters=&tags=&warnings=&authors=&ex_genres=&ex_fandoms=&ex_characters=&ex_tags=&ex_warnings=&ex_authors=';

    final body = await _fetchApi(url);
    final document = parse(body);

    final novelElements = document.querySelectorAll(
      '#search-result-list > li, article.story, article.post, .card, .story-card, .ranking-item, ul.ranking-list li, .bsx, .book-item, .fcn-story',
    );

    List<Novel> novels = [];
    final seenPaths = <String>{};

    for (var element in novelElements) {
      final linkEl = element.querySelector(
        '.card__title a, h2 a, h3 a, h4 a, .card-title a, .story-title a, .story__title a, .ranking-title a, .entry-title a, .tt',
      );
      if (linkEl == null) continue;

      final novelName = linkEl.text.trim();
      var novelPath = linkEl.attributes['href'] ?? '';
      if (novelPath.isEmpty) {
        final firstLink = element.querySelector('a');
        novelPath = firstLink?.attributes['href'] ?? '';
      }

      var cover =
          element.querySelector('img')?.attributes['data-src'] ??
          element.querySelector('img')?.attributes['data-lazy-src'] ??
          element.querySelector('img')?.attributes['src'] ??
          element
              .querySelector('.ranking-cover, .story-cover, .img-cover')
              ?.attributes['data-bg'];

      if (cover == null || cover.isEmpty) {
        final styleEl = element.querySelector('[style*="url("]');
        final style =
            styleEl?.attributes['style'] ?? element.attributes['style'];
        if (style != null && style.isNotEmpty) {
          final match = RegExp(r'url\(([^)]+)\)').firstMatch(style);
          if (match != null) {
            cover =
                match.group(1)?.replaceAll("'", '').replaceAll('"', '').trim();
          }
        }
      }

      if (novelName.isNotEmpty && novelPath.isNotEmpty) {
        final path = _shrinkURL(novelPath);
        if (seenPaths.contains(path)) continue;
        seenPaths.add(path);

        if (cover != null && cover.startsWith('/')) {
          cover = site + cover;
        }

        novels.add(
          Novel(
            id: path,
            title: novelName,
            coverImageUrl: cover ?? defaultCover,
            author: '',
            description: '',
            genres: [],
            chapters: [],
            artist: '',
            statusString: '',
            pluginId: name,
          ),
        );
      }
    }

    return novels;
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final body = await _fetchApi('$site/$novelPath/');
    final document = parse(body);

    final novel = Novel(
      id: novelPath,
      title:
          document
              .querySelector('h1.story__identity-title, h1.post-title')
              ?.text
              .trim() ??
          'Sem título',
      coverImageUrl: defaultCover,
      author: 'Desconhecido',
      description: '',
      genres: [],
      chapters: [],
      artist: '',
      statusString: '',
      pluginId: name,
    );

    var author =
        document
            .querySelector(
              'span.custom-story-info a.author, a[href*="/author/"], a[rel="author"]',
            )
            ?.text
            .trim() ??
        document
            .querySelector(
              '.story__author, .story-author, .author-name, .post-author, [class*="__author"]',
            )
            ?.text
            .trim();

    if (author == null || author.isEmpty) {
      final metaText =
          document
              .querySelector(
                '.story__identity-meta, .story-meta, .custom-story-info',
              )
              ?.text
              .trim();
      if (metaText != null && metaText.isNotEmpty) {
        final parts = metaText.split('|');
        if (parts.isNotEmpty) {
          author =
              parts[0]
                  .replaceAll(
                    RegExp(
                      r'^(Autor[a]?|Por|Author|by)[\s:]*',
                      caseSensitive: false,
                    ),
                    '',
                  )
                  .trim();
        }
      }
    }
    novel.author = author ?? 'Desconhecido';

    var cover =
        document
            .querySelector('figure.story__thumbnail img')
            ?.attributes['data-src'] ??
        document
            .querySelector('figure.story__thumbnail img')
            ?.attributes['src'] ??
        document
            .querySelector('.story__thumbnail img')
            ?.attributes['data-src'] ??
        document.querySelector('.story__thumbnail img')?.attributes['src'] ??
        document
            .querySelector('figure.story__thumbnail > a')
            ?.attributes['href'];
    novel.coverImageUrl = cover ?? defaultCover;

    final genreElements = document.querySelectorAll(
      'div.tag-group > a, section.tag-group > a, .genres a',
    );
    novel.genres = genreElements.map((e) => e.text.trim()).toList();

    var summaryHtml =
        document
            .querySelector(
              'section.story__summary, div.story__summary, .summary',
            )
            ?.innerHtml ??
        '';
    summaryHtml = summaryHtml.replaceAll(
      RegExp(r'<br\s*\/?>', caseSensitive: false),
      '\n',
    );
    summaryHtml = summaryHtml.replaceAll(
      RegExp(r'<\/p>', caseSensitive: false),
      '\n\n',
    );
    summaryHtml = summaryHtml.replaceAll(
      RegExp(r'<\/div>', caseSensitive: false),
      '\n',
    );
    final summaryDoc = parse(summaryHtml);
    novel.description =
        summaryDoc.body?.text.trim().replaceAll(RegExp(r'\n{3,}'), '\n\n') ??
        '';

    final chapterElements = document.querySelectorAll(
      'li.chapter-group__list-item, ul.chapter-list li, .chapters li, .chapter-item',
    );

    int chapterIndex = 1;
    for (var el in chapterElements) {
      final link = el.querySelector('a');
      if (link == null) continue;

      final chapterName = link.text.trim();
      var chapterPath = link.attributes['href'] ?? '';
      if (chapterName.isEmpty || chapterPath.isEmpty) continue;

      chapterPath = _shrinkURL(chapterPath);

      final match =
          RegExp(
            r'(?:cap[íi]tulo|cap\.?|ch\.?)\s*(\d+(?:\.\d+)?)',
            caseSensitive: false,
          ).firstMatch(chapterName) ??
          RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(chapterName);
      final chapterNumber =
          match != null ? double.tryParse(match.group(1)!)?.toInt() : null;

      novel.chapters.add(
        Chapter(
          id: chapterPath,
          title: chapterName,
          content: '',
          chapterNumber: chapterNumber ?? chapterIndex,
        ),
      );
      chapterIndex++;
    }

    var statusText =
        document.querySelector('span.story__status')?.text.trim().toLowerCase();
    if (statusText == null || statusText.isEmpty) {
      final metaText =
          document
              .querySelector('div.story__identity-meta, .story-meta')
              ?.text ??
          '';
      statusText = metaText.toLowerCase();
    }

    if (statusText.contains('ongoing') ||
        statusText.contains('andamento') ||
        statusText.contains('lançando') ||
        statusText.contains('ativa')) {
      novel.status = NovelStatus.Andamento;
    } else if (statusText.contains('completed') ||
        statusText.contains('completo')) {
      novel.status = NovelStatus.Completa;
    } else if (statusText.contains('cancelled') ||
        statusText.contains('cancelado') ||
        statusText.contains('dropado')) {
      novel.status = NovelStatus.Desconhecido;
    } else if (statusText.contains('hiatus') ||
        statusText.contains('hiato') ||
        statusText.contains('pausado')) {
      novel.status = NovelStatus.Pausada;
    } else {
      novel.status = NovelStatus.Desconhecido;
    }

    return novel;
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final body = await _fetchApi('$site/$chapterPath/');
    final document = parse(body);

    final content = document.querySelector(
      'section#chapter-content > div, div.chapter-content',
    );
    if (content == null) return '';

    content
        .querySelectorAll(
          'script, style, iframe, .patreon-popup, .fcn-notice, .fictioneer-notice, div.card',
        )
        .forEach((el) => el.remove());

    return content.innerHtml;
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final page = pageNo == 1 ? '' : 'page/$pageNo/';
    final url =
        '$site/$page?s=${Uri.encodeComponent(searchTerm)}&post_type=fcn_story&sentence=0&orderby=relevance&order=desc&age_rating=Any&story_status=Any&miw=0&maw=0&genres=&fandoms=&characters=&tags=&warnings=&authors=&ex_genres=&ex_fandoms=&ex_characters=&ex_tags=&ex_warnings=&ex_authors=';

    final body = await _fetchApi(url);
    final document = parse(body);

    final novelElements = document.querySelectorAll(
      '#search-result-list > li, article.story, article.post, .card, .story-card, .ranking-item, ul.ranking-list li, .bsx, .book-item, .fcn-story',
    );

    List<Novel> novels = [];
    final seenPaths = <String>{};

    for (var element in novelElements) {
      final linkEl = element.querySelector(
        '.card__title a, h2 a, h3 a, h4 a, .card-title a, .story-title a, .story__title a, .ranking-title a, .entry-title a, .tt',
      );
      if (linkEl == null) continue;

      final novelName = linkEl.text.trim();
      var novelPath = linkEl.attributes['href'] ?? '';
      if (novelPath.isEmpty) {
        final firstLink = element.querySelector('a');
        novelPath = firstLink?.attributes['href'] ?? '';
      }

      var cover =
          element.querySelector('img')?.attributes['data-src'] ??
          element.querySelector('img')?.attributes['data-lazy-src'] ??
          element.querySelector('img')?.attributes['src'] ??
          element
              .querySelector('.ranking-cover, .story-cover, .img-cover')
              ?.attributes['data-bg'];

      if (cover == null || cover.isEmpty) {
        final styleEl = element.querySelector('[style*="url("]');
        final style =
            styleEl?.attributes['style'] ?? element.attributes['style'];
        if (style != null && style.isNotEmpty) {
          final match = RegExp(r'url\(([^)]+)\)').firstMatch(style);
          if (match != null) {
            cover =
                match.group(1)?.replaceAll("'", '').replaceAll('"', '').trim();
          }
        }
      }

      if (novelName.isNotEmpty && novelPath.isNotEmpty) {
        final path = _shrinkURL(novelPath);
        if (seenPaths.contains(path)) continue;
        seenPaths.add(path);

        if (cover != null && cover.startsWith('/')) {
          cover = site + cover;
        }

        novels.add(
          Novel(
            id: path,
            title: novelName,
            coverImageUrl: cover ?? defaultCover,
            author: '',
            description: '',
            genres: [],
            chapters: [],
            artist: '',
            statusString: '',
            pluginId: name,
          ),
        );
      }
    }

    return novels;
  }

  @override
  Future<List<Novel>> getAllNovels({
    BuildContext? context,
    int pageNo = 1,
  }) async {
    return popularNovels(pageNo, filters: {}, context: context);
  }
}
