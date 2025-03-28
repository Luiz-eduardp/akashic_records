import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';

class ChapterListWidget extends StatelessWidget {
  final List<Chapter> chapters;
  final Function(String) onChapterTap;

  const ChapterListWidget({
    super.key,
    required this.chapters,
    required this.onChapterTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return ListTile(
          title: Text(
            chapter.title,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          onTap: () => onChapterTap(chapter.id),
        );
      },
    );
  }
}
