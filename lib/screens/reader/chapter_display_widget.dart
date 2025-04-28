import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:html/dom.dart' as dom;

class ChapterDisplay extends StatefulWidget {
  final String? chapterContent;
  final ReaderSettings readerSettings;

  const ChapterDisplay({
    super.key,
    required this.chapterContent,
    required this.readerSettings,
  });

  @override
  State<ChapterDisplay> createState() => _ChapterDisplayState();
}

class _ChapterDisplayState extends State<ChapterDisplay>
    with AutomaticKeepAliveClientMixin {
  late Future<String> _htmlContentFuture;
  WebViewController? _webViewController;
  bool _isLoading = true;

  static const double _headerMargin = 20.0;
  static const double _bottomMargin = 20.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _htmlContentFuture = _prepareHtmlContent(
      widget.chapterContent,
      widget.readerSettings,
    );
    _initializeWebViewController();
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
                setState(() {
                  _isLoading = true;
                });
              },
              onPageFinished: (String url) async {
                await _injectJavaScript();
                setState(() {
                  _isLoading = false;
                });
              },
              onWebResourceError: (WebResourceError error) {
                if (kDebugMode) {
                  print('Web resource error: ${error.description}');
                }
                setState(() {
                  _isLoading = false;
                });
              },
            ),
          )
          ..loadHtmlString(await _htmlContentFuture);
  }

  Future<void> _injectJavaScript() async {
    await _webViewController!.runJavaScript('''
      document.addEventListener('touchstart', function(event) {
        if (event.touches.length > 1) {
          event.preventDefault();
        }
      }, { passive: false });

      document.addEventListener('touchmove', function(event) {
        if (event.touches.length > 1) {
          event.preventDefault();
        }
      }, { passive: false });

      document.addEventListener('touchend', function(event) {
        if (event.touches.length > 1) {
          event.preventDefault();
        }
      }, { passive: false });

      document.addEventListener('gesturestart', function(event) {
        event.preventDefault();
      });

      document.addEventListener('gesturechange', function(event) {
        event.preventDefault();
      });

      document.addEventListener('gestureend', function(event) {
        event.preventDefault();
      });
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

  Future<void> _injectCustomJavaScript(String? customJs) async {
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

  @override
  void didUpdateWidget(covariant ChapterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterContent != widget.chapterContent ||
        oldWidget.readerSettings != widget.readerSettings) {
      _htmlContentFuture = _prepareHtmlContent(
        widget.chapterContent,
        widget.readerSettings,
      );
      _reloadWebView();
    }
  }

  Future<void> _reloadWebView() async {
    setState(() {
      _isLoading = true;
    });
    await _webViewController?.loadHtmlString(await _htmlContentFuture);
    setState(() {
      _isLoading = false;
    });
  }

  Future<String> _prepareHtmlContent(
    String? content,
    ReaderSettings readerSettings,
  ) async {
    final cleanedContent = _cleanChapterContent(content);
    final paragraphs = _splitIntoParagraphs(cleanedContent);
    return _buildHtmlContent(readerSettings, paragraphs);
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
            -webkit-user-select: text; /* Permite seleção no iOS */
            -moz-user-select: text; /* Permite seleção no Firefox */
            -ms-user-select: text; /* Permite seleção no IE/Edge */
            user-select: text; /* Permite seleção na maioria dos navegadores */
          }
          h1 {
            font-size: ${readerSettings.fontSize + 6}px;
            color: ${_colorToHtmlColor(readerSettings.textColor)};
          }
          h2 {
            font-size: ${readerSettings.fontSize + 4}px;
            color: ${_colorToHtmlColor(readerSettings.textColor)};
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
          ${readerSettings.customCss ?? ''}
        </style>
      </head>
      <body>
        <div class="reader-content">
            ${paragraphs.join("<br><br>")}
        </div>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Stack(
      children: [
        FutureBuilder<String>(
          future: _htmlContentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {}
                },
                child: RefreshIndicator(
                  onRefresh: _reloadWebView,
                  backgroundColor: theme.colorScheme.surface,
                  color: theme.colorScheme.primary,
                  child: WebViewWidget(controller: _webViewController!),
                ),
              );
            } else {
              return Container(
                color: theme.colorScheme.surface.withOpacity(0.8),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              );
            }
          },
        ),
        if (_isLoading)
          Container(
            color: theme.colorScheme.surface.withOpacity(0.8),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _colorToHtmlColor(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
