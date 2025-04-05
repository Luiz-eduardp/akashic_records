import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/screens/about/about_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onLocaleChanged});

  final Function(Locale) onLocaleChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  String _currentVersion = 'Carregando...'.translate;
  String _latestVersion = 'Carregando...'.translate;
  String? _downloadUrl;
  bool _updateAvailable = false;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _checkVersion();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

        if (_isUpdateAvailable(_currentVersion, _latestVersion)) {
          await _resetInitialScreenPreference();
        }
      } else {
        setState(() {
          _latestVersion = 'Erro ao carregar'.translate;
          _isLoading = false;
        });
        print('Erro ao buscar releases: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _latestVersion = 'Erro ao carregar'.translate;
        _isLoading = false;
      });
      print('Erro: $e');
    }
  }

  Future<void> _resetInitialScreenPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasShownInitialScreen');
    print('hasShownInitialScreen preference reset.');
  }

  bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    final cleanedLatestVersion =
        latestVersion.startsWith('v')
            ? latestVersion.substring(1)
            : latestVersion;
    return cleanedLatestVersion.compareTo(currentVersion) > 0;
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
      appBar: AppBar(
        title: Text('Configurações'.translate),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          DropdownButton<Locale>(
            value: I18n.currentLocate,
            icon: const Icon(Icons.language, color: Colors.white),
            dropdownColor: theme.colorScheme.primary,
            style: TextStyle(color: theme.colorScheme.onPrimary),
            items:
                I18n.supportedLocales.map((Locale locale) {
                  return DropdownMenuItem<Locale>(
                    value: locale,
                    child: Text(locale.languageCode),
                  );
                }).toList(),
            onChanged: (Locale? newLocale) async {
              if (newLocale != null) {
                await I18n.updateLocate(newLocale);
                widget.onLocaleChanged(newLocale);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.secondary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
          tabs: [
            Tab(text: 'Aparência'.translate, icon: const Icon(Icons.palette)),
            Tab(
              text: 'Atualização'.translate,
              icon: const Icon(Icons.system_update),
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.background,
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: _ThemeSettings(appState: appState, theme: theme),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SettingsTile(
                    title: 'Versão do Aplicativo'.translate,
                    subtitle: 'Atual: $_currentVersion'.translate,
                  ),
                  SettingsTile(
                    title: 'Última Versão'.translate,
                    subtitle:
                        _isLoading ? 'Carregando...'.translate : _latestVersion,
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Atualizar Aplicativo'.translate),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _AboutButton(),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
      ),
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
        Text('Tema:'.translate, style: theme.textTheme.titleMedium),
        RadioListTile<ThemeMode>(
          title: Text('Sistema'.translate),
          value: ThemeMode.system,
          groupValue: appState.themeMode,
          onChanged: (ThemeMode? value) {
            appState.setThemeMode(value!);
          },
          activeColor: theme.colorScheme.secondary,
          controlAffinity: ListTileControlAffinity.platform,
        ),
        RadioListTile<ThemeMode>(
          title: Text('Claro'.translate),
          value: ThemeMode.light,
          groupValue: appState.themeMode,
          onChanged: (ThemeMode? value) {
            appState.setThemeMode(value!);
          },
          activeColor: theme.colorScheme.secondary,
          controlAffinity: ListTileControlAffinity.platform,
        ),
        RadioListTile<ThemeMode>(
          title: Text('Escuro'.translate),
          value: ThemeMode.dark,
          groupValue: appState.themeMode,
          onChanged: (ThemeMode? value) {
            appState.setThemeMode(value!);
          },
          activeColor: theme.colorScheme.secondary,
          controlAffinity: ListTileControlAffinity.platform,
        ),
        const SizedBox(height: 16),
        Text('Cor de Destaque:'.translate, style: theme.textTheme.titleMedium),
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                appState.accentColor == color
                    ? Colors.black
                    : Colors.transparent,
            width: 3,
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

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('Sobre'.translate),
      ),
    );
  }
}
