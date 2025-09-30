import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';

class InitialLoadingScreen extends StatelessWidget {
  final bool updateAvailable;
  final String? downloadUrl;
  final bool showChangelog;
  final VoidCallback onDone;

  const InitialLoadingScreen({
    super.key,
    required this.updateAvailable,
    this.downloadUrl,
    required this.showChangelog,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('welcome'.translate),
            if (updateAvailable) Text('update_available'.translate),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onDone,
              child: Text('continue'.translate),
            ),
          ],
        ),
      ),
    );
  }
}
