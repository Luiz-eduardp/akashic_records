import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:akashic_records/screens/shell_screen.dart';
import 'package:akashic_records/services/registry_init.dart';
import 'package:akashic_records/screens/home_screen.dart';
import 'package:akashic_records/screens/local_epubs/local_epubs_screen.dart';
import 'package:akashic_records/screens/settings/settings_screen.dart';
import 'package:akashic_records/screens/reader/reader_screen.dart';
import 'package:akashic_records/screens/favorites_screen.dart';
import 'package:akashic_records/screens/plugins_screen.dart';
import 'package:akashic_records/screens/backups_screen.dart';
import 'package:akashic_records/theme/app_theme.dart';
import 'package:akashic_records/theme/app_colors.dart';
import 'package:akashic_records/theme/app_text_styles.dart';
import 'package:akashic_records/services/app_lifecycle_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  await I18n.initialize(defaultLocale: const Locale('en'));
  registerDefaultPlugins();
  final appState = AppState();
  await appState.initialize();

  WidgetsBinding.instance.addObserver(AppLifecycleHandler(appState));

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
          theme: AppTheme.lightTheme(accentColor: state.accentColor),
          darkTheme: AppTheme.darkTheme(accentColor: state.accentColor),
          builder: (context, child) {
            final widget = child ?? const SizedBox.shrink();
            return Stack(
              children: [
                SafeArea(child: widget),
                if (!state.isOnline)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Container(
                        color: AppColors.warning,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        child: Center(
                          child: Text(
                            'Offline mode: some features may be unavailable',
                            style: AppTextStyles.bodyMedium(Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          home: const ShellScreen(),
          routes: {
            '/home': (ctx) => const HomeScreen(),
            '/backups': (ctx) => const BackupsScreen(),
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
            '/local_epubs': (ctx) => const LocalEpubsScreen(),
            '/plugins': (ctx) => const PluginsScreen(),
          },
        );
      },
    );
  }
}
