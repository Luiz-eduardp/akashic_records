import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class TextTab extends StatefulWidget {
  const TextTab({super.key});

  @override
  State<TextTab> createState() => _TextTabState();
}

class _TextTabState extends State<TextTab> {
  final List<String> fontOptions = [
    'Pinyon Script, cursive',
    'Lexend Giga, sans-serif',
    'Arial',
    'Times New Roman',
    'Courier New',
    'Roboto',
    'Open Sans',
    'Lato',
  ];

  final TextEditingController _fontSizeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFontSizeController();
  }

  void _initializeFontSizeController() {
    final appState = Provider.of<AppState>(context, listen: false);
    _fontSizeController.text =
        appState.readerSettings.fontSize.round().toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeFontSizeController();
  }

  @override
  void dispose() {
    _fontSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final readerSettings = appState.readerSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tamanho da Fonte:'.translate,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          TextFormField(
            controller: _fontSizeController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              hintText: '12-100',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: () {
                  _updateFontSize(context, readerSettings);
                },
              ),
            ),
            onFieldSubmitted: (value) {
              _updateFontSize(context, readerSettings);
            },
          ),

          const SizedBox(height: 16),

          Text(
            'Fonte:'.translate,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                fontOptions
                    .map((String font) => _buildFontButton(font, context))
                    .toList(),
          ),

          const SizedBox(height: 20),

          Text(
            'Espaçamento:'.translate,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: readerSettings.lineHeight,
            min: 1.0,
            max: 3.0,
            divisions: 20,
            label: readerSettings.lineHeight.toStringAsFixed(1),
            onChanged: (value) {
              _updateReaderSettings(
                context,
                readerSettings.copyWith(lineHeight: value),
              );
            },
          ),

          const SizedBox(height: 16),

          Text(
            'Alinhamento do Texto:'.translate,
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

          const SizedBox(height: 16),

          Text(
            'Peso da Fonte:'.translate,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFontWeightButton(FontWeight.normal, context),
              _buildFontWeightButton(FontWeight.bold, context),
            ],
          ),

          const SizedBox(height: 16),

          ExpansionTile(
            title: Text(
              'Opções Avançadas'.translate,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            children: [
              const SizedBox(height: 10),

              Text(
                'Cor do Texto:'.translate,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ColorPicker(
                selectedColor: readerSettings.textColor,
                onColorChanged: (color) {
                  _updateReaderSettings(
                    context,
                    readerSettings.copyWith(textColor: color),
                  );
                },
              ),

              Text(
                'Cor de Fundo:'.translate,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ColorPicker(
                selectedColor: readerSettings.backgroundColor,
                onColorChanged: (color) {
                  _updateReaderSettings(
                    context,
                    readerSettings.copyWith(backgroundColor: color),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFontButton(String font, BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final readerSettings = appState.readerSettings;

    return ChoiceChip(
      label: Text(font),
      selected: readerSettings.fontFamily == font,
      onSelected: (selected) {
        _updateReaderSettings(
          context,
          readerSettings.copyWith(fontFamily: font),
        );
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
      case TextAlign.end:
        icon = Icons.format_align_left;
    }

    return ChoiceChip(
      label: Icon(icon),
      selected: readerSettings.textAlign == align,
      onSelected: (selected) {
        _updateReaderSettings(
          context,
          readerSettings.copyWith(textAlign: align),
        );
      },
    );
  }

  Widget _buildFontWeightButton(FontWeight fontWeight, BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final readerSettings = appState.readerSettings;
    String fontWeightName =
        fontWeight == FontWeight.normal
            ? 'Normal'.translate
            : 'Negrito'.translate;

    return ChoiceChip(
      label: Text(fontWeightName),
      selected: readerSettings.fontWeight == fontWeight,
      onSelected: (selected) {
        _updateReaderSettings(
          context,
          readerSettings.copyWith(fontWeight: fontWeight),
        );
      },
    );
  }

  void _updateReaderSettings(BuildContext context, ReaderSettings newSettings) {
    Provider.of<AppState>(
      context,
      listen: false,
    ).setReaderSettings(newSettings);
  }

  void _updateFontSize(BuildContext context, ReaderSettings readerSettings) {
    final String value = _fontSizeController.text;
    if (value.isNotEmpty) {
      final double? newFontSize = double.tryParse(value);
      if (newFontSize != null && newFontSize >= 12 && newFontSize <= 100) {
        _updateReaderSettings(
          context,
          readerSettings.copyWith(fontSize: newFontSize),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, insira um valor entre 12 e 100.')),
        );
        _fontSizeController.text = readerSettings.fontSize.round().toString();
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Por favor, insira um valor.')));
      _fontSizeController.text = readerSettings.fontSize.round().toString();
    }
  }
}

class ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        _buildColorButton(Colors.black),
        _buildColorButton(Colors.white),
        _buildColorButton(Colors.blue),
        _buildColorButton(Colors.red),
        _buildColorButton(Colors.green),
        _buildColorButton(Colors.yellow),
        _buildColorButton(Colors.orange),
        _buildColorButton(Colors.purple),
        _buildColorButton(Colors.pink),
        _buildColorButton(Colors.teal),
        _buildColorButton(Colors.lime),
        _buildColorButton(Colors.indigo),
        _buildColorButton(Colors.cyan),
        _buildColorButton(Colors.amber),
        _buildColorButton(Colors.brown),
        _buildColorButton(Colors.grey),
        _buildColorButton(Colors.blueGrey),
        _buildColorButton(Colors.deepOrange),
        _buildColorButton(Colors.deepPurple),
        _buildColorButton(Colors.lightBlue),
        _buildColorButton(Colors.lightGreen),
        _buildColorButton(Colors.limeAccent),
        _buildColorButton(Colors.orangeAccent),
        _buildColorButton(Colors.pinkAccent),
        _buildColorButton(Colors.purpleAccent),
        _buildColorButton(Colors.redAccent),
        _buildColorButton(Colors.tealAccent),
        _buildColorButton(Colors.yellowAccent),
        _buildColorButton(const Color(0xFFE91E63)),
        _buildColorButton(const Color(0xFF673AB7)),
        _buildColorButton(const Color(0xFF3F51B5)),
        _buildColorButton(const Color(0xFF03A9F4)),
        _buildColorButton(const Color(0xFF4CAF50)),
        _buildColorButton(const Color(0xFFFFEB3B)),
        _buildColorButton(const Color(0xFFFF9800)),
        _buildColorButton(const Color(0xFF795548)),
        _buildColorButton(const Color(0xFF9E9E9E)),
        _buildColorButton(const Color(0xFF607D8B)),
        _buildColorButton(const Color(0xFF2196F3)),
        _buildColorButton(const Color(0xFF8BC34A)),
        _buildColorButton(const Color(0xFFFFC107)),
        _buildColorButton(const Color(0xFFF44336)),
        _buildColorButton(const Color(0xFF00BCD4)),
        _buildColorButton(const Color(0xFFCDDC39)),
        _buildColorButton(const Color(0xFFFF5722)),
        _buildColorButton(const Color(0xFF9C27B0)),
        _buildColorButton(const Color(0xFF009688)),
        _buildColorButton(const Color(0xFF607D8B)),
        _buildColorButton(const Color(0xFF33691E)),
      ],
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        onColorChanged(color);
      },
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: selectedColor == color ? Colors.orange : Colors.grey,
            width: 2,
          ),
        ),
      ),
    );
  }
}

extension CopyWithReaderSettings on ReaderSettings {
  ReaderSettings copyWith({
    String? theme,
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    TextAlign? textAlign,
    Color? backgroundColor,
    Color? textColor,
    FontWeight? fontWeight,
    CustomColors? customColors,
    String? customJs,
    String? customCss,
  }) {
    return ReaderSettings(
      theme: this.theme,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      textAlign: textAlign ?? this.textAlign,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontWeight: fontWeight ?? this.fontWeight,
      customColors: customColors ?? this.customColors,
      customJs: customJs ?? this.customJs,
      customCss: customCss ?? this.customCss,
    );
  }
}
