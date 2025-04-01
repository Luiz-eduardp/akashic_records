import 'package:akashic_records/screens/home_screen.dart';
import 'package:akashic_records/screens/plugins/plugins_screen.dart';
import 'package:akashic_records/screens/settings/settings_screen.dart';
import 'package:akashic_records/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  await appState.initialize();

  runApp(
    ChangeNotifierProvider(create: (context) => appState, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Akashic Records',
      themeMode: appState.themeMode,
      theme: AppThemes.lightTheme(appState.accentColor),
      darkTheme: AppThemes.darkTheme(appState.accentColor),
      home:
          appState.settingsLoaded ? const HomeScreen() : const LoadingScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/plugins': (context) => const PluginsScreen(),
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Carregando...',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
