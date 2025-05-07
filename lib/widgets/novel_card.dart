import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NovelCard extends StatelessWidget {
  final Novel novel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NovelCard({
    super.key,
    required this.novel,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AspectRatio(
                    aspectRatio: 2 / 3,
                    child: CachedNetworkImage(
                      imageUrl:
                          novel.coverImageUrl.isNotEmpty
                              ? novel.coverImageUrl
                              : 'https://placehold.co/400x600.png?text=Cover%20Not%20Found',
                      fit: BoxFit.cover,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      placeholder:
                          (context, url) => Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.secondary,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Image.network(
                            'https://placehold.co/400x600.png?text=Cover%20Not%20Found',
                            fit: BoxFit.cover,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                          ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (novel.author != null && novel.author.isNotEmpty)
                    Text(
                      novel.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    novel.pluginId,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
