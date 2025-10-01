import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';

typedef ChapterTap = void Function(Chapter chapter, int index);
typedef ChapterLongPress = void Function(Chapter chapter, int index);

class ChapterList extends StatefulWidget {
  final List<Chapter> chapters;
  final Set<String> readChapters;
  final ChapterTap onTap;
  final ChapterLongPress? onLongPressToggleRead;

  const ChapterList({
    super.key,
    required this.chapters,
    required this.readChapters,
    required this.onTap,
    this.onLongPressToggleRead,
  });

  @override
  State<ChapterList> createState() => _ChapterListState();
}

class _ChapterListState extends State<ChapterList> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: widget.chapters.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final ch = widget.chapters[i];
        final originalIndex = i;
        final isRead = widget.readChapters.contains(ch.id);
        return ListTile(
          title: Text(ch.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: ch.releaseDate != null ? Text(ch.releaseDate!) : null,
          trailing:
              isRead
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
          onTap: () => widget.onTap(ch, originalIndex),
          onLongPress:
              widget.onLongPressToggleRead == null
                  ? null
                  : () => widget.onLongPressToggleRead!(ch, originalIndex),
        );
      },
    );
  }
}
