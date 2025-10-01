import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChapterCountBadge extends StatelessWidget {
  final int count;
  final bool showPlus;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const ChapterCountBadge({
    super.key,
    required this.count,
    this.showPlus = false,
    this.backgroundColor,
    this.textStyle,
  });

  String _format(int n) {
    try {
      return NumberFormat.decimalPattern().format(n);
    } catch (_) {
      return n.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final bg =
        backgroundColor ?? Theme.of(context).colorScheme.primaryContainer;
    final style =
        textStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minWidth: 24, maxWidth: 88),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${showPlus ? '+' : ''}${_format(count)}',
          style: style,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
