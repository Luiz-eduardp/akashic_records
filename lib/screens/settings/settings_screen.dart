import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/screens/about/about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aparência',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _ThemeSettings(appState: appState, theme: theme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _AboutButton(),
    );
  }
}

class _ThemeSettings extends StatelessWidget {
  const _ThemeSettings({required this.appState, required this.theme});

  final AppState appState;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tema:', style: theme.textTheme.titleMedium),
        RadioListTile<ThemeMode>(
          title: const Text('Sistema'),
          value: ThemeMode.system,
          groupValue: appState.themeMode,
          onChanged: (ThemeMode? value) {
            appState.setThemeMode(value!);
          },
          activeColor: theme.colorScheme.secondary,
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Claro'),
          value: ThemeMode.light,
          groupValue: appState.themeMode,
          onChanged: (ThemeMode? value) {
            appState.setThemeMode(value!);
          },
          activeColor: theme.colorScheme.secondary,
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Escuro'),
          value: ThemeMode.dark,
          groupValue: appState.themeMode,
          onChanged: (ThemeMode? value) {
            appState.setThemeMode(value!);
          },
          activeColor: theme.colorScheme.secondary,
        ),
        const SizedBox(height: 16),
        Text('Cor de Destaque:', style: theme.textTheme.titleMedium),
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
              .map((color) => _ColorButton(color: color, appState: appState))
              .toList(),
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({required this.color, required this.appState});

  final Color color;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        appState.setAccentColor(color);
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                appState.accentColor == color
                    ? Colors.black
                    : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _AboutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text('Sobre'),
      ),
    );
  }
}
