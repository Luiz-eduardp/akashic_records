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
    final pluginVersion = pluginService?.version ?? 'Desconhecido'.translate;
    final pluginlang = pluginService?.lang ?? 'Desconhecido'.translate;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PluginNovelsScreen(pluginName: pluginName),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  Icons.extension,
                  size: 32.0,
                  color: theme.colorScheme.primary,
                ),
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
                          style: theme.textTheme.titleLarge!.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(width: 3.0),
                        Text(
                          pluginlang,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Text(
                          'Versão'.translate + ': ',
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          pluginVersion,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
