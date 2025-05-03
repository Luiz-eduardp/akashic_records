import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NovelListTile extends StatelessWidget {
  final Novel novel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NovelListTile({
    super.key,
    required this.novel,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ListTile(
          leading: AspectRatio(
            aspectRatio: 0.7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl:
                    novel.coverImageUrl.isNotEmpty
                        ? novel.coverImageUrl
                        : 'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed',
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Image.network(
                      'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed',
                      fit: BoxFit.cover,
                    ),
              ),
            ),
          ),
          title: Text(
            novel.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (novel.author != null && novel.author.isNotEmpty)
                Text(
                  novel.author,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                novel.pluginId,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          trailing: Icon(
            Icons.arrow_forward_ios,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
        ),
      ),
    );
  }
}
