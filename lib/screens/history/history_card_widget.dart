import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:akashic_records/i18n/i18n.dart';

class HistoryCardWidget extends StatelessWidget {
  final String novelTitle;
  final String chapterTitle;
  final String pluginId;
  final DateTime lastRead;
  final VoidCallback onTap;

  const HistoryCardWidget({
    Key? key,
    required this.novelTitle,
    required this.chapterTitle,
    required this.pluginId,
    required this.lastRead,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(lastRead);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                novelTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                chapterTitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      pluginId.isNotEmpty
                          ? pluginId
                          : 'Plugin desativado'.translate,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
