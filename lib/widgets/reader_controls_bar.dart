import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:akashic_records/i18n/i18n.dart';

class ReaderControlsBar extends StatelessWidget {
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onOpenChapters;
  final VoidCallback onOpenSettings;
  final VoidCallback onSave;
  final VoidCallback onToggleTts;
  final bool ttsPlaying;
  final double progress;
  final ValueChanged<double>? onScrub;
  final VoidCallback? onParallelRead;
  final VoidCallback? onSleepTimer;

  const ReaderControlsBar({
    super.key,
    required this.onPrev,
    required this.onNext,
    required this.onOpenChapters,
    required this.onOpenSettings,
    required this.onSave,
    required this.onToggleTts,
    required this.ttsPlaying,
    this.progress = 0.0,
    this.onScrub,
    this.onParallelRead,
    this.onSleepTimer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onScrub != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    color: (isDark ? colorScheme.surfaceContainer : colorScheme.surface).withOpacity(0.88),
                    child: Row(
                      children: [
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                              activeTrackColor: colorScheme.primary,
                              inactiveTrackColor: colorScheme.surfaceContainerHigh,
                              thumbColor: colorScheme.primary,
                            ),
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChanged: onScrub,
                            ),
                          ),
                        ),
                        if (onParallelRead != null)
                          IconButton(
                            icon: const Icon(Icons.vertical_split_rounded, size: 20),
                            tooltip: 'Leitor Paralelo Lado a Lado',
                            onPressed: onParallelRead,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: (isDark ? colorScheme.surfaceContainer : colorScheme.surface).withOpacity(0.92),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'no_previous_chapter'.translate,
                        icon: const Icon(Icons.chevron_left_rounded, size: 26),
                        onPressed: onPrev,
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'chapters'.translate,
                            icon: const Icon(Icons.format_list_bulleted_rounded),
                            onPressed: onOpenChapters,
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.surfaceContainerHigh.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: 'download'.translate,
                            icon: const Icon(Icons.file_download_outlined),
                            onPressed: onSave,
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.surfaceContainerHigh.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filled(
                            tooltip: ttsPlaying ? 'pause' : 'play',
                            onPressed: onToggleTts,
                            style: IconButton.styleFrom(
                              backgroundColor: ttsPlaying ? colorScheme.error : colorScheme.primary,
                              foregroundColor: ttsPlaying ? colorScheme.onError : colorScheme.onPrimary,
                            ),
                            icon: Icon(
                              ttsPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 26,
                            ),
                          ),
                          if (onSleepTimer != null) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              tooltip: 'sleep_timer'.translate,
                              icon: const Icon(Icons.timer_outlined, size: 22),
                              onPressed: onSleepTimer,
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.surfaceContainerHigh.withOpacity(0.6),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: 'settings'.translate,
                            icon: const Icon(Icons.tune_rounded),
                            onPressed: onOpenSettings,
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.surfaceContainerHigh.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      IconButton.filledTonal(
                        tooltip: 'no_next_chapter'.translate,
                        icon: const Icon(Icons.chevron_right_rounded, size: 26),
                        onPressed: onNext,
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
