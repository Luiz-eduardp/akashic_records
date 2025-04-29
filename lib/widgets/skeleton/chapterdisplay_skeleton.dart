import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChapterDisplaySkeleton extends StatelessWidget {
  const ChapterDisplaySkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[600]! : Colors.grey[100]!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final lineSpacing = 20.0;
        final lineHeight = 12.0;
        final titleHeight = 24.0;
        final titleBottomPadding = 24.0;
        final contentPadding = 10.0;
        final totalUsableHeight =
            screenHeight - contentPadding - titleHeight - titleBottomPadding;

        final lineCount =
            (totalUsableHeight / (lineHeight + lineSpacing)).floor();

        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Padding(
            padding: const EdgeInsets.all(1.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: screenWidth * 0.9,
                  height: 24.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                SizedBox(height: 24.0),
                ...List.generate(
                  lineCount,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Container(
                      width: screenWidth * 0.9,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
