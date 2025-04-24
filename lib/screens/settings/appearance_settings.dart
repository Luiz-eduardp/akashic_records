import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/state/app_state.dart';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema:'.translate,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          _ThemeModeSelection(appState: appState, theme: theme),
          const SizedBox(height: 24),
          Text(
            'Cor de Destaque:'.translate,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          _ColorPalette(appState: appState, theme: theme),
        ],
      ),
    );
  }
}

class _ThemeModeSelection extends StatelessWidget {
  const _ThemeModeSelection({required this.appState, required this.theme});

  final AppState appState;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ThemeModeCard(
          title: 'Sistema'.translate,
          themeMode: ThemeMode.system,
          appState: appState,
          theme: theme,
        ),
        const SizedBox(height: 8),
        _ThemeModeCard(
          title: 'Claro'.translate,
          themeMode: ThemeMode.light,
          appState: appState,
          theme: theme,
        ),
        const SizedBox(height: 8),
        _ThemeModeCard(
          title: 'Escuro'.translate,
          themeMode: ThemeMode.dark,
          appState: appState,
          theme: theme,
        ),
      ],
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
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
    return InkWell(
      onTap: () {
        appState.setThemeMode(themeMode);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Radio<ThemeMode>(
              value: themeMode,
              groupValue: appState.themeMode,
              onChanged: (ThemeMode? value) {
                appState.setThemeMode(value!);
              },
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPalette extends StatelessWidget {
  const _ColorPalette({required this.appState, required this.theme});

  final AppState appState;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final List<Color> availableColors = [
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
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: availableColors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final color = availableColors[index];
          return _ColorCard(color: color, appState: appState, theme: theme);
        },
      ),
    );
  }
}

class _ColorCard extends StatelessWidget {
  const _ColorCard({
    required this.color,
    required this.appState,
    required this.theme,
  });

  final Color color;
  final AppState appState;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isSelected = appState.accentColor == color;

    return GestureDetector(
      onTap: () {
        appState.setAccentColor(color);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? theme.colorScheme.onSurface : Colors.transparent,
            width: 3,
          ),
        ),
        child:
            isSelected
                ? Center(
                  child: Icon(
                    Icons.check,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                )
                : null,
      ),
    );
  }
}
