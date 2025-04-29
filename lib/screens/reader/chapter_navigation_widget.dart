import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final bool canGoPrevious = !isLoading && currentChapterIndex > 0;
    final bool canGoNext =
        !isLoading && currentChapterIndex < chapters.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        NavigationButton(
          onPressed: canGoPrevious ? onPreviousChapter : null,
          icon: Icons.arrow_back_ios,
          label: 'Anterior'.translate,
          isEnabled: canGoPrevious,
        ),
        Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
                tooltip: 'Lista de Capítulos'.translate,
              ),
        ),
        NavigationButton(
          onPressed: canGoNext ? onNextChapter : null,
          icon: Icons.arrow_forward_ios,
          label: 'Próximo'.translate,
          isEnabled: canGoNext,
        ),
      ],
    );
  }
}

class NavigationButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isEnabled;

  const NavigationButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16,
        color:
            isEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.3),
      ),
      label: Text(
        label,
        style: TextStyle(
          color:
              isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        enabledMouseCursor:
            isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      ),
    );
  }
}
