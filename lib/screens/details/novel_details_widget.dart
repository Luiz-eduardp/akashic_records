import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'chapter_list_widget.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class NovelDetailsWidget extends StatefulWidget {
  final Novel novel;
  final String? lastReadChapterId;
  final int? lastReadChapterIndex;
  final VoidCallback? onContinueReading;
  final Function(String) onChapterTap;
  final String? loadingErrorMessage;
  final Future<void> Function()? onRetryLoad;

  const NovelDetailsWidget({
    super.key,
    required this.novel,
    required this.lastReadChapterId,
    required this.lastReadChapterIndex,
    this.onContinueReading,
    required this.onChapterTap,
    this.loadingErrorMessage,
    this.onRetryLoad,
  });

  @override
  State<NovelDetailsWidget> createState() => _NovelDetailsWidgetState();
}

class _NovelDetailsWidgetState extends State<NovelDetailsWidget>
    with AutomaticKeepAliveClientMixin {
  bool _showFullSynopsis = false;
  late List<String> _paragraphs;
  Set<String> _readChapterIds = {};
  bool _isLoading = true;
  bool _isSynopsisHTML = false;

  @override
  bool get wantKeepAlive => true;

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
    try {
      _readChapterIds = await _loadReadChapterIdsFromHistory();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Set<String>> _loadReadChapterIdsFromHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = 'history_${widget.novel.id}';
      final historyString = prefs.getString(historyKey) ?? '[]';
      List<dynamic> history = List<dynamic>.from(jsonDecode(historyString));

      Set<String> readIds = {};
      for (var item in history) {
        if (item is Map && item.containsKey('chapterId')) {
          readIds.add(item['chapterId'].toString());
        }
        if (item is Map && item.containsKey('dateRead')) {
          try {
            final formatter = DateFormat('yyyy/MM/dd');
            final dateRead = formatter.parse(item['dateRead'].toString());
            print('Parsed date: $dateRead');
          } catch (e) {
            print('Error parsing date: $e');
          }
        }
      }

      return readIds;
    } catch (e) {
      debugPrint('Error loading read chapter IDs: $e');
      return {};
    }
  }

  Future<void> _saveReadChapterIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'read_chapters_${widget.novel.id}';
      await prefs.setStringList(key, _readChapterIds.toList());
    } catch (e) {
      debugPrint('Error saving read chapter IDs: $e');
    }
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

  Widget _buildCoverImage(String coverImageUrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CachedNetworkImage(
          imageUrl: coverImageUrl,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.surfaceVariant,
                highlightColor: Theme.of(context).colorScheme.onInverseSurface,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
              ),
          errorWidget:
              (context, url, error) => Image.network(
                'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed',
                fit: BoxFit.cover,
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String firstParagraph = _paragraphs.isNotEmpty ? _paragraphs[0] : '';
    final bool hasMoreThanOneParagraph = _paragraphs.length > 1;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: colorScheme.surface,
        color: colorScheme.primary,
        child: LayoutBuilder(
          builder:
              (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight * 0.4,
                        maxHeight: constraints.maxHeight * 0.6,
                      ),
                      child: AspectRatio(
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
                                    Rect.fromLTRB(
                                      0,
                                      0,
                                      rect.width,
                                      rect.height,
                                    ),
                                  );
                                },
                                blendMode: BlendMode.darken,
                                child: _buildCoverImage(
                                  widget.novel.coverImageUrl,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: _buildCoverImage(
                                                widget.novel.coverImageUrl,
                                              ),
                                            ),
                                      );
                                    },
                                    child: FractionallySizedBox(
                                      widthFactor: 0.4,
                                      child: AspectRatio(
                                        aspectRatio: 0.7,
                                        child: Card(
                                          elevation: 8,
                                          clipBehavior: Clip.antiAlias,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: _buildCoverImage(
                                            widget.novel.coverImageUrl,
                                          ),
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
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          shadows: const [
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
                                        'por ${widget.novel.author.split(' ').take(2).join(' ')}',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: Colors.white70,
                                              shadows: const [
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
                                    widget.novel.status.name
                                        .toString()
                                        .translate,
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
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
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                },
                              )
                              : Text(
                                _showFullSynopsis
                                    ? widget.novel.description
                                    : firstParagraph,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                          if (hasMoreThanOneParagraph && !_isSynopsisHTML)
                            Align(
                              alignment: Alignment.bottomRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showFullSynopsis = !_showFullSynopsis;
                                  });
                                },
                                child: Text(
                                  _showFullSynopsis
                                      ? 'Ver Menos'.translate
                                      : 'Ver Mais'.translate,
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (widget.onContinueReading != null)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.onContinueReading?.call();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Continuando a leitura...'.translate,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
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
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _isLoading
                              ? Center(
                                child: CircularProgressIndicator(
                                  color: colorScheme.primary,
                                ),
                              )
                              : ChapterListWidget(
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
              ),
        ),
      ),
    );
  }
}
