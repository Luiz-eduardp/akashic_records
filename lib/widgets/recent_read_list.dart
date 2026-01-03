import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/widgets/optimized_network_image.dart';

typedef OpenReaderCallback = void Function(Novel novel, int chapterIndex);

class RecentReadList extends StatelessWidget {
  final List<Map<String, dynamic>> recentReadChapters;
  final OpenReaderCallback onOpenReader;

  const RecentReadList({super.key, required this.recentReadChapters, required this.onOpenReader});

  @override
  Widget build(BuildContext context) {
    if (recentReadChapters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.menu_book, size: 48, color: Colors.grey.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('no_novels_stored'.translate, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentReadChapters.length,
      itemBuilder: (context, index) {
        final entry = recentReadChapters[index];
        final Novel novel = entry['novel'];
        final chapter = entry['chapter'];
        final chapIndex = entry['index'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: OptimizedNetworkImage(
                novel.coverImageUrl,
                width: 50,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(novel.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${'chapter'.translate}: ${chapter.title}', maxLines: 1),
            trailing: FilledButton.tonal(
              onPressed: () => onOpenReader(novel, chapIndex),
              child: Text('continue'.translate),
            ),
          ),
        );
      },
    );
  }
}
