import 'dart:convert';
import 'package:akashic_records/screens/home_screen.dart';
import 'package:akashic_records/screens/plugins/plugins_screen.dart';
import 'package:akashic_records/screens/settings/settings_screen.dart';
import 'package:akashic_records/themes/app_themes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  await appState.initialize();

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
    if (!kDebugMode) {
      _checkVersion(prefs);
    }
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
            print('Removed hasShownInitialScreen due to new version.');
            setState(() {
              _hasShownInitialScreen = false;
            });
          }
        }

        setState(() {});
      } else {
        print('Erro ao buscar releases: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao verificar versão: $e');
    }
  }

  bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    final cleanedLatestVersion =
        latestVersion.startsWith('v')
            ? latestVersion.substring(1)
            : latestVersion;
    return cleanedLatestVersion.compareTo(currentVersion) > 0;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    Widget homeScreen;

    if (kDebugMode) {
      homeScreen = const InitialLoadingScreen();
    } else {
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
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Akashic Records',
      themeMode: appState.themeMode,
      theme: AppThemes.lightTheme(appState.accentColor),
      darkTheme: AppThemes.darkTheme(appState.accentColor),
      home: homeScreen,
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/plugins': (context) => const PluginsScreen(),
      },
    );
  }
}

class InitialLoadingScreen extends StatefulWidget {
  const InitialLoadingScreen({
    super.key,
    this.updateAvailable = false,
    this.downloadUrl,
  });

  final bool updateAvailable;
  final String? downloadUrl;

  @override
  State<InitialLoadingScreen> createState() => _InitialLoadingScreenState();
}

class _InitialLoadingScreenState extends State<InitialLoadingScreen> {
  String _body = 'Carregando...';
  String _uploader = 'Carregando...';
  String _avatarUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/AkashicRecordsApp/akashic_records/releases/latest',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final body = data['body'] as String;
        final author = data['author'];
        final uploaderLogin = author['login'] as String;
        final avatarUrl = author['avatar_url'] as String;

        setState(() {
          _body = body;
          _uploader = uploaderLogin;
          _avatarUrl = avatarUrl;
          _isLoading = false;
        });
      } else {
        setState(() {
          _body = 'Erro ao carregar';
          _uploader = 'Erro ao carregar';
          _isLoading = false;
        });
        print('Erro ao buscar releases: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _body = 'Erro ao carregar';
        _uploader = 'Erro ao carregar';
        _isLoading = false;
      });
      print('Erro: $e');
    }
  }

  Future<void> _setInitialScreenShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasShownInitialScreen', true);
  }

  Future<void> _downloadAndInstall() async {
    if (widget.downloadUrl != null) {
      final Uri url = Uri.parse(widget.downloadUrl!);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch ${widget.downloadUrl}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Carregando dados do GitHub...',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                MarkdownBody(
                  data: _body,
                  onTapLink: (text, url, title) {
                    if (url != null) {
                      launchUrl(Uri.parse(url));
                    }
                  },
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Enviado por:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(backgroundImage: NetworkImage(_avatarUrl)),
                    const SizedBox(width: 8),
                    Text(_uploader),
                  ],
                ),
                if (widget.updateAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _downloadAndInstall();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Atualizar Aplicativo'),
                    ),
                  ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _setInitialScreenShown();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                    child: const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
