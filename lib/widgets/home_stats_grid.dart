import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';

class HomeStatsGrid extends StatelessWidget {
  final int totalWordsRead;
  final int totalChaptersRead;
  final int favoritesCount;

  const HomeStatsGrid({
    super.key,
    required this.totalWordsRead,
    required this.totalChaptersRead,
    required this.favoritesCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(context, 'words_read'.translate, '$totalWordsRead', Icons.auto_stories),
          _verticalDivider(),
          _statItem(context, 'chapters_read'.translate, '$totalChaptersRead', Icons.collections_bookmark),
          _verticalDivider(),
          _statItem(context, 'favorites'.translate, '$favoritesCount', Icons.favorite),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() => Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.3));
}
