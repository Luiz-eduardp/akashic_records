import 'package:flutter/material.dart';

class ReaderControlsBar extends StatelessWidget {
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onOpenChapters;
  final VoidCallback onOpenSettings;
  final VoidCallback onSave;
  final VoidCallback onToggleTts;
  final bool ttsPlaying;

  const ReaderControlsBar({
    super.key,
    required this.onPrev,
    required this.onNext,
    required this.onOpenChapters,
    required this.onOpenSettings,
    required this.onSave,
    required this.onToggleTts,
    required this.ttsPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.98),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Previous',
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrev,
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Chapters',
                  icon: const Icon(Icons.list),
                  onPressed: onOpenChapters,
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Save offline',
                  icon: const Icon(Icons.download),
                  onPressed: onSave,
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: onToggleTts,
                  backgroundColor: ttsPlaying ? color : null,
                  child: Icon(ttsPlaying ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings),
                  onPressed: onOpenSettings,
                ),
              ],
            ),
            IconButton(
              tooltip: 'Next',
              icon: const Icon(Icons.chevron_right),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}
