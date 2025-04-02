import 'dart:ui';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlParser;
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
  late double _webViewHeight;

  static const double _headerMargin = 20.0;
  static const double _bottomMargin = 20.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appBarHeight = Scaffold.of(context).appBarMaxHeight ?? 0.0;
    final chapterNavigationHeight = 50.0;
    final screenHeight = MediaQuery.of(context).size.height;

    setState(() {
      _webViewHeight =
          screenHeight -
          appBarHeight -
          chapterNavigationHeight -
          _headerMargin -
          _bottomMargin;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _processContent();
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);

    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..enableZoom(false)
          ..setBackgroundColor(Colors.transparent);
    _updateWebViewContent();
  }

  @override
  void didUpdateWidget(covariant ChapterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterContent != widget.chapterContent ||
        oldWidget.readerSettings != widget.readerSettings) {
      _processContent();
      _updateWebViewContent();
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

  String _buildHtmlContent(ReaderSettings readerSettings, bool isFocused) {
    final opacity = readerSettings.focusMode && !isFocused ? 0.4 : 1.0;
    final fontWeight =
        isFocused
            ? '600'
            : (readerSettings.fontWeight == FontWeight.bold
                ? 'bold'
                : 'normal');

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body {
            margin: 40px;
            padding: 0;
            font-size: ${readerSettings.fontSize}px;
            font-family: ${readerSettings.fontFamily};
            line-height: ${readerSettings.lineHeight};
            text-align: ${readerSettings.textAlign.toString().split('.').last};
            color: ${_colorToHtmlColor(readerSettings.textColor)};
            font-weight: $fontWeight;
            opacity: $opacity;
            /* Adicionando padding para simular margem */
            padding-top: ${_headerMargin}px;
            padding-bottom: ${_bottomMargin}px;
          }
          h1 {
            font-size: ${readerSettings.fontSize + 6}px;
            color: ${_colorToHtmlColor(readerSettings.textColor)};
            opacity: $opacity;
          }
          h2 {
            font-size: ${readerSettings.fontSize + 4}px;
            color: ${_colorToHtmlColor(readerSettings.textColor)};
            opacity: $opacity;
          }
          p {
            color: ${_colorToHtmlColor(readerSettings.textColor)};
            opacity: $opacity;
          }
          a {
            color: ${_colorToHtmlColor(readerSettings.textColor)};
            text-decoration: underline;
            opacity: $opacity;
          }
          b, strong {
            font-weight: bold;
            color: ${_colorToHtmlColor(readerSettings.textColor)};
            opacity: $opacity;
          }
        </style>
      </head>
      <body>
        ${_paragraphs.join("<br><br>")}
      </body>
      </html>
    ''';
  }

  Future<void> _updateWebViewContent() async {
    if (_webViewController == null) return;

    final readerSettings = widget.readerSettings;
    final isFocused = false;

    final newHtmlContent = _buildHtmlContent(readerSettings, isFocused);

    if (newHtmlContent != _currentHtmlContent) {
      await _webViewController!.loadHtmlString(newHtmlContent);
      _currentHtmlContent = newHtmlContent;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final readerSettings = widget.readerSettings;

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final scrollDelta = pointerSignal.scrollDelta.dy;
          _updateFocusedIndex(scrollDelta > 0 ? 1 : -1);
        }
      },
      child: LongPressDraggable(
        hapticFeedbackOnStart: false,
        axis: Axis.vertical,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: SizedBox.shrink(),
        child: Column(
          children: [
            if (readerSettings.focusMode)
              ClipRect(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: readerSettings.backgroundColor.withOpacity(0.7),
                    height: _webViewHeight,
                    width: double.infinity,
                  ),
                ),
              ),

            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: WebViewWidget(controller: _webViewController!),
              ),
            ),
          ],
        ),
        onDragUpdate: (details) {
          final scrollDelta = details.delta.dy;
          _updateFocusedIndex(scrollDelta > 0 ? -1 : 1);
        },
      ),
    );
  }

  String _colorToHtmlColor(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }
}
