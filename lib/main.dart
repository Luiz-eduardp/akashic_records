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
  SharedPreferences prefs;
  Locale initialLocale;
  const List<String> supportedLanguageCodes = ['en', 'pt', 'es', 'ja'];

  try {
    prefs = await SharedPreferences.getInstance();
    final savedLocaleCode = prefs.getString('locale');
    if (savedLocaleCode != null &&
        supportedLanguageCodes.contains(savedLocaleCode)) {
      initialLocale = Locale(savedLocaleCode);
    } else {
      initialLocale = const Locale('en');
    }
  } catch (e) {
    debugPrint("Error loading SharedPreferences or locale: $e");
    prefs = await SharedPreferences.getInstance();
    initialLocale = const Locale('en');
  }

  try {
    await I18n.initialize(
      defaultLocale: initialLocale,
      supportLocales: const [
        Locale('en'),
        Locale('pt'),
        Locale('es'),
        Locale('ja'),
      ],
    );
    debugPrint(
      "I18n Initialized successfully for locale: ${initialLocale.languageCode}",
    );
  } catch (e) {
    debugPrint("Error initializing I18n: $e");
  }

  final appState = AppState();
  try {
    await appState.initialize();
    debugPrint("AppState Initialized successfully.");
  } catch (e) {
    debugPrint("Error initializing AppState: $e");
  }

  runApp(ChangeNotifierProvider.value(value: appState, child: const MyApp()));
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMyAppState();
    });
  }

  Future<void> _initializeMyAppState() async {
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      _hasShownInitialScreen = prefs.getBool('hasShownInitialScreen') ?? false;

      await _checkVersion(prefs);
    } catch (e) {
      debugPrint("Error during MyApp initialization: $e");
      _hasShownInitialScreen = false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkVersion(SharedPreferences prefs) async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/AkashicRecordsApp/akashic_records/releases/latest',
            ),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersionTag = data['tag_name']?.toString() ?? '';
        final latestVersion =
            latestVersionTag.startsWith('v')
                ? latestVersionTag.substring(1)
                : latestVersionTag;

        final assets = data['assets'] as List<dynamic>? ?? [];
        String? apkDownloadUrl;

        for (var asset in assets) {
          final assetName = asset?['name']?.toString();
          if (assetName != null && assetName.endsWith('.apk')) {
            apkDownloadUrl = asset?['browser_download_url'] as String?;
            break;
          }
        }

        if (currentVersion.isNotEmpty && latestVersion.isNotEmpty) {
          _updateAvailable = _isUpdateAvailable(currentVersion, latestVersion);
          _downloadUrl = apkDownloadUrl;

          if (_updateAvailable && _downloadUrl != null) {
            if (!_hasShownInitialScreen) {
              debugPrint(
                "Update available ($latestVersion > $currentVersion), forcing initial screen.",
              );
              await prefs.setBool('hasShownInitialScreen', false);
              if (mounted) {
                setState(() {
                  _hasShownInitialScreen = false;
                });
              }
            }
          }
        } else {
          debugPrint(
            'Could not compare versions: current=$currentVersion, latest=$latestVersion',
          );
        }
      } else {
        debugPrint(
          'Error fetching releases: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('Error checking version: $e');
    }
  }

  bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    try {
      List<int> currentParts =
          currentVersion.split('.').map(int.parse).toList();
      List<int> latestParts = latestVersion.split('.').map(int.parse).toList();

      while (currentParts.length < latestParts.length) {
        currentParts.add(0);
      }
      while (latestParts.length < currentParts.length) {
        latestParts.add(0);
      }

      for (int i = 0; i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) {
          return true;
        } else if (latestParts[i] < currentParts[i]) {
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint(
        "Error comparing versions '$currentVersion' and '$latestVersion': $e",
      );
      return false;
    }
  }

  Future<void> _updateLocale(Locale newLocale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('locale', newLocale.languageCode);
      await I18n.updateLocate(newLocale);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error updating locale: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (_isLoading) {
          return MaterialApp(
            theme: AppThemes.lightTheme(appState.accentColor),
            darkTheme: AppThemes.darkTheme(appState.accentColor),
            themeMode: appState.themeMode,
            locale: I18n.currentLocate,
            supportedLocales: I18n.supportedLocales,
            localizationsDelegates: const [
              I18nDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: appState.accentColor),
              ),
            ),
          );
        }

        Widget homeWidget;
        if (!_hasShownInitialScreen ||
            Provider.of<AppState>(context, listen: false).showChangelog) {
          homeWidget = InitialLoadingScreen(
            updateAvailable: _updateAvailable,
            downloadUrl: _downloadUrl,
            onDone: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasShownInitialScreen', true);
                if (mounted) {
                  setState(() {
                    _hasShownInitialScreen = true;
                  });
                }
                Provider.of<AppState>(
                  context,
                  listen: false,
                ).setShowChangelog(false);
              } catch (e) {
                debugPrint("Error saving 'hasShownInitialScreen': $e");
              }
            },
          );
        } else {
          homeWidget = const HomeScreen();
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
          home: homeWidget,
          routes: {
            '/settings':
                (context) => SettingsScreen(onLocaleChanged: _updateLocale),
            '/plugins': (context) => const PluginsScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}
