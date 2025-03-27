import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/screens/about/about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children:
                  availableColors
                      .map((color) => _buildColorButton(color, appState, theme))
                      .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
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
      ),
    );
  }

  Widget _buildColorButton(Color color, AppState appState, ThemeData theme) {
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
