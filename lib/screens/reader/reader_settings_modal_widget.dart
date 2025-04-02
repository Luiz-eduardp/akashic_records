import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

class ReaderSettingsModal extends StatefulWidget {
  const ReaderSettingsModal({super.key});

  @override
  State<ReaderSettingsModal> createState() => _ReaderSettingsModalState();
}

class _ReaderSettingsModalState extends State<ReaderSettingsModal>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          Text(
            'Configurações de Leitura',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Aparência'),
              Tab(text: 'Texto'),
              Tab(text: 'Avançado'),
              Tab(text: 'CSS'),
            ],
          ),
          SizedBox(
            height: 500,
            child: TabBarView(
              controller: _tabController,
              children: [
                AppearanceTab(),
                TextTab(),
                AdvancedTab(),
                CustomCssTab(),
              ],
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
        Text('Tema:', style: Theme.of(context).textTheme.titleMedium),
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
            'Cores Customizadas:',
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
                child: const Text('Fundo'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _showColorPicker(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      readerSettings.customColors?.textColor ?? Colors.grey,
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
              focusMode: value,
              customJs: readerSettings.customJs,
              customCss: readerSettings.customCss,
            );
            appState.setReaderSettings(newSettings);
          },
        ),
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
          focusMode: readerSettings.focusMode,
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
          title: const Text('Escolha uma cor'),
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
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('OK'),
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
                  focusMode: readerSettings.focusMode,
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
          min: 35,
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
              focusMode: readerSettings.focusMode,
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
              focusMode: readerSettings.focusMode,
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
          focusMode: readerSettings.focusMode,
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
          focusMode: readerSettings.focusMode,
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
          focusMode: readerSettings.focusMode,
          customJs: readerSettings.customJs,
          customCss: readerSettings.customCss,
        );
        appState.setReaderSettings(newSettings);
      },
    );
  }
}

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
            'JavaScript Customizado:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _customJsController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Digite seu JavaScript customizado aqui...',
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
                focusMode: readerSettings.focusMode,
                customJs: _customJsController.text,
                customCss: readerSettings.customCss,
              );
              appState.setReaderSettings(newSettings);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JavaScript customizado salvo!')),
              );
            },
            child: const Text('Salvar JavaScript Customizado'),
          ),
        ],
      ),
    );
  }
}

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
                focusMode: readerSettings.focusMode,
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
