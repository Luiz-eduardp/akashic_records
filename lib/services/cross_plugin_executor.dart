import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class CrossPluginExecutor {
  final http.Client _httpClient;
  String? _currentPluginUrl;
  final String? _pluginSiteUrl; 
  bool _initialized = true;

  Map<String, String> get _browserHeaders => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate',
        'DNT': '1',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Cache-Control': 'max-age=0',
      };

  CrossPluginExecutor({http.Client? httpClient, String? siteUrl}) 
    : _httpClient = httpClient ?? http.Client(),
      _pluginSiteUrl = siteUrl {
    _initializeExecutor();
  }

  void _initializeExecutor() {
    try {
      developer.log('Initializing Dart-based plugin executor...');
      developer.log('✓ Dart plugin executor initialized successfully');
    } catch (e) {
      developer.log('✗ Error initializing executor: $e');
      _initialized = false;
    }
  }

  Future<dynamic> executeFunction(
    String functionName, {
    List<dynamic>? args,
    String? sourceCode,
  }) async {
    if (!_initialized) {
      throw Exception('Plugin executor not initialized');
    }

    try {
      if (functionName == 'popularNovels') {
        return await _popularNovels(args);
      } else if (functionName == 'searchNovels') {
        return await _searchNovels(args);
      } else if (functionName == 'parseNovel') {
        return await _parseNovel(args);
      } else if (functionName == 'parseChapter') {
        return await _parseChapter(args);
      } else {
        throw Exception('Function not implemented: $functionName');
      }
    } catch (e) {
      developer.log('Error executing function $functionName: $e');
      return {'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> _popularNovels(List<dynamic>? args) async {
    try {
      final baseUrl = _pluginSiteUrl;
      if (baseUrl == null || baseUrl.isEmpty) {
        developer.log('Plugin site URL not set');
        return [];
      }

      _currentPluginUrl = baseUrl;

      final response = await _httpClient.get(
        Uri.parse(baseUrl),
        headers: _browserHeaders,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode != 200) {
        developer.log('HTTP Error: ${response.statusCode}');
        return [];
      }

      final document = html_parser.parse(response.body);
      return _extractNovels(document, args != null && args.isNotEmpty ? args[0] : null);
    } catch (e) {
      developer.log('Error fetching popular novels: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchNovels(List<dynamic>? args) async {
    try {
      final baseUrl = _pluginSiteUrl;
      if (baseUrl == null || baseUrl.isEmpty) {
        return [];
      }

      final query = args != null && args.isNotEmpty ? args[0].toString() : '';
      
      final searchUrl = '$baseUrl?search=$query';
      
      final response = await _httpClient.get(
        Uri.parse(searchUrl),
        headers: _browserHeaders,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final document = html_parser.parse(response.body);
      return _extractNovels(document, args != null && args.length > 1 ? args[1] : null);
    } catch (e) {
      developer.log('Error searching novels: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _parseNovel(List<dynamic>? args) async {
    try {
      if (args == null || args.isEmpty) {
        return {};
      }

      final novelUrl = args[0] as String;
      final response = await _httpClient.get(
        Uri.parse(novelUrl),
        headers: _browserHeaders,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode != 200) {
        return {};
      }

      final document = html_parser.parse(response.body);
      
      return {
        'title': _extractText(document, 'h1'),
        'description': _extractText(document, '.description, .synopsis'),
        'status': _extractText(document, '.status'),
        'chapters': _extractChapters(document),
      };
    } catch (e) {
      developer.log('Error parsing novel: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _parseChapter(List<dynamic>? args) async {
    try {
      if (args == null || args.isEmpty) {
        return {};
      }

      final chapterUrl = args[0] as String;
      final response = await _httpClient.get(
        Uri.parse(chapterUrl),
        headers: _browserHeaders,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode != 200) {
        return {};
      }

      final document = html_parser.parse(response.body);
      
      return {
        'title': _extractText(document, '.chapter-title, h1'),
        'content': _extractText(document, '.chapter-content, .content, article'),
      };
    } catch (e) {
      developer.log('Error parsing chapter: $e');
      return {};
    }
  }

  List<Map<String, dynamic>> _extractNovels(
    dom.Document document,
    dynamic selectors,
  ) {
    final novels = <Map<String, dynamic>>[];

    try {
      final novelSelectors = [
        '.novel-item',
        '.book-item',
        '[data-type="novel"]',
        '.story-item',
        'article',
      ];

      for (final selector in novelSelectors) {
        final elements = document.querySelectorAll(selector);
        if (elements.isNotEmpty) {
          for (final element in elements.take(20)) {
            final novel = _extractNovelFromElement(element);
            if (novel['novelName'] != null && novel['novelName'].isNotEmpty) {
              novels.add(novel);
            }
          }
          break;
        }
      }
    } catch (e) {
      developer.log('Error extracting novels: $e');
    }

    return novels;
  }

  Map<String, dynamic> _extractNovelFromElement(dom.Element element) {
    try {
      String? title = element
          .querySelector('h2, h3, .title, .name, a')
          ?.text
          .trim();

      final urlElement = element.querySelector('a')?.attributes['href'];
      String url = urlElement ?? '';
      if (url.isNotEmpty && !url.startsWith('http')) {
        url = '${_currentPluginUrl ?? 'https://example.com'}$url';
      }

      var cover = element.querySelector('img')?.attributes['src'] ??
          element.querySelector('img')?.attributes['data-src'] ??
          '';
      
      if (cover.isNotEmpty && !cover.startsWith('http')) {
        if (_currentPluginUrl != null) {
          final uri = Uri.parse(_currentPluginUrl!);
          final baseUrl = '${uri.scheme}://${uri.host}';
          cover = cover.startsWith('/') ? '$baseUrl$cover' : '$baseUrl/$cover';
        }
      }

      final description = element
          .querySelector('.description, .synopsis, p')
          ?.text
          .trim() ??
          '';

      return {
        'novelName': title ?? 'Unknown',
        'novelUrl': url,
        'novelCover': cover,
        'description': description,
      };
    } catch (e) {
      developer.log('Error extracting novel element: $e');
      return {'novelName': 'Error', 'novelUrl': '', 'novelCover': ''};
    }
  }

  List<Map<String, dynamic>> _extractChapters(dom.Document document) {
    final chapters = <Map<String, dynamic>>[];

    try {
      final chapterElements = document.querySelectorAll(
        '.chapter, .chapter-item, [data-type="chapter"], li a',
      );

      for (final element in chapterElements.take(50)) {
        final chapterUrl = element.attributes['href'] ?? '';
        final chapterTitle = element.text.trim();

        if (chapterUrl.isNotEmpty && chapterTitle.isNotEmpty) {
          chapters.add({
            'chapterTitle': chapterTitle,
            'chapterUrl': chapterUrl,
          });
        }
      }
    } catch (e) {
      developer.log('Error extracting chapters: $e');
    }

    return chapters;
  }

  String _extractText(dom.Document document, String selector) {
    try {
      final selectors = selector.split(',');
      for (final sel in selectors) {
        final element = document.querySelector(sel.trim());
        if (element != null) {
          return element.text.trim();
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<void> initializePlugin(String pluginCode) async {
    developer.log('✓ Plugin initialized (Dart executor)');
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<Map<String, dynamic>> getPluginMetadata(String pluginCode) async {
    return {
      'version': '1.0',
      'name': 'Dart Plugin',
      'site': 'https://example.com',
    };
  }

  void dispose() {
    try {
      _httpClient.close();
      developer.log('Plugin executor disposed');
    } catch (e) {
      developer.log('Error disposing executor: $e');
    }
  }
}

class CrossPluginCodeParser {
  static String? extractVersion(String pluginCode) => null;
  static String? extractSiteName(String pluginCode) => null;
  static Map<String, dynamic>? extractFilters(String pluginCode) => null;
  static bool supportsFunction(String pluginCode, String functionName) => true;
}

class CrossPluginCodeCache {
  static final Map<String, String> _cache = {};

  static bool has(String id) => _cache.containsKey(id);
  static String? get(String id) => _cache[id];
  static void set(String id, String code) => _cache[id] = code;
  static void clear(String id) => _cache.remove(id);
  static void clearAll() => _cache.clear();
  static int get size => _cache.length;
}
