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

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CachedNetworkImage(
                    imageUrl:
                        novel.coverImageUrl.isNotEmpty
                            ? novel.coverImageUrl
                            : 'https://placehold.co/400x450.png?text=Sem%20Capa',
                    fit: BoxFit.cover,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    placeholder:
                        (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Image.network(
                          'https://placehold.co/400x450.png?text=Sem%20Capa',
                          fit: BoxFit.cover,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                        ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: novel.title,
                    child: Text(
                      novel.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (novel.author != null && novel.author.isNotEmpty)
                    Tooltip(
                      message: novel.author,
                      child: Text(
                        novel.author,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
            ),
          ],
        ),
      ),
    );
  }
}
