import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:akashic_records/i18n/i18n.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sobre'.translate),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surfaceVariant,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        elevation: 1,
        surfaceTintColor: theme.colorScheme.surfaceVariant,
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
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Na filosofia, os Akashic Records são considerados um registro universal de tudo o que aconteceu, acontece e acontecerá. É a "biblioteca cósmica" da existência.'
                    .translate,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Inspirados por essa ideia, o Akashic Records, o aplicativo, busca ser um portal para as histórias, um registro pessoal de suas leituras. Aqui, você pode mergulhar no mundo das novels, salvar suas favoritas e construir sua própria biblioteca de conhecimento e entretenimento.'
                    .translate,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'O que o Akashic Records oferece:'.translate,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                theme,
                'Leitura Ilimitada: Explore um vasto catálogo de novels, descobrindo novos mundos e personagens.'
                    .translate,
              ),
              _buildFeatureItem(
                theme,
                'Sua Biblioteca Pessoal: Salve suas novels favoritas, crie sua própria biblioteca e acompanhe suas leituras de forma organizada e eficiente.'
                    .translate,
              ),
              _buildFeatureItem(
                theme,
                'Fontes Brasileiras: Curadoria cuidadosa com foco em novels em português, garantindo uma experiência de leitura rica e variada, com conteúdo que você adora.'
                    .translate,
              ),
              _buildFeatureItem(
                theme,
                'Coleta Inteligente: Utilizamos a técnica de "scrap" para buscar novels em diversos sites, trazendo as melhores histórias diretamente para você.'
                    .translate,
              ),
              const SizedBox(height: 24),
              Text(
                'Sobre o Desenvolvedor:'.translate,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Luiz Eduardo, desenvolvedor Fullstack com experiência em Magento, PHP, Flutter, Dart, Vue, React, Native, TypeScript, JavaScript e Python.'
                    .translate,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _launchURL('https://github.com/Luiz-eduardp'),
                child: Text(
                  'Github: https://github.com/Luiz-eduardp',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Agradecemos a você por usar o Akashic Records. Explore, descubra novas histórias e compartilhe suas impressões! Seu feedback é muito importante para continuarmos melhorando.'
                    .translate,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildFeatureItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
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
