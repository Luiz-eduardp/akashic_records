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
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.surfaceVariant,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AspectRatio(
                    aspectRatio: 2 / 3,
                    child: _buildCoverImage(
                      context,
                      novel.coverImageUrl,
                      constraints,
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
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (novel.author != null && novel.author.isNotEmpty)
                    Text(
                      novel.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    novel.pluginId,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildCoverImage(
    BuildContext context,
    String coverImageUrl,
    BoxConstraints constraints,
  ) {
    ThemeData theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    if (coverImageUrl.startsWith('data:image')) {
      final imageData = coverImageUrl.split(',').last;
      final bytes = base64Decode(imageData);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage(context, constraints, colorScheme);
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl:
            coverImageUrl.isNotEmpty
                ? coverImageUrl
                : 'https://placehold.co/400x600.png?text=Cover%20Not%20Found',
        fit: BoxFit.cover,
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        placeholder:
            (context, url) => Shimmer.fromColors(
              baseColor:
                  isDarkMode ? Colors.grey[700]! : colorScheme.surfaceVariant,
              highlightColor:
                  isDarkMode ? Colors.grey[600]! : colorScheme.onInverseSurface,
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                color: Colors.grey,
              ),
            ),
        errorWidget:
            (context, url, error) =>
                _buildErrorImage(context, constraints, colorScheme),
      );
    }
  }

  Widget _buildErrorImage(
    BuildContext context,
    BoxConstraints constraints,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      color: colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
