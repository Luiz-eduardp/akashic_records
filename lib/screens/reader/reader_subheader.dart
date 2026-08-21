import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:akashic_records/i18n/i18n.dart';

class ReaderSubheader extends StatelessWidget {
  final int wordCount;
  final String time;
  final int batteryLevel;
  final double progress;
  final Color accent;
  final double wpm;
  final int sleepTimerMinutes;

  const ReaderSubheader({
    super.key,
    required this.wordCount,
    required this.time,
    required this.batteryLevel,
    required this.progress,
    required this.accent,
    this.wpm = 200.0,
    this.sleepTimerMinutes = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final actualWpm = wpm > 50 ? wpm : 200.0;
    final remainingWords = (wordCount * (1.0 - progress)).clamp(0, wordCount.toDouble());
    final estMinutesLeft = (remainingWords / actualWpm).ceil();

    final remainingText = wordCount > 0
        ? '${(progress * 100).toInt()}% • ' +
            'time_left_chapter'.translateParams({'minutes': estMinutesLeft.toString()})
        : '${(progress * 100).toInt()}%';

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: (isDark ? colorScheme.surfaceContainer : colorScheme.surface).withOpacity(0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.battery_charging_full_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          batteryLevel >= 0 ? '$batteryLevel%' : '--',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (sleepTimerMinutes > 0) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.timer_outlined, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${sleepTimerMinutes}m',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(width: 12),
                        Text(
                          'words_per_minute'.translateParams({'wpm': actualWpm.toInt().toString()}),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          remainingText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                color: accent,
                backgroundColor: colorScheme.surfaceContainerHigh,
                minHeight: 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
