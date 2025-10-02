import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/novel_detail_screen.dart';

const double kCoverWidth = 120.0;
const double kCoverHeight = 180.0;

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
  String _currentFilter = 'popular';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = PluginRegistry.get(widget.pluginName);
    _loadPopular();
  }

  Future<void> _loadPopular() async {
    if (_service == null || _loading) return;

    if (_searchCtrl.text.isNotEmpty) {
      _searchCtrl.clear();
    }

    setState(() {
      _loading = true;
      _currentFilter = 'popular';
    });

    try {
      final list = await _service!.popularNovels(1);
      setState(() => _novels = list);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'failed_load_popular'.translate}: $e')),
      );
      setState(() => _novels = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _search(String term) async {
    term = term.trim();
    if (_service == null || _loading || term.isEmpty) return;

    setState(() {
      _loading = true;
      _currentFilter = 'search';
    });

    try {
      final list = await _service!.searchNovels(term, 1);
      setState(() => _novels = list);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'failed_search'.translate}: $e')),
      );
      setState(() => _novels = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildNovelGridItem(Novel novel) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => NovelDetailScreen(novel: novel)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  novel.coverImageUrl.isNotEmpty
                      ? Image.network(
                        novel.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              child: Center(
                                child: Icon(
                                  Icons.book_outlined,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                      )
                      : Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Center(
                          child: Icon(
                            Icons.book_outlined,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            novel.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            novel.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.pluginName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'search_novels_hint'.translate,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHigh,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      isDense: true,
                    ),
                    onSubmitted: (v) => _search(v),
                  ),
                ),
                const SizedBox(width: 12),
                ActionChip(
                  avatar:
                      _currentFilter == 'popular'
                          ? Icon(
                            Icons.star,
                            color: theme.colorScheme.onPrimary,
                            size: 18,
                          )
                          : null,
                  label: Text('popular'.translate),
                  labelStyle: TextStyle(
                    color:
                        _currentFilter == 'popular'
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor:
                      _currentFilter == 'popular'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primaryContainer,
                  onPressed: _loading ? null : _loadPopular,
                ),
              ],
            ),
          ),

          if (_loading) const LinearProgressIndicator(minHeight: 3.0),

          Expanded(
            child:
                _novels.isEmpty && !_loading
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          _currentFilter == 'search'
                              ? 'no_search_results'.translate
                              : 'no_popular_novels_found'.translate,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: 0.55,
                          ),
                      itemCount: _novels.length,
                      itemBuilder: (ctx, i) {
                        return _buildNovelGridItem(_novels[i]);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
