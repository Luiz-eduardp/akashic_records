import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/state/app_state.dart';

class AkashicColors {
  static const Color gold = Color(0xFFD4AF37);
  static const Color brownDark = Color(0xFF2B1B0E);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color beige = Color(0xFFF5DEB3);
}

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({
    super.key,
    required this.appState,
    required this.theme,
  });

  final AppState appState;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema:'.translate,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          ThemeModeSelection(appState: appState, theme: theme),
          const SizedBox(height: 24),
          Text(
            'Cor de Destaque:'.translate,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          ColorPalette(appState: appState, theme: theme),
        ],
      ),
    );
  }
}

class ThemeModeSelection extends StatelessWidget {
  const ThemeModeSelection({required this.appState, required this.theme});

  final AppState appState;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ThemeModeTile(
          title: 'Sistema'.translate,
          themeMode: ThemeMode.system,
          appState: appState,
          theme: theme,
        ),
        const SizedBox(height: 8),
        ThemeModeTile(
          title: 'Claro'.translate,
          themeMode: ThemeMode.light,
          appState: appState,
          theme: theme,
        ),
        const SizedBox(height: 8),
        ThemeModeTile(
          title: 'Escuro'.translate,
          themeMode: ThemeMode.dark,
          appState: appState,
          theme: theme,
        ),
      ],
    );
  }
}

class ThemeModeTile extends StatelessWidget {
  const ThemeModeTile({
    required this.title,
    required this.themeMode,
    required this.appState,
    required this.theme,
  });

  final String title;
  final ThemeMode themeMode;
  final AppState appState;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isSelected = appState.themeMode == themeMode;
    return RadioListTile<ThemeMode>(
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      value: themeMode,
      groupValue: appState.themeMode,
      onChanged: (ThemeMode? value) => appState.setThemeMode(value!),
      activeColor: theme.colorScheme.primary,
      tileColor:
          isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

class ColorPalette extends StatelessWidget {
  const ColorPalette({required this.appState, required this.theme});

  final AppState appState;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    const availableColors = [
      AkashicColors.gold,
      AkashicColors.beige,
      AkashicColors.bronze,
      AkashicColors.brownDark,
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
      Colors.amber,
      Colors.cyan,
    ];

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: availableColors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final color = availableColors[index];
          return ColorCard(color: color, appState: appState, theme: theme);
        },
      ),
    );
  }
}

class ColorCard extends StatelessWidget {
  const ColorCard({
    required this.color,
    required this.appState,
    required this.theme,
  });

  final Color color;
  final AppState appState;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isSelected = appState.accentColor.value == color.value;

    return InkWell(
      onTap: () => appState.setAccentColor(color),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? theme.colorScheme.onSurface : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child:
            isSelected
                ? Icon(
                  Icons.check,
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                )
                : null,
      ),
    );
  }
}
