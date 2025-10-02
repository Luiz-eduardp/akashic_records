import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/screens/plugin_browser_screen.dart';

class PluginsScreen extends StatefulWidget {
  const PluginsScreen({super.key});

  @override
  State<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends State<PluginsScreen> {
  final Map<String, bool> _states = {};
  String _selectedLang = 'all';
  String _searchQuery = '';
  bool _onlyAvailable = false;

  final Map<String, String> langLabels = {
    'en': 'english'.translate,
    'pt': 'portuguese_br'.translate,
    'ja': 'japanese'.translate,
    'es': 'spanish'.translate,
    'Unknown': 'unknown'.translate,
    'all': 'all'.translate,
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
    final names =
        <String>{}
          ..addAll(PluginRegistry.registeredPluginNames)
          ..addAll(instances.map((p) => p.name));
    final entries =
        names.map((n) => MapEntry(n, PluginRegistry.get(n))).toList();

    return entries.where((e) {
      final name = e.key.toLowerCase();
      final svc = e.value;
      final lang = (svc?.lang ?? 'Unknown');

      if (_selectedLang != 'all' &&
          lang.toLowerCase() != _selectedLang.toLowerCase()) {
        return false;
      }

      if (_onlyAvailable && svc == null) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final site = (svc?.siteUrl ?? '').toLowerCase();
        if (!name.contains(q) &&
            !site.contains(q) &&
            !lang.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<String, List<MapEntry<String, dynamic>>> _getGroupedPlugins(
    List<MapEntry<String, dynamic>> filtered,
  ) {
    final Map<String, List<MapEntry<String, dynamic>>> grouped = {};
    for (final e in filtered) {
      final svc = e.value;
      final lang = svc?.lang ?? 'Unknown';
      grouped.putIfAbsent(lang, () => []).add(e);
    }
    return grouped;
  }

  Widget _buildLanguageChips(Set<String> langs) {
    final languageOptions = ['all', ...langs.toList()..sort()];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children:
            languageOptions.map((l) {
              final label = langLabels[l] ?? l;
              final selected = _selectedLang == l;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  avatar:
                      selected
                          ? Icon(
                            Icons.check,
                            size: 18,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                          : null,
                  label: Text(label),
                  labelStyle:
                      selected
                          ? TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          )
                          : null,
                  backgroundColor:
                      selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHigh,
                  onPressed: () => setState(() => _selectedLang = l),
                ),
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instances = PluginRegistry.allPlugins;
    final langs = <String>{};
    for (final p in instances) {
      if (p.lang.isNotEmpty) langs.add(p.lang.toLowerCase());
    }

    final filtered = _getFilteredPlugins();
    final grouped = _getGroupedPlugins(filtered);
    final sortedKeys =
        grouped.keys.toList()
          ..sort((a, b) => (langLabels[a] ?? a).compareTo(langLabels[b] ?? b));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('plugins'.translate),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: 'plugin_marketplace'.translate,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Marketplace coming soon!'.translate)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'search_plugins_or_site'.translate,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerHigh,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(height: 12),
                _buildLanguageChips(langs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'only_available'.translate,
                        style: Theme.of(context).textTheme.bodyLarge,
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
            child:
                filtered.isEmpty
                    ? Center(
                      child: Text(
                        'no_plugins_match_filters'.translate,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    )
                    : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children:
                          sortedKeys.expand((lang) {
                            final list = grouped[lang]!;
                            return [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  20,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  '${langLabels[lang] ?? lang} (${list.length})',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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

  Widget _buildPluginTile(
    BuildContext context,
    MapEntry<String, dynamic> entry,
  ) {
    final name = entry.key;
    final p = entry.value as dynamic;
    final enabled = _states[name] ?? true;
    final isAvailable = p != null;
    final theme = Theme.of(context);
    final opacity = isAvailable ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              isAvailable
                  ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => PluginBrowserScreen(pluginName: p.name),
                    ),
                  )
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('plugin_failed_to_initialize'.translate),
                    ),
                  ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      isAvailable
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceVariant,
                  foregroundColor:
                      isAvailable
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                  child: Text(
                    (name.isNotEmpty ? name[0].toUpperCase() : '?'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAvailable
                            ? (p.siteUrl ?? 'unavailable'.translate)
                            : 'unavailable'.translate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (isAvailable && (p.lang ?? '').isNotEmpty)
                            Chip(
                              label: Text(p.lang.toUpperCase()),
                              padding: EdgeInsets.zero,
                              labelStyle: const TextStyle(fontSize: 10),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (!isAvailable)
                            Chip(
                              label: Text('failed_to_load'.translate),
                              backgroundColor: theme.colorScheme.errorContainer,
                              labelStyle: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (isAvailable && !enabled)
                            Chip(
                              label: Text('disabled'.translate),
                              backgroundColor: theme.colorScheme.outlineVariant,
                              labelStyle: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (isAvailable)
                            Text(
                              'tap_to_browse'.translate,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isAvailable)
                  Switch(
                    value: enabled,
                    onChanged: (v) async {
                      setState(() => _states[name] = v);
                      await Provider.of<AppState>(
                        context,
                        listen: false,
                      ).setPluginState(name, v);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
