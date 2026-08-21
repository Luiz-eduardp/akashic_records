import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/src/widgets/framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:akashic_records/services/core/proxy_client.dart';
import 'package:akashic_records/services/lnreader_js_runtime.dart';

class LnReaderPluginManifest {
  final String id;
  final String name;
  final String site;
  final String lang;
  final String version;
  final String url;
  final String iconUrl;

  LnReaderPluginManifest({
    required this.id,
    required this.name,
    required this.site,
    required this.lang,
    required this.version,
    required this.url,
    required this.iconUrl,
  });

  factory LnReaderPluginManifest.fromJson(Map<String, dynamic> json) {
    return LnReaderPluginManifest(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      site: json['site'] ?? '',
      lang: json['lang'] ?? 'English',
      version: json['version'] ?? '1.0.0',
      url: json['url'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
    );
  }
}

class LnReaderDynamicPlugin implements PluginService {
  final LnReaderPluginManifest manifest;
  final ProxyClient _client = ProxyClient();
  LnReaderJsRuntime? _runtime;
  String? _cachedJsCode;

  LnReaderDynamicPlugin(this.manifest);

  @override
  String get name => '${manifest.name} (LN)';

  @override
  String get lang => _mapLangCode(manifest.lang);

  @override
  String get siteUrl => manifest.site;

  @override
  String get version => manifest.version;

  @override
  Map<String, dynamic> get filters => {};

  String _mapLangCode(String rawLang) {
    final lower = rawLang.toLowerCase();
    if (lower.contains('portug') || lower.contains('pt')) return 'pt';
    if (lower.contains('spanish') || lower.contains('español') || lower.contains('es')) return 'es';
    if (lower.contains('japanese') || lower.contains('日本語') || lower.contains('ja')) return 'ja';
    if (lower.contains('chinese') || lower.contains('中文') || lower.contains('zh')) return 'zh';
    if (lower.contains('russian') || lower.contains('русский') || lower.contains('ru')) return 'ru';
    if (lower.contains('french') || lower.contains('français') || lower.contains('fr')) return 'fr';
    if (lower.contains('arabic') || lower.contains('العربية') || lower.contains('ar')) return 'ar';
    if (lower.contains('indonesian') || lower.contains('id')) return 'id';
    return 'en';
  }

  Future<LnReaderJsRuntime?> _getJsRuntime() async {
    if (_runtime != null && _cachedJsCode != null) return _runtime;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'ln_js_code_${manifest.id}';
      String? code = prefs.getString(cacheKey);

      if (code == null || code.isEmpty) {
        if (manifest.url.isNotEmpty) {
          final res = await http.get(Uri.parse(manifest.url)).timeout(const Duration(seconds: 12));
          if (res.statusCode == 200 && res.body.isNotEmpty) {
            code = res.body;
            await prefs.setString(cacheKey, code);
          }
        }
      }

      if (code != null && code.isNotEmpty) {
        _cachedJsCode = code;
        final runtime = LnReaderJsRuntime();
        final ok = await runtime.loadPluginScript(code);
        if (ok) {
          _runtime = runtime;
          return _runtime;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    final runtime = await _getJsRuntime();
    if (runtime != null) {
      try {
        final jsResults = await runtime.popularNovels(siteUrl, page, name, lang);
        if (jsResults.isNotEmpty) return jsResults;
      } catch (_) {}
    }

    return _fallbackPopularNovels(page);
  }

  Future<List<Novel>> _fallbackPopularNovels(int page) async {
    final cleanSite = siteUrl.endsWith('/') ? siteUrl.substring(0, siteUrl.length - 1) : siteUrl;
    final candidates = [
      '$cleanSite/novel/page/$page/?m_orderby=rating',
      '$cleanSite/novels/page/$page/',
      '$cleanSite/page/$page/?m_orderby=rating',
      '$cleanSite/series/page/$page/',
      '$cleanSite/page/$page/',
      cleanSite,
    ];

    for (final targetUrl in candidates) {
      try {
        final res = await _client.get(Uri.parse(targetUrl)).timeout(const Duration(seconds: 12));
        if (res.statusCode != 200 || res.body.isEmpty) continue;

        final document = html_parser.parse(res.body);
        final list = <Novel>[];
        final seenPaths = <String>{};

        final items = document.querySelectorAll(
          '.page-item-detail, .li-row, .short-story, .row, .item-thumb, .novel-item, .series-item, article, .book-item, .post, .entry, .list-item, .media, .item-card, .book-card, .col-md-3, .col-6',
        );

        for (final item in items) {
          final titleEl = item.querySelector(
            '.post-title a, .tit a, .title a, h3 a, h2 a, h4 a, .entry-title a, .novel-title a, a[href*="/novel/"], a[href*="/book/"], a[href*="/series/"]',
          );
          final title = titleEl?.text.trim() ?? '';
          final path = titleEl?.attributes['href'] ?? '';
          final img = item.querySelector('img')?.attributes['data-src'] ??
              item.querySelector('img')?.attributes['src'] ??
              item.querySelector('img')?.attributes['data-lazy-src'] ??
              '';

          if (title.isNotEmpty && path.isNotEmpty && !seenPaths.contains(path)) {
            seenPaths.add(path);
            list.add(Novel(
              id: path.startsWith('http') ? path : '$cleanSite$path',
              title: title,
              coverImageUrl: img.startsWith('http') ? img : (img.isNotEmpty ? '$cleanSite$img' : ''),
              author: manifest.name,
              description: '',
              chapters: [],
              pluginId: name,
              genres: ['LNReader Source', lang.toUpperCase()],
            ));
          }
        }

        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return [];
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final runtime = await _getJsRuntime();
    if (runtime != null) {
      try {
        final jsResults = await runtime.searchNovels(siteUrl, searchTerm, pageNo, name, lang);
        if (jsResults.isNotEmpty) return jsResults;
      } catch (_) {}
    }

    return _fallbackSearchNovels(searchTerm, pageNo);
  }

  Future<List<Novel>> _fallbackSearchNovels(String searchTerm, int pageNo) async {
    final cleanSite = siteUrl.endsWith('/') ? siteUrl.substring(0, siteUrl.length - 1) : siteUrl;
    final candidates = [
      '$cleanSite/?s=${Uri.encodeComponent(searchTerm)}&post_type=wp-manga',
      '$cleanSite/search?q=${Uri.encodeComponent(searchTerm)}',
      '$cleanSite/?s=${Uri.encodeComponent(searchTerm)}',
    ];

    for (final targetUrl in candidates) {
      try {
        final res = await _client.get(Uri.parse(targetUrl)).timeout(const Duration(seconds: 12));
        if (res.statusCode != 200 || res.body.isEmpty) continue;

        final document = html_parser.parse(res.body);
        final list = <Novel>[];
        final seenPaths = <String>{};

        final items = document.querySelectorAll(
          '.c-tabs-item__content, .page-item-detail, .li-row, .short-story, article, .novel-item, .post, .entry, .book-item',
        );

        for (final item in items) {
          final titleEl = item.querySelector(
            '.post-title a, .tit a, .title a, h3 a, h2 a, h4 a, .entry-title a, .novel-title a',
          );
          final title = titleEl?.text.trim() ?? '';
          final path = titleEl?.attributes['href'] ?? '';
          final img = item.querySelector('img')?.attributes['data-src'] ??
              item.querySelector('img')?.attributes['src'] ??
              item.querySelector('img')?.attributes['data-lazy-src'] ??
              '';

          if (title.isNotEmpty && path.isNotEmpty && !seenPaths.contains(path)) {
            seenPaths.add(path);
            list.add(Novel(
              id: path.startsWith('http') ? path : '$cleanSite$path',
              title: title,
              coverImageUrl: img.startsWith('http') ? img : (img.isNotEmpty ? '$cleanSite$img' : ''),
              author: manifest.name,
              description: '',
              chapters: [],
              pluginId: name,
              genres: ['LNReader Source', lang.toUpperCase()],
            ));
          }
        }

        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return [];
  }

  @override
  Future<List<Novel>> getAllNovels({BuildContext? context}) async {
    return popularNovels(1, context: context);
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final runtime = await _getJsRuntime();
    if (runtime != null) {
      try {
        final res = await runtime.parseNovel(siteUrl, novelPath, name, lang);
        if (res != null) return res;
      } catch (_) {}
    }

    return _fallbackParseNovel(novelPath);
  }

  Future<Novel> _fallbackParseNovel(String novelPath) async {
    final cleanSite = siteUrl.endsWith('/') ? siteUrl.substring(0, siteUrl.length - 1) : siteUrl;
    final url = novelPath.startsWith('http') ? novelPath : '$cleanSite$novelPath';
    final res = await _client.get(Uri.parse(url));
    final document = html_parser.parse(res.body);

    final title = document.querySelector('.post-title h1, h1.tit, h1.title, h1, .entry-title')?.text.trim() ?? manifest.name;
    final cover = document.querySelector('.summary_image img, .pic img, .poster img, .cover img, .book-cover img')?.attributes['src'] ?? '';
    final author = document.querySelector('.author-content a, .author a, .info a')?.text.trim() ?? manifest.name;
    final summary = document.querySelector('.description-summary, .intro, .summary, .description, .entry-content')?.text.trim() ?? '';

    final chapters = <Chapter>[];
    final chapterEls = document.querySelectorAll(
      '.wp-manga-chapter a, .chapter-list li a, #list-chapter a, .chapters-list a, .chapter-item a, ul.chapters a, .list-chapters a, table a[href*="chapter"], .version-chap a, li.a-item a',
    );

    for (int i = 0; i < chapterEls.length; i++) {
      final el = chapterEls[i];
      final cTitle = el.text.trim();
      final cPath = el.attributes['href'] ?? '';
      if (cPath.isNotEmpty && cTitle.isNotEmpty) {
        chapters.add(Chapter(
          id: cPath.startsWith('http') ? cPath : '$cleanSite$cPath',
          title: cTitle,
          releaseDate: '',
          chapterNumber: i + 1,
        ));
      }
    }

    return Novel(
      id: url,
      title: title,
      coverImageUrl: cover.startsWith('http') ? cover : (cover.isNotEmpty ? '$cleanSite$cover' : ''),
      author: author,
      description: summary,
      chapters: chapters,
      pluginId: name,
      genres: ['LNReader Source', lang.toUpperCase()],
    );
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final runtime = await _getJsRuntime();
    if (runtime != null) {
      try {
        final res = await runtime.parseChapter(siteUrl, chapterPath);
        if (res.isNotEmpty && !res.contains('Failed to parse')) return res;
      } catch (_) {}
    }

    return _fallbackParseChapter(chapterPath);
  }

  Future<String> _fallbackParseChapter(String chapterPath) async {
    final cleanSite = siteUrl.endsWith('/') ? siteUrl.substring(0, siteUrl.length - 1) : siteUrl;
    final url = chapterPath.startsWith('http') ? chapterPath : '$cleanSite$chapterPath';
    final res = await _client.get(Uri.parse(url));
    final document = html_parser.parse(res.body);

    final contentEl = document.querySelector(
      '.reading-content, #chapter-container, #txt, .text-left, .chapter-content, #arr_text, .entry-content, .content, .chapter-body, #chapter-content, .text-content',
    );
    return contentEl?.innerHtml ?? '<p>Failed to load chapter content.</p>';
  }
}

class LnReaderJsEngine {
  static const String manifestUrl = 'https://raw.githubusercontent.com/LNReader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json';
  static const String _prefsKey = 'lnreader_plugins_manifest_cache';

  static Future<int> syncAndRegisterPlugins() async {
    int registeredCount = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonStr = prefs.getString(_prefsKey);

      try {
        final res = await http.get(Uri.parse(manifestUrl)).timeout(const Duration(seconds: 15));
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          jsonStr = res.body;
          await prefs.setString(_prefsKey, jsonStr);
        }
      } catch (_) {}

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = json.decode(jsonStr);
        for (final item in list) {
          try {
            final manifest = LnReaderPluginManifest.fromJson(item);
            if (manifest.id.isNotEmpty && manifest.name.isNotEmpty) {
              final plugin = LnReaderDynamicPlugin(manifest);
              PluginRegistry.register(plugin);
              registeredCount++;
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    return registeredCount;
  }
}
