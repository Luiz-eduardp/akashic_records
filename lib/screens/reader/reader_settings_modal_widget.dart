import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';

class ReaderSettingsModal extends StatefulWidget {
  const ReaderSettingsModal({Key? key});

  @override
  State<ReaderSettingsModal> createState() => _ReaderSettingsModalState();
}

class _ReaderSettingsModalState extends State<ReaderSettingsModal>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _ = Provider.of<AppState>(context);
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
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Aparência'), Tab(text: 'Texto')],
          ),
          SizedBox(
            height: 500,
            child: TabBarView(
              controller: _tabController,
              children: [AppearanceTab(), TextTab()],
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
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

class AppearanceTab extends StatefulWidget {
  @override
  _AppearanceTabState createState() => _AppearanceTabState();
}

class _AppearanceTabState extends State<AppearanceTab> {
  Color? _customBackgroundColor;
  Color? _customTextColor;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final readerSettings = appState.readerSettings;
    _customBackgroundColor = readerSettings.customColors?.backgroundColor;
    _customTextColor = readerSettings.customColors?.textColor;
    return ListView(
      children: [
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
        if (readerSettings.theme == ReaderTheme.amoledDark ||
            readerSettings.theme == ReaderTheme.darkGreen) ...[
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
        SwitchListTile(
          title: const Text('Modo Foco'),
          value: readerSettings.focusMode,
          onChanged: (bool value) {
            ReaderSettings newSettings = ReaderSettings(
              theme: readerSettings.theme,
              fontSize: readerSettings.fontSize,
              fontFamily: readerSettings.fontFamily,
              lineHeight: readerSettings.lineHeight,
              textAlign: readerSettings.textAlign,
              backgroundColor: readerSettings.backgroundColor,
              textColor: readerSettings.textColor,
              fontWeight: readerSettings.fontWeight,
              customColors: readerSettings.customColors,
              focusMode: value,
            );
            Provider.of<AppState>(
              context,
              listen: false,
            ).setReaderSettings(newSettings);
          },
        ),
      ],
    );
  }

  Widget _buildThemeButton(ReaderTheme theme) {
    final appState = Provider.of<AppState>(context, listen: false);
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
        ReaderSettings newSettings = ReaderSettings(
          theme: theme,
          fontSize: readerSettings.fontSize,
          fontFamily: readerSettings.fontFamily,
          lineHeight: readerSettings.lineHeight,
          textAlign: readerSettings.textAlign,
          backgroundColor: backgroundColor,
          textColor: textColor,
          fontWeight: readerSettings.fontWeight,
          customColors: readerSettings.customColors,
          focusMode: readerSettings.focusMode,
        );

        if (theme == ReaderTheme.amoledDark || theme == ReaderTheme.darkGreen) {
          newSettings.customColors = CustomColors(
            backgroundColor: _customBackgroundColor,
            textColor: _customTextColor,
          );
          newSettings.backgroundColor =
              _customBackgroundColor ?? backgroundColor;
          newSettings.textColor = _customTextColor ?? textColor;
        } else {
          newSettings.customColors = null;
        }

        appState.setReaderSettings(newSettings);
      },
    );
  }

  Future<void> _showColorPicker(BuildContext context, bool isBackground) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final readerSettings = appState.readerSettings;
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
      if (isBackground) {
        _customBackgroundColor = pickedColor;
        ReaderSettings newSettings = ReaderSettings(
          theme: readerSettings.theme,
          fontSize: readerSettings.fontSize,
          fontFamily: readerSettings.fontFamily,
          lineHeight: readerSettings.lineHeight,
          textAlign: readerSettings.textAlign,
          backgroundColor:
              _customBackgroundColor ?? readerSettings.backgroundColor,
          textColor: readerSettings.textColor,
          fontWeight: readerSettings.fontWeight,
          customColors: CustomColors(
            backgroundColor: _customBackgroundColor,
            textColor: readerSettings.customColors?.textColor,
          ),
          focusMode: readerSettings.focusMode,
        );
        appState.setReaderSettings(newSettings);
      } else {
        _customTextColor = pickedColor;
        ReaderSettings newSettings = ReaderSettings(
          theme: readerSettings.theme,
          fontSize: readerSettings.fontSize,
          fontFamily: readerSettings.fontFamily,
          lineHeight: readerSettings.lineHeight,
          textAlign: readerSettings.textAlign,
          backgroundColor: readerSettings.backgroundColor,
          textColor: _customTextColor ?? readerSettings.textColor,
          fontWeight: readerSettings.fontWeight,
          customColors: CustomColors(
            backgroundColor: readerSettings.customColors?.backgroundColor,
            textColor: _customTextColor,
          ),
          focusMode: readerSettings.focusMode,
        );
        appState.setReaderSettings(newSettings);
      }
    }
  }
}

class TextTab extends StatelessWidget {
  final List<String> fontOptions = [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Source Sans Pro',
    'Noto Sans',
    'Arial',
    'Times New Roman',
    'Courier New',
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final readerSettings = appState.readerSettings;
    return ListView(
      children: [
        const Text('Tamanho da Fonte:'),
        Slider(
          value: readerSettings.fontSize,
          min: 12,
          max: 30,
          divisions: 18,
          label: readerSettings.fontSize.round().toString(),
          onChanged: (value) {
            ReaderSettings newSettings = ReaderSettings(
              theme: readerSettings.theme,
              fontSize: value,
              fontFamily: readerSettings.fontFamily,
              lineHeight: readerSettings.lineHeight,
              textAlign: readerSettings.textAlign,
              backgroundColor: readerSettings.backgroundColor,
              textColor: readerSettings.textColor,
              fontWeight: readerSettings.fontWeight,
              customColors: readerSettings.customColors,
              focusMode: readerSettings.focusMode,
            );
            appState.setReaderSettings(newSettings);
          },
        ),
        const Text('Fonte:'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              fontOptions
                  .map((String font) => _buildFontButton(font, context))
                  .toList(),
        ),
        const SizedBox(height: 20),
        const Text('Espaçamento:'),
        Slider(
          value: readerSettings.lineHeight,
          min: 1.0,
          max: 3.0,
          divisions: 20,
          label: readerSettings.lineHeight.toStringAsFixed(1),
          onChanged: (value) {
            ReaderSettings newSettings = ReaderSettings(
              theme: readerSettings.theme,
              fontSize: readerSettings.fontSize,
              fontFamily: readerSettings.fontFamily,
              lineHeight: value,
              textAlign: readerSettings.textAlign,
              backgroundColor: readerSettings.backgroundColor,
              textColor: readerSettings.textColor,
              fontWeight: readerSettings.fontWeight,
              customColors: readerSettings.customColors,
              focusMode: readerSettings.focusMode,
            );
            appState.setReaderSettings(newSettings);
          },
        ),
        const Text('Alinhamento do Texto:'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTextAlignButton(TextAlign.left, context),
            _buildTextAlignButton(TextAlign.center, context),
            _buildTextAlignButton(TextAlign.right, context),
            _buildTextAlignButton(TextAlign.justify, context),
          ],
        ),
        const Text('Peso da Fonte:'),
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
        ReaderSettings newSettings = ReaderSettings(
          theme: readerSettings.theme,
          fontSize: readerSettings.fontSize,
          fontFamily: font,
          lineHeight: readerSettings.lineHeight,
          textAlign: readerSettings.textAlign,
          backgroundColor: readerSettings.backgroundColor,
          textColor: readerSettings.textColor,
          fontWeight: readerSettings.fontWeight,
          customColors: readerSettings.customColors,
          focusMode: readerSettings.focusMode,
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
        ReaderSettings newSettings = ReaderSettings(
          theme: readerSettings.theme,
          fontSize: readerSettings.fontSize,
          fontFamily: readerSettings.fontFamily,
          lineHeight: readerSettings.lineHeight,
          textAlign: align,
          backgroundColor: readerSettings.backgroundColor,
          textColor: readerSettings.textColor,
          fontWeight: readerSettings.fontWeight,
          customColors: readerSettings.customColors,
          focusMode: readerSettings.focusMode,
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
        ReaderSettings newSettings = ReaderSettings(
          theme: readerSettings.theme,
          fontSize: readerSettings.fontSize,
          fontFamily: readerSettings.fontFamily,
          lineHeight: readerSettings.lineHeight,
          textAlign: readerSettings.textAlign,
          backgroundColor: readerSettings.backgroundColor,
          textColor: readerSettings.textColor,
          fontWeight: fontWeight,
          customColors: readerSettings.customColors,
          focusMode: readerSettings.focusMode,
        );
        appState.setReaderSettings(newSettings);
      },
    );
  }
}
