import 'package:akashic_records/screens/library/plugin_novels_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/i18n/i18n.dart';

class PluginCard extends StatelessWidget {
  final String pluginName;

  const PluginCard({super.key, required this.pluginName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);
    final pluginService = appState.pluginServices[pluginName];
    final pluginVersion = pluginService?.version ?? 'Unknown'.translate;
    final pluginlang = pluginService?.lang ?? 'Unknown'.translate;

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4.0,
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PluginNovelsScreen(pluginName: pluginName),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.extension,
                size: 48.0,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          pluginName,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(width: 4.0),

                        Text(
                          pluginlang,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Versão'.translate + ' - ' + pluginVersion,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
