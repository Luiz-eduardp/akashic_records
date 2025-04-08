import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';

class ChapterNavigation extends StatelessWidget {
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;
  final bool isLoading;
  final ReaderSettings readerSettings;
  final int currentChapterIndex;
  final List<Chapter> chapters;

  const ChapterNavigation({
    super.key,
    required this.onPreviousChapter,
    required this.onNextChapter,
    required this.isLoading,
    required this.readerSettings,
    required this.currentChapterIndex,
    required this.chapters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(
            onPressed:
                isLoading || currentChapterIndex <= 0
                    ? null
                    : onPreviousChapter,
            icon: Icon(
              Icons.arrow_back_ios,
              size: 16,
              color:
                  (isLoading || currentChapterIndex <= 0)
                      ? theme.colorScheme.onSurface.withOpacity(0.3)
                      : theme.colorScheme.primary,
            ),
            label: Text(
              'Anterior'.translate,
              style: TextStyle(
                color:
                    (isLoading || currentChapterIndex <= 0)
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
          TextButton.icon(
            onPressed:
                isLoading || currentChapterIndex >= chapters.length - 1
                    ? null
                    : onNextChapter,
            icon: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color:
                  (isLoading || currentChapterIndex >= chapters.length - 1)
                      ? theme.colorScheme.onSurface.withOpacity(0.3)
                      : theme.colorScheme.primary,
            ),
            label: Text(
              'Próximo'.translate,
              style: TextStyle(
                color:
                    (isLoading || currentChapterIndex >= chapters.length - 1)
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
      ),
    );
  }
}
