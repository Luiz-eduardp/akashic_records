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
  String _selectedLang = 'All';
  String _searchQuery = '';
  bool _onlyAvailable = false;

  Future<void> _load() async {
    final appState = Provider.of<AppState>(context, listen: false);
    for (final pName in PluginRegistry.registeredPluginNames) {
      final enabled = await appState.getPluginState(pName);
      _states[pName] = enabled;
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final instances = PluginRegistry.allPlugins;
    final names =
        <String>{}
          ..addAll(PluginRegistry.registeredPluginNames)
          ..addAll(instances.map((p) => p.name));
    final entries =
        names.map((n) => MapEntry(n, PluginRegistry.get(n))).toList();

    final langs = <String>{};
    for (final p in instances) {
      if (p.lang.isNotEmpty) langs.add(p.lang);
    }
    final languageOptions = ['all', ...langs.toList()..sort()];

    final filtered =
        entries.where((e) {
          final name = e.key.toLowerCase();
          final svc = e.value;
          if (_selectedLang != 'All') {
            final lang = svc?.lang ?? 'Unknown';
            if (lang != _selectedLang) return false;
          }
          if (_onlyAvailable && svc == null) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final site = (svc?.siteUrl ?? '').toLowerCase();
            if (!name.contains(q) && !site.contains(q)) return false;
          }
          return true;
        }).toList();

    final Map<String, List<MapEntry<String, dynamic>>> grouped = {};
    for (final e in filtered) {
      final svc = e.value;
      final lang = svc?.lang ?? 'Unknown';
      grouped.putIfAbsent(lang, () => []).add(e);
    }

    final langLabels = <String, String>{
      'en': 'english'.translate,
      'pt': 'portuguese_br'.translate,
      'ja': 'japanese'.translate,
      'es': 'spanish'.translate,
      'Unknown': 'unknown'.translate,
    };

    return Scaffold(
      appBar: AppBar(title: Text('plugins'.translate)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'search_plugins_or_site'.translate,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        languageOptions.map((l) {
                          final label =
                              l == 'all'
                                  ? 'all'.translate
                                  : (langLabels[l] ?? l);
                          final selected = _selectedLang == l;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: selected,
                              onSelected:
                                  (_) => setState(() => _selectedLang = l),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 4),
                    Text('only_available'.translate),
                    Switch(
                      value: _onlyAvailable,
                      onChanged: (v) => setState(() => _onlyAvailable = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: () {
                final widgetList = <Widget>[];
                final sortedKeys = grouped.keys.toList()..sort();
                for (final lang in sortedKeys) {
                  final list = grouped[lang]!;
                  widgetList.add(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Row(
                        children: [
                          Text(
                            langLabels[lang] ?? lang,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(width: 8),
                          Chip(label: Text('${list.length}')),
                        ],
                      ),
                    ),
                  );
                  for (final e in list) {
                    final name = e.key;
                    final p = e.value as dynamic;
                    final enabled = _states[name] ?? true;
                    widgetList.add(
                      Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: InkWell(
                          onTap:
                              p != null
                                  ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (ctx) => PluginBrowserScreen(
                                            pluginName: p.name,
                                          ),
                                    ),
                                  )
                                  : () => ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'plugin_failed_to_initialize'.translate,
                                      ),
                                    ),
                                  ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                  foregroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                  child: Text(
                                    (name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (p != null
                                            ? (p.siteUrl ??
                                                'unavailable'.translate)
                                            : 'unavailable'.translate),
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          if (p != null &&
                                              (p.lang ?? '').isNotEmpty)
                                            Chip(label: Text(p.lang)),
                                          const SizedBox(width: 8),
                                          Text(
                                            'tap_to_browse'.translate,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
                return widgetList;
              }(),
            ),
          ),
        ],
      ),
    );
  }
}
