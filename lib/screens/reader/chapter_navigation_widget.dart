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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton(
            onPressed:
                isLoading || currentChapterIndex <= 0
                    ? null
                    : onPreviousChapter,
            style: TextButton.styleFrom(
              foregroundColor: readerSettings.textColor.withOpacity(
                isLoading ? 0.5 : 1.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios, size: 16),
                const SizedBox(width: 8),
                Text('Anterior'.translate),
              ],
            ),
          ),
          TextButton(
            onPressed:
                isLoading || currentChapterIndex >= chapters.length - 1
                    ? null
                    : onNextChapter,
            style: TextButton.styleFrom(
              foregroundColor: readerSettings.textColor.withOpacity(
                isLoading ? 0.5 : 1.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
            child: Row(
              children: [
                Text('Próximo'.translate),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
