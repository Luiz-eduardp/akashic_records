import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum ReaderTheme {
  Akashic,
  light,
  dark,
  sepia,
  darkGreen,
  grey,
  solarizedLight,
  solarizedDark,
  translucent,
  midnightBlue,
  lavender,
  mint,
  sand,
  coral,
  cyberpunk,
  highContrast,
  materialLight,
  materialDark,
  nord,
  roseQuartz,
  amethyst,
  forest,
  ocean,
  sunset,
  dracula,
  gruvboxLight,
  gruvboxDark,
  monokai,
  solarized,
  calmingBlue,
  darkOpaque,
  lime,
  teal,
  amber,
  deepOrange,
  brown,
  blueGrey,
  indigo,
  cyan,
  khaki,
  slateGray,
  rosyBrown,
  oliveDrab,
  peru,
  darkSlateGray,
  cadetBlue,
  mediumTurquoise,
  lightSeaGreen,
  darkCyan,
  steelBlue,
  royalBlue,
  night,
  coal,
  obsidian,
  deepPurple,
  midnight,
  kindleClassic,
  kindleEInk,
  kindlePaperwhite,
  kindleOasis,
  kindleVoyage,
  kindleBasic,
  kindleFire,
  kindleDX,
  kindleKids,
  kindleScribe,
  bloodMoon,
  auroraBorealis,
  retroGaming,
  synthwave,
  desertSand,
  arcticBlue,
  crimsonRed,
  emeraldGreen,
  goldenHour,
  silverLining,
  bronzeAge,
  copperField,
  ironForge,
  onyxNight,
  pearlWhite,
  sapphireSea,
  topazSunset,
  jadeForest,
  rubyRed,
  citrineGlow,
  garnetDeep,
  quartzClean,
  vanillaCream,
  chocolateDark,
  coffeeBean,
  brickRed,
  cementGray,
  concreteJungle,
  mossGreen,
  skyBlue,
  cloudWhite,
}

class AppearanceTab extends StatefulWidget {
  const AppearanceTab({Key? key});

  @override
  State<AppearanceTab> createState() => _AppearanceTabState();
}

class _AppearanceTabState extends State<AppearanceTab> {
  @override
  Widget build(BuildContext context) {
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

  ThemeData _getThemeData(ReaderTheme theme) {
    switch (theme) {
      case ReaderTheme.light:
        return ThemeData.light();
      case ReaderTheme.dark:
        return ThemeData.dark();
      case ReaderTheme.sepia:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFAF0E6),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFAF0E6),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF795548)),
          ),
        );
      case ReaderTheme.Akashic:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD4AF37),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF2B1B0E),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFF5DEB3)),
          ),
        );
      case ReaderTheme.darkGreen:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B5E20),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF1B5E20),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF81C784)),
          ),
        );
      case ReaderTheme.grey:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF616161),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF616161),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFCFD8DC)),
          ),
        );
      case ReaderTheme.solarizedLight:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFDF6E3),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFDF6E3),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF586E75)),
          ),
        );
      case ReaderTheme.solarizedDark:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF002B36),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF002B36),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF93A1A1)),
          ),
        );
      case ReaderTheme.translucent:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.grey.withOpacity(0.7),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: Colors.grey.withOpacity(0.7),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.midnightBlue:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A237E),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF1A237E),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFB3E5FC)),
          ),
        );
      case ReaderTheme.lavender:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF3E5F5),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF3E5F5),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF4A148C)),
          ),
        );
      case ReaderTheme.mint:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE8F5E9),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFE8F5E9),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF1B5E20)),
          ),
        );
      case ReaderTheme.sand:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFEDE7F6),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFEDE7F6),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF5D4037)),
          ),
        );
      case ReaderTheme.coral:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFCDD2),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFFCDD2),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFD32F2F)),
          ),
        );
      case ReaderTheme.cyberpunk:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF000000),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF000000),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF00FF00)),
          ),
        );
      case ReaderTheme.highContrast:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: Colors.black,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.yellow),
          ),
        );
      case ReaderTheme.materialLight:
        return ThemeData.light();
      case ReaderTheme.materialDark:
        return ThemeData.dark();
      case ReaderTheme.nord:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E3440),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF2E3440),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFD8DEE9)),
          ),
        );
      case ReaderTheme.roseQuartz:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF8BBD0),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8BBD0),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF880E4F)),
          ),
        );
      case ReaderTheme.amethyst:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD1C4E9),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFD1C4E9),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF4527A0)),
          ),
        );
      case ReaderTheme.forest:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF43A047),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF43A047),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.ocean:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0277BD),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0277BD),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.sunset:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF6F00),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFFFF6F00),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.dracula:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF282A36),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF282A36),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFF8F8F2)),
          ),
        );
      case ReaderTheme.gruvboxLight:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFBF1C7),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFBF1C7),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF3C3836)),
          ),
        );
      case ReaderTheme.gruvboxDark:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF282828),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF282828),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFEBDBB2)),
          ),
        );
      case ReaderTheme.monokai:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF272822),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF272822),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFF8F8F2)),
          ),
        );
      case ReaderTheme.solarized:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFDF6E3),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFDF6E3),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF586E75)),
          ),
        );
      case ReaderTheme.calmingBlue:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFECEFF1),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFECEFF1),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF455A64)),
          ),
        );
      case ReaderTheme.darkOpaque:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF37474F),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF37474F),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFB0BEC5)),
          ),
        );
      case ReaderTheme.lime:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFcddc39),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFcddc39),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF212121)),
          ),
        );
      case ReaderTheme.teal:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF009688),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF009688),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.amber:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFffc107),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFffc107),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF212121)),
          ),
        );
      case ReaderTheme.deepOrange:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFff5722),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFFff5722),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.brown:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF795548),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF795548),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.blueGrey:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF607d8b),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF607d8b),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.indigo:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3f51b5),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF3f51b5),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.cyan:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00bcd4),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFF00bcd4),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF212121)),
          ),
        );
      case ReaderTheme.khaki:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFf0e68c),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFf0e68c),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF212121)),
          ),
        );
      case ReaderTheme.slateGray:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF708090),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF708090),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.rosyBrown:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFbc8f8f),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFFbc8f8f),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.oliveDrab:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6b8e23),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF6b8e23),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.peru:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFcd853f),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFFcd853f),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.darkSlateGray:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2f4f4f),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF2f4f4f),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.cadetBlue:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5f9ea0),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF5f9ea0),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.mediumTurquoise:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF48d1cc),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFF48d1cc),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF212121)),
          ),
        );
      case ReaderTheme.lightSeaGreen:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF20b2aa),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF20b2aa),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.darkCyan:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF008b8b),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF008b8b),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.steelBlue:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4682b4),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF4682b4),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );
      case ReaderTheme.royalBlue:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4169e1),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF4169e1),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        );

      case ReaderTheme.night:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D1D2E),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0D1D2E),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF9AC6FF)),
          ),
        );
      case ReaderTheme.coal:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF36454F),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF36454F),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFD3D3D3)),
          ),
        );
      case ReaderTheme.obsidian:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF000000),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF000000),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF808080)),
          ),
        );
      case ReaderTheme.deepPurple:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF301934),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF301934),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFE0B0FF)),
          ),
        );
      case ReaderTheme.midnight:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF25315B),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF25315B),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFE6E8E9)),
          ),
        );

      case ReaderTheme.kindleClassic:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE3DAC9),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFE3DAC9),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF000000)),
          ),
        );
      case ReaderTheme.kindleEInk:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF2F2F2),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF2F2F2),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
          ),
        );
      case ReaderTheme.kindlePaperwhite:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFAFAFA),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF000000)),
          ),
        );
      case ReaderTheme.kindleOasis:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF9F3E1),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF9F3E1),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF000000)),
          ),
        );
      case ReaderTheme.kindleVoyage:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFEBEBEB),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFEBEBEB),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF0A0A0A)),
          ),
        );
      case ReaderTheme.kindleBasic:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE2D8C7),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFE2D8C7),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF000000)),
          ),
        );
      case ReaderTheme.kindleFire:
        return ThemeData.light();
      case ReaderTheme.kindleDX:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD1CEC7),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFD1CEC7),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF000000)),
          ),
        );
      case ReaderTheme.kindleKids:
        return ThemeData.light();
      case ReaderTheme.kindleScribe:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE8E2D6),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFE8E2D6),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF000000)),
          ),
        );
      case ReaderTheme.bloodMoon:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B0000),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF8B0000),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFFFE4E1)),
          ),
        );
      case ReaderTheme.auroraBorealis:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF004B49),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF004B49),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF7FFFD4)),
          ),
        );
      case ReaderTheme.retroGaming:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF16161D),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF16161D),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFFFD800)),
          ),
        );
      case ReaderTheme.synthwave:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF232323),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF232323),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFFF00FF)),
          ),
        );
      case ReaderTheme.desertSand:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD2B48C),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFD2B48C),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF6F4E37)),
          ),
        );
      case ReaderTheme.arcticBlue:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFADD8E6),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFADD8E6),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF000080)),
          ),
        );
      case ReaderTheme.crimsonRed:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFDC143C),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFFDC143C),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFFFFFFF)),
          ),
        );
      case ReaderTheme.emeraldGreen:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF50C878),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF50C878),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF000000)),
          ),
        );
      case ReaderTheme.goldenHour:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFD700),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFFD700),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF8B4513)),
          ),
        );
      case ReaderTheme.silverLining:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC0C0C0),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFC0C0C0),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF696969)),
          ),
        );
      case ReaderTheme.bronzeAge:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFCD7F32),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFCD7F32),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF222222)),
          ),
        );
      case ReaderTheme.copperField:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB87333),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFB87333),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF000000)),
          ),
        );
      case ReaderTheme.ironForge:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF778899),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF778899),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFFFFFFF)),
          ),
        );
      case ReaderTheme.onyxNight:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF353839),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF353839),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFEEEEEE)),
          ),
        );
      case ReaderTheme.pearlWhite:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF8F8FF),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F8FF),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF696969)),
          ),
        );
      case ReaderTheme.sapphireSea:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F52BA),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0F52BA),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFE6E6FA)),
          ),
        );
      case ReaderTheme.topazSunset:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFC87C),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFFC87C),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF8B4513)),
          ),
        );
      case ReaderTheme.jadeForest:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00A36C),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF00A36C),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFFFFFFF)),
          ),
        );
      case ReaderTheme.rubyRed:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE0115F),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFFE0115F),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFFFFFFF)),
          ),
        );
      case ReaderTheme.citrineGlow:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE4D00A),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFE4D00A),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF2F2F2F)),
          ),
        );
      case ReaderTheme.garnetDeep:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF67001F),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF67001F),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFF08080)),
          ),
        );
      case ReaderTheme.quartzClean:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD8DAE4),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFD8DAE4),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF232323)),
          ),
        );
      case ReaderTheme.vanillaCream:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF3E5AB),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF3E5AB),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF603913)),
          ),
        );
      case ReaderTheme.chocolateDark:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF342D2B),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF342D2B),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFD2691E)),
          ),
        );
      case ReaderTheme.coffeeBean:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2B1B17),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF2B1B17),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFE6D8B9)),
          ),
        );
      case ReaderTheme.brickRed:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB22222),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFFB22222),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFFFFFFF)),
          ),
        );
      case ReaderTheme.cementGray:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF95A5A6),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFF95A5A6),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF2C3E50)),
          ),
        );
      case ReaderTheme.concreteJungle:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7F8C8D),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF7F8C8D),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFFFFFFF)),
          ),
        );
      case ReaderTheme.mossGreen:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8A9A5B),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF8A9A5B),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFFF0F0F0)),
          ),
        );
      case ReaderTheme.skyBlue:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF87CEEB),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFF87CEEB),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF2F4F4F)),
          ),
        );
      case ReaderTheme.cloudWhite:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFEBF4FA),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFEBF4FA),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF696969)),
          ),
        );
    }
  }

  Widget _buildThemeCard(ReaderTheme theme, BuildContext context) {
    final appState = context.watch<AppState>();
    final readerSettings = appState.readerSettings;
    final themeData = _getThemeData(theme);

    return Card(
      color: themeData.scaffoldBackgroundColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final newSettings = ReaderSettings(
            themeIndex: theme.index,
            fontSize: readerSettings.fontSize,
            fontFamily: readerSettings.fontFamily,
            lineHeight: readerSettings.lineHeight,
            textAlignIndex: readerSettings.textAlignIndex,
            backgroundColorValue: themeData.scaffoldBackgroundColor.value,
            textColorValue: themeData.textTheme.bodyMedium!.color!.value,
            fontWeightIndex: readerSettings.fontWeightIndex,
            customJs: readerSettings.customJs,
            customCss: readerSettings.customCss,
            customBackgroundColorValue:
                readerSettings.customBackgroundColorValue,
            customTextColorValue: readerSettings.customTextColorValue,
          );

          context.read<AppState>().setReaderSettings(newSettings);
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
                      color: themeData.textTheme.bodyMedium!.color!,
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
