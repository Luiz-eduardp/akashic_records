import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdvancedTab extends StatefulWidget {
  const AdvancedTab({super.key});

  @override
  State<AdvancedTab> createState() => _AdvancedTabState();
}

class _AdvancedTabState extends State<AdvancedTab> {
  final TextEditingController _customJsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _customJsController.text = appState.readerSettings.customJs ?? '';
  }

  @override
  void dispose() {
    _customJsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final readerSettings = appState.readerSettings;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'JavaScript Customizado:'.translate,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Classes e tags úteis: .reader-content, p, h1, h2, a, b, strong'
                  .translate,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _customJsController,
              maxLines: 10,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Digite seu JavaScript customizado aqui...'.translate,
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.all(16.0),
              ),
              onChanged: (value) {},
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final newSettings = ReaderSettings(
                  theme: readerSettings.theme,
                  fontSize: readerSettings.fontSize,
                  fontFamily: readerSettings.fontFamily,
                  lineHeight: readerSettings.lineHeight,
                  textAlign: readerSettings.textAlign,
                  backgroundColor: readerSettings.backgroundColor,
                  textColor: readerSettings.textColor,
                  fontWeight: readerSettings.fontWeight,
                  customColors: readerSettings.customColors,
                  customJs: _customJsController.text,
                  customCss: readerSettings.customCss,
                );
                appState.setReaderSettings(newSettings);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'JavaScript customizado salvo!'.translate,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text('Salvar JavaScript Customizado'.translate),
            ),
          ],
        ),
      ),
    );
  }
}
