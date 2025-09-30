import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';

class ReaderSubheader extends StatelessWidget {
  final int wordCount;
  final String time;
  final int batteryLevel;
  final double progress;
  final Color accent;

  const ReaderSubheader({
    super.key,
    required this.wordCount,
    required this.time,
    required this.batteryLevel,
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text('${'words_read'.translate}: $wordCount')),
              Text(time),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Icon(Icons.battery_full, size: 16),
                  const SizedBox(width: 4),
                  Text(batteryLevel >= 0 ? '$batteryLevel%' : '--'),
                ],
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: progress,
          color: accent,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          minHeight: 3,
        ),
      ],
    );
  }
}
