import 'package:akashic_records/utils/launchUrl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/i18n/i18n.dart';

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
    'LightNovelBrasil',
    'BlogDoAmonNovels',
  ];

  final List<String> availablePluginsEn = [
    'NovelsOnline',
    'RoyalRoad',
    'Webnovel',
    'ReaperScans',
    'NovelBin',
  ];
  final List<String> availablePluginsEspanish = ['SkyNovels', 'NovelasLigera'];

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final appState = Provider.of<AppState>(context);
    final selectedPlugins = appState.selectedPlugins;

    return Scaffold(
      appBar: AppBar(title: Text('Plugins'.translate), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPluginSection(
                context,
                'Português (Brasil)'.translate,
                availablePluginsPtBr,
                selectedPlugins,
                appState,
              ),
              const SizedBox(height: 24),
              _buildPluginSection(
                context,
                'Inglês'.translate,
                availablePluginsEn,
                selectedPlugins,
                appState,
              ),
              const SizedBox(height: 24),
              _buildPluginSection(
                context,
                'Espanhol'.translate,
                availablePluginsEspanish,
                selectedPlugins,
                appState,
              ),
              const SizedBox(height: 24),
              _buildRequestPluginSection(context),
            ],
          ),
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
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...plugins.map((plugin) {
          return Card(
            elevation: 1,
            surfaceTintColor: theme.colorScheme.surfaceVariant,
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CheckboxListTile(
                title: Text(
                  plugin,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
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
                activeColor: theme.colorScheme.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
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
          'Não encontrou o que procurava?'.translate,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap:
              () => launchURL(
                'https://github.com/AkashicRecordsApp/akashic_records/issues/new/choose',
              ),
          child: Text(
            'Peça para adicionarmos um novo plugin!'.translate,
            style: TextStyle(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Clique no link acima para abrir uma solicitação no GitHub.'
              .translate,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
