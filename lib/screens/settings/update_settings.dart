import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'settings_tile.dart';

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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsTile(
          title: 'Versão do Aplicativo'.translate,
          subtitle: _currentVersion,
        ),
        SettingsTile(
          title: 'Última Versão'.translate,
          subtitle: _isLoading ? 'Carregando...'.translate : _latestVersion,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Atualizar Aplicativo'.translate),
          ),
      ],
    );
  }
}
