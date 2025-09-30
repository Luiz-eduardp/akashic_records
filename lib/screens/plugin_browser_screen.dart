import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/novel_detail_screen.dart';

class PluginBrowserScreen extends StatefulWidget {
  final String pluginName;
  const PluginBrowserScreen({super.key, required this.pluginName});

  @override
  State<PluginBrowserScreen> createState() => _PluginBrowserScreenState();
}

class _PluginBrowserScreenState extends State<PluginBrowserScreen> {
  PluginService? _service;
  List<Novel> _novels = [];
  bool _loading = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = PluginRegistry.get(widget.pluginName);
    _loadPopular();
  }

  Future<void> _loadPopular() async {
    if (_service == null) return;
    setState(() => _loading = true);
    try {
      final list = await _service!.popularNovels(1);
      setState(() => _novels = list);
    } catch (e) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _search(String term) async {
    if (_service == null) return;
    setState(() => _loading = true);
    try {
      final list = await _service!.searchNovels(term, 1);
      setState(() => _novels = list);
    } catch (e) {
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pluginName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'search'.translate,
                    ),
                    onSubmitted: (v) => _search(v),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _loadPopular,
                  child: Text('popular'.translate),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _novels.length,
              itemBuilder: (ctx, i) {
                final n = _novels[i];
                return ListTile(
                  leading:
                      n.coverImageUrl.isNotEmpty
                          ? Image.network(
                            n.coverImageUrl,
                            width: 48,
                            height: 64,
                            fit: BoxFit.cover,
                          )
                          : null,
                  title: Text(n.title),
                  subtitle: Text(n.author),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => NovelDetailScreen(novel: n),
                        ),
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
