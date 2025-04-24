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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tema:'.translate,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        RadioListTile<ThemeMode>(
          title: Text(
            'Sistema'.translate,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          value: ThemeMode.system,
          groupValue: appState.themeMode,
          onChanged: (ThemeMode? value) {
            appState.setThemeMode(value!);
          },
          activeColor: theme.colorScheme.primary,
          controlAffinity: ListTileControlAffinity.platform,
        ),
        RadioListTile<ThemeMode>(
          title: Text(
            'Claro'.translate,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          value: ThemeMode.light,
          groupValue: appState.themeMode,
          onChanged: (ThemeMode? value) {
            appState.setThemeMode(value!);
          },
          activeColor: theme.colorScheme.primary,
          controlAffinity: ListTileControlAffinity.platform,
        ),
        RadioListTile<ThemeMode>(
          title: Text(
            'Escuro'.translate,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          value: ThemeMode.dark,
          groupValue: appState.themeMode,
          onChanged: (ThemeMode? value) {
            appState.setThemeMode(value!);
          },
          activeColor: theme.colorScheme.primary,
          controlAffinity: ListTileControlAffinity.platform,
        ),
        const SizedBox(height: 16),
        Text(
          'Cor de Destaque:'.translate,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        _ColorPalette(appState: appState, theme: theme),
      ],
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

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children:
          availableColors
              .map(
                (color) => _ColorButton(
                  color: color,
                  appState: appState,
                  theme: theme,
                ),
              )
              .toList(),
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.color,
    required this.appState,
    required this.theme,
  });

  final Color color;
  final AppState appState;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        appState.setAccentColor(color);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                appState.accentColor == color
                    ? theme.colorScheme.onSurface
                    : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}
