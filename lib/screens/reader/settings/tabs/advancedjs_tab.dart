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
    final readerSettings = appState.readerSettings;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JavaScript Customizado:'.translate,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Classes e tags úteis: .reader-content, p, h1, h2, a, b, strong'
                .translate,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _customJsController,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: 'Digite seu JavaScript customizado aqui...'.translate,
              border: OutlineInputBorder(),
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
                  content: Text('JavaScript customizado salvo!'.translate),
                ),
              );
            },
            child: Text('Salvar JavaScript Customizado'.translate),
          ),
        ],
      ),
    );
  }
}
