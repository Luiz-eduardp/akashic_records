import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = 'Carregando...'.translate;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sobre'.translate,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bem-vindo ao Akashic Records!'.translate,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Na filosofia, os Akashic Records são considerados um registro universal de tudo o que aconteceu, acontece e acontecerá. É a "biblioteca cósmica" da existência.'
                    .translate,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Inspirados por essa ideia, o Akashic Records, o aplicativo, busca ser um portal para as histórias, um registro pessoal de suas leituras. Aqui, você pode mergulhar no mundo das novels, salvar suas favoritas e construir sua própria biblioteca de conhecimento e entretenimento.'
                    .translate,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              _SectionTitle(
                title: 'O que o Akashic Records oferece:'.translate,
              ),
              const SizedBox(height: 12),
              _FeatureItem(
                text:
                    'Leitura Ilimitada: Explore um vasto catálogo de novels, descobrindo novos mundos e personagens.'
                        .translate,
              ),
              _FeatureItem(
                text:
                    'Sua Biblioteca Pessoal: Salve suas novels favoritas, crie sua própria biblioteca e acompanhe suas leituras de forma organizada e eficiente.'
                        .translate,
              ),
              _FeatureItem(
                text:
                    'Fontes Brasileiras: Curadoria cuidadosa com foco em novels em português, garantindo uma experiência de leitura rica e variada, com conteúdo que você adora.'
                        .translate,
              ),
              _FeatureItem(
                text:
                    'Coleta Inteligente: Utilizamos a técnica de "scrap" para buscar novels em diversos sites, trazendo as melhores histórias diretamente para você.'
                        .translate,
              ),

              const SizedBox(height: 24),

              _SectionTitle(title: 'Sobre o Desenvolvedor:'.translate),
              const SizedBox(height: 12),
              Text(
                'Luiz Eduardo, desenvolvedor Fullstack com experiência em Magento, PHP, Flutter, Dart, Vue, React, Native, TypeScript, JavaScript e Python.'
                    .translate,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              _LinkText(
                url: 'https://github.com/Luiz-eduardp',
                text: 'Github: https://github.com/Luiz-eduardp',
              ),

              const SizedBox(height: 24),

              ListTile(
                title: Text(
                  'Versão do Aplicativo'.translate,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(_version),
              ),

              const SizedBox(height: 24),

              Text(
                'Agradecemos a você por usar o Akashic Records. Explore, descubra novas histórias e compartilhe suas impressões! Seu feedback é muito importante para continuarmos melhorando.'
                    .translate,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  final String url;
  final String text;

  const _LinkText({required this.url, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: () => _launchURL(url),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }
}
