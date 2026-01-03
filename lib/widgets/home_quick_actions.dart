import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';

class HomeQuickActions extends StatelessWidget {
  final int localEpubCount;
  final int localEpubChapters;

  const HomeQuickActions({super.key, required this.localEpubCount, required this.localEpubChapters});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(Icons.folder_zip_outlined, color: colorScheme.onSecondaryContainer),
        title: Text('local_epubs'.translate, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer)),
        subtitle: Text('$localEpubCount arquivos, $localEpubChapters capítulos', style: TextStyle(color: colorScheme.onSecondaryContainer.withOpacity(0.7))),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSecondaryContainer),
        onTap: () => Navigator.pushNamed(context, '/local_epubs'),
      ),
    );
  }
}
