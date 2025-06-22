import 'dart:async';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:html/dom.dart' as dom;

class ChapterDisplay extends StatefulWidget {
  final String? chapterContent;
  final String chapterId;
  final ReaderSettings readerSettings;
  final ValueNotifier<double> scrollPercentageNotifier;
  final VoidCallback? onToggleUiVisibility;

  const ChapterDisplay({
    super.key,
    required this.chapterContent,
    required this.readerSettings,
    required this.chapterId,
    required this.scrollPercentageNotifier,
    this.onToggleUiVisibility,
  });

  @override
  State<ChapterDisplay> createState() => _ChapterDisplayState();
}

class _ChapterDisplayState extends State<ChapterDisplay>
    with AutomaticKeepAliveClientMixin {
  WebViewController? _webViewController;
  bool _isLoading = true;
  double _scrollPosition = 0.0;
  String get scrollPositionKey => 'scrollPosition_${widget.chapterId}';
  late SharedPreferences _prefs;
  late String _htmlContent;
  double _contentHeight = 0.0;
  final ScrollController _scrollController = ScrollController();

  static const double _headerMargin = 20.0;
  static const double _bottomMargin = 20.0;

  bool _isUiHidden = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAsyncState();
    _scrollController.addListener(_updateScrollPercentage);
  }

  @override
  void dispose() {
    _saveScrollPositionBeforeDispose();
    _webViewController?.clearCache();
    _webViewController = null;
    _scrollController.removeListener(_updateScrollPercentage);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollPercentage() {
    if (_scrollController.hasClients && _contentHeight > 0) {
      double currentScroll = _scrollController.offset;
      double maxScrollExtent =
          _contentHeight - MediaQuery.of(context).size.height;

      if (maxScrollExtent < 0) {
        maxScrollExtent = 0;
      }

      double scrollPercentage = currentScroll / maxScrollExtent;

      if (scrollPercentage > 1.0) {
        scrollPercentage = 1.0;
      } else if (scrollPercentage < 0.0) {
        scrollPercentage = 0.0;
      }

      widget.scrollPercentageNotifier.value = scrollPercentage;
    }
  }

  Future<void> _initializeAsyncState() async {
    _prefs = await SharedPreferences.getInstance();
    _htmlContent = await _prepareHtmlContent(
      widget.chapterContent,
      widget.readerSettings,
    );
    await _loadScrollPosition();
    _initializeWebViewController();
  }

  @override
  void didUpdateWidget(covariant ChapterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterContent != widget.chapterContent ||
        oldWidget.readerSettings != widget.readerSettings) {
      _updateHtmlContent();
    }
  }

  Future<void> _updateHtmlContent() async {
    setState(() {
      _isLoading = true;
    });
    _htmlContent = await _prepareHtmlContent(
      widget.chapterContent,
      widget.readerSettings,
    );
    _reloadWebView();
  }

  Future<void> _loadScrollPosition() async {
    _scrollPosition = _prefs.getDouble(scrollPositionKey) ?? 0.0;
  }

  Future<void> _saveScrollPosition(double position) async {
    await _prefs.setDouble(scrollPositionKey, position);
  }

  Future<void> _saveScrollPositionBeforeDispose() async {
    if (_webViewController != null) {
      try {
        final result = await _webViewController!.runJavaScriptReturningResult(
          'window.saveScrollPosition();',
        );
        if (result is num) {
          await _saveScrollPosition(result.toDouble());
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to save scroll position: $e');
        }
      }
    }
  }

  Future<void> _initializeWebViewController() async {
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..enableZoom(false)
          ..setBackgroundColor(Colors.transparent)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                  });
                }
              },
              onPageFinished: (String url) async {
                await _injectJavaScript();
                _restoreScrollPosition();
                await _getContentHeight();
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              onWebResourceError: (WebResourceError error) {
                if (kDebugMode) {
                  print('Web resource error: ${error.description}');
                }
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
            ),
          )
          ..loadHtmlString(_htmlContent);

    try {
      await _webViewController!.runJavaScriptReturningResult('''
        function sendScrollPosition() {
          const scrollPosition = document.documentElement.scrollTop || document.body.scrollTop;
          return scrollPosition
        }
        ''');
    } catch (e) {
      if (kDebugMode) {
        print("error: $e");
      }
    }
  }

  Future<void> _injectJavaScript() async {
    if (_webViewController == null) return;
    await _webViewController!.runJavaScript('''
      function getScrollPosition() {
        return document.documentElement.scrollTop || document.body.scrollTop;
      }

      function saveScrollPosition() {
        const scrollPosition = getScrollPosition();
        console.log("saving scroll position: " + scrollPosition);
        return scrollPosition;
      }

      function getContentHeight() {
        return document.documentElement.scrollHeight || document.body.scrollHeight;
      }

      window.getScrollPosition = getScrollPosition;
      window.saveScrollPosition = saveScrollPosition;
      window.getContentHeight = getContentHeight;
    ''');
    _injectCustomJavaScript(widget.readerSettings.customJs);

    final appState = Provider.of<AppState>(context, listen: false);
    List<CustomPlugin> enabledPlugins =
        appState.customPlugins.where((plugin) => plugin.enabled).toList();

    enabledPlugins.sort((a, b) => a.priority.compareTo(b.priority));

    for (final plugin in enabledPlugins) {
      _injectCustomJavaScript(plugin.code);
    }
  }

  Future<void> _restoreScrollPosition() async {
    if (_scrollPosition > 0 && _webViewController != null) {
      try {
        await _webViewController!.runJavaScript(
          'window.scrollTo(0, $_scrollPosition);',
        );
      } catch (e) {
        if (kDebugMode) {
          print('Failed to restore scroll position: $e');
        }
      }
    }
  }

  Future<void> _injectCustomJavaScript(String? customJs) async {
    if (_webViewController == null) return;
    if (customJs != null && customJs.isNotEmpty) {
      try {
        await _webViewController?.runJavaScript(customJs);
      } catch (e) {
        if (kDebugMode) {
          debugPrint("Erro ao injetar JavaScript: $e");
        }
      }
    }
  }

  Future<void> _reloadWebView() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    if (_webViewController != null) {
      await _webViewController?.loadHtmlString(_htmlContent);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _prepareHtmlContent(
    String? content,
    ReaderSettings readerSettings,
  ) async {
    final cacheKey = '$content${readerSettings.hashCode}';
    if (_cleanedContentCache.containsKey(cacheKey)) {
      return _cleanedContentCache[cacheKey]!;
    }
    final cleanedContent = _cleanChapterContent(content);
    final paragraphs = _splitIntoParagraphs(cleanedContent);
    final htmlContent = _buildHtmlContent(readerSettings, paragraphs);
    _cleanedContentCache[cacheKey] = htmlContent;
    return htmlContent;
  }

  String _cleanChapterContent(String? content) {
    if (content == null || content.isEmpty) {
      return "";
    }

    final document = htmlParser.parse(content);

    document.querySelectorAll('script').forEach((element) => element.remove());

    document
        .querySelectorAll('noscript')
        .forEach((element) => element.remove());

    document
        .querySelectorAll('p')
        .where((element) => element.innerHtml.trim().isEmpty)
        .forEach((element) => element.remove());

    document
        .querySelectorAll('div')
        .where((element) => element.innerHtml.trim().isEmpty)
        .forEach((element) => element.remove());

    List<dom.Node> comments =
        document.body!.nodes.whereType<dom.Comment>().toList();
    for (dom.Node node in comments) {
      node.remove();
    }

    const selectorsToRemove = ['.ad-container', '.ads'];
    for (final selector in selectorsToRemove) {
      document
          .querySelectorAll(selector)
          .forEach((element) => element.remove());
    }

    document
        .querySelectorAll('*')
        .where((element) => element.text.toLowerCase().contains('discord.com'))
        .forEach((element) => element.remove());

    document
        .querySelectorAll('center[class*="ad"]')
        .forEach((element) => element.remove());

    return document.body?.innerHtml ?? "";
  }

  List<String> _splitIntoParagraphs(String cleanedContent) {
    final document = htmlParser.parse(cleanedContent);
    return document.querySelectorAll('p').map((e) => e.innerHtml).toList();
  }

  String _buildHtmlContent(
    ReaderSettings readerSettings,
    List<String> paragraphs,
  ) {
    final fontWeight =
        (readerSettings.fontWeight == FontWeight.bold ? 'bold' : 'normal');

    bool isArabic = false;
    for (final paragraph in paragraphs) {
      if (RegExp(r'[\u0600-\u06FF]').hasMatch(paragraph)) {
        isArabic = true;
        break;
      }
    }

    String directionAttribute = isArabic ? 'dir="rtl"' : '';
    String textAlignStyle = isArabic ? 'text-align: right;' : '';

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link href="https://fonts.googleapis.com/css2?family=${readerSettings.fontFamily}:ital,wght@0,100..900;1,100..900&display=swap" rel="stylesheet">
        <style>
          body {
            margin: 40px 20px 20px 20px;
            padding: 0;
            font-size: ${readerSettings.fontSize}px;
            font-family: ${readerSettings.fontFamily} !important;
            line-height: ${readerSettings.lineHeight};
            text-align: ${readerSettings.textAlign.toString().split('.').last};
            color: ${_colorToHtmlColor(readerSettings.textColor)};
            background-color: ${_colorToHtmlColor(readerSettings.backgroundColor)};
            font-weight: $fontWeight;
            padding-top: ${_headerMargin}px;
            padding-bottom: ${_bottomMargin}px;
          word-wrap: break-word;
            -webkit-user-select: text;
            -moz-user-select: text;
            -ms-user-select: text;
            user-select: text;
            $textAlignStyle
          }
          h1 {
            font-size: ${readerSettings.fontSize + 8}px; /* Aumentado */
            color: ${_colorToHtmlColor(readerSettings.textColor)};
            margin-top: 1.5em; /* Adicionado */
            margin-bottom: 0.8em; /* Adicionado */
          }
          h2 {
            font-size: ${readerSettings.fontSize + 5}px; /* Aumentado */
            color: ${_colorToHtmlColor(readerSettings.textColor)};
            margin-top: 1.2em; /* Adicionado */
            margin-bottom: 0.6em; /* Adicionado */
          }
          p {
            color: ${_colorToHtmlColor(readerSettings.textColor)};
            margin-bottom: 1em;
          }
          a {
            color: ${_colorToHtmlColor(readerSettings.textColor)};
            text-decoration: underline;
          }
          b, strong {
            font-weight: bold;
            color: ${_colorToHtmlColor(readerSettings.textColor)};
          }
          img { /* Adicionado estilo para imagens */
            max-width: 100%;
            height: auto;
            display: block;
            margin: 1em auto;
          }
          ul, ol { /* Adicionado estilo para listas */
            margin-bottom: 1em;
            padding-left: 1.5em;
          }
          li { /* Adicionado estilo para itens de lista */
            margin-bottom: 0.5em;
          }
          blockquote { /* Adicionado estilo para blockquotes */
            border-left: 4px solid ${_colorToHtmlColor(readerSettings.textColor.withOpacity(0.5))};
            padding-left: 1em;
            margin-left: 1em;
            font-style: italic;
          }
          pre { /* Adicionado estilo para código pré-formatado */
            background-color: ${_colorToHtmlColor(readerSettings.textColor.withOpacity(0.1))};
            padding: 1em;
            overflow-x: auto;
            margin-bottom: 1em;
          }
          code { /* Adicionado estilo para código */
            font-family: monospace;
          }
          table { /* Adicionado estilo para tabelas */
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 1em;
          }
          th, td { /* Adicionado estilo para células de tabela */
            border: 1px solid ${_colorToHtmlColor(readerSettings.textColor.withOpacity(0.3))};
            padding: 0.5em;
            text-align: left;
          }
          th { /* Adicionado estilo para cabeçalhos de tabela */
            background-color: ${_colorToHtmlColor(readerSettings.textColor.withOpacity(0.2))};
          }
          ${readerSettings.customCss ?? ''}
        </style>
      </head>
      <body $directionAttribute>
        <div class="reader-content">
            ${paragraphs.join("<br><br>")}
        </div>
      </body>
      </html>
    ''';
  }

  Future<void> _getContentHeight() async {
    if (_webViewController != null) {
      try {
        final result = await _webViewController!.runJavaScriptReturningResult(
          'window.getContentHeight();',
        );
        if (result is num) {
          setState(() {
            _contentHeight = result.toDouble();
          });
          print("Content height: $_contentHeight");
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to get content height: $e');
        }
      }
    }
  }

  void _toggleUiVisibility() {
    setState(() {
      _isUiHidden = !_isUiHidden;
    });
    widget.onToggleUiVisibility?.call();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onDoubleTap: _toggleUiVisibility,
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {}
              },
              child: RefreshIndicator(
                onRefresh: _reloadWebView,
                backgroundColor: theme.colorScheme.surface,
                color: theme.colorScheme.primary,
                child:
                    _webViewController != null && !_isLoading
                        ? WebViewWidget(controller: _webViewController!)
                        : Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _colorToHtmlColor(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  final Map<String, String> _cleanedContentCache = {};
}
