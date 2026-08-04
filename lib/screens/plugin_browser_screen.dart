import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/novel_detail_screen.dart';
import 'package:akashic_records/widgets/optimized_network_image.dart';

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
    developer.log('PluginBrowserScreen initState: pluginName=${widget.pluginName}, service=${_service.runtimeType}');
    _loadPopular();
  }

  Future<void> _loadPopular() async {
    if (_service == null || _loading) return;

    developer.log('_loadPopular: starting');
    if (_searchCtrl.text.isNotEmpty) {
      _searchCtrl.clear();
    }

    setState(() {
      _loading = true;
      _currentFilter = 'popular';
    });

    try {
      final list = await _service!.popularNovels(1, context: context);
      developer.log('_loadPopular: got ${list.length} novels');
      _setNovelCollections(list);
    } catch (e) {
      developer.log('_loadPopular: error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'failed_load_popular'.translate}: $e')),
      );
      _clearNovels();
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
      _setNovelCollections(list);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'failed_search'.translate}: $e')),
      );
      _clearNovels();
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildNovelGridItem(Novel novel) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => NovelDetailScreen(novel: novel)),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => NovelDetailScreen(novel: novel)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: kCoverHeight,
                    width: double.infinity,
                    child: OptimizedNetworkImage(
                      novel.coverImageUrl,
                      fit: BoxFit.cover,
                      placeholder: Center(
                        child: Icon(
                          Icons.book_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                novel.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                novel.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
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
            child: _buildStandardContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardContent() {
    final theme = Theme.of(context);
    if (_novels.isEmpty && !_loading) {
      return Center(
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
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshCurrentFilter,
      child: LayoutBuilder(builder: (ctx, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 3;
        if (width < 600) crossAxisCount = 2;
        else if (width < 1000) crossAxisCount = 3;
        else crossAxisCount = 4;

        final childAspect = kCoverWidth / kCoverHeight;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: childAspect,
          ),
          itemCount: _novels.length,
          itemBuilder: (ctx, i) {
            return _buildNovelGridItem(_novels[i]);
          },
        );
      }),
    );
  }

  Future<void> _refreshCurrentFilter() async {
    if (_currentFilter == 'popular') {
      await _loadPopular();
    } else if (_currentFilter == 'search') {
      await _search(_searchCtrl.text);
    }
  }

  void _setNovelCollections(List<Novel> novels) {
    setState(() {
      _novels = novels;
    });
  }

  void _clearNovels() {
    setState(() {
      _novels = [];
    });
  }
}
