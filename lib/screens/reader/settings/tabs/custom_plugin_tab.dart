import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomPluginTab extends StatefulWidget {
  const CustomPluginTab({super.key});

  @override
  _CustomPluginTabState createState() => _CustomPluginTabState();
}

class _CustomPluginTabState extends State<CustomPluginTab> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    List<CustomPlugin> plugins = appState.customPlugins;

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            itemCount: plugins.length,
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final CustomPlugin item = plugins.removeAt(oldIndex);
                plugins.insert(newIndex, item);

                for (int i = 0; i < plugins.length; i++) {
                  plugins[i] = CustomPlugin(
                    name: plugins[i].name,
                    code: plugins[i].code,
                    use: plugins[i].use,
                    enabled: plugins[i].enabled,
                    priority: i,
                  );
                }
                appState.setCustomPlugins(plugins);
              });
            },
            itemBuilder: (context, index) {
              final plugin = plugins[index];
              return Card(
                key: ValueKey(plugin.name),
                child: ListTile(
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
                  title: Text(plugin.name),
                  subtitle: Text("Priority: ${plugin.priority}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: plugin.enabled,
                        onChanged: (bool value) {
                          setState(() {
                            plugins[index] = CustomPlugin(
                              name: plugin.name,
                              code: plugin.code,
                              use: plugin.use,
                              enabled: value,
                              priority: plugin.priority,
                            );
                            appState.updateCustomPlugin(index, plugins[index]);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditDialog(context, index, plugin);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteConfirmationDialog(context, index);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              _showAddDialog(context);
            },
            child: const Text('Adicionar Plugin Customizado'),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    String name = '';
    String code = '';
    String use = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Plugin'.translate),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Nome'.translate),
                  onChanged: (value) {
                    name = value;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Forma de uso'.translate,
                  ),
                  onChanged: (value) {
                    use = value;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Código JavaScript'.translate,
                  ),
                  maxLines: 5,
                  onChanged: (value) {
                    code = value;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'.translate),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Salvar'.translate),
              onPressed: () {
                if (name.isNotEmpty && code.isNotEmpty) {
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  appState.addCustomPlugin(
                    CustomPlugin(name: name, code: code, use: use),
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, int index, CustomPlugin plugin) {
    String name = plugin.name;
    String code = plugin.code;
    String use = plugin.use;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Plugin'.translate),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Nome'.translate),
                  initialValue: plugin.name,
                  onChanged: (value) {
                    name = value;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Forma de uso'.translate,
                  ),
                  initialValue: plugin.use,
                  onChanged: (value) {
                    use = value;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Código JavaScript'.translate,
                  ),
                  maxLines: 5,
                  initialValue: plugin.code,
                  onChanged: (value) {
                    code = value;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'.translate),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Salvar'.translate),
              onPressed: () {
                if (name.isNotEmpty && code.isNotEmpty) {
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  appState.updateCustomPlugin(
                    index,
                    CustomPlugin(
                      name: name,
                      code: code,
                      use: use,
                      enabled: plugin.enabled,
                      priority: plugin.priority,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Deletar Plugin'.translate),
          content: Text(
            'Tem certeza que deseja deletar este plugin?'.translate,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'.translate),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Deletar'.translate),
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                appState.removeCustomPlugin(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
