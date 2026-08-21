import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/widgets/m3e/m3e_app_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ParallelReaderScreen extends StatefulWidget {
  final Novel leftNovel;
  final Novel? rightNovel;

  const ParallelReaderScreen({
    super.key,
    required this.leftNovel,
    this.rightNovel,
  });

  @override
  State<ParallelReaderScreen> createState() => _ParallelReaderScreenState();
}

class _ParallelReaderScreenState extends State<ParallelReaderScreen> {
  late Novel _leftNovel;
  Novel? _rightNovel;

  int _leftChapterIdx = 0;
  int _rightChapterIdx = 0;

  WebViewController? _leftWebController;
  WebViewController? _rightWebController;

  @override
  void initState() {
    super.initState();
    _leftNovel = widget.leftNovel;
    _rightNovel = widget.rightNovel;

    _initWebControllers();
  }

  void _initWebControllers() {
    String leftContent = 'No Content';
    if (_leftNovel.chapters.isNotEmpty && _leftChapterIdx < _leftNovel.chapters.length) {
      leftContent = _leftNovel.chapters[_leftChapterIdx].content ?? 'No Content';
    }

    _leftWebController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_buildHtmlContent(leftContent));

    if (_rightNovel != null && _rightNovel!.chapters.isNotEmpty) {
      String rightContent = 'No Content';
      if (_rightChapterIdx < _rightNovel!.chapters.length) {
        rightContent = _rightNovel!.chapters[_rightChapterIdx].content ?? 'No Content';
      }
      _rightWebController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadHtmlString(_buildHtmlContent(rightContent));
    }
  }

  String _buildHtmlContent(String content) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body {
            font-family: sans-serif;
            font-size: 17px;
            line-height: 1.6;
            padding: 16px;
            color: #333;
            background: #FAFAFA;
          }
          @media (prefers-color-scheme: dark) {
            body { background: #121212; color: #E0E0E0; }
          }
          h1, h2, h3 { color: #0EA5E9; }
          blockquote { border-left: 3px solid #0EA5E9; padding-left: 10px; margin: 12px 0; }
          pre { background: rgba(128,128,128,0.15); padding: 10px; border-radius: 8px; }
        </style>
      </head>
      <body>
        $content
      </body>
      </html>
    ''';
  }

  void _selectRightNovel() {
    final appState = Provider.of<AppState>(context, listen: false);
    final allNovels = appState.localNovels;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return ListView.builder(
          itemCount: allNovels.length,
          itemBuilder: (context, index) {
            final novel = allNovels[index];
            return ListTile(
              title: Text(novel.title),
              subtitle: Text(novel.author),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _rightNovel = novel;
                  _rightChapterIdx = 0;
                  final content = novel.chapters.isNotEmpty ? (novel.chapters[0].content ?? 'No Content') : 'No Content';
                  _rightWebController = WebViewController()
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..loadHtmlString(_buildHtmlContent(content));
                });
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final leftTitle = (_leftNovel.chapters.isNotEmpty && _leftChapterIdx < _leftNovel.chapters.length)
        ? _leftNovel.chapters[_leftChapterIdx].title
        : _leftNovel.title;

    final rightTitle = (_rightNovel != null && _rightNovel!.chapters.isNotEmpty && _rightChapterIdx < _rightNovel!.chapters.length)
        ? _rightNovel!.chapters[_rightChapterIdx].title
        : (_rightNovel?.title ?? '');

    return Scaffold(
      appBar: M3EAppBar(
        title: 'parallel_reader'.translate,
        subtitle: '${_leftNovel.title} vs ${_rightNovel?.title ?? "pick_second_book".translate}',
        actions: [
          IconButton(
            tooltip: 'pick_second_book'.translate,
            icon: const Icon(Icons.book_outlined),
            onPressed: _selectRightNovel,
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: theme.colorScheme.surfaceContainerHigh,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          leftTitle,
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        onPressed: _leftChapterIdx > 0
                            ? () {
                                setState(() {
                                  _leftChapterIdx--;
                                  final content = _leftNovel.chapters[_leftChapterIdx].content ?? '';
                                  _leftWebController?.loadHtmlString(
                                    _buildHtmlContent(content),
                                  );
                                });
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        onPressed: _leftNovel.chapters.isNotEmpty && _leftChapterIdx < _leftNovel.chapters.length - 1
                            ? () {
                                setState(() {
                                  _leftChapterIdx++;
                                  final content = _leftNovel.chapters[_leftChapterIdx].content ?? '';
                                  _leftWebController?.loadHtmlString(
                                    _buildHtmlContent(content),
                                  );
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _leftWebController != null
                      ? WebViewWidget(controller: _leftWebController!)
                      : const SizedBox(),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _rightNovel == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_stories_outlined, size: 48),
                        const SizedBox(height: 12),
                        Text('no_second_book_selected'.translate),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _selectRightNovel,
                          child: Text('pick_second_book'.translate),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: theme.colorScheme.surfaceContainerHigh,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                rightTitle,
                                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, size: 20),
                              onPressed: _rightChapterIdx > 0
                                  ? () {
                                      setState(() {
                                        _rightChapterIdx--;
                                        final content = _rightNovel!.chapters[_rightChapterIdx].content ?? '';
                                        _rightWebController?.loadHtmlString(
                                          _buildHtmlContent(content),
                                        );
                                      });
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, size: 20),
                              onPressed: _rightNovel!.chapters.isNotEmpty && _rightChapterIdx < _rightNovel!.chapters.length - 1
                                  ? () {
                                      setState(() {
                                        _rightChapterIdx++;
                                        final content = _rightNovel!.chapters[_rightChapterIdx].content ?? '';
                                        _rightWebController?.loadHtmlString(
                                          _buildHtmlContent(content),
                                        );
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _rightWebController != null
                            ? WebViewWidget(controller: _rightWebController!)
                            : const SizedBox(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
