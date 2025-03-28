import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/widgets/novel_card.dart';
import 'package:shimmer/shimmer.dart';

class NovelGridWidget extends StatelessWidget {
  final List<Novel> novels;
  final bool isLoading;
  final String? errorMessage;
  final ScrollController scrollController;
  final Function(Novel) onNovelTap;

  const NovelGridWidget({
    super.key,
    required this.novels,
    required this.isLoading,
    required this.errorMessage,
    required this.scrollController,
    required this.onNovelTap,
  });

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: double.infinity, height: 150, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: double.infinity, height: 20, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: 100, height: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (novels.isEmpty && errorMessage == null && !isLoading) {
      return LayoutBuilder(
        builder: (context, viewportConstraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: const Center(child: Text("Nenhuma novel encontrada.")),
            ),
          );
        },
      );
    }
    if (novels.isEmpty && errorMessage != null) {
      return Center(child: Text(errorMessage!));
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
        itemCount: novels.length + (isLoading ? 4 : 0),
        itemBuilder: (context, index) {
          if (index < novels.length) {
            final novel = novels[index];
            return NovelCard(novel: novel, onTap: () => onNovelTap(novel));
          } else if (isLoading && index < novels.length + 4) {
            return _buildLoadingSkeleton();
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
