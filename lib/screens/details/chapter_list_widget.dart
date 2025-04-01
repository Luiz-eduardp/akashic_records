import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';

class ChapterListWidget extends StatelessWidget {
  final List<Chapter> chapters;
  final Function(String) onChapterTap;
  final String? lastReadChapterId;

  const ChapterListWidget({
    super.key,
    required this.chapters,
    required this.onChapterTap,
    this.lastReadChapterId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chapters.length,
      separatorBuilder:
          (context, index) => Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final isLastRead = chapter.id == lastReadChapterId;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChapterTap(chapter.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      chapter.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isLastRead ? FontWeight.bold : FontWeight.normal,
                        color:
                            isLastRead
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isLastRead)
                    Icon(Icons.bookmark, color: theme.colorScheme.secondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
