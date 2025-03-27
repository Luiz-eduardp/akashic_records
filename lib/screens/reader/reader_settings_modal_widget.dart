import 'package:flutter/material.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';

enum ReaderTheme {
  light,
  dark,
  sepia,
  darkGreen,
  amoledDark,
  grey,
  solarizedLight,
  solarizedDark,
}

class CustomColors {
  final Color? backgroundColor;
  final Color? textColor;

  CustomColors({this.backgroundColor, this.textColor});
}

class ReaderSettings {
  ReaderTheme theme;
  double fontSize;
  String fontFamily;
  double lineHeight;
  TextAlign textAlign;
  Color backgroundColor;
  Color textColor;

  CustomColors? customColors;

  ReaderSettings({
    this.theme = ReaderTheme.light,
    this.fontSize = 18.0,
    this.fontFamily = 'Roboto',
    this.lineHeight = 1.5,
    this.textAlign = TextAlign.justify,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.customColors,
  });

  Map<String, dynamic> toMap() {
    return {
      'theme': theme.index,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'lineHeight': lineHeight,
      'textAlign': textAlign.index,
      'backgroundColor': backgroundColor.value,
      'textColor': textColor.value,
      'customBackgroundColor': customColors?.backgroundColor?.value,
      'customTextColor': customColors?.textColor?.value,
    };
  }

  static ReaderSettings fromMap(Map<String, dynamic> map) {
    return ReaderSettings(
      theme: ReaderTheme.values[map['theme'] ?? 0],
      fontSize: map['fontSize'] ?? 18.0,
      fontFamily: map['fontFamily'] ?? 'Roboto',
      lineHeight: map['lineHeight'] ?? 1.5,
      textAlign: TextAlign.values[map['textAlign'] ?? 3],
      backgroundColor: Color(map['backgroundColor'] ?? Colors.white.value),
      textColor: Color(map['textColor'] ?? Colors.black.value),
      customColors: CustomColors(
        backgroundColor:
            map['customBackgroundColor'] != null
                ? Color(map['customBackgroundColor'])
                : null,
        textColor:
            map['customTextColor'] != null
                ? Color(map['customTextColor'])
                : null,
      ),
    );
  }
}

class ReaderSettingsModal extends StatefulWidget {
  final ReaderSettings readerSettings;
  final Function(ReaderSettings) onSettingsChanged;
  final VoidCallback onSave;

  const ReaderSettingsModal({
    super.key,
    required this.readerSettings,
    required this.onSettingsChanged,
    required this.onSave,
  });

  @override
  State<ReaderSettingsModal> createState() => _ReaderSettingsModalState();
}

class _ReaderSettingsModalState extends State<ReaderSettingsModal> {
  late ReaderSettings _localSettings;

  Color? _customBackgroundColor;
  Color? _customTextColor;

  @override
  void initState() {
    super.initState();

    _localSettings = widget.readerSettings;
    _customBackgroundColor =
        widget.readerSettings.customColors?.backgroundColor;
    _customTextColor = widget.readerSettings.customColors?.textColor;
  }

  Future<void> _showColorPicker(BuildContext context, bool isBackground) async {
    Color currentColor =
        isBackground
            ? _customBackgroundColor ?? Colors.white
            : _customTextColor ?? Colors.black;

    Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Escolha uma cor'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (Color color) {
                currentColor = color;
                setState(() {
                  if (isBackground) {
                    _customBackgroundColor = color;
                  } else {
                    _customTextColor = color;
                  }
                });
              },

              enableAlpha: true,
              labelTypes: const [ColorLabelType.rgb, ColorLabelType.hsv],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(currentColor);
              },
            ),
          ],
        );
      },
    );

    if (pickedColor != null) {
      setState(() {
        if (isBackground) {
          _customBackgroundColor = pickedColor;
          _localSettings.customColors = CustomColors(
            backgroundColor: _customBackgroundColor,
            textColor: _localSettings.customColors?.textColor,
          );
        } else {
          _customTextColor = pickedColor;
          _localSettings.customColors = CustomColors(
            backgroundColor: _localSettings.customColors?.backgroundColor,
            textColor: _customTextColor,
          );
        }

        if (_localSettings.theme == ReaderTheme.amoledDark ||
            _localSettings.theme == ReaderTheme.darkGreen) {
          _localSettings.backgroundColor =
              _customBackgroundColor ?? _localSettings.backgroundColor;
          _localSettings.textColor =
              _customTextColor ?? _localSettings.textColor;
        }

        widget.onSettingsChanged(_localSettings);
      });
    }
  }

  Widget _buildThemeButton(ReaderTheme theme) {
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
      selected: _localSettings.theme == theme,
      onSelected: (selected) {
        setState(() {
          _localSettings.theme = theme;

          _localSettings.backgroundColor = backgroundColor;
          _localSettings.textColor = textColor;

          if (_localSettings.theme == ReaderTheme.amoledDark ||
              _localSettings.theme == ReaderTheme.darkGreen) {
            _localSettings.customColors = CustomColors(
              backgroundColor: _customBackgroundColor,
              textColor: _customTextColor,
            );
            _localSettings.backgroundColor =
                _customBackgroundColor ?? backgroundColor;
            _localSettings.textColor = _customTextColor ?? textColor;
          } else {
            _localSettings.customColors = null;
          }
          widget.onSettingsChanged(_localSettings);
        });
      },
    );
  }

  Widget _buildTextAlignButton(TextAlign align) {
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
      selected: _localSettings.textAlign == align,
      onSelected: (selected) {
        setState(() {
          _localSettings.textAlign = align;
          widget.onSettingsChanged(_localSettings);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configurações de Leitura',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('Tema:'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildThemeButton(ReaderTheme.light),
              _buildThemeButton(ReaderTheme.dark),
              _buildThemeButton(ReaderTheme.sepia),
              _buildThemeButton(ReaderTheme.darkGreen),
              _buildThemeButton(ReaderTheme.amoledDark),
              _buildThemeButton(ReaderTheme.grey),
              _buildThemeButton(ReaderTheme.solarizedLight),
              _buildThemeButton(ReaderTheme.solarizedDark),
            ],
          ),

          if (_localSettings.theme == ReaderTheme.amoledDark ||
              _localSettings.theme == ReaderTheme.darkGreen) ...[
            const SizedBox(height: 20),
            const Text('Cores Customizadas:'),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _showColorPicker(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _customBackgroundColor ?? Colors.grey,
                  ),
                  child: const Text('Fundo'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _showColorPicker(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _customTextColor ?? Colors.grey,
                  ),
                  child: const Text('Texto'),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),
          const Text('Tamanho da Fonte:'),
          Slider(
            value: _localSettings.fontSize,
            min: 12,
            max: 30,
            divisions: 18,
            label: _localSettings.fontSize.round().toString(),
            onChanged: (value) {
              setState(() {
                _localSettings.fontSize = value;
              });
              widget.onSettingsChanged(_localSettings);
            },
          ),
          const Text('Fonte:'),
          DropdownButton<String>(
            value: _localSettings.fontFamily,
            isExpanded: true,
            items:
                [
                  'Roboto',
                  'Open Sans',
                  'Lato',
                  'Montserrat',
                  'Source Sans Pro',
                  'Noto Sans',
                  'Arial',
                  'Times New Roman',
                  'Courier New',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _localSettings.fontFamily = value!;
              });
              widget.onSettingsChanged(_localSettings);
            },
          ),
          const SizedBox(height: 20),
          const Text('Espaçamento:'),
          Slider(
            value: _localSettings.lineHeight,
            min: 1.0,
            max: 3.0,
            divisions: 20,
            label: _localSettings.lineHeight.toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _localSettings.lineHeight = value;
              });
              widget.onSettingsChanged(_localSettings);
            },
          ),
          const Text('Alinhamento do Texto:'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTextAlignButton(TextAlign.left),
              _buildTextAlignButton(TextAlign.center),
              _buildTextAlignButton(TextAlign.right),
              _buildTextAlignButton(TextAlign.justify),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                widget.onSettingsChanged(_localSettings);
                widget.onSave();
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
