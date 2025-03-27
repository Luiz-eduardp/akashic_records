import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingDetailsSkeletonWidget extends StatelessWidget {
  const LoadingDetailsSkeletonWidget({super.key});

  Widget _buildImageSkeleton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(width: 150, height: 220, color: Colors.white),
    );
  }

  Widget _buildLargeImageSkeleton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 300,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextSkeleton(
    BuildContext context, {
    double width = double.infinity,
    double height = 16,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(width: width, height: height, color: Colors.white),
    );
  }

  Widget _buildButtonSkeleton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(width: double.infinity, height: 48, color: Colors.white),
    );
  }

  Widget _buildListSkeleton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
      child: Column(
        children: List.generate(
          5,
          (index) => ListTile(
            title: _buildTextSkeleton(context, width: 200),
            subtitle: _buildTextSkeleton(context, width: 150),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _buildLargeImageSkeleton(context),
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(child: _buildImageSkeleton(context)),
              ),
              Positioned(
                top: 250,
                left: 0,
                right: 0,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildTextSkeleton(context, height: 24),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildTextSkeleton(context, width: 150, height: 18),
                const SizedBox(height: 16),
                ...List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildTextSkeleton(context),
                  ),
                ),
                const SizedBox(height: 24),
                _buildButtonSkeleton(context),
                const SizedBox(height: 16),
                const Text(
                  'Capítulos:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildListSkeleton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
