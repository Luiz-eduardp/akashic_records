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
        if (kDebugMode) {
          print('Erro ao buscar releases: ${response.statusCode}');
        }
      }
    } catch (e) {
      setState(() {
        _latestVersion = 'Erro ao carregar'.translate;
        _isLoading = false;
      });
      if (kDebugMode) {
        print('Erro: $e');
      }
    }
  }

  Future<void> _resetInitialScreenPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasShownInitialScreen');
    if (kDebugMode) {
      print('hasShownInitialScreen preference reset.');
    }
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
        backgroundColor: theme.colorScheme.surfaceVariant,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        surfaceTintColor: theme.colorScheme.surfaceVariant,
        scrolledUnderElevation: 3,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: I18n.currentLocate,
                icon: Icon(
                  Icons.language,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                dropdownColor: theme.colorScheme.surface,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                items:
                    I18n.supportedLocales.map((Locale locale) {
                      return DropdownMenuItem<Locale>(
                        value: locale,
                        child: Text(
                          locale.languageCode,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                onChanged: (Locale? newLocale) async {
                  if (newLocale != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('locale', newLocale.languageCode);
                    await I18n.updateLocate(newLocale);
                    widget.onLocaleChanged(newLocale);
                  }
                },
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.onSurface,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
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
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAppearanceTab(theme, appState),
            _buildUpdateTab(theme),
          ],
        ),
      ),
      bottomNavigationBar: _AboutButton(),
    );
  }

  Widget _buildAppearanceTab(ThemeData theme, AppState appState) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child:
          _isLoading
              ? const SkeletonCard()
              : Card(
                elevation: 1,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _ThemeSettings(appState: appState, theme: theme),
                ),
              ),
    );
  }

  Widget _buildUpdateTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child:
          _isLoading
              ? const SkeletonCard()
              : Card(
                elevation: 1,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingsTile(
                        title: 'Versão do Aplicativo'.translate,
                        subtitle: _currentVersion,
                      ),
                      SettingsTile(
                        title: 'Última Versão'.translate,
                        subtitle:
                            _isLoading
                                ? 'Carregando...'.translate
                                : _latestVersion,
                      ),
                      const SizedBox(height: 16),
                      if (_updateAvailable)
                        ElevatedButton(
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
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
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
                    ],
                  ),
                ),
              ),
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
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
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
        Text(
          'Tema:'.translate,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        RadioListTile<ThemeMode>(
          title: Text(
            'Sistema'.translate,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          value: ThemeMode.system,
          groupValue: appState.themeMode,
          onChanged: (ThemeMode? value) {
            appState.setThemeMode(value!);
          },
          activeColor: theme.colorScheme.primary,
          controlAffinity: ListTileControlAffinity.platform,
        ),
        RadioListTile<ThemeMode>(
          title: Text(
            'Claro'.translate,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          value: ThemeMode.light,
          groupValue: appState.themeMode,
          onChanged: (ThemeMode? value) {
            appState.setThemeMode(value!);
          },
          activeColor: theme.colorScheme.primary,
          controlAffinity: ListTileControlAffinity.platform,
        ),
        RadioListTile<ThemeMode>(
          title: Text(
            'Escuro'.translate,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          value: ThemeMode.dark,
          groupValue: appState.themeMode,
          onChanged: (ThemeMode? value) {
            appState.setThemeMode(value!);
          },
          activeColor: theme.colorScheme.primary,
          controlAffinity: ListTileControlAffinity.platform,
        ),
        const SizedBox(height: 16),
        Text(
          'Cor de Destaque:'.translate,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
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
              .map(
                (color) => _ColorButton(
                  color: color,
                  appState: appState,
                  theme: theme,
                ),
              )
              .toList(),
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.color,
    required this.appState,
    required this.theme,
  });

  final Color color;
  final AppState appState;
  final ThemeData theme;

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
                    ? theme.colorScheme.onSurface
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
        color: theme.colorScheme.surfaceVariant,
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
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
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

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonLine(context, theme, widthFactor: 0.8),
            const SizedBox(height: 10),
            _buildSkeletonLine(context, theme, widthFactor: 0.6),
            const SizedBox(height: 20),
            _buildSkeletonLine(context, theme),
            const SizedBox(height: 10),
            _buildSkeletonLine(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLine(
    BuildContext context,
    ThemeData theme, {
    double widthFactor = 1.0,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * widthFactor,
      height: 10,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
