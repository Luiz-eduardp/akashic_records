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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Plugin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nome'),
                  onChanged: (value) {
                    name = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Código JavaScript',
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
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () {
                if (name.isNotEmpty && code.isNotEmpty) {
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  appState.addCustomPlugin(
                    CustomPlugin(name: name, code: code),
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Plugin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nome'),
                  initialValue: plugin.name,
                  onChanged: (value) {
                    name = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Código JavaScript',
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
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Salvar'),
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
          title: const Text('Deletar Plugin'),
          content: const Text('Tem certeza que deseja deletar este plugin?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Deletar'),
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
