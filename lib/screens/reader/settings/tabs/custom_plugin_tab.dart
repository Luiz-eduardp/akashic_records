import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
                              appState.updateCustomPlugin(
                                index,
                                plugins[index],
                              );
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PluginEditorScreen(
                                      plugin: plugin,
                                      index: index,
                                    ),
                              ),
                            );
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PluginEditorScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text('Adicionar Plugin Customizado'.translate),
              ),
            ),
          ),
        ],
      ),
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

class PluginEditorScreen extends StatefulWidget {
  final CustomPlugin? plugin;
  final int? index;

  const PluginEditorScreen({super.key, this.plugin, this.index});

  @override
  _PluginEditorScreenState createState() => _PluginEditorScreenState();
}

class _PluginEditorScreenState extends State<PluginEditorScreen> {
  String name = '';
  String use = '';
  late CodeController codeController;

  @override
  void initState() {
    super.initState();
    name = widget.plugin?.name ?? '';
    use = widget.plugin?.use ?? '';
    codeController = CodeController(
      language: javascript,
      text: widget.plugin?.code ?? '',
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.plugin != null;
    final title =
        isEditing ? 'Editar Plugin'.translate : 'Adicionar Plugin'.translate;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surfaceVariant,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (name.isNotEmpty && codeController.text.isNotEmpty) {
                final appState = Provider.of<AppState>(context, listen: false);
                final plugin = CustomPlugin(
                  name: name,
                  code: codeController.text,
                  use: use,
                );
                if (isEditing) {
                  appState.updateCustomPlugin(widget.index!, plugin);
                } else {
                  appState.addCustomPlugin(plugin);
                }
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
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                initialValue: name,
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
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                initialValue: use,
                onChanged: (value) {
                  use = value;
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: CodeField(
                    controller: codeController,
                    textStyle: GoogleFonts.sourceCodePro(
                      textStyle: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
