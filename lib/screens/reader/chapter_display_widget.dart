import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int _currentFocusedIndex = 0;
  WebViewController? _webViewController;
  String _currentHtmlContent = "";

  static const double _headerMargin = 20.0;
  static const double _bottomMargin = 20.0;

  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _processContent();
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);

    _webViewController = WebViewController();
    _initializeWebViewController();
  }

  Future<void> _initializeWebViewController() async {
    await _webViewController!.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _webViewController!.enableZoom(false);
    await _webViewController!.setBackgroundColor(Colors.transparent);

    _webViewController!.setNavigationDelegate(
      NavigationDelegate(
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
        debugPrint("Erro ao injetar JavaScript: $e");
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

  void _onItemPositionsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      final firstVisibleIndex = positions
          .where((position) => position.itemLeadingEdge >= 0)
          .map((position) => position.index)
          .reduce((value, element) => value < element ? value : element);

      setState(() {
        _currentFocusedIndex = firstVisibleIndex;
      });
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(
      _onItemPositionsChanged,
    );
    _refreshController.dispose();
    super.dispose();
  }

  void _processContent() {
    final cleanedContent = _cleanChapterContent(widget.chapterContent);
    _splitIntoParagraphs(cleanedContent);
  }

  String _cleanChapterContent(String? content) {
    if (content == null || content.isEmpty) {
      return "";
    }

    final document = htmlParser.parse(content);

    const selectorsToRemove = ['p:empty', '.ad-container', '.ads'];
    for (final selector in selectorsToRemove) {
      document
          .querySelectorAll(selector)
          .forEach((element) => element.remove());
    }

    document
        .querySelectorAll('*')
        .where((element) => element.text.toLowerCase().contains('discord.com'))
        .forEach((element) => element.remove());

    document.querySelectorAll('div').forEach((element) {
      if (element.children.length == 1 &&
          element.attributes.isEmpty &&
          element.text.trim().isEmpty) {
        element.remove();
      }
    });

    return document.body?.innerHtml ?? "";
  }

  void _splitIntoParagraphs(String cleanedContent) {
    final document = htmlParser.parse(cleanedContent);
    _paragraphs =
        document.querySelectorAll('p').map((e) => e.innerHtml).toList();
  }

  void _updateFocusedIndex(int delta) {
    final newIndex = (_currentFocusedIndex + delta).clamp(
      0,
      _paragraphs.length - 1,
    );
    setState(() {
      _currentFocusedIndex = newIndex;
    });
    if (newIndex > _currentFocusedIndex) {
      _scrollToIndex(newIndex);
    } else {
      _scrollToIndex(newIndex);
    }
  }

  void _scrollToIndex(int index, {bool animate = true}) async {
    if (_paragraphs.isEmpty) return;

    final validIndex = index.clamp(0, _paragraphs.length - 1);

    try {
      await _scrollController.scrollTo(
        index: validIndex,
        duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    } finally {}
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
      await _webViewController!.loadHtmlString(newHtmlContent);
      _currentHtmlContent = newHtmlContent;
    }
  }

  Future<void> _onRefresh() async {
    _processContent();
    await updateWebViewContent();

    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final scrollDelta = pointerSignal.scrollDelta.dy;
          _updateFocusedIndex(scrollDelta > 0 ? 1 : -1);
        }
      },
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: LongPressDraggable(
          hapticFeedbackOnStart: false,
          axis: Axis.vertical,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: SizedBox.shrink(),
          child: Column(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: WebViewWidget(controller: _webViewController!),
                ),
              ),
            ],
          ),
          onDragUpdate: (details) {},
        ),
      ),
    );
  }

  String _colorToHtmlColor(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }
}

class RefreshController {
  RefreshController({required bool initialRefresh});

  void refreshCompleted() {}

  void dispose() {}
}
