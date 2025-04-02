import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';

class ChapterNavigation extends StatelessWidget {
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;
  final bool isLoading;
  final ReaderSettings readerSettings;

  const ChapterNavigation({
    super.key,
    required this.onPreviousChapter,
    required this.onNextChapter,
    required this.isLoading,
    required this.readerSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton(
            onPressed: isLoading ? null : onPreviousChapter,
            style: TextButton.styleFrom(
              foregroundColor: readerSettings.textColor.withOpacity(
                isLoading ? 0.5 : 1.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
            child: Row(
              children: const [
                Icon(Icons.arrow_back_ios, size: 16),
                SizedBox(width: 8),
                Text('Anterior'),
              ],
            ),
          ),
          TextButton(
            onPressed: isLoading ? null : onNextChapter,
            style: TextButton.styleFrom(
              foregroundColor: readerSettings.textColor.withOpacity(
                isLoading ? 0.5 : 1.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
            child: Row(
              children: const [
                Text('Próximo'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
