import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:akashic_records/screens/shell_screen.dart';
import 'package:akashic_records/services/registry_init.dart';
import 'package:akashic_records/screens/home_screen.dart';
import 'package:akashic_records/screens/settings/settings_screen.dart';
import 'package:akashic_records/screens/reader/reader_screen.dart';
import 'package:akashic_records/screens/favorites_screen.dart';
import 'package:akashic_records/screens/updates_screen.dart';
import 'package:akashic_records/screens/plugins_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await I18n.initialize(defaultLocale: const Locale('en'));
  registerDefaultPlugins();
  final appState = AppState();
  await appState.initialize();
  runApp(ChangeNotifierProvider.value(value: appState, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return MaterialApp(
          title: 'Akashic Records'.translate,
          locale: state.currentLocale,
          supportedLocales: I18n.supportedLocales,
          localizationsDelegates: [
            I18nDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          themeMode: state.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: state.accentColor,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: state.accentColor,
          ),
          builder: (context, child) {
            return SafeArea(child: child ?? const SizedBox.shrink());
          },
          home: const ShellScreen(),
          routes: {
            '/home': (ctx) => const HomeScreen(),
            '/settings':
                (ctx) => SettingsScreen(
                  onLocaleChanged: (locale) async {
                    await I18n.updateLocate(locale);
                    await Provider.of<AppState>(
                      ctx,
                      listen: false,
                    ).setLocale(locale);
                  },
                ),
            '/reader': (ctx) => const ReaderScreen(),
            '/favorites': (ctx) => const FavoritesScreen(),
            '/updates': (ctx) => const UpdatesScreen(),
            '/plugins': (ctx) => const PluginsScreen(),
          },
        );
      },
    );
  }
}
