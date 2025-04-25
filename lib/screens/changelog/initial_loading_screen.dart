import 'dart:convert';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class InitialLoadingScreen extends StatefulWidget {
  const InitialLoadingScreen({
    super.key,
    this.updateAvailable = false,
    this.downloadUrl,
    required Future<Null> Function() onDone,
  });

  final bool updateAvailable;
  final String? downloadUrl;

  @override
  State<InitialLoadingScreen> createState() => _InitialLoadingScreenState();
}

class _InitialLoadingScreenState extends State<InitialLoadingScreen> {
  String _body = 'Carregando...'.translate;
  String _uploader = 'Carregando...'.translate;
  String _avatarUrl = '';
  bool _isLoading = true;
  String _loadingMessage = 'Carregando dados do GitHub...'.translate;

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
          _body =
              'Falha ao carregar o changelog. Verifique sua conexão com a internet e tente novamente.'
                  .translate;
          _uploader = 'Erro ao carregar'.translate;
          _isLoading = false;
          _loadingMessage = 'Erro ao carregar dados'.translate;
        });
        debugPrint('Erro ao buscar releases: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _body =
            'Falha ao carregar o changelog. Verifique sua conexão com a internet e tente novamente.'
                .translate;
        _uploader = 'Erro ao carregar'.translate;
        _isLoading = false;
        _loadingMessage = 'Erro ao carregar dados'.translate;
      });
      debugPrint('Erro: $e');
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Changelog da Versão'.translate,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surfaceVariant,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        surfaceTintColor: theme.colorScheme.surfaceVariant,
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loadingMessage,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: MarkdownBody(
                            data: _body,
                            onTapLink: (text, url, title) {
                              if (url != null) {
                                launchUrl(Uri.parse(url));
                              }
                            },
                            styleSheet: MarkdownStyleSheet.fromTheme(
                              theme,
                            ).copyWith(
                              p: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                              h1: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              h2: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              h3: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              listBullet: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                              code: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                              blockquoteDecoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2.0,
                                  ),
                                ),
                                color: theme.colorScheme.surfaceVariant
                                    .withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Enviado por:'.translate,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(_avatarUrl),
                          radius: 24,
                        ),
                        title: Text(
                          _uploader,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (widget.updateAvailable)
                        Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.system_update_alt),
                              label: Text('Atualizar Aplicativo'.translate),
                              onPressed: () {
                                _downloadAndInstall();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _setInitialScreenShown();
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Continuar'.translate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
