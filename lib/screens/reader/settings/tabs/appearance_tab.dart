import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

class AppearanceTab extends StatefulWidget {
  const AppearanceTab({super.key});

  @override
  State<AppearanceTab> createState() => _AppearanceTabState();
}

class _AppearanceTabState extends State<AppearanceTab> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final readerSettings = appState.readerSettings;

    return ListView(
      children: [
        Text('Tema:'.translate, style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildThemeButton(ReaderTheme.light, context),
            _buildThemeButton(ReaderTheme.dark, context),
            _buildThemeButton(ReaderTheme.sepia, context),
            _buildThemeButton(ReaderTheme.darkGreen, context),
            _buildThemeButton(ReaderTheme.amoledDark, context),
            _buildThemeButton(ReaderTheme.grey, context),
            _buildThemeButton(ReaderTheme.solarizedLight, context),
            _buildThemeButton(ReaderTheme.solarizedDark, context),
          ],
        ),
        if (readerSettings.theme == ReaderTheme.amoledDark ||
            readerSettings.theme == ReaderTheme.darkGreen) ...[
          const SizedBox(height: 20),
          Text(
            'Cores Customizadas:'.translate,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _showColorPicker(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      readerSettings.customColors?.backgroundColor ??
                      Colors.grey,
                ),
                child: Text('Fundo'.translate),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _showColorPicker(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      readerSettings.customColors?.textColor ?? Colors.grey,
                ),
                child: Text('Texto'.translate),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildThemeButton(ReaderTheme theme, BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final readerSettings = appState.readerSettings;

    late Color backgroundColor;
    late Color textColor;

    switch (theme) {
      case ReaderTheme.light:
        backgroundColor = Colors.white;
        textColor = Colors.black;
        break;
      case ReaderTheme.dark:
        backgroundColor = Colors.black;
        textColor = Colors.white;
        break;
      case ReaderTheme.sepia:
        backgroundColor = const Color(0xFFf5e7c8);
        textColor = Colors.black;
        break;
      case ReaderTheme.darkGreen:
        backgroundColor = const Color(0xFF1a2a1a);
        textColor = const Color(0xFFa7d1ab);
        break;
      case ReaderTheme.amoledDark:
        backgroundColor = Colors.black;
        textColor = Colors.white;
        break;
      case ReaderTheme.grey:
        backgroundColor = Colors.grey[800]!;
        textColor = Colors.white;
        break;
      case ReaderTheme.solarizedLight:
        backgroundColor = const Color(0xfffdf6e3);
        textColor = const Color(0xff586e75);
        break;
      case ReaderTheme.solarizedDark:
        backgroundColor = const Color(0xff002b36);
        textColor = const Color(0xff93a1a1);
        break;
    }

    return ChoiceChip(
      label: Text(theme.toString().split('.').last),
      selected: readerSettings.theme == theme,
      onSelected: (selected) {
        final newSettings = ReaderSettings(
          theme: theme,
          fontSize: readerSettings.fontSize,
          fontFamily: readerSettings.fontFamily,
          lineHeight: readerSettings.lineHeight,
          textAlign: readerSettings.textAlign,
          backgroundColor: backgroundColor,
          textColor: textColor,
          fontWeight: readerSettings.fontWeight,
          customColors:
              theme == ReaderTheme.amoledDark || theme == ReaderTheme.darkGreen
                  ? readerSettings.customColors
                  : null,
          customJs: readerSettings.customJs,
          customCss: readerSettings.customCss,
        );
        appState.setReaderSettings(newSettings);
      },
    );
  }

  Future<void> _showColorPicker(BuildContext context, bool isBackground) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final readerSettings = appState.readerSettings;
    final currentColor =
        isBackground
            ? (readerSettings.customColors?.backgroundColor ?? Colors.white)
            : (readerSettings.customColors?.textColor ?? Colors.black);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color tempColor = currentColor;
        return AlertDialog(
          title: Text('Escolha uma cor'.translate),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (Color color) {
                tempColor = color;
              },
              enableAlpha: true,
              labelTypes: const [ColorLabelType.rgb, ColorLabelType.hsv],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'.translate),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('OK'.translate),
              onPressed: () {
                final updatedCustomColors = CustomColors(
                  backgroundColor:
                      isBackground
                          ? tempColor
                          : readerSettings.customColors?.backgroundColor,
                  textColor:
                      !isBackground
                          ? tempColor
                          : readerSettings.customColors?.textColor,
                );

                final newSettings = ReaderSettings(
                  theme: readerSettings.theme,
                  fontSize: readerSettings.fontSize,
                  fontFamily: readerSettings.fontFamily,
                  lineHeight: readerSettings.lineHeight,
                  textAlign: readerSettings.textAlign,
                  backgroundColor: readerSettings.backgroundColor,
                  textColor: readerSettings.textColor,
                  fontWeight: readerSettings.fontWeight,
                  customColors: updatedCustomColors,
                  customJs: readerSettings.customJs,
                  customCss: readerSettings.customCss,
                );
                appState.setReaderSettings(newSettings);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
