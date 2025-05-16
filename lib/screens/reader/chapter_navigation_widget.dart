import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/i18n/i18n.dart';

class ChapterNavigation extends StatelessWidget {
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;
  final bool isLoading;
  final ReaderSettings readerSettings;
  final int currentChapterIndex;
  final List<Chapter> chapters;
  final String novelId;
  final Function(String) onChapterTap;
  final String? lastReadChapterId;
  final Set<String> readChapterIds;
  final Function(String) onMarkAsRead;
  final Color navigationColor;

  const ChapterNavigation({
    super.key,
    required this.onPreviousChapter,
    required this.onNextChapter,
    required this.isLoading,
    required this.readerSettings,
    required this.currentChapterIndex,
    required this.chapters,
    required this.novelId,
    required this.onChapterTap,
    this.lastReadChapterId,
    this.readChapterIds = const {},
    required this.onMarkAsRead,
    required this.navigationColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool canGoPrevious = !isLoading && currentChapterIndex > 0;
    final bool canGoNext =
        !isLoading && currentChapterIndex < chapters.length - 1;

    return Material(
      color: navigationColor,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavigationButton(
              context: context,
              onPressed: canGoPrevious ? onPreviousChapter : null,
              icon: Icons.arrow_back_ios_new_rounded,
              label: 'Anterior'.translate,
              isEnabled: canGoPrevious,
              theme: theme,
              colorScheme: colorScheme,
            ),
            IconButton(
              icon: const Icon(Icons.list_rounded),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              tooltip: 'Lista de Capítulos'.translate,
              color: colorScheme.onSurfaceVariant,
            ),
            _buildNavigationButton(
              context: context,
              onPressed: canGoNext ? onNextChapter : null,
              icon: Icons.arrow_forward_ios_rounded,
              label: 'Próximo'.translate,
              isEnabled: canGoNext,
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required ThemeData theme,
    required ColorScheme colorScheme,
    bool isEnabled = true,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 24,
        color:
            isEnabled
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color:
              isEnabled
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        backgroundColor:
            isEnabled ? colorScheme.primaryContainer : Colors.transparent,
        disabledForegroundColor: colorScheme.onSurfaceVariant,
        disabledIconColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
