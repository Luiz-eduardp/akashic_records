import 'package:flutter/material.dart';
import 'package:akashic_records/screens/reader/reader_settings_modal_widget.dart';

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
          ElevatedButton(
            onPressed: isLoading ? null : onPreviousChapter,
            style: ElevatedButton.styleFrom(
              backgroundColor: readerSettings.backgroundColor,
              foregroundColor: readerSettings.textColor,
            ),
            child: const Text('Anterior'),
          ),
          ElevatedButton(
            onPressed: isLoading ? null : onNextChapter,
            style: ElevatedButton.styleFrom(
              backgroundColor: readerSettings.backgroundColor,
              foregroundColor: readerSettings.textColor,
            ),
            child: const Text('Próximo'),
          ),
        ],
      ),
    );
  }
}
