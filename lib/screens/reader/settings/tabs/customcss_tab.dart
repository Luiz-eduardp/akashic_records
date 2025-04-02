import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomCssTab extends StatefulWidget {
  const CustomCssTab({super.key});

  @override
  State<CustomCssTab> createState() => _CustomCssTabState();
}

class _CustomCssTabState extends State<CustomCssTab> {
  final TextEditingController _customCssController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _customCssController.text = appState.readerSettings.customCss ?? '';
  }

  @override
  void dispose() {
    _customCssController.dispose();
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
            'CSS Customizado:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Classes e tags úteis: .reader-content, p, h1, h2, a, b, strong',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _customCssController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Digite seu CSS customizado aqui...',
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
                customJs: readerSettings.customJs,
                customCss: _customCssController.text,
              );
              appState.setReaderSettings(newSettings);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSS customizado salvo!')),
              );
            },
            child: const Text('Salvar CSS Customizado'),
          ),
        ],
      ),
    );
  }
}
