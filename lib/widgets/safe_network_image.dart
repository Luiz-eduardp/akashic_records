import 'package:flutter/material.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return const SizedBox.shrink();
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (ctx, error, stack) => const SizedBox.shrink(),
      loadingBuilder: (ctx, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? SizedBox(width: width, height: height);
      },
    );
  }
}
