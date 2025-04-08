// ignore_for_file: dead_code

import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
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
  List<String> _paragraphs = [];
  WebViewController? _webViewController;
  String _currentHtmlContent = "";
  bool _isLoading = true;

  static const double _headerMargin = 20.0;
  static const double _bottomMargin = 20.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _processContent();
    _webViewController = WebViewController();
    _initializeWebViewController();
  }

  Future<void> _initializeWebViewController() async {
    await _webViewController!.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _webViewController!.enableZoom(false);
    await _webViewController!.setBackgroundColor(Colors.transparent);

    _webViewController!.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          setState(() {
            _isLoading = true;
          });
        },
        onPageFinished: (String url) async {
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
    );
    await updateWebViewContent();
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
      _processContent();
      updateWebViewContent();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _processContent() {
    String cleanedContent = _cleanChapterContent(widget.chapterContent);
    _splitIntoParagraphs(cleanedContent);
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

  void _splitIntoParagraphs(String cleanedContent) {
    final document = htmlParser.parse(cleanedContent);
    _paragraphs =
        document.querySelectorAll('p').map((e) => e.innerHtml).toList();
  }

  String _buildHtmlContent(ReaderSettings readerSettings) {
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
            text-decoration: underline;          }
          b, strong {
            font-weight: bold;
            color: ${_colorToHtmlColor(readerSettings.textColor)};
          }
          ${readerSettings.customCss ?? ''}
        </style>
      </head>
      <body>
        <div class="reader-content">
            ${_paragraphs.join("<br><br>")}
        </div>
      </body>
      </html>
    ''';
  }

  Future<void> updateWebViewContent() async {
    if (_webViewController == null) return;

    final readerSettings = widget.readerSettings;

    final newHtmlContent = _buildHtmlContent(readerSettings);

    if (newHtmlContent != _currentHtmlContent) {
      setState(() {
        _isLoading = true;
      });
      await _webViewController!.loadHtmlString(newHtmlContent);
      _currentHtmlContent = newHtmlContent;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (false) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('HTML Content (Dev Mode)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy HTML to Clipboard',
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: widget.chapterContent ?? ''),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('HTML copied to clipboard!')),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: SelectableText(
            widget.chapterContent ?? 'No content available',
            style: TextStyle(
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {}
          },
          child: RefreshIndicator(
            onRefresh: updateWebViewContent,
            backgroundColor: theme.colorScheme.surface,
            color: theme.colorScheme.primary,
            child: WebViewWidget(controller: _webViewController!),
          ),
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
}
