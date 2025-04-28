import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChapterDisplaySkeleton extends StatelessWidget {
  const ChapterDisplaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[600]! : Colors.grey[100]!;
    final random = Random();

    double getRandomWidth(double maxWidth) {
      return maxWidth * 0.9;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: getRandomWidth(constraints.maxWidth * 0.8),
                    height: 24.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  ...List.generate(
                    random.nextInt(5) + 5,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: getRandomWidth(constraints.maxWidth),
                            height: 12.0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          const SizedBox(height: 4.0),

                          Container(
                            width: getRandomWidth(constraints.maxWidth),
                            height: 12.0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          const SizedBox(height: 4.0),

                          Container(
                            width: getRandomWidth(constraints.maxWidth),
                            height: 12.0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),

                          if (random.nextDouble() > 0.5)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Container(
                                width: getRandomWidth(
                                  constraints.maxWidth * 0.6,
                                ),
                                height: 12.0,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ),

                          if (random.nextDouble() > 0.7)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Container(
                                width: getRandomWidth(
                                  constraints.maxWidth * 0.8,
                                ),
                                height: 12.0,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
