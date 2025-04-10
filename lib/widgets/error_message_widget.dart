import 'package:flutter/material.dart';

class ErrorMessageWidget extends StatelessWidget {
  final String errorMessage;

  const ErrorMessageWidget({
    super.key,
    required this.errorMessage,
    TextStyle? style,
  });

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(errorMessage));
  }
}
