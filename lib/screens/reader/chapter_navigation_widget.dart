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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 2.0,
            ),
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
          if (isLoading)
            Container(
              color: navigationColor.withOpacity(0.7),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
        ],
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
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor:
            isEnabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
        disabledForegroundColor: colorScheme.onSurfaceVariant,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color:
                isEnabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color:
                  isEnabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
