import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChapterDisplaySkeleton extends StatelessWidget {
  const ChapterDisplaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final highlightColor = theme.colorScheme.surfaceContainer;
    final random = Random();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final lineSpacing = 20.0;
        final lineHeight = 12.0;
        final titleHeight = 24.0;
        final titleBottomPadding = 24.0;
        final contentPaddingVertical = 20.0;
        final contentPaddingHorizontal = 16.0;
        final totalUsableHeight =
            screenHeight -
            contentPaddingVertical * 2 -
            titleHeight -
            titleBottomPadding;

        final lineCount =
            (totalUsableHeight / (lineHeight + lineSpacing)).floor();

        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: contentPaddingHorizontal,
              vertical: contentPaddingVertical,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: screenWidth * 0.7,
                  height: titleHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                SizedBox(height: titleBottomPadding),
                ...List.generate(lineCount, (index) {
                  final lineWidth =
                      screenWidth * (0.6 + random.nextDouble() * 0.3);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Container(
                      width: lineWidth,
                      height: lineHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
