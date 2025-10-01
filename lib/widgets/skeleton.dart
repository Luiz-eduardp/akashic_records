import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool _isCircle;
  final Color? baseColor;
  final Color? highlightColor;

  const LoadingSkeleton.rect({
    super.key,
    this.width = double.infinity,
    this.height = 12,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  }) : _isCircle = false;

  const LoadingSkeleton.square({
    super.key,
    this.width = 48,
    this.height = 48,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
    required int radius,
  }) : _isCircle = false;

  const LoadingSkeleton.circle({
    super.key,
    this.width = 40,
    this.height = 40,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  }) : _isCircle = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base =
        baseColor ??
        (isDark
            ? theme.colorScheme.surface.withOpacity(0.6)
            : theme.colorScheme.surface.withOpacity(0.3));
    final highlight =
        highlightColor ??
        (isDark
            ? theme.colorScheme.background.withOpacity(0.2)
            : theme.colorScheme.background.withOpacity(0.12));
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius:
              _isCircle ? null : (borderRadius ?? BorderRadius.circular(8)),
          shape: _isCircle ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }
}
