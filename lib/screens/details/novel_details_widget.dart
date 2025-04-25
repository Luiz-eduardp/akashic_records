import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'chapter_list_widget.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_html/flutter_html.dart';

class NovelDetailsWidget extends StatefulWidget {
  final Novel novel;
  final String? lastReadChapterId;
  final int? lastReadChapterIndex;
  final VoidCallback? onContinueReading;
  final Function(String) onChapterTap;

  const NovelDetailsWidget({
    super.key,
    required this.novel,
    required this.lastReadChapterId,
    required this.lastReadChapterIndex,
    this.onContinueReading,
    required this.onChapterTap,
    String? loadingErrorMessage,
    Future<void> Function()? onRetryLoad,
  });

  @override
  State<NovelDetailsWidget> createState() => _NovelDetailsWidgetState();
}

class _NovelDetailsWidgetState extends State<NovelDetailsWidget> {
  bool _showFullSynopsis = false;
  late List<String> _paragraphs;
  Set<String> _readChapterIds = {};
  bool _isLoading = true;
  bool _isSynopsisHTML = false;

  @override
  void initState() {
    super.initState();
    _isSynopsisHTML = _isHTML(widget.novel.description);
    _paragraphs = _splitSynopsis(widget.novel.description);
    _loadData();
  }

  bool _isHTML(String text) {
    return text.startsWith('<') && text.endsWith('>');
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadReadChapterIdsFromHistory();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadReadChapterIdsFromHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = 'history_${widget.novel.id}';
    final historyString = prefs.getString(historyKey) ?? '[]';
    List<dynamic> history = List<dynamic>.from(jsonDecode(historyString));

    Set<String> readIds = {};
    for (var item in history) {
      readIds.add(item['chapterId']);
    }

    setState(() {
      _readChapterIds = readIds;
    });
  }

  Future<void> _saveReadChapterIds() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'read_chapters_${widget.novel.id}';
    await prefs.setStringList(key, _readChapterIds.toList());
  }

  List<String> _splitSynopsis(String synopsis) {
    if (_isSynopsisHTML) {
      return [synopsis];
    } else {
      List<String> paragraphs =
          synopsis.split('\n').where((p) => p.trim().isNotEmpty).toList();
      if (paragraphs.length >= 2) {
        return paragraphs;
      } else if (paragraphs.length == 1) {
        int mid = paragraphs[0].length ~/ 2;
        return [paragraphs[0].substring(0, mid), paragraphs[0].substring(mid)];
      } else {
        return ["", ""];
      }
    }
  }

  void _markAsRead(String chapterId) {
    setState(() {
      if (_readChapterIds.contains(chapterId)) {
        _readChapterIds.remove(chapterId);
      } else {
        _readChapterIds.add(chapterId);
      }
      _saveReadChapterIds();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String firstParagraph = _paragraphs.isNotEmpty ? _paragraphs[0] : '';
    final bool hasMoreThanOneParagraph = _paragraphs.length > 1;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ).createShader(
                        Rect.fromLTRB(0, 0, rect.width, rect.height),
                      );
                    },
                    blendMode: BlendMode.darken,
                    child: CachedNetworkImage(
                      imageUrl: widget.novel.coverImageUrl,
                      fit: BoxFit.cover,
                      errorWidget:
                          (context, url, error) => Image.network(
                            'https://placehold.co/400x450.png?text=Sem%20Capa',
                            fit: BoxFit.cover,
                          ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 16),
                      FractionallySizedBox(
                        widthFactor: 0.4,
                        child: AspectRatio(
                          aspectRatio: 0.7,
                          child: Card(
                            elevation: 8,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: widget.novel.coverImageUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) =>
                                      Container(color: Colors.grey.shade300),
                              errorWidget:
                                  (context, url, error) =>
                                      const Center(child: Icon(Icons.error)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.novel.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 3,
                              color: Colors.black87,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      if (widget.novel.author != null &&
                          widget.novel.author.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            widget.novel.author.startsWith('por')
                                ? widget.novel.author
                                : 'por ${widget.novel.author}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white70,
                              shadows: [
                                Shadow(
                                  blurRadius: 2,
                                  color: Colors.black54,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Text(
                        widget.novel.status.name.toString().translate,
                        style: theme.textTheme.titleSmall?.copyWith(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumo'.translate,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _isSynopsisHTML
                    ? Html(
                      data:
                          _showFullSynopsis
                              ? widget.novel.description
                              : firstParagraph,
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          textAlign: TextAlign.justify,
                          lineHeight: LineHeight.number(1.5),
                          fontSize: FontSize(
                            theme.textTheme.bodyMedium!.fontSize!,
                          ),
                          color: theme.textTheme.bodyMedium!.color,
                        ),
                      },
                    )
                    : Text(
                      _showFullSynopsis
                          ? widget.novel.description
                          : firstParagraph,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      textAlign: TextAlign.justify,
                      overflow: TextOverflow.fade,
                    ),
                if (hasMoreThanOneParagraph && !_isSynopsisHTML)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showFullSynopsis = !_showFullSynopsis;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 0,
                        ),
                        child: Text(
                          _showFullSynopsis
                              ? 'Ver Menos'.translate
                              : 'Ver Mais'.translate,
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                if (widget.onContinueReading != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onContinueReading,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Continuar Leitura'.translate),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Capítulos:'.translate +
                      ' ${widget.novel.numberOfChapters == 0 ? 0 : widget.novel.numberOfChapters.toString()}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ChapterListWidget(
                    novelId: widget.novel.id,
                    chapters: widget.novel.chapters,
                    onChapterTap: widget.onChapterTap,
                    lastReadChapterId: widget.lastReadChapterId,
                    readChapterIds: _readChapterIds,
                    onMarkAsRead: _markAsRead,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
