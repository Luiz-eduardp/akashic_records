import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'chapter_list_widget.dart';

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
  });

  @override
  State<NovelDetailsWidget> createState() => _NovelDetailsWidgetState();
}

class _NovelDetailsWidgetState extends State<NovelDetailsWidget> {
  bool _showFullSynopsis = false;
  late List<String> _paragraphs;

  @override
  void initState() {
    super.initState();
    _paragraphs = _splitSynopsis(widget.novel.description);
  }

  List<String> _splitSynopsis(String synopsis) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final String firstParagraph = _paragraphs.isNotEmpty ? _paragraphs[0] : '';
    final bool hasMoreThanOneParagraph = _paragraphs.length > 1;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: screenWidth,
                height: 280,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      widget.novel.coverImageUrl,
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.5),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 16,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    widget.novel.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 5,
                          color: Colors.black.withOpacity(0.7),
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 16,
                child: SizedBox(
                  width: 130,
                  height: 190,
                  child: Card(
                    elevation: 10,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.novel.author != null &&
                    widget.novel.author.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      widget.novel.author.startsWith('por')
                          ? widget.novel.author
                          : 'por ${widget.novel.author}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),

                Html(
                  data:
                      _showFullSynopsis
                          ? widget.novel.description
                          : firstParagraph,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: FontSize(
                        theme.textTheme.bodyMedium?.fontSize ?? 14,
                      ),
                      lineHeight: LineHeight(1.4),
                    ),
                  },
                ),
                if (hasMoreThanOneParagraph)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showFullSynopsis = !_showFullSynopsis;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _showFullSynopsis ? 'Ver Menos' : 'Ver Mais',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Continuar Leitura'),
                    ),
                  ),

                const SizedBox(height: 16),

                Text(
                  'Capítulos:',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ChapterListWidget(
                  chapters: widget.novel.chapters,
                  onChapterTap: widget.onChapterTap,
                  lastReadChapterId: widget.lastReadChapterId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
