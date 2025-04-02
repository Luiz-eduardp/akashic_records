import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TextTab extends StatelessWidget {
  final List<String> fontOptions = [
    'Pinyon Script, cursive',
    'Lexend Giga, sans-serif',
    'Arial',
    'Times New Roman',
    'Courier New',
  ];

  TextTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final readerSettings = appState.readerSettings;
    return ListView(
      children: [
        Text(
          'Tamanho da Fonte:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: readerSettings.fontSize,
          min: 12,
          max: 100,
          divisions: 50,
          label: readerSettings.fontSize.round().toString(),
          onChanged: (value) {
            final newSettings = ReaderSettings(
              theme: readerSettings.theme,
              fontSize: value,
              fontFamily: readerSettings.fontFamily,
              lineHeight: readerSettings.lineHeight,
              textAlign: readerSettings.textAlign,
              backgroundColor: readerSettings.backgroundColor,
              textColor: readerSettings.textColor,
              fontWeight: readerSettings.fontWeight,
              customColors: readerSettings.customColors,
              customJs: readerSettings.customJs,
              customCss: readerSettings.customCss,
            );
            appState.setReaderSettings(newSettings);
          },
        ),
        Text('Fonte:', style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              fontOptions
                  .map((String font) => _buildFontButton(font, context))
                  .toList(),
        ),
        const SizedBox(height: 20),
        Text('Espaçamento:', style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: readerSettings.lineHeight,
          min: 1.0,
          max: 3.0,
          divisions: 20,
          label: readerSettings.lineHeight.toStringAsFixed(1),
          onChanged: (value) {
            final newSettings = ReaderSettings(
              theme: readerSettings.theme,
              fontSize: readerSettings.fontSize,
              fontFamily: readerSettings.fontFamily,
              lineHeight: value,
              textAlign: readerSettings.textAlign,
              backgroundColor: readerSettings.backgroundColor,
              textColor: readerSettings.textColor,
              fontWeight: readerSettings.fontWeight,
              customColors: readerSettings.customColors,
              customJs: readerSettings.customJs,
              customCss: readerSettings.customCss,
            );
            appState.setReaderSettings(newSettings);
          },
        ),
        Text(
          'Alinhamento do Texto:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTextAlignButton(TextAlign.left, context),
            _buildTextAlignButton(TextAlign.center, context),
            _buildTextAlignButton(TextAlign.right, context),
            _buildTextAlignButton(TextAlign.justify, context),
          ],
        ),
        Text('Peso da Fonte:', style: Theme.of(context).textTheme.titleMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildFontWeightButton(FontWeight.normal, context),
            _buildFontWeightButton(FontWeight.bold, context),
          ],
        ),
      ],
    );
  }

  Widget _buildFontButton(String font, BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final readerSettings = appState.readerSettings;

    return ChoiceChip(
      label: Text(font),
      selected: readerSettings.fontFamily == font,
      onSelected: (selected) {
        final newSettings = ReaderSettings(
          theme: readerSettings.theme,
          fontSize: readerSettings.fontSize,
          fontFamily: font,
          lineHeight: readerSettings.lineHeight,
          textAlign: readerSettings.textAlign,
          backgroundColor: readerSettings.backgroundColor,
          textColor: readerSettings.textColor,
          fontWeight: readerSettings.fontWeight,
          customColors: readerSettings.customColors,
          customJs: readerSettings.customJs,
          customCss: readerSettings.customCss,
        );
        appState.setReaderSettings(newSettings);
      },
    );
  }

  Widget _buildTextAlignButton(TextAlign align, BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final readerSettings = appState.readerSettings;
    IconData icon;
    switch (align) {
      case TextAlign.left:
        icon = Icons.format_align_left;
        break;
      case TextAlign.center:
        icon = Icons.format_align_center;
        break;
      case TextAlign.right:
        icon = Icons.format_align_right;
        break;
      case TextAlign.justify:
        icon = Icons.format_align_justify;
        break;
      case TextAlign.start:
        throw UnimplementedError();
      case TextAlign.end:
        throw UnimplementedError();
    }

    return ChoiceChip(
      label: Icon(icon),
      selected: readerSettings.textAlign == align,
      onSelected: (selected) {
        final newSettings = ReaderSettings(
          theme: readerSettings.theme,
          fontSize: readerSettings.fontSize,
          fontFamily: readerSettings.fontFamily,
          lineHeight: readerSettings.lineHeight,
          textAlign: align,
          backgroundColor: readerSettings.backgroundColor,
          textColor: readerSettings.textColor,
          fontWeight: readerSettings.fontWeight,
          customColors: readerSettings.customColors,
          customJs: readerSettings.customJs,
          customCss: readerSettings.customCss,
        );
        appState.setReaderSettings(newSettings);
      },
    );
  }

  Widget _buildFontWeightButton(FontWeight fontWeight, BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final readerSettings = appState.readerSettings;
    String fontWeightName =
        fontWeight == FontWeight.normal ? 'Normal' : 'Negrito';

    return ChoiceChip(
      label: Text(fontWeightName),
      selected: readerSettings.fontWeight == fontWeight,
      onSelected: (selected) {
        final newSettings = ReaderSettings(
          theme: readerSettings.theme,
          fontSize: readerSettings.fontSize,
          fontFamily: readerSettings.fontFamily,
          lineHeight: readerSettings.lineHeight,
          textAlign: readerSettings.textAlign,
          backgroundColor: readerSettings.backgroundColor,
          textColor: readerSettings.textColor,
          fontWeight: fontWeight,
          customColors: readerSettings.customColors,
          customJs: readerSettings.customJs,
          customCss: readerSettings.customCss,
        );
        appState.setReaderSettings(newSettings);
      },
    );
  }
}
