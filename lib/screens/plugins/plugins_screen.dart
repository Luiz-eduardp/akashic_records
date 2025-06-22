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
  Map<PluginLanguage, List<String>> pluginsByLanguage = {};
  final Map<PluginLanguage, bool> _languageExpanded = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context, listen: false);
    pluginsByLanguage = {};
    appState.pluginInfo.forEach((name, info) {
      if (!pluginsByLanguage.containsKey(info.language)) {
        pluginsByLanguage[info.language] = [];
        _languageExpanded[info.language] = false;
      }
      pluginsByLanguage[info.language]!.add(name);
    });
  }

  void _toggleAll(PluginLanguage language, bool newValue) {
    final appState = Provider.of<AppState>(context, listen: false);
    final plugins = pluginsByLanguage[language] ?? [];
    final updatedPlugins = Set<String>.from(appState.selectedPlugins);

    setState(() {
      if (newValue) {
        updatedPlugins.addAll(plugins);
      } else {
        updatedPlugins.removeAll(plugins);
      }
      appState.setSelectedPlugins(updatedPlugins);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Plugins'.translate), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final language in PluginLanguage.values)
                if (pluginsByLanguage.containsKey(language))
                  _buildPluginSection(
                    context,
                    language,
                    pluginsByLanguage[language]!,
                    appState.selectedPlugins,
                    appState,
                  ),
              const SizedBox(height: 16),
              _buildRequestPluginSection(context),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageName(PluginLanguage language) {
    switch (language) {
      case PluginLanguage.ptBr:
        return 'Português (Brasil)'.translate;
      case PluginLanguage.en:
        return 'Inglês'.translate;
      case PluginLanguage.es:
        return 'Espanhol'.translate;
      case PluginLanguage.ja:
        return 'Japonês'.translate;

      case PluginLanguage.Local:
        return 'Dispositivo'.translate;
      case PluginLanguage.id:
        return 'Indonésio'.translate;
      case PluginLanguage.fr:
        return 'Francês'.translate;
      case PluginLanguage.ar:
        return 'Árabe'.translate;
    }
  }

  Widget _buildPluginSection(
    BuildContext context,
    PluginLanguage language,
    List<String> plugins,
    Set<String> selectedPlugins,
    AppState appState,
  ) {
    final theme = Theme.of(context);
    final languageName = _getLanguageName(language);

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 8.0),
      title: Text(
        languageName,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      initiallyExpanded: _languageExpanded[language] ?? false,
      onExpansionChanged: (expanded) {
        setState(() {
          _languageExpanded[language] = expanded;
        });
      },
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selecionar Todos'.translate,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              Switch(
                value: plugins.every(
                  (plugin) => selectedPlugins.contains(plugin),
                ),
                onChanged: (newValue) => _toggleAll(language, newValue),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
        ...plugins.map((plugin) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 2.0,
              horizontal: 8.0,
            ),
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
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRequestPluginSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Não encontrou o que procurava?'.translate,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
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
            const SizedBox(height: 6),
            Text(
              'Clique no link acima para abrir uma solicitação no GitHub.'
                  .translate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
