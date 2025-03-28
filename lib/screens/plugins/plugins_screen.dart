import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';

class PluginsScreen extends StatefulWidget {
  const PluginsScreen({super.key});

  @override
  State<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends State<PluginsScreen> {
  List<String> availablePluginsPtBr = [
    'NovelMania',
    'Tsundoku',
    'CentralNovel',
    'MtlNovelPt',
  ];

  List<String> availablePluginsEn = [
    'BoxNovel',
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appState = Provider.of<AppState>(context, listen: true);
    final selectedPlugins = appState.selectedPlugins;

    return Scaffold(
      appBar: AppBar(title: const Text('Plugins')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'pt-br:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildPluginList(availablePluginsPtBr, selectedPlugins, appState, isDarkMode, context),
            const SizedBox(height: 16),
            Text(
              'english:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildPluginList(availablePluginsEn, selectedPlugins, appState, isDarkMode, context),
          ],
        ),
      ),
    );
  }

  Widget _buildPluginList(List<String> plugins, Set<String> selectedPlugins, AppState appState, bool isDarkMode, BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: plugins.length,
        itemBuilder: (context, index) {
          final plugin = plugins[index];
          return Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            color: isDarkMode ? const Color(0xFF424242) : Colors.white,
            child: ListTile(
              title: Row(
                children: [
                  Checkbox(
                    value: selectedPlugins.contains(plugin),
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        final updatedPlugins = Set<String>.from(
                          selectedPlugins,
                        );
                        if (newValue) {
                          updatedPlugins.add(plugin);
                        } else {
                          updatedPlugins.remove(plugin);
                        }
                        appState.setSelectedPlugins(updatedPlugins);
                        print(
                          "Plugins Selecionados: ${appState.selectedPlugins}",
                        );
                      }
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  Expanded(
                    child: Text(
                      plugin,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}