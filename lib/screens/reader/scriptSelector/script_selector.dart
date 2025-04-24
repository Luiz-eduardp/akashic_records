import 'dart:convert';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class ScriptSelectorScreen extends StatefulWidget {
  const ScriptSelectorScreen({super.key});

  @override
  _ScriptSelectorScreenState createState() => _ScriptSelectorScreenState();
}

class _ScriptSelectorScreenState extends State<ScriptSelectorScreen> {
  List<ScriptInfo> scripts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  Future<void> _loadScripts() async {
    final appState = Provider.of<AppState>(context, listen: false);
    scripts.clear();
    for (String url in appState.scriptUrls) {
      await _extractScriptsFromJson(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Provider.of<AppState>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Selecionar Script'.translate,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surfaceVariant,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Gerenciar URLs'.translate,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UrlManagementScreen(),
                ),
              ).then((_) {
                _loadScripts();
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scripts Encontrados'.translate,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (isLoading)
                              const Center(child: CircularProgressIndicator())
                            else if (scripts.isEmpty)
                              Center(
                                child: Text(
                                  'Nenhum script encontrado.'.translate,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                height: screenHeight * 0.8,
                                child: ListView.builder(
                                  itemCount: scripts.length,
                                  itemBuilder: (context, index) {
                                    return _buildScriptTile(
                                      context,
                                      scripts[index],
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _extractScriptsFromJson(String url) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);

        for (var item in jsonList) {
          String use = item['use'] ?? '';
          String code = item['code'] ?? '';
          String name = item['name'] ?? 'Sem nome';

          setState(() {
            scripts.add(
              ScriptInfo(
                type: ScriptType.json,
                name: name,
                use: use,
                code: code,
              ),
            );
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar a página: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: Invalid Json')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildScriptTile(BuildContext context, ScriptInfo scriptInfo) {
    final theme = Theme.of(context);
    String subtitle = scriptInfo.use ?? 'Sem descrição';
    String title = scriptInfo.name ?? 'Sem nome';

    return Card(
      color: theme.colorScheme.surface,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            _addScriptToState(scriptInfo, context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: Text('Adicionar'.translate),
        ),
      ),
    );
  }

  Future<void> _addScriptToState(
    ScriptInfo scriptInfo,
    BuildContext context,
  ) async {
    final theme = Theme.of(context);
    String scriptContent = scriptInfo.code ?? '';
    String scriptName = scriptInfo.name ?? 'Sem nome';
    String scriptUse = scriptInfo.use ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = scriptName;
        String use = scriptUse;

        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'Informações do Plugin'.translate,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Nome do Plugin'.translate,
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
                    labelText: 'Como usar'.translate,
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
                if (name.isNotEmpty) {
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  final plugin = CustomPlugin(
                    name: name,
                    code: scriptContent,
                    use: use,
                  );
                  appState.addCustomPlugin(plugin);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

enum ScriptType { json }

class ScriptInfo {
  final ScriptType type;
  final String? name;
  final String? use;
  final String? code;

  ScriptInfo({required this.type, this.name, this.use, this.code});
}

class UrlManagementScreen extends StatefulWidget {
  const UrlManagementScreen({super.key});

  @override
  _UrlManagementScreenState createState() => _UrlManagementScreenState();
}

class _UrlManagementScreenState extends State<UrlManagementScreen> {
  final TextEditingController urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Gerenciar URLs'.translate,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surfaceVariant,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: urlController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Adicionar URL'.translate,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add, color: theme.colorScheme.primary),
                  onPressed: () {
                    final url = urlController.text;
                    if (url.isNotEmpty) {
                      appState.addScriptUrl(url);
                      urlController.clear();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: appState.scriptUrls.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: theme.colorScheme.surface,
                    child: ListTile(
                      title: Text(
                        appState.scriptUrls[index],
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () {
                          appState.removeScriptUrl(index);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        tooltip: "Voltar".translate,
        child: const Icon(Icons.arrow_back),
      ),
    );
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }
}
