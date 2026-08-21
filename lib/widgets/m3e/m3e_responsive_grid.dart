import 'package:flutter/material.dart';

class M3EResponsiveGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry padding;

  const M3EResponsiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.childAspectRatio = 0.65,
    this.crossAxisSpacing = 14.0,
    this.mainAxisSpacing = 14.0,
    this.padding = const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 96.0),
  });

  int _calculateColumns(double width) {
    if (width < 600) {
      return 2;
    } else if (width < 900) {
      return 3;
    } else if (width < 1200) {
      return 4;
    } else if (width < 1600) {
      return 5;
    } else {
      return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = _calculateColumns(constraints.maxWidth);
        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
