import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/screens/about/about_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentVersion = 'Carregando...';
  String _latestVersion = 'Carregando...';
  String? _downloadUrl;
  bool _updateAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentVersion = packageInfo.version;
      });

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

        setState(() {
          _latestVersion = latestVersion;
          _downloadUrl = apkDownloadUrl;
          _updateAvailable = _isUpdateAvailable(
            _currentVersion,
            _latestVersion,
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _latestVersion = 'Erro ao carregar';
          _isLoading = false;
        });
        print('Erro ao buscar releases: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _latestVersion = 'Erro ao carregar';
        _isLoading = false;
      });
      print('Erro: $e');
    }
  }

  bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    return latestVersion.compareTo('v$currentVersion') > 0;
  }

  Future<void> _downloadAndInstall() async {
    if (_downloadUrl != null) {
      final Uri url = Uri.parse(_downloadUrl!);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $_downloadUrl');
      }
    }
  }

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
              Text(
                'Atualização',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Versão do Aplicativo'),
                subtitle: Text('Atual: $_currentVersion'),
              ),
              ListTile(
                title: const Text('Última Versão'),
                subtitle:
                    _isLoading
                        ? const Text('Carregando...')
                        : Text(_latestVersion),
              ),
              if (_updateAvailable)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (kIsWeb) {
                        launchUrl(
                          Uri.parse(
                            'https://github.com/AkashicRecordsApp/akashic_records/releases/latest',
                          ),
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        _downloadAndInstall();
                      }
                    },
                    child: const Text('Atualizar Aplicativo'),
                  ),
                ),
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
