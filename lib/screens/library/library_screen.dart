import 'package:akashic_records/screens/library/plugin_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/i18n/i18n.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child:
            appState.selectedPlugins.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Nenhum plugin selecionado. Acesse as configurações para adicionar plugins.'
                            .translate,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onBackground),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/plugins');
                        },
                        child: Text('Plugins'.translate),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  itemCount: appState.selectedPlugins.length,
                  itemBuilder: (context, index) {
                    final pluginName = appState.selectedPlugins.elementAt(
                      index,
                    );
                    return PluginCard(pluginName: pluginName);
                  },
                ),
      ),
    );
  }
}
