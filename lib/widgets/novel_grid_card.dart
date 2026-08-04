import 'package:flutter/material.dart';
import 'package:akashic_records/widgets/optimized_network_image.dart';
import 'package:akashic_records/screens/novel_detail_screen.dart';

class NovelGridCard extends StatelessWidget {
  final dynamic novel;
  final VoidCallback? onTap;
  final VoidCallback? onContinue;
  final VoidCallback? onRemove;
  final bool dismissible;
  final String? heroTag;
  final int? unreadCount;

  const NovelGridCard({
    super.key,
    required this.novel,
    this.onTap,
    this.onContinue,
    this.onRemove,
    this.dismissible = false,
    this.heroTag,
    this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRead = novel.lastReadChapterId != null;

    double progress = 0;
    if (novel.chapters.isNotEmpty && hasRead) {
      final lastIdx = novel.chapters.indexWhere((c) => c.id == novel.lastReadChapterId);
      if (lastIdx >= 0) progress = (lastIdx + 1) / novel.chapters.length;
    }

    Widget content = GestureDetector(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NovelDetailScreen(novel: novel)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: heroTag != null
                      ? Hero(
                          tag: heroTag!,
                          child: OptimizedNetworkImage(
                            novel.coverImageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: Container(
                              color: theme.colorScheme.surfaceVariant,
                            ),
                          ),
                        )
                      : OptimizedNetworkImage(
                          novel.coverImageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: Container(
                            color: theme.colorScheme.surfaceVariant,
                          ),
                        ),
                ),
                if (hasRead && progress > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: FloatingActionButton.small(
                    heroTag: 'play_${novel.id}',
                    backgroundColor: theme.colorScheme.primary,
                    onPressed: onContinue,
                    child: Icon(
                      hasRead ? Icons.play_arrow : Icons.menu_book,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                if (unreadCount != null && (unreadCount ?? 0) > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unreadCount! > 99 ? '99+' : '${unreadCount!}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            novel.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            novel.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (hasRead && progress > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );

    if (dismissible && onRemove != null) {
      return Dismissible(
        key: Key('fav_${novel.id}'),
        direction: DismissDirection.up,
        onDismissed: (_) => onRemove!(),
        child: content,
      );
    }

    return content;
  }
}
