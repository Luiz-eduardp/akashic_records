import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_js/flutter_js.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/services/core/proxy_client.dart';

class LnReaderJsRuntime {
  late final JavascriptRuntime _jsRuntime;
  final ProxyClient _proxyClient = ProxyClient();
  bool _initialized = false;

  final Map<int, dom.Node> _nodeRegistry = {};
  int _nodeCounter = 1;

  LnReaderJsRuntime() {
    _jsRuntime = getJavascriptRuntime();
  }

  Future<void> initPolyfills() async {
    if (_initialized) return;

    _jsRuntime.onMessage('_dart_cheerio_create', (dynamic htmlStr) {
      try {
        final doc = html_parser.parse(htmlStr.toString());
        final id = _nodeCounter++;
        _nodeRegistry[id] = doc;
        return id;
      } catch (_) {
        return 0;
      }
    });

    _jsRuntime.onMessage('_dart_cheerio_query', (dynamic args) {
      try {
        final map = args is String ? json.decode(args) : args;
        final int parentId = map['parentId'] ?? 0;
        final String selector = map['selector'] ?? '';

        final parentNode = _nodeRegistry[parentId];
        if (parentNode == null) return '[]';

        List<dom.Element> results = [];
        if (parentNode is dom.Document) {
          results = parentNode.querySelectorAll(selector);
        } else if (parentNode is dom.Element) {
          results = parentNode.querySelectorAll(selector);
        }

        final list = <Map<String, dynamic>>[];
        for (final el in results) {
          final id = _nodeCounter++;
          _nodeRegistry[id] = el;
          list.add({
            'id': id,
            'tag': el.localName ?? '',
            'text': el.text.trim(),
            'html': el.innerHtml,
            'attrs': el.attributes.map((k, v) => MapEntry(k.toString(), v.toString())),
          });
        }
        return json.encode(list);
      } catch (_) {
        return '[]';
      }
    });

    _jsRuntime.onMessage('_dart_fetch_url', (dynamic urlStr) async {
      try {
        final url = urlStr.toString();
        developer.log('[JsRuntime] Fetching URL: "$url"');
        final response = await _proxyClient.get(Uri.parse(url));
        developer.log('[JsRuntime] Fetch URL "$url" returned status ${response.statusCode} (${response.bodyBytes.length} bytes)');
        return '__HTTP_STATUS__:${response.statusCode}__BODY__:${response.body}';
      } catch (e) {
        developer.log('[JsRuntime] ERROR fetching URL "$urlStr": $e');
        return '__HTTP_STATUS__:500__BODY__:';
      }
    });

    final polyfills = '''
      var window = this;
      var global = this;
      var globalThis = this;

      var exports = {};
      var module = { exports: exports };

      var console = {
        log: function(msg) {},
        error: function(msg) {},
        warn: function(msg) {},
        info: function(msg) {}
      };

      function atob(str) {
        return _dart_atob(str);
      }

      function btoa(str) {
        return _dart_btoa(str);
      }

      var TextDecoder = function() {};
      TextDecoder.prototype.decode = function(bytes) {
        return String.fromCharCode.apply(null, bytes);
      };

      var TextEncoder = function() {};
      TextEncoder.prototype.encode = function(str) {
        var buf = new ArrayBuffer(str.length);
        var bufView = new Uint8Array(buf);
        for (var i = 0, strLen = str.length; i < strLen; i++) {
          bufView[i] = str.charCodeAt(i);
        }
        return bufView;
      };

      var cheerio = {
        load: function(htmlStr) {
          var docId = _dart_cheerio_create(htmlStr || '');

          function makeWrapper(nodes) {
            var wrapper = function(sel) {
              if (typeof sel === 'string') {
                var qRes = _dart_cheerio_query(JSON.stringify({ parentId: docId, selector: sel }));
                var rawList = [];
                try { rawList = JSON.parse(qRes); } catch(e) {}
                return makeWrapper(rawList);
              }
              if (sel && typeof sel === 'object') {
                if (Array.isArray(sel)) return makeWrapper(sel);
                return makeWrapper([sel]);
              }
              return makeWrapper([]);
            };

            wrapper.length = nodes.length;
            for (var i = 0; i < nodes.length; i++) {
              wrapper[i] = nodes[i];
            }

            wrapper.each = function(cb) {
              for (var i = 0; i < nodes.length; i++) {
                cb.call(makeWrapper([nodes[i]]), i, nodes[i]);
              }
              return this;
            };

            wrapper.map = function(cb) {
              var res = [];
              for (var i = 0; i < nodes.length; i++) {
                res.push(cb.call(makeWrapper([nodes[i]]), i, nodes[i]));
              }
              return makeWrapper(res);
            };

            wrapper.find = function(sel) {
              var allSub = [];
              for (var i = 0; i < nodes.length; i++) {
                var qRes = _dart_cheerio_query(JSON.stringify({ parentId: nodes[i].id, selector: sel }));
                try {
                  var rawList = JSON.parse(qRes);
                  allSub = allSub.concat(rawList);
                } catch(e) {}
              }
              return makeWrapper(allSub);
            };

            wrapper.text = function() {
              if (nodes.length > 0) return nodes[0].text || '';
              return '';
            };

            wrapper.attr = function(name) {
              if (nodes.length > 0 && nodes[0].attrs) {
                return nodes[0].attrs[name] || '';
              }
              return '';
            };

            wrapper.html = function() {
              if (nodes.length > 0) return nodes[0].html || '';
              return '';
            };

            wrapper.first = function() {
              return makeWrapper(nodes.length > 0 ? [nodes[0]] : []);
            };

            wrapper.last = function() {
              return makeWrapper(nodes.length > 0 ? [nodes[nodes.length - 1]] : []);
            };

            wrapper.eq = function(idx) {
              if (idx >= 0 && idx < nodes.length) return makeWrapper([nodes[idx]]);
              return makeWrapper([]);
            };

            wrapper.get = function(idx) {
              if (idx === undefined) return nodes;
              return nodes[idx];
            };

            return wrapper;
          }

          return function(sel) {
            return makeWrapper([])(sel);
          };
        }
      };

      function require(name) {
        if (name === "cheerio" || name === "@libs/cheerio") {
          return cheerio;
        }
        if (name === "@libs/storage") {
          return {
            storage: {
              get: function(k) { return ""; },
              set: function(k, v) {},
              remove: function(k) {}
            }
          };
        }
        if (name === "@libs/novelStatus") {
          return {
            NovelStatus: {
              Ongoing: "Ongoing",
              Completed: "Completed",
              Unknown: "Unknown",
              Licensed: "Licensed",
              PublishingFinished: "Publishing Finished",
              OnHiatus: "On Hiatus"
            }
          };
        }
        if (name === "dayjs" || name.indexOf("dayjs") !== -1) {
          var dayjsFn = function(val) {
            return {
              subtract: function() { return this; },
              format: function() { return val ? String(val) : ""; }
            };
          };
          dayjsFn.default = dayjsFn;
          return dayjsFn;
        }
        if (name === "@libs/fetch" || name.indexOf("fetch") !== -1) {
          return {
            fetchApi: function(url, init) {
              var raw = _dart_fetch_url(url);
              var status = 200;
              var respStr = raw || "";
              if (respStr.indexOf("__HTTP_STATUS__:") === 0) {
                var parts = respStr.split("__BODY__:");
                status = parseInt(parts[0].replace("__HTTP_STATUS__:", ""), 10) || 200;
                respStr = parts.slice(1).join("__BODY__:");
              }
              return Promise.resolve({
                ok: status >= 200 && status < 400,
                status: status,
                statusText: status === 200 ? "OK" : "Error",
                url: url,
                text: function() { return Promise.resolve(respStr); },
                json: function() {
                  try {
                    return Promise.resolve(JSON.parse(respStr));
                  } catch(e) {
                    return Promise.resolve({});
                  }
                }
              });
            },
            fetchFile: function(url, init) {
              var raw = _dart_fetch_url(url);
              var respStr = raw || "";
              if (respStr.indexOf("__HTTP_STATUS__:") === 0) {
                var parts = respStr.split("__BODY__:");
                respStr = parts.slice(1).join("__BODY__:");
              }
              return Promise.resolve(respStr);
            }
          };
        }
        if (name === "@libs/defaultCover") {
          return { defaultCover: "https://via.placeholder.com/150" };
        }
        return {};
      }
    ''';

    _jsRuntime.evaluate(polyfills);

    _jsRuntime.onMessage('_dart_atob', (dynamic args) {
      try {
        final str = args.toString();
        return utf8.decode(base64.decode(str));
      } catch (_) {
        return '';
      }
    });

    _jsRuntime.onMessage('_dart_btoa', (dynamic args) {
      try {
        final str = args.toString();
        return base64.encode(utf8.encode(str));
      } catch (_) {
        return '';
      }
    });

    _initialized = true;
  }

  Future<bool> loadPluginScript(String pluginCode) async {
    await initPolyfills();
    try {
      final prepCode = '''
        var pluginInstance = null;
        if (typeof module !== 'undefined' && module.exports && module.exports.default) {
          pluginInstance = module.exports.default;
        } else if (typeof exports !== 'undefined' && exports.default) {
          pluginInstance = exports.default;
        } else if (typeof module !== 'undefined' && module.exports) {
          pluginInstance = module.exports;
        }

        if (typeof pluginInstance === 'function' && typeof pluginInstance.popularNovels !== 'function') {
          try {
            pluginInstance = new pluginInstance({ showLatestNovels: false, filters: {} });
          } catch(e) {}
        }
      ''';
      final evalResult = _jsRuntime.evaluate(prepCode);
      return !evalResult.isError;
    } catch (_) {
      return false;
    }
  }

  Future<List<Novel>> popularNovels(String siteUrl, int page, String pluginId, String lang) async {
    await initPolyfills();
    try {
      developer.log('[JsRuntime] Executing popularNovels page $page for "$pluginId" ($siteUrl)...');
      final evalResult = await _jsRuntime.evaluateAsync('''
        (async function() {
          var p = typeof pluginInstance !== 'undefined' ? pluginInstance : (typeof plugin !== 'undefined' ? plugin : null);
          if (p && typeof p.popularNovels === 'function') {
            var opts = { showLatestNovels: false, filters: {} };
            var res = await p.popularNovels($page, opts);
            return JSON.stringify(res);
          }
          return "[]";
        })()
      ''');

      if (!evalResult.isError && evalResult.rawResult != null) {
        final str = evalResult.rawResult.toString();
        if (str.startsWith('[')) {
          final List list = json.decode(str);
          final novels = _parseJsNovelList(list, siteUrl, pluginId, lang);
          developer.log('[JsRuntime] popularNovels for "$pluginId" parsed ${novels.length} novels');
          return novels;
        }
      } else if (evalResult.isError) {
        developer.log('[JsRuntime] ERROR evaluating popularNovels for "$pluginId": ${evalResult.stringResult}');
      }
    } catch (e) {
      developer.log('[JsRuntime] EXCEPTION in popularNovels for "$pluginId": $e');
    }
    return [];
  }

  Future<List<Novel>> searchNovels(String siteUrl, String searchTerm, int page, String pluginId, String lang) async {
    await initPolyfills();
    try {
      final sanitizedTerm = json.encode(searchTerm);
      final evalResult = await _jsRuntime.evaluateAsync('''
        (async function() {
          var p = typeof pluginInstance !== 'undefined' ? pluginInstance : (typeof plugin !== 'undefined' ? plugin : null);
          if (p && typeof p.searchNovels === 'function') {
            var opts = { showLatestNovels: false, filters: {} };
            var res = await p.searchNovels($sanitizedTerm, $page, opts);
            return JSON.stringify(res);
          }
          return "[]";
        })()
      ''');

      if (!evalResult.isError && evalResult.rawResult != null) {
        final str = evalResult.rawResult.toString();
        if (str.startsWith('[')) {
          final List list = json.decode(str);
          return _parseJsNovelList(list, siteUrl, pluginId, lang);
        }
      }
    } catch (_) {}
    return [];
  }

  Future<Novel?> parseNovel(String siteUrl, String novelPath, String pluginId, String lang) async {
    await initPolyfills();
    try {
      final sanitizedPath = json.encode(novelPath);
      final evalResult = await _jsRuntime.evaluateAsync('''
        (async function() {
          var p = typeof pluginInstance !== 'undefined' ? pluginInstance : (typeof plugin !== 'undefined' ? plugin : null);
          if (p && typeof p.parseNovel === 'function') {
            var res = await p.parseNovel($sanitizedPath);
            return JSON.stringify(res);
          }
          return "null";
        })()
      ''');

      if (!evalResult.isError && evalResult.rawResult != null) {
        final str = evalResult.rawResult.toString();
        if (str.startsWith('{')) {
          final Map map = json.decode(str);
          final title = map['name'] ?? map['title'] ?? 'Unknown Title';
          final cover = map['cover'] ?? map['coverImageUrl'] ?? '';
          final author = map['author'] ?? 'Unknown Author';
          final summary = map['summary'] ?? map['description'] ?? '';
          final rawChapters = map['chapters'] as List? ?? [];

          final chapters = <Chapter>[];
          for (int i = 0; i < rawChapters.length; i++) {
            final cMap = rawChapters[i];
            if (cMap is Map) {
              final cTitle = cMap['name'] ?? cMap['title'] ?? 'Chapter ${i + 1}';
              final cPath = cMap['path'] ?? cMap['url'] ?? cMap['id'] ?? '';
              final release = cMap['releaseTime'] ?? cMap['releaseDate'] ?? '';
              chapters.add(Chapter(
                id: cPath.toString().startsWith('http') ? cPath.toString() : '$siteUrl${cPath.toString()}',
                title: cTitle.toString(),
                releaseDate: release.toString(),
                chapterNumber: i + 1,
              ));
            }
          }

          final fullUrl = novelPath.startsWith('http') ? novelPath : '$siteUrl$novelPath';
          return Novel(
            id: fullUrl,
            title: title.toString(),
            coverImageUrl: cover.toString().startsWith('http') ? cover.toString() : (cover.toString().isNotEmpty ? '$siteUrl${cover.toString()}' : ''),
            author: author.toString(),
            description: summary.toString(),
            chapters: chapters,
            pluginId: pluginId,
            genres: ['LNReader Plugin', lang.toUpperCase()],
          );
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String> parseChapter(String siteUrl, String chapterPath) async {
    await initPolyfills();
    try {
      final sanitizedPath = json.encode(chapterPath);
      final evalResult = await _jsRuntime.evaluateAsync('''
        (async function() {
          var p = typeof pluginInstance !== 'undefined' ? pluginInstance : (typeof plugin !== 'undefined' ? plugin : null);
          if (p && typeof p.parseChapter === 'function') {
            var res = await p.parseChapter($sanitizedPath);
            return res;
          }
          return "";
        })()
      ''');

      if (!evalResult.isError && evalResult.rawResult != null) {
        return evalResult.rawResult.toString();
      }
    } catch (_) {}
    return '<p>Failed to parse chapter content.</p>';
  }

  List<Novel> _parseJsNovelList(List rawList, String siteUrl, String pluginId, String lang) {
    final list = <Novel>[];
    for (final item in rawList) {
      if (item is Map) {
        final title = item['name'] ?? item['title'] ?? '';
        final path = item['path'] ?? item['url'] ?? item['id'] ?? '';
        final cover = item['cover'] ?? item['coverImageUrl'] ?? '';

        if (title.toString().isNotEmpty && path.toString().isNotEmpty) {
          final fullId = path.toString().startsWith('http') ? path.toString() : '$siteUrl${path.toString()}';
          final fullCover = cover.toString().startsWith('http') ? cover.toString() : (cover.toString().isNotEmpty ? '$siteUrl${cover.toString()}' : '');

          list.add(Novel(
            id: fullId,
            title: title.toString(),
            coverImageUrl: fullCover,
            author: pluginId,
            description: '',
            chapters: [],
            pluginId: pluginId,
            genres: ['LNReader Plugin', lang.toUpperCase()],
          ));
        }
      }
    }
    return list;
  }

  void dispose() {
    _jsRuntime.dispose();
  }
}
