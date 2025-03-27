// lib/screens/about/about_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo ao Akashic Records!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Na filosofia, os Akashic Records são considerados um registro universal de tudo o que aconteceu, acontece e acontecerá.  É a "biblioteca cósmica" da existência.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Inspirados por essa ideia, o Akashic Records, o aplicativo, busca ser um portal para as histórias, um registro pessoal de suas leituras.  Aqui, você pode mergulhar no mundo das novels, salvar suas favoritas e construir sua própria biblioteca de conhecimento e entretenimento.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'O que o Akashic Records oferece:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Leitura Ilimitada: Explore um vasto catálogo de novels, descobrindo novos mundos e personagens.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Sua Biblioteca Pessoal: Salve suas novels favoritas, crie sua própria biblioteca e acompanhe suas leituras de forma organizada e eficiente.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Fontes Brasileiras: Curadoria cuidadosa com foco em novels em português, garantindo uma experiência de leitura rica e variada, com conteúdo que você adora.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Coleta Inteligente: Utilizamos a técnica de "scrap" para buscar novels em diversos sites, trazendo as melhores histórias diretamente para você.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('Sobre o Desenvolvedor:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Luiz Eduardo, desenvolvedor Fullstack com experiência em Magento, PHP, Flutter, Dart, Vue, React, Native, TypeScript, JavaScript e Python.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _launchURL('https://github.com/Luiz-eduardp'),
              child: Text(
                'Github: https://github.com/Luiz-eduardp',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Agradecemos a você por usar o Akashic Records. Explore, descubra novas histórias e compartilhe suas impressões! Seu feedback é muito importante para continuarmos melhorando.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }
}
