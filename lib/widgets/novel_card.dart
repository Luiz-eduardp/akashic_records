import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

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
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: _buildCoverImage(context, novel.coverImageUrl),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      novel.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (novel.author != null && novel.author.isNotEmpty)
                      Text(
                        novel.author,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        novel.pluginId,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context, String coverImageUrl) {
    ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget placeholderWidget = Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainer,
      child: Container(color: Colors.white),
    );

    Widget errorWidget = Container(
      color: colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          size: 48,
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
    );

    if (coverImageUrl.startsWith('data:image')) {
      final imageData = coverImageUrl.split(',').last;
      final bytes = base64Decode(imageData);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => errorWidget,
      );
    } else {
      return CachedNetworkImage(
        imageUrl:
            coverImageUrl.isNotEmpty
                ? coverImageUrl
                : 'https://placehold.co/400x600.png?text=Cover%20Not%20Found',
        fit: BoxFit.cover,
        placeholder: (context, url) => placeholderWidget,
        errorWidget: (context, url, error) => errorWidget,
      );
    }
  }
}
