import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';

typedef ChapterTap = void Function(Chapter chapter, int index);

class ChapterList extends StatefulWidget {
  final List<Chapter> chapters;
  final Set<String> readChapters;
  final ChapterTap onTap;

  const ChapterList({
    super.key,
    required this.chapters,
    required this.readChapters,
    required this.onTap,
  });

  @override
  State<ChapterList> createState() => _ChapterListState();
}

class _ChapterListState extends State<ChapterList> {
  @override
  Widget build(BuildContext context) {
    final originalIndices = List<int>.generate(
      widget.chapters.length,
      (i) => i,
    );
    final paired = List.generate(
      widget.chapters.length,
      (i) => MapEntry(widget.chapters[i], originalIndices[i]),
    );
    paired.sort((a, b) {
      final Chapter ca = a.key;
      final Chapter cb = b.key;
      if ((ca.releaseDate?.isNotEmpty ?? false) &&
          (cb.releaseDate?.isNotEmpty ?? false)) {
        try {
          final da = DateTime.tryParse(ca.releaseDate!);
          final db = DateTime.tryParse(cb.releaseDate!);
          if (da != null && db != null) return db.compareTo(da);
        } catch (_) {}
        return cb.releaseDate!.compareTo(ca.releaseDate!);
      }

      if ((ca.chapterNumber != null) && (cb.chapterNumber != null)) {
        return (cb.chapterNumber ?? 0).compareTo(ca.chapterNumber ?? 0);
      }

      return b.value.compareTo(a.value);
    });
    return ListView.separated(
      itemCount: paired.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final ch = paired[i].key;
        final originalIndex = paired[i].value;
        final isRead = widget.readChapters.contains(ch.id);
        return ListTile(
          title: Text(ch.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: ch.releaseDate != null ? Text(ch.releaseDate!) : null,
          trailing:
              isRead
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
          onTap: () => widget.onTap(ch, originalIndex),
        );
      },
    );
  }
}
