import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class NovelGridSkeletonWidget extends StatelessWidget {
  final int itemCount;
  final double? aspectRatio;

  const NovelGridSkeletonWidget({
    super.key,
    this.itemCount = 4,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[600]! : Colors.grey[100]!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 150).floor().clamp(2, 4);
        final itemWidth = constraints.maxWidth / crossAxisCount;
        final itemHeight = aspectRatio ?? itemWidth * 1.4;

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: itemWidth / itemHeight,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  Container(
                    width: double.infinity,
                    height: 14.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  const SizedBox(height: 4.0),

                  Container(
                    width: itemWidth * 0.6,
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
