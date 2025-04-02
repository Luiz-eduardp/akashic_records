import 'dart:ui';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as htmlParser;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ChapterDisplay extends StatefulWidget {
  final String? chapterContent;
  final ReaderSettings readerSettings;

  const ChapterDisplay({super.key, required this.chapterContent, required this.readerSettings});

  @override
  State<ChapterDisplay> createState() => _ChapterDisplayState();
}

class _ChapterDisplayState extends State<ChapterDisplay>
    with AutomaticKeepAliveClientMixin {
  List<String> _paragraphs = [];
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  int _currentFocusedIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _processContent();
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);
  }

  @override
  void didUpdateWidget(covariant ChapterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterContent != widget.chapterContent ||
        oldWidget.readerSettings != widget.readerSettings) {
      _processContent();
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
    _itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);
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
      document.querySelectorAll(selector).forEach((element) => element.remove());
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
    _paragraphs = document.querySelectorAll('p').map((e) => e.innerHtml).toList();
  }


  void _updateFocusedIndex(int delta) {
      final newIndex = (_currentFocusedIndex + delta).clamp(0, _paragraphs.length - 1);
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
    } finally {
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
        child: ScrollablePositionedList.builder(
          itemCount: _paragraphs.length,
          itemScrollController: _scrollController,
          itemPositionsListener: _itemPositionsListener,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          initialScrollIndex: _currentFocusedIndex,
          itemBuilder: (context, index) {
            final isFocused = readerSettings.focusMode && index == _currentFocusedIndex;
            final paragraph = _paragraphs[index];

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (readerSettings.focusMode && !isFocused)
                    Positioned.fill(
                      child: ClipRect(
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: readerSettings.backgroundColor.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  Html(
                    data: paragraph,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(readerSettings.fontSize),
                        fontFamily: readerSettings.fontFamily,
                        lineHeight: LineHeight(readerSettings.lineHeight),
                        textAlign: readerSettings.textAlign,
                        color: readerSettings.textColor.withOpacity(readerSettings.focusMode && !isFocused ? 0.4 : 1.0),
                        fontWeight: isFocused ? FontWeight.w600 : readerSettings.fontWeight,
                      ),
                      "h1": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(readerSettings.fontSize + 6),
                        color: readerSettings.textColor.withOpacity(readerSettings.focusMode && !isFocused ? 0.4 : 1.0),
                      ),
                      "h2": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(readerSettings.fontSize + 4),
                        color: readerSettings.textColor.withOpacity(readerSettings.focusMode && !isFocused ? 0.4 : 1.0),
                      ),
                      "p": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        color: readerSettings.textColor.withOpacity(readerSettings.focusMode && !isFocused ? 0.4 : 1.0),
                      ),
                      "a": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        textDecoration: TextDecoration.underline,
                        color: readerSettings.textColor.withOpacity(readerSettings.focusMode && !isFocused ? 0.4 : 1.0),
                      ),
                      "b": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontWeight: FontWeight.bold,
                        color: readerSettings.textColor.withOpacity(readerSettings.focusMode && !isFocused ? 0.4 : 1.0),
                      ),
                      "strong": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontWeight: FontWeight.bold,
                        color: readerSettings.textColor.withOpacity(readerSettings.focusMode && !isFocused ? 0.4 : 1.0),
                      ),
                    },
                    onLinkTap: (String? url, Map<String, String> attributes, dom.Element? element) {
                      if (url != null) {
                        debugPrint("Abrindo URL: $url");
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
        onDragUpdate: (details) {
          final scrollDelta = details.delta.dy;
          _updateFocusedIndex(scrollDelta > 0 ? -1 : 1);
        },
      ),
    );
  }
}