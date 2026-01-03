import 'package:flutter/material.dart';

class OptimizedNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const OptimizedNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return placeholder ??
          Container(color: Colors.grey, width: width, height: height);
    }

    return Image.network(
      url!,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child:
              frame == null
                  ? SizedBox(
                    width: width,
                    height: height,
                    child: placeholder ?? const ColoredBox(color: Colors.grey),
                  )
                  : child,
        );
      },
      errorBuilder:
          (_, __, ___) =>
              placeholder ??
              Container(color: Colors.grey, width: width, height: height),
    );
  }
}
