import 'package:flutter/material.dart';
import 'package:akashic_records/models/novel.dart';
import 'package:akashic_records/widgets/novel_card.dart';

class FavoriteGridWidget extends StatelessWidget {
  final List<Novel> favoriteNovels;
  final Function(Novel, String) onNovelTap;
  final String Function(Novel) getPluginIdForNovel;
  final Future<void> Function() onRefresh;

  const FavoriteGridWidget({
    super.key,
    required this.favoriteNovels,
    required this.onNovelTap,
    required this.getPluginIdForNovel,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (favoriteNovels.isEmpty) {
      return const Center(child: Text("Você não possui favoritos!"));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          int crossAxisCount = (constraints.maxWidth / 150).floor().clamp(2, 4);

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.7,
            ),
            itemCount: favoriteNovels.length,
            itemBuilder: (context, index) {
              final novel = favoriteNovels[index];
              final pluginId = getPluginIdForNovel(novel);
              return NovelCard(
                novel: novel,
                onTap: () => onNovelTap(novel, pluginId),
              );
            },
          );
        },
      ),
    );
  }
}
