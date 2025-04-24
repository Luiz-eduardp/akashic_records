import 'dart:convert';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/screens/home_screen.dart';
import 'package:akashic_records/screens/plugins/plugins_screen.dart';
import 'package:akashic_records/screens/settings/settings_screen.dart';
import 'package:akashic_records/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:akashic_records/screens/changelog/initial_loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  await appState.initialize();

  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale');
  Locale initialLocale =
      savedLocale != null ? Locale(savedLocale) : const Locale('en');

  await I18n.initialize(
    defaultLocale: initialLocale,
    supportLocales: const [Locale('en'), Locale('pt'), Locale('es')],
  );

  runApp(
    ChangeNotifierProvider(create: (context) => appState, child: const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasShownInitialScreen = false;
  bool _isLoading = true;
  bool _updateAvailable = false;
  String? _downloadUrl;

  @override
  void initState() {
    super.initState();
    _checkIfInitialScreenShown();
  }

  Future<void> _checkIfInitialScreenShown() async {
    final prefs = await SharedPreferences.getInstance();
    _hasShownInitialScreen = prefs.getBool('hasShownInitialScreen') ?? false;
    setState(() {
      _isLoading = false;
    });

    _checkVersion(prefs);
  }

  Future<void> _checkVersion(SharedPreferences prefs) async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/AkashicRecordsApp/akashic_records/releases/latest',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name'] as String;
        final assets = data['assets'] as List<dynamic>;
        String? apkDownloadUrl;

        for (var asset in assets) {
          if (asset['name'].toString().endsWith('.apk')) {
            apkDownloadUrl = asset['browser_download_url'] as String;
            break;
          }
        }

        _updateAvailable = _isUpdateAvailable(currentVersion, latestVersion);
        _downloadUrl = apkDownloadUrl;

        if (_updateAvailable) {
          if (_hasShownInitialScreen) {
            await prefs.remove('hasShownInitialScreen');

            setState(() {
              _hasShownInitialScreen = false;
            });
          }
        }

        setState(() {});
      } else {
        debugPrint('Erro ao buscar releases: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao verificar versão: $e');
    }
  }

  bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    final latestParts = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < currentParts.length; i++) {
      if (i >= latestParts.length) break;
      if (currentParts[i] < latestParts[i]) return true;
      if (currentParts[i] > latestParts[i]) return false;
    }

    return latestParts.length > currentParts.length;
  }

  Future<void> _updateLocale(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale.languageCode);
    setState(() {
      I18n.updateLocate(newLocale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (_isLoading) {
      return MaterialApp(
        theme: AppThemes.lightTheme(appState.accentColor),
        darkTheme: AppThemes.darkTheme(appState.accentColor),
        themeMode: ThemeMode.system,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: appState.accentColor),
          ),
        ),
        locale: I18n.currentLocate,
        supportedLocales: I18n.supportedLocales,
        localizationsDelegates: const [
          I18nDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
      );
    }

    Widget homeScreen;

    if (_hasShownInitialScreen) {
      homeScreen = const HomeScreen();
    } else {
      homeScreen = Scaffold(
        body: InitialLoadingScreen(
          updateAvailable: _updateAvailable,
          downloadUrl: _downloadUrl,
        ),
      );
    }

    return MaterialApp(
      locale: I18n.currentLocate,
      supportedLocales: I18n.supportedLocales,
      localizationsDelegates: const [
        I18nDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: 'Akashic Records'.translate,
      themeMode: appState.themeMode,
      theme: AppThemes.lightTheme(appState.accentColor),
      darkTheme: AppThemes.darkTheme(appState.accentColor),
      home: homeScreen,
      routes: {
        '/settings':
            (context) => SettingsScreen(onLocaleChanged: _updateLocale),
        '/plugins': (context) => const PluginsScreen(),
      },
    );
  }
}
