import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/screens/about/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:akashic_records/utils/backup_restore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onLocaleChanged});

  final Function(Locale) onLocaleChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _onLocaleChange(Locale? newLocale) async {
    if (newLocale != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('locale', newLocale.languageCode);
      await I18n.updateLocate(newLocale);
      widget.onLocaleChanged(newLocale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'.translate),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildLanguageSetting(context, theme),
          const Divider(),
          _buildSectionTitle(context, 'Aparência'.translate, theme),
          _buildAppearanceSetting(context, appState, theme),
          const Divider(),
          _buildSectionTitle(context, 'Atualização'.translate, theme),
          UpdateSettings(),
          const Divider(),
          _buildSectionTitle(context, 'Backup e Restauração'.translate, theme),
          _buildBackupRestoreSettings(context, appState, theme),
          const Divider(),
          _buildSectionTitle(context, 'Sobre'.translate, theme),
          _buildAboutSetting(context, theme),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLanguageSetting(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Idioma'.translate, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Selecione o idioma da aplicação.'.translate,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Locale>(
              value: I18n.currentLocate,
              decoration: InputDecoration(
                labelText: 'Idioma'.translate,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items:
                  I18n.supportedLocales.map((locale) {
                    return DropdownMenuItem(
                      value: locale,
                      child: Text(locale.languageCode),
                    );
                  }).toList(),
              onChanged: _onLocaleChange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSetting(
    BuildContext context,
    AppState appState,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalize o tema e a cor de destaque da aplicação.'.translate,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.brightness_4),
              title: Text('Tema'.translate),
              subtitle: Text(_getThemeModeDescription(appState.themeMode)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showThemeModeDialog(context, appState, theme),
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: Text('Cor de destaque'.translate),
              subtitle: Text('Toque para alterar'.translate),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showColorPickerDialog(context, appState, theme),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Sistema'.translate;
      case ThemeMode.light:
        return 'Claro'.translate;
      case ThemeMode.dark:
        return 'Escuro'.translate;
    }
  }

  void _showThemeModeDialog(
    BuildContext context,
    AppState appState,
    ThemeData theme,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecionar Tema'.translate),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text('Sistema'.translate),
                value: ThemeMode.system,
                groupValue: appState.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    appState.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('Claro'.translate),
                value: ThemeMode.light,
                groupValue: appState.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    appState.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('Escuro'.translate),
                value: ThemeMode.dark,
                groupValue: appState.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    appState.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'.translate),
            ),
          ],
        );
      },
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    AppState appState,
    ThemeData theme,
  ) {
    const availableColors = [
      AkashicColors.gold,
      AkashicColors.beige,
      AkashicColors.bronze,
      AkashicColors.brownDark,
      Color(0xFF2E294E),
      Color(0xFFF5F5DC),
      Color(0xFF121212),
      Color(0xFF704214),
      Color(0xFF006400),
      Colors.grey,
      Color(0xFFFDF6E3),
      Color(0xFF002B36),
      Color.fromRGBO(0, 0, 0, 0.5),
      Color(0xFF191970),
      Color(0xFFE6E6FA),
      Color(0xFF3EB489),
      Color(0xFFC2B280),
      Color(0xFFFF7F50),
      Color(0xFFF0F8FF),
      Color(0xFF000000),
      Color(0xFFFAFAFA),
      Color(0xFF303030),
      Color(0xFF2E3440),
      Color(0xFFF7CAC9),
      Color(0xFF9966CC),
      Color(0xFF228B22),
      Color(0xFF4682B4),
      Color(0xFFFF8000),
      Color(0xFF282a36),
      Color(0xFFFBF1C7),
      Color(0xFF282828),
      Color(0xFF272822),
      Color(0xFFFDF6E3),
      Color(0xFFADD8E6),
      Color(0xFF333333),
      Colors.lime,
      Colors.teal,
      Colors.amber,
      Color(0xFFFF4500),
      Colors.brown,
      Color(0xFF607D8B),
      Colors.indigo,
      Colors.cyan,
      Color(0xFFF0E68C),
      Color(0xFF708090),
      Color(0xFFBC8F8F),
      Color(0xFF6B8E23),
      Color(0xFFCD853F),
      Color(0xFF2F4F4F),
      Color(0xFF5F9EA0),
      Color(0xFF48D1CC),
      Color(0xFF20B2AA),
      Color(0xFF008B8B),
      Color(0xFF4682B4),
      Color(0xFF4169E1),
      Color(0xFF0C090A),
      Color(0xFF34282C),
      Color(0xFF3F3F3F),
      Color(0xFF301934),
      Color(0xFF191970),
      Color(0xFFC6B38A),
      Color(0xFFF2F1E9),
      Color(0xFFF5F5DC),
      Color(0xFFE9E3D4),
      Color(0xFFD1C5B5),
      Color(0xFFECE6D9),
      Color(0xFFBFA88B),
      Color(0xFFA79278),
      Color(0xFFE0D8C3),
      Color(0xFFD8CDBE),
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecionar Cor de Destaque'.translate),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: availableColors.length,
              itemBuilder: (context, index) {
                final color = availableColors[index];
                final isSelected = appState.accentColor.value == color.value;

                return InkWell(
                  onTap: () {
                    appState.setAccentColor(color);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected
                                ? theme.colorScheme.onSurface
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child:
                        isSelected
                            ? Icon(
                              Icons.check,
                              color:
                                  useWhiteForeground(color)
                                      ? Colors.white
                                      : Colors.black,
                            )
                            : null,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'.translate),
            ),
          ],
        );
      },
    );
  }

  bool useWhiteForeground(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
  }

  Widget _buildBackupRestoreSettings(
    BuildContext context,
    AppState appState,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Faça backup ou restaure os dados do seu aplicativo.'.translate,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: Text('Fazer Backup'.translate),
              subtitle: Text(
                'Exportar dados do aplicativo para um arquivo JSON'.translate,
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final filePath = await exportBackup(appState);
                if (filePath.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Backup salvo em:'.translate + filePath),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao fazer backup'.translate)),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: Text('Restaurar Backup'.translate),
              subtitle: Text(
                'Importar dados do aplicativo de um arquivo JSON'.translate,
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final success = await importBackup(appState);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Backup restaurado com sucesso!'.translate),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao restaurar backup'.translate),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSetting(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações sobre a aplicação e seus desenvolvedores.'.translate,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                'Sobre o aplicativo'.translate,
                textAlign: TextAlign.start,
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AkashicColors {
  static const Color gold = Color(0xFFD4AF37);
  static const Color brownDark = Color(0xFF2B1B0E);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color beige = Color(0xFFF5DEB3);
}

class UpdateSettings extends StatefulWidget {
  const UpdateSettings({super.key});

  @override
  State<UpdateSettings> createState() => _UpdateSettingsState();
}

class _UpdateSettingsState extends State<UpdateSettings> {
  String _currentVersion = 'Carregando...'.translate;
  String _latestVersion = 'Carregando...'.translate;
  String? _downloadUrl;
  bool _updateAvailable = false;
  bool _isLoading = true;
  bool _errorLoading = false;

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

      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/AkashicRecordsApp/akashic_records/releases/latest',
            ),
          )
          .timeout(const Duration(seconds: 10));

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
          _errorLoading = false;
        });
      } else {
        setState(() {
          _latestVersion = 'Erro ao carregar'.translate;
          _isLoading = false;
          _errorLoading = true;
        });
        if (kDebugMode) {
          print('Erro ao buscar releases: ${response.statusCode}');
        }
      }
    } catch (e) {
      setState(() {
        _latestVersion = 'Erro ao carregar'.translate;
        _isLoading = false;
        _errorLoading = true;
      });
      if (kDebugMode) {
        print('Erro: $e');
      }
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
      try {
        final Uri url = Uri.parse(_downloadUrl!);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          throw Exception('Could not launch $_downloadUrl');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir o link de download: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.info),
          title: Text('Versão do Aplicativo'.translate),
          subtitle: Text(_currentVersion),
        ),
        ListTile(
          leading: const Icon(Icons.system_update),
          title: Text('Última Versão'.translate),
          subtitle: Text(
            _isLoading
                ? 'Carregando...'.translate
                : _errorLoading
                ? 'Erro ao carregar'.translate
                : _latestVersion,
          ),
        ),
        const SizedBox(height: 10),
        if (_errorLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Falha ao verificar atualizações. Verifique sua conexão com a internet.'
                  .translate,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        if (_updateAvailable && !_errorLoading)
          ElevatedButton.icon(
            icon: const Icon(Icons.system_update_alt),
            label: Text('Atualizar Aplicativo'.translate),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}
