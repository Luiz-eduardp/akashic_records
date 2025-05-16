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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      setState(() {
        isLoading = false;
      });
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Selecionar Script'.translate,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 3,
        scrolledUnderElevation: 5,
        surfaceTintColor: colorScheme.surfaceTint,
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
            style: IconButton.styleFrom(foregroundColor: colorScheme.onSurface),
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
                          style: IconButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                          ),
                        ),
                      ]
                      : null,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadScripts,
        backgroundColor: colorScheme.surface,
        color: colorScheme.primary,
        child: SafeArea(
          child: Builder(
            builder: (BuildContext context) {
              return _buildContent(context, theme, colorScheme);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Carregando scripts...'.translate,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
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
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (scripts.isEmpty) {
      return _buildNoScriptsFound(theme, colorScheme);
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredScripts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemBuilder: (context, index) {
                return _buildScriptTile(
                  context,
                  _filteredScripts[index],
                  colorScheme,
                  theme,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoScriptsFound(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code_off, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Nenhum script encontrado.\nAdicione URLs de scripts para começar.'
                  .translate,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
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
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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

        setState(() {
          scripts.addAll(newScripts);
        });
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
      ).showSnackBar(SnackBar(content: Text('Erro: JSON inválido')));
      if (kDebugMode) {
        debugPrint("Error parsing JSON: $e");
      }
    }
  }

  Widget _buildScriptTile(
    BuildContext context,
    ScriptInfo scriptInfo,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final subtitle = scriptInfo.use ?? 'Sem descrição';
    final title = scriptInfo.name ?? 'Sem nome';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.surfaceVariant,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: FilledButton(
          onPressed: () {
            _addScriptToState(scriptInfo, context, theme, colorScheme);
          },
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text('Adicionar'.translate),
        ),
      ),
    );
  }

  Future<void> _addScriptToState(
    ScriptInfo scriptInfo,
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) async {
    final scriptContent = scriptInfo.code ?? '';
    final scriptName = scriptInfo.name ?? 'Sem nome';
    final scriptUse = scriptInfo.use ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = scriptName;
        String use = scriptUse;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Text(
            'Informações do Plugin'.translate,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nome do Plugin'.translate,
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.primary),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                  ),
                  initialValue: name,
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Como usar'.translate,
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.primary),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
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
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
    final colorScheme = theme.colorScheme;

    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gerenciar URLs'.translate,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 3,
        scrolledUnderElevation: 5,
        backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.8),
        surfaceTintColor: Colors.transparent,
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
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Adicionar URL'.translate,
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add, color: colorScheme.primary),
                  tooltip: 'Adicionar URL'.translate,
                  onPressed: () {
                    final url = urlController.text;
                    if (url.isNotEmpty) {
                      appState.addScriptUrl(url);
                      urlController.clear();
                    }
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                  ),
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
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: colorScheme.surfaceVariant,
                    child: ListTile(
                      title: Text(
                        appState.scriptUrls[index],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: colorScheme.error,
                        ),
                        tooltip: 'Remover URL'.translate,
                        onPressed: () => appState.removeScriptUrl(index),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.errorContainer,
                          foregroundColor: colorScheme.onErrorContainer,
                        ),
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
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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
