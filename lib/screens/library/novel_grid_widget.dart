import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/widgets/novel_card.dart';
import 'package:akashic_records/screens/library/novel_grid_skeleton_widget.dart';

class NovelGridWidget extends StatelessWidget {
  final List<Novel> novels;
  final bool isLoading;
  final String? errorMessage;
  final ScrollController scrollController;
  final Function(Novel) onNovelTap;
  final Function(Novel) onNovelLongPress;

  const NovelGridWidget({
    super.key,
    required this.novels,
    required this.isLoading,
    required this.errorMessage,
    required this.scrollController,
    required this.onNovelTap,
    required this.onNovelLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && novels.isEmpty) {
      return NovelGridSkeletonWidget(itemCount: 8);
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    if (novels.isEmpty) {
      return LayoutBuilder(
        builder: (context, viewportConstraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 50,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Nenhuma novel encontrada.".translate,
                      style: TextStyle(color: Theme.of(context).disabledColor),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: GridView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.7,
        ),
        itemCount: novels.length,
        itemBuilder: (context, index) {
          final novel = novels[index];
          return NovelCard(
            novel: novel,
            onTap: () => onNovelTap(novel),
            onLongPress: () => onNovelLongPress(novel),
          );
        },
      ),
    );
  }
}
