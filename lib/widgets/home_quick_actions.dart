import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/screens/reading_history_screen.dart';

class HomeQuickActions extends StatelessWidget {
  final int localEpubCount;
  final int localEpubChapters;

  const HomeQuickActions({super.key, required this.localEpubCount, required this.localEpubChapters});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      spacing: 12,
      children: [
        Card(
          elevation: 0,
          color: colorScheme.secondaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Icon(Icons.folder_zip_outlined, color: colorScheme.onSecondaryContainer),
            title: Text('local_epubs'.translate, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer)),
            subtitle: Text('local_epub_info'.translate.replaceAll('{count}', '$localEpubCount').replaceAll('{chapters}', '$localEpubChapters'), style: TextStyle(color: colorScheme.onSecondaryContainer.withOpacity(0.7))),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSecondaryContainer),
            onTap: () => Navigator.pushNamed(context, '/local_epubs'),
          ),
        ),
        Card(
          elevation: 0,
          color: colorScheme.tertiaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Icon(Icons.history, color: colorScheme.onTertiaryContainer),
            title: Text('reading_history'.translate, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onTertiaryContainer)),
            subtitle: Text('reading_history_desc'.translate, style: TextStyle(color: colorScheme.onTertiaryContainer.withOpacity(0.7))),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onTertiaryContainer),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReadingHistoryScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
}
