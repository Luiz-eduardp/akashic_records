import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as htmlParser;

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

  @override
  void initState() {
    super.initState();
    _cleanedContent = _cleanChapterContent(widget.chapterContent);
  }

  @override
  void didUpdateWidget(covariant ChapterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.chapterContent != widget.chapterContent ||
        oldWidget.readerSettings != widget.readerSettings) {
      _cleanedContent = _cleanChapterContent(widget.chapterContent);
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child:
          _cleanedContent != null && _cleanedContent!.isNotEmpty
              ? Html(
                data: _cleanedContent,
                style: {
                  "body": Style(
                    fontSize: FontSize(widget.readerSettings.fontSize),
                    fontFamily: widget.readerSettings.fontFamily,
                    lineHeight: LineHeight(widget.readerSettings.lineHeight),
                    textAlign: widget.readerSettings.textAlign,
                    color: widget.readerSettings.textColor,
                  ),
                  "h1": Style(
                    fontSize: FontSize(widget.readerSettings.fontSize + 6),
                  ),
                  "h2": Style(
                    fontSize: FontSize(widget.readerSettings.fontSize + 4),
                  ),
                  "p": Style(margin: Margins.only(bottom: 16.0)),
                  "a": Style(
                    color: Colors.blue,
                    textDecoration: TextDecoration.underline,
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
              )
              : const SizedBox.shrink(),
    );
  }
}
