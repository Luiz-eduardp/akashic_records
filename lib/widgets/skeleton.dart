import 'package:flutter/material.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  const LoadingSkeleton.rect({super.key, this.width = double.infinity, this.height = 12, this.borderRadius}) : _isCircle = false;
  const LoadingSkeleton.square({super.key, this.width = 48, this.height = 48, this.borderRadius}) : _isCircle = false;
  const LoadingSkeleton.circle({super.key, this.width = 40, this.height = 40, this.borderRadius}) : _isCircle = true;

  final bool _isCircle;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceVariant;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: _isCircle ? null : (borderRadius ?? BorderRadius.circular(6)),
        shape: _isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}
