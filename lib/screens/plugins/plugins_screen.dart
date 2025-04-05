import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:url_launcher/url_launcher.dart';

class PluginsScreen extends StatefulWidget {
  const PluginsScreen({super.key});

  @override
  State<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends State<PluginsScreen> {
  final List<String> availablePluginsPtBr = [
    'NovelMania',
    'Tsundoku',
    'CentralNovel',
    'MtlNovelPt',
    'LightNovelBrasil'
  ];

  final List<String> availablePluginsEn = ['NovelsOnline', 'RoyalRoad'];

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final appState = Provider.of<AppState>(context);
    final selectedPlugins = appState.selectedPlugins;

    return Scaffold(
      appBar: AppBar(title: const Text('Plugins'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPluginSection(
              context,
              'Português (Brasil)',
              availablePluginsPtBr,
              selectedPlugins,
              appState,
            ),
            const SizedBox(height: 24),
            _buildPluginSection(
              context,
              'Inglês',
              availablePluginsEn,
              selectedPlugins,
              appState,
            ),
            const SizedBox(height: 24),
            _buildRequestPluginSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPluginSection(
    BuildContext context,
    String title,
    List<String> plugins,
    Set<String> selectedPlugins,
    AppState appState,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...plugins.map((plugin) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: CheckboxListTile(
              title: Text(plugin),
              value: selectedPlugins.contains(plugin),
              onChanged: (bool? newValue) {
                if (newValue != null) {
                  final updatedPlugins = Set<String>.from(selectedPlugins);
                  if (newValue) {
                    updatedPlugins.add(plugin);
                  } else {
                    updatedPlugins.remove(plugin);
                  }
                  appState.setSelectedPlugins(updatedPlugins);
                }
              },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: theme.colorScheme.secondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRequestPluginSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Não encontrou o que procurava?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap:
              () => _launchURL(
                'https://github.com/AkashicRecordsApp/akashic_records/issues/new/choose',
              ),
          child: Text(
            'Peça para adicionarmos um novo plugin!',
            style: TextStyle(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Clique no link acima para abrir uma solicitação no GitHub.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }
}
