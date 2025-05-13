import 'dart:convert';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/foundation.dart';
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
  String? _errorMessage;
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  Future<void> _loadScripts() async {
    setState(() {
      isLoading = true;
      scripts.clear();
      _errorMessage = null;
      _searchTerm = '';
      _searchController.clear();
    });

    final appState = Provider.of<AppState>(context, listen: false);
    try {
      for (String url in appState.scriptUrls) {
        await _extractScriptsFromJson(url);
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erro ao carregar scripts:'.translate + ' ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<ScriptInfo> get _filteredScripts {
    if (_searchTerm.isEmpty) {
      return scripts;
    } else {
      return scripts
          .where(
            (script) =>
                script.name?.toLowerCase().contains(
                  _searchTerm.toLowerCase(),
                ) ==
                true,
          )
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Selecionar Script'.translate),
        centerTitle: true,
        elevation: 1,
        scrolledUnderElevation: 3,
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
              ).then((_) => _loadScripts());
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Filtrar por título'.translate,
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
              onSubmitted: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
              leading: const Icon(Icons.search),
              trailing:
                  _searchTerm.isNotEmpty
                      ? [
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchTerm = '';
                              _searchController.clear();
                            });
                          },
                        ),
                      ]
                      : null,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadScripts,
        color: theme.colorScheme.primary,
        child: SafeArea(
          child: Builder(
            builder: (BuildContext context) {
              return _buildContent(context, theme);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Carregando scripts...'.translate,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (scripts.isEmpty) {
      return _buildNoScriptsFound(theme);
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'Scripts encontrados:'.translate +
                  ' ${_filteredScripts.length} / ${scripts.length}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredScripts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemBuilder: (context, index) {
                return _buildScriptTile(context, _filteredScripts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoScriptsFound(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum script encontrado.\nAdicione URLs de scripts para começar.'
                  .translate,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UrlManagementScreen(),
                  ),
                ).then((_) => _loadScripts());
              },
              icon: const Icon(Icons.add_link),
              label: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text('Gerenciar URLs'.translate),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _extractScriptsFromJson(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);

        List<ScriptInfo> newScripts = [];
        for (var item in jsonList) {
          if (item is Map<String, dynamic>) {
            final use = item['use'] as String? ?? '';
            final code = item['code'] as String? ?? '';
            final name = item['name'] as String? ?? 'Sem nome';

            newScripts.add(
              ScriptInfo(
                type: ScriptType.json,
                name: name,
                use: use,
                code: code,
              ),
            );
          } else {
            if (kDebugMode) {
              print('Unexpected data type in script list: ${item.runtimeType}');
            }
          }
        }

        if (mounted) {
          setState(() {
            scripts.addAll(newScripts);
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao carregar a página: ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: JSON inválido')));
      }
      if (kDebugMode) {
        debugPrint("Error parsing JSON: $e");
      }
    }
  }

  Widget _buildScriptTile(BuildContext context, ScriptInfo scriptInfo) {
    final theme = Theme.of(context);
    final subtitle = scriptInfo.use ?? 'Sem descrição';
    final title = scriptInfo.name ?? 'Sem nome';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: FilledButton(
          onPressed: () {
            _addScriptToState(scriptInfo, context);
          },
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
    final scriptContent = scriptInfo.code ?? '';
    final scriptName = scriptInfo.name ?? 'Sem nome';
    final scriptUse = scriptInfo.use ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = scriptName;
        String use = scriptUse;

        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: theme.colorScheme.surface,
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
                  onChanged: (value) => name = value,
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
                  onChanged: (value) => use = value,
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
              onPressed: () => Navigator.of(context).pop(),
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
                    enabled: true,
                    priority: 10,
                  );
                  appState.addCustomPlugin(plugin);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
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
      appBar: AppBar(
        title: Text('Gerenciar URLs'.translate),
        centerTitle: true,
        elevation: 1,
        scrolledUnderElevation: 3,
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
                  tooltip: 'Adicionar URL'.translate,
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
              child: ListView.separated(
                itemCount: appState.scriptUrls.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                        tooltip: 'Remover URL'.translate,
                        onPressed: () => appState.removeScriptUrl(index),
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
        onPressed: () => Navigator.pop(context),
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
