import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';

class ChapterNavigation extends StatefulWidget {
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;
  final bool isLoading;
  final ReaderSettings readerSettings;
  final int currentChapterIndex;
  final List<Chapter> chapters;
  final String novelId;
  final Function(String) onChapterTap;
  final String? lastReadChapterId;
  final Set<String> readChapterIds;
  final Function(String) onMarkAsRead;

  const ChapterNavigation({
    super.key,
    required this.onPreviousChapter,
    required this.onNextChapter,
    required this.isLoading,
    required this.readerSettings,
    required this.currentChapterIndex,
    required this.chapters,
    required this.novelId,
    required this.onChapterTap,
    this.lastReadChapterId,
    this.readChapterIds = const {},
    required this.onMarkAsRead,
  });

  @override
  State<ChapterNavigation> createState() => _ChapterNavigationState();
}

class _ChapterNavigationState extends State<ChapterNavigation> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TextButton.icon(
          onPressed:
              widget.isLoading || widget.currentChapterIndex <= 0
                  ? null
                  : widget.onPreviousChapter,
          icon: Icon(
            Icons.arrow_back_ios,
            size: 16,
            color:
                (widget.isLoading || widget.currentChapterIndex <= 0)
                    ? theme.colorScheme.onSurface.withOpacity(0.3)
                    : theme.colorScheme.primary,
          ),
          label: Text(
            'Anterior'.translate,
            style: TextStyle(
              color:
                  (widget.isLoading || widget.currentChapterIndex <= 0)
                      ? theme.colorScheme.onSurface.withOpacity(0.3)
                      : theme.colorScheme.primary,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
        ),
        TextButton.icon(
          onPressed:
              widget.isLoading ||
                      widget.currentChapterIndex >= widget.chapters.length - 1
                  ? null
                  : widget.onNextChapter,
          icon: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color:
                (widget.isLoading ||
                        widget.currentChapterIndex >=
                            widget.chapters.length - 1)
                    ? theme.colorScheme.onSurface.withOpacity(0.3)
                    : theme.colorScheme.primary,
          ),
          label: Text(
            'Próximo'.translate,
            style: TextStyle(
              color:
                  (widget.isLoading ||
                          widget.currentChapterIndex >=
                              widget.chapters.length - 1)
                      ? theme.colorScheme.onSurface.withOpacity(0.3)
                      : theme.colorScheme.primary,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
