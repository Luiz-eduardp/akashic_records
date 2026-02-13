import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:akashic_records/models/cross_plugin_model.dart';
import 'package:akashic_records/screens/plugin_browser_screen.dart';
import 'package:akashic_records/services/cross_plugin_loader.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:akashic_records/widgets/optimized_network_image.dart';

class CrossPluginBrowserScreen extends StatefulWidget {
  final String sourceUrl;
  const CrossPluginBrowserScreen({
    super.key,
    this.sourceUrl =
        'https://raw.githubusercontent.com/lnreader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json',
  });

  @override
  State<CrossPluginBrowserScreen> createState() =>
      _CrossPluginBrowserScreenState();
}

class _CrossPluginBrowserScreenState extends State<CrossPluginBrowserScreen> {
  late final CrossPluginLoader _loader;
  List<CrossPluginItem> _plugins = [];
  List<CrossPluginItem> _filteredPlugins = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _selectedLanguage;
  Set<String> _languages = {};

  @override
  void initState() {
    super.initState();
    _loader = CrossPluginLoader();
    _loadPlugins();
  }

  Future<void> _loadPlugins() async {
    try {
      setState(() => _loading = true);

      final plugins = await _loader.loadPluginList(widget.sourceUrl);

      final languages = <String>{};
      for (final plugin in plugins) {
        languages.add(plugin.lang);
      }

      setState(() {
        _plugins = plugins;
        _filteredPlugins = plugins;
        _languages = languages;
        _loading = false;
      });

      developer.log('Loaded ${plugins.length} plugins');
    } catch (e) {
      developer.log('Error loading plugins: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar plugins: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _loading = false);
    }
  }

  void _filterPlugins() {
    final query = _searchQuery.toLowerCase();
    final filtered =
        _plugins.where((plugin) {
          final nameMatch = plugin.name.toLowerCase().contains(query);
          final langMatch =
              _selectedLanguage == null ||
              plugin.lang.toLowerCase() == _selectedLanguage!.toLowerCase();
          return nameMatch && langMatch;
        }).toList();

    setState(() => _filteredPlugins = filtered);
  }

  Future<void> _loadPlugin(CrossPluginItem item) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Carregando plugin: ${item.name}...'),
                ],
              ),
            ),
      );

      final service = await _loader.loadPlugin(item, widget.sourceUrl);
      PluginRegistry.register(service);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plugin ${item.name} carregado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (ctx) => PluginBrowserScreen(pluginName: item.name),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar plugin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      developer.log('Error loading plugin ${item.id}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cross Plugins'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterPlugins();
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar plugins...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHigh,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: const Text('Todos'),
                          selected: _selectedLanguage == null,
                          onSelected: (_) {
                            setState(() => _selectedLanguage = null);
                            _filterPlugins();
                          },
                        ),
                      ),
                      ..._languages.map(
                        (lang) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(lang),
                            selected: _selectedLanguage == lang,
                            onSelected: (_) {
                              setState(
                                () =>
                                    _selectedLanguage =
                                        _selectedLanguage == lang ? null : lang,
                              );
                              _filterPlugins();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredPlugins.isEmpty
                    ? Center(
                      child: Text(
                        _plugins.isEmpty
                            ? 'Nenhum plugin disponível'
                            : 'Nenhum plugin encontrado',
                        style: theme.textTheme.titleMedium,
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadPlugins,
                      child: ListView.builder(
                        itemCount: _filteredPlugins.length,
                        itemBuilder: (ctx, index) {
                          final plugin = _filteredPlugins[index];
                          return _buildPluginItem(plugin);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPluginItem(CrossPluginItem plugin) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 60,
            child: OptimizedNetworkImage(
              plugin.iconUrl,
              fit: BoxFit.cover,
              placeholder: Center(
                child: Icon(
                  Icons.extension,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          plugin.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              plugin.site,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    plugin.lang,
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Text('v${plugin.version}', style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton.icon(
          onPressed: () => _loadPlugin(plugin),
          icon: const Icon(Icons.download),
          label: const Text('Carregar'),
        ),
        onTap: () => _loadPlugin(plugin),
      ),
    );
  }
}
