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
    final theme = Theme.of(context);
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
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                color: theme.colorScheme.surface,
                child: ListTile(
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    plugin.name,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    "Priority: ${plugin.priority}",
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: plugin.enabled,
                        activeColor: theme.colorScheme.primary,
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
                        icon: Icon(
                          Icons.edit,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _showEditDialog(context, index, plugin);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: theme.colorScheme.error,
                        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text('Adicionar Plugin Customizado'.translate),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    String name = '';
    String code = '';
    String use = '';
    final theme = Theme.of(context);

    showGeneralDialog(
      context: context,
      pageBuilder: (
        BuildContext buildContext,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Adicionar Plugin'.translate,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            backgroundColor: theme.colorScheme.surfaceVariant,
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            leading: IconButton(
              icon: Icon(
                Icons.close,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            actions: [
              TextButton(
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
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.primary,
                ),
                child: Text('Salvar'.translate),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Nome'.translate,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      name = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Forma de uso'.translate,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      use = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Código JavaScript'.translate,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 5,
                    onChanged: (value) {
                      code = value;
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, int index, CustomPlugin plugin) {
    String name = plugin.name;
    String code = plugin.code;
    String use = plugin.use;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Editar Plugin'.translate,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Nome'.translate,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  initialValue: plugin.name,
                  onChanged: (value) {
                    name = value;
                  },
                ),
                TextFormField(
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Forma de uso'.translate,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  initialValue: plugin.use,
                  onChanged: (value) {
                    use = value;
                  },
                ),
                TextFormField(
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Código JavaScript'.translate,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              child: Text(
                'Cancelar'.translate,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'Deletar Plugin'.translate,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Text(
            'Tem certeza que deseja deletar este plugin?'.translate,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancelar'.translate,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
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
