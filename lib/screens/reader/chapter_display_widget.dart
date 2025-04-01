import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as htmlParser;
import 'dart:ui';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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

class _ChapterDisplayState extends State<ChapterDisplay> {
  String? _cleanedContent;
  List<String> _paragraphs = [];
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int _currentFocusedIndex = 0;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _cleanedContent = _cleanChapterContent(widget.chapterContent);
    _splitIntoParagraphs();

    _itemPositionsListener.itemPositions.addListener(() {
      if (_isScrolling) return;

      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final mostVisibleIndex =
            positions.reduce((a, b) {
              if (a.itemLeadingEdge < 0 && b.itemLeadingEdge >= 0) {
                return b;
              } else if (b.itemLeadingEdge < 0 && a.itemLeadingEdge >= 0) {
                return a;
              } else {
                return a.itemLeadingEdge.abs() < b.itemLeadingEdge.abs()
                    ? a
                    : b;
              }
            }).index;

        if (mostVisibleIndex != _currentFocusedIndex) {
          setState(() {
            _currentFocusedIndex = mostVisibleIndex;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChapterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.chapterContent != widget.chapterContent ||
        oldWidget.readerSettings != widget.readerSettings) {
      _cleanedContent = _cleanChapterContent(widget.chapterContent);
      _splitIntoParagraphs();
      _scrollToIndex(_currentFocusedIndex, animate: false);
    }
  }

  String _cleanChapterContent(String? content) {
    if (content == null || content.isEmpty) {
      return "";
    }

    final document = htmlParser.parse(content);

    for (final element in document.querySelectorAll('p')) {
      if (element.text.trim().isEmpty) {
        element.remove();
      }
    }

    for (final element in document.querySelectorAll('.ad-container')) {
      element.remove();
    }
    for (final element in document.querySelectorAll('.ads')) {
      element.remove();
    }

    for (final element in document.querySelectorAll('*')) {
      if (element.text.toLowerCase().contains('discord.com')) {
        element.remove();
      }
    }

    for (final element in document.querySelectorAll('*')) {
      if (element.children.isEmpty && element.text.trim().isEmpty) {
        element.remove();
      }
    }

    return document.body?.innerHtml ?? "";
  }

  void _splitIntoParagraphs() {
    if (_cleanedContent == null || _cleanedContent!.isEmpty) {
      _paragraphs = [];
      return;
    }

    final document = htmlParser.parse(_cleanedContent);
    _paragraphs =
        document.querySelectorAll('p').map((e) => e.innerHtml).toList();
  }

  void _scrollToIndex(int index, {bool animate = true}) async {
    if (_paragraphs.isEmpty) return;

    if (index < 0) {
      index = 0;
    } else if (index >= _paragraphs.length) {
      index = _paragraphs.length - 1;
    }

    setState(() {
      _currentFocusedIndex = index;
    });

    _isScrolling = true;

    try {
      await _scrollController.scrollTo(
        index: index,
        duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    } finally {
      _isScrolling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final readerSettings = widget.readerSettings;

    return ScrollablePositionedList.builder(
      itemCount: _paragraphs.length,
      itemScrollController: _scrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        final isFocused =
            readerSettings.focusMode && index == _currentFocusedIndex;
        final paragraph = _paragraphs[index];

        return GestureDetector(
          onTap: () {
            _scrollToIndex(index);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 40.0),
            child: AnimatedScale(
              scale: isFocused ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (readerSettings.focusMode && !isFocused)
                    Positioned.fill(
                      child: ClipRect(
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: readerSettings.backgroundColor.withOpacity(
                              0.7,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Html(
                    data: paragraph,
                    style: {
                      "body": Style(
                        fontSize: FontSize(readerSettings.fontSize),
                        fontFamily: readerSettings.fontFamily,
                        lineHeight: LineHeight(readerSettings.lineHeight),
                        textAlign: readerSettings.textAlign,
                        color: readerSettings.textColor.withOpacity(
                          readerSettings.focusMode && !isFocused ? 0.4 : 1.0,
                        ),
                        fontWeight: readerSettings.fontWeight,
                      ),
                      "h1": Style(
                        fontSize: FontSize(readerSettings.fontSize + 6),
                        color: readerSettings.textColor.withOpacity(
                          readerSettings.focusMode && !isFocused ? 0.4 : 1.0,
                        ),
                      ),
                      "h2": Style(
                        fontSize: FontSize(readerSettings.fontSize + 4),
                        color: readerSettings.textColor.withOpacity(
                          readerSettings.focusMode && !isFocused ? 0.4 : 1.0,
                        ),
                      ),
                      "p": Style(
                        margin: Margins.only(bottom: 0),
                        color: readerSettings.textColor.withOpacity(
                          readerSettings.focusMode && !isFocused ? 0.4 : 1.0,
                        ),
                      ),
                      "a": Style(
                        textDecoration: TextDecoration.underline,
                        color: readerSettings.textColor.withOpacity(
                          readerSettings.focusMode && !isFocused ? 0.4 : 1.0,
                        ),
                      ),
                      "b": Style(
                        fontWeight: FontWeight.bold,
                        color: readerSettings.textColor.withOpacity(
                          readerSettings.focusMode && !isFocused ? 0.4 : 1.0,
                        ),
                      ),
                      "strong": Style(
                        fontWeight: FontWeight.bold,
                        color: readerSettings.textColor.withOpacity(
                          readerSettings.focusMode && !isFocused ? 0.4 : 1.0,
                        ),
                      ),
                    },
                    onLinkTap: (
                      String? url,
                      Map<String, String> attributes,
                      dom.Element? element,
                    ) {
                      if (url != null) {
                        debugPrint("Abrindo URL: $url");
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
