import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/widgets/skeleton.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';

class NovelHeader extends StatelessWidget {
  final Novel novel;
  final bool loading;
  const NovelHeader({super.key, required this.novel, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isFav = novel.isFavorite;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child:
                loading
                    ? const LoadingSkeleton.square()
                    : (novel.coverImageUrl.isNotEmpty
                        ? Image.network(
                          novel.coverImageUrl,
                          width: 96,
                          height: 128,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                width: 96,
                                height: 128,
                                color: Colors.grey,
                              ),
                        )
                        : Container(
                          width: 96,
                          height: 128,
                          color: Colors.grey,
                        )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          loading
                              ? const LoadingSkeleton.rect(height: 22)
                              : Text(
                                novel.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                    ),
                    IconButton(
                      tooltip: 'favorites'.translate,
                      icon: Icon(isFav ? Icons.star : Icons.star_border),
                      onPressed: () async {
                        try {
                          final exists = appState.localNovels.any(
                            (n) => n.id == novel.id,
                          );
                          if (!exists) {
                            final toSave = novel;
                            toSave.isFavorite = true;
                            await appState.addOrUpdateNovel(toSave);
                          } else {
                            await appState.toggleFavorite(novel.id);
                          }
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (!loading && novel.author.isNotEmpty)
                  Text(
                    '${'by'.translate} ${novel.author}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else if (loading)
                  const LoadingSkeleton.rect(height: 14),
                const SizedBox(height: 8),
                loading
                    ? const LoadingSkeleton.rect(height: 56)
                    : Text(
                      novel.description,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
