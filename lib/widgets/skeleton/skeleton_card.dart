import 'package:flutter/material.dart';

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonLine(context, theme, widthFactor: 0.8),
            const SizedBox(height: 10),
            _buildSkeletonLine(context, theme, widthFactor: 0.6),
            const SizedBox(height: 20),
            _buildSkeletonLine(context, theme),
            const SizedBox(height: 10),
            _buildSkeletonLine(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLine(
    BuildContext context,
    ThemeData theme, {
    double widthFactor = 1.0,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * widthFactor,
      height: 10,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
