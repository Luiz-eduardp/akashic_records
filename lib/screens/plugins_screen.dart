import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/screens/plugin_browser_screen.dart';
import 'package:akashic_records/widgets/m3e/m3e_app_bar.dart';
import 'package:akashic_records/services/plugins/opds_plugins.dart';
import 'package:akashic_records/services/lnreader_js_engine.dart';

class PluginsScreen extends StatefulWidget {
  const PluginsScreen({super.key});

  @override
  State<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends State<PluginsScreen> {
  final Map<String, bool> _states = {};
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _onlyAvailable = false;

  final Map<String, String> categoryLabels = {
    'all': 'Todos os Plugins',
    'opds': 'Catálogos OPDS',
    'en': 'English',
    'pt': 'Português (BR)',
    'ja': '日本語 (Japanese)',
    'es': 'Español',
    'fr': 'Français',
    'ar': 'العربية',
    'id': 'Indonesian',
    'cross plugin': 'Multi-Idiomas',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.microtask(() async {
      final appState = Provider.of<AppState>(context, listen: false);
      for (final pName in PluginRegistry.registeredPluginNames) {
        final enabled = await appState.getPluginState(pName);
        _states[pName] = enabled;
      }
      if (mounted) setState(() {});
    });
  }

  List<MapEntry<String, dynamic>> _getFilteredPlugins() {
    final instances = PluginRegistry.allPlugins;
    final names = <String>{}
      ..addAll(PluginRegistry.registeredPluginNames)
      ..addAll(instances.map((p) => p.name));
    final entries = names.map((n) => MapEntry(n, PluginRegistry.get(n))).toList();

    return entries.where((e) {
      final name = e.key.toLowerCase();
      final svc = e.value;
      final lang = (svc?.lang ?? 'Unknown').toLowerCase();
      final isOpds = name.contains('opds');

      if (_selectedCategory == 'opds' && !isOpds) return false;
      if (_selectedCategory != 'all' && _selectedCategory != 'opds' && lang != _selectedCategory) return false;

      if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) {
        final site = (svc?.siteUrl ?? '').toLowerCase();
        if (!site.contains(_searchQuery.toLowerCase())) return false;
      }

      if (_onlyAvailable && _states[e.key] != true) return false;

      return true;
    }).toList();
  }

  Map<String, List<MapEntry<String, dynamic>>> _getGroupedPlugins(
    List<MapEntry<String, dynamic>> filtered,
  ) {
    final Map<String, List<MapEntry<String, dynamic>>> grouped = {};
    for (final e in filtered) {
      final svc = e.value;
      final name = e.key;
      final lang = name.toLowerCase().contains('opds') ? 'opds' : (svc?.lang ?? 'Unknown').toLowerCase();
      grouped.putIfAbsent(lang, () => []).add(e);
    }
    return grouped;
  }

  void _showCalibreUrlDialog(CalibreCustomOpds plugin) {
    final controller = TextEditingController(text: plugin.customUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.dns_rounded, color: Colors.blue),
            const SizedBox(width: 12),
            Text('calibre_opds_server'.translate),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'calibre_server_url_prompt'.translate,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'http://192.168.1.100:8080/opds',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.translate),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  plugin.customUrl = controller.text.trim();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('calibre_server_updated'.translate)),
                );
              }
            },
            child: Text('save'.translate),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['all', 'opds', 'pt', 'en', 'ja', 'es', 'fr', 'ar', 'id', 'cross plugin'];
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: categories.map((cat) {
          final label = categoryLabels[cat] ?? cat.toUpperCase();
          final selected = _selectedCategory == cat;
          final isOpdsChip = cat == 'opds';

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              selected: selected,
              avatar: isOpdsChip
                  ? Icon(Icons.cloud_download_rounded, size: 16, color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.primary)
                  : (selected ? Icon(Icons.check_rounded, size: 16, color: theme.colorScheme.onPrimary) : null),
              label: Text(label),
              labelStyle: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              ),
              selectedColor: isOpdsChip ? Colors.deepPurple : theme.colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (v) {
                setState(() => _selectedCategory = cat);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPluginTile(BuildContext context, MapEntry<String, dynamic> entry) {
    final name = entry.key;
    final p = entry.value as dynamic;
    final enabled = _states[name] ?? true;
    final isAvailable = p != null;
    final theme = Theme.of(context);
    final isOpds = name.toLowerCase().contains('opds');
    final isCalibre = name.contains('Calibre');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isOpds
              ? Colors.deepPurple.withOpacity(0.3)
              : theme.colorScheme.outlineVariant.withOpacity(0.3),
          width: isOpds ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: isAvailable
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => PluginBrowserScreen(pluginName: p.name),
                    ),
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isOpds
                            ? Colors.deepPurple.withOpacity(0.15)
                            : theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isOpds ? Icons.cloud_download_rounded : Icons.extension_rounded,
                        color: isOpds
                            ? Colors.deepPurple
                            : theme.colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAvailable ? (p.siteUrl ?? '') : 'Indisponível',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: enabled,
                      activeColor: isOpds ? Colors.deepPurple : theme.colorScheme.primary,
                      onChanged: (v) async {
                        setState(() => _states[name] = v);
                        await Provider.of<AppState>(context, listen: false).setPluginState(name, v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOpds
                            ? Colors.deepPurple.withOpacity(0.12)
                            : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOpds ? Icons.auto_stories_rounded : Icons.language_rounded,
                            size: 14,
                            color: isOpds ? Colors.deepPurple : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpds ? 'Catálogo OPDS' : 'Scraper Web (${p?.lang?.toUpperCase() ?? "EN"})',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isOpds ? Colors.deepPurple : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (isCalibre && p is CalibreCustomOpds)
                          IconButton(
                            icon: const Icon(Icons.settings_rounded, size: 20),
                            tooltip: 'Configurar URL do Servidor',
                            onPressed: () => _showCalibreUrlDialog(p),
                          ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.grid_view_rounded, size: 16),
                          label: Text('browse'.translate, style: const TextStyle(fontSize: 13)),
                          onPressed: isAvailable
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => PluginBrowserScreen(pluginName: p.name),
                                    ),
                                  )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredPlugins();
    final grouped = _getGroupedPlugins(filtered);
    final sortedKeys = grouped.keys.toList()..sort();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: M3EAppBar(
        title: 'plugins'.translate,
        subtitle: '${filtered.length} ${'extensions_and_catalogs'.translate}',
        actions: [
          IconButton(
            tooltip: 'syncing_lnreader_plugins'.translate,
            icon: const Icon(Icons.sync_rounded),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('syncing_lnreader_plugins'.translate)),
              );
              final count = await LnReaderJsEngine.syncAndRegisterPlugins();
              await _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('lnreader_plugins_synced'.translateParams({'count': count.toString()})),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'search_plugins_or_site'.translate,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHigh,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(height: 12),
                _buildCategoryChips(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'only_available'.translate,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Switch(
                        value: _onlyAvailable,
                        onChanged: (v) => setState(() => _onlyAvailable = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.extension_off_rounded, size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          'no_search_results'.translate,
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 110),
                    children: sortedKeys.expand((groupKey) {
                      final list = grouped[groupKey]!;
                      final groupTitle = groupKey == 'opds'
                          ? 'Catálogos OPDS E-Books'
                          : (categoryLabels[groupKey] ?? groupKey.toUpperCase());

                      return [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            '$groupTitle (${list.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: groupKey == 'opds' ? Colors.deepPurple : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        ...list.map((e) => _buildPluginTile(context, e)),
                      ];
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
