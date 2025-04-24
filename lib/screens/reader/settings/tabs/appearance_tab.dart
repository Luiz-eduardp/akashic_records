import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppearanceTab extends StatefulWidget {
  const AppearanceTab({super.key});

  @override
  State<AppearanceTab> createState() => _AppearanceTabState();
}

class _AppearanceTabState extends State<AppearanceTab> {
  @override
  Widget build(BuildContext context) {
    Provider.of<AppState>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        double cardAspectRatio = constraints.maxWidth > 600 ? 2.8 : 2.5;

        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Tema:'.translate,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: cardAspectRatio,
              children:
                  ReaderTheme.values
                      .map((theme) => _buildThemeCard(theme, context))
                      .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeCard(ReaderTheme theme, BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final readerSettings = appState.readerSettings;

    late Color backgroundColor;
    late Color textColor;

    switch (theme) {
      case ReaderTheme.light:
        backgroundColor = const Color(0xFFFAFAFA);
        textColor = const Color(0xFF212121);
        break;
      case ReaderTheme.dark:
        backgroundColor = const Color(0xFF121212);
        textColor = const Color(0xFFE0E0E0);
        break;
      case ReaderTheme.sepia:
        backgroundColor = const Color(0xFFFAF0E6);
        textColor = const Color(0xFF795548);
        break;
      case ReaderTheme.darkGreen:
        backgroundColor = const Color(0xFF1B5E20);
        textColor = const Color(0xFF81C784);
        break;
      case ReaderTheme.grey:
        backgroundColor = const Color(0xFF616161);
        textColor = const Color(0xFFCFD8DC);
        break;
      case ReaderTheme.solarizedLight:
        backgroundColor = const Color(0xFFFDF6E3);
        textColor = const Color(0xFF586E75);
        break;
      case ReaderTheme.solarizedDark:
        backgroundColor = const Color(0xFF002B36);
        textColor = const Color(0xFF93A1A1);
        break;
      case ReaderTheme.translucent:
        backgroundColor = Colors.grey.withOpacity(0.7);
        textColor = Colors.white;
        break;
      case ReaderTheme.midnightBlue:
        backgroundColor = const Color(0xFF1A237E);
        textColor = const Color(0xFFB3E5FC);
        break;
      case ReaderTheme.lavender:
        backgroundColor = const Color(0xFFF3E5F5);
        textColor = const Color(0xFF4A148C);
        break;
      case ReaderTheme.mint:
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF1B5E20);
        break;
      case ReaderTheme.sand:
        backgroundColor = const Color(0xFFEDE7F6);
        textColor = const Color(0xFF5D4037);
        break;
      case ReaderTheme.coral:
        backgroundColor = const Color(0xFFFFCDD2);
        textColor = const Color(0xFFD32F2F);
        break;
      case ReaderTheme.cyberpunk:
        backgroundColor = const Color(0xFF000000);
        textColor = const Color(0xFF00FF00);
        break;
      case ReaderTheme.highContrast:
        backgroundColor = Colors.black;
        textColor = Colors.yellow;
        break;
      case ReaderTheme.materialLight:
        backgroundColor = const Color(0xFFFFFFFF);
        textColor = const Color(0xFF212121);
        break;
      case ReaderTheme.materialDark:
        backgroundColor = const Color(0xFF303030);
        textColor = const Color(0xFFFFFFFF);
        break;
      case ReaderTheme.nord:
        backgroundColor = const Color(0xFF2E3440);
        textColor = const Color(0xFFD8DEE9);
        break;
      case ReaderTheme.roseQuartz:
        backgroundColor = const Color(0xFFF8BBD0);
        textColor = const Color(0xFF880E4F);
        break;
      case ReaderTheme.amethyst:
        backgroundColor = const Color(0xFFD1C4E9);
        textColor = const Color(0xFF4527A0);
        break;
      case ReaderTheme.forest:
        backgroundColor = const Color(0xFF43A047);
        textColor = const Color(0xFFFFFFFF);
        break;
      case ReaderTheme.ocean:
        backgroundColor = const Color(0xFF0277BD);
        textColor = const Color(0xFFFFFFFF);
        break;
      case ReaderTheme.sunset:
        backgroundColor = const Color(0xFFFF6F00);
        textColor = const Color(0xFFFFFFFF);
        break;
      case ReaderTheme.dracula:
        backgroundColor = const Color(0xFF282A36);
        textColor = const Color(0xFFF8F8F2);
        break;
      case ReaderTheme.gruvboxLight:
        backgroundColor = const Color(0xFFFBF1C7);
        textColor = const Color(0xFF3C3836);
        break;
      case ReaderTheme.gruvboxDark:
        backgroundColor = const Color(0xFF282828);
        textColor = const Color(0xFFEBDBB2);
        break;
      case ReaderTheme.monokai:
        backgroundColor = const Color(0xFF272822);
        textColor = const Color(0xFFF8F8F2);
        break;
      case ReaderTheme.solarized:
        backgroundColor = const Color(0xFFFDF6E3);
        textColor = const Color(0xFF586E75);
        break;
      case ReaderTheme.calmingBlue:
        backgroundColor = const Color(0xFFECEFF1);
        textColor = const Color(0xFF455A64);
        break;
      case ReaderTheme.darkOpaque:
        backgroundColor = const Color(0xFF37474F);
        textColor = const Color(0xFFB0BEC5);
        break;
      case ReaderTheme.lime:
        backgroundColor = const Color(0xFFcddc39);
        textColor = const Color(0xFF212121);
        break;
      case ReaderTheme.teal:
        backgroundColor = const Color(0xFF009688);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.amber:
        backgroundColor = const Color(0xFFffc107);
        textColor = const Color(0xFF212121);
        break;
      case ReaderTheme.deepOrange:
        backgroundColor = const Color(0xFFff5722);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.brown:
        backgroundColor = const Color(0xFF795548);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.blueGrey:
        backgroundColor = const Color(0xFF607d8b);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.indigo:
        backgroundColor = const Color(0xFF3f51b5);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.cyan:
        backgroundColor = const Color(0xFF00bcd4);
        textColor = const Color(0xFF212121);
        break;
      case ReaderTheme.khaki:
        backgroundColor = const Color(0xFFf0e68c);
        textColor = const Color(0xFF212121);
        break;
      case ReaderTheme.slateGray:
        backgroundColor = const Color(0xFF708090);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.rosyBrown:
        backgroundColor = const Color(0xFFbc8f8f);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.oliveDrab:
        backgroundColor = const Color(0xFF6b8e23);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.peru:
        backgroundColor = const Color(0xFFcd853f);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.darkSlateGray:
        backgroundColor = const Color(0xFF2f4f4f);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.cadetBlue:
        backgroundColor = const Color(0xFF5f9ea0);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.mediumTurquoise:
        backgroundColor = const Color(0xFF48d1cc);
        textColor = const Color(0xFF212121);
        break;
      case ReaderTheme.lightSeaGreen:
        backgroundColor = const Color(0xFF20b2aa);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.darkCyan:
        backgroundColor = const Color(0xFF008b8b);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.steelBlue:
        backgroundColor = const Color(0xFF4682b4);
        textColor = const Color(0xFFffffff);
        break;
      case ReaderTheme.royalBlue:
        backgroundColor = const Color(0xFF4169e1);
        textColor = const Color(0xFFffffff);
        break;

      case ReaderTheme.night:
        backgroundColor = const Color(0xFF0D1D2E);
        textColor = const Color(0xFF9AC6FF);
        break;
      case ReaderTheme.coal:
        backgroundColor = const Color(0xFF36454F);
        textColor = const Color(0xFFD3D3D3);
        break;
      case ReaderTheme.obsidian:
        backgroundColor = const Color(0xFF000000);
        textColor = const Color(0xFF808080);
        break;
      case ReaderTheme.deepPurple:
        backgroundColor = const Color(0xFF301934);
        textColor = const Color(0xFFE0B0FF);
        break;
      case ReaderTheme.midnight:
        backgroundColor = const Color(0xFF25315B);
        textColor = const Color(0xFFE6E8E9);
        break;
    }

    return Card(
      color: backgroundColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final newSettings = ReaderSettings(
            theme: theme,
            fontSize: readerSettings.fontSize,
            fontFamily: readerSettings.fontFamily,
            lineHeight: readerSettings.lineHeight,
            textAlign: readerSettings.textAlign,
            backgroundColor: backgroundColor,
            textColor: textColor,
            fontWeight: readerSettings.fontWeight,
            customJs: readerSettings.customJs,
            customCss: readerSettings.customCss,
          );
          appState.setReaderSettings(newSettings);
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    theme.toString().split('.').last,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
