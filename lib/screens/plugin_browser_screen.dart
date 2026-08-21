import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/novel_detail_screen.dart';
import 'package:akashic_records/widgets/optimized_network_image.dart';
import 'package:akashic_records/state/app_state.dart';

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
  String? _errorMessage;
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, bool> _importingMap = {};
  final List<String> _navHistory = [];

  @override
  void initState() {
    super.initState();
    _service = PluginRegistry.get(widget.pluginName);
    developer.log('[PluginBrowser] Opened screen for plugin: "${widget.pluginName}" | Service found: ${_service != null}');
    _loadPopular();
  }

  Future<void> _loadPopular({String? subUrl}) async {
    if (_service == null) {
      developer.log('[PluginBrowser] ERROR: Plugin service "${widget.pluginName}" was not found in PluginRegistry!');
      setState(() {
        _errorMessage = 'Plugin "${widget.pluginName}" is not registered.';
      });
      return;
    }
    if (_loading) return;

    if (_searchCtrl.text.isNotEmpty) {
      _searchCtrl.clear();
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      developer.log('[PluginBrowser] Loading popular novels for "${widget.pluginName}" (subUrl: $subUrl)...');
      final Map<String, dynamic>? filters = subUrl != null ? <String, dynamic>{'subUrl': subUrl} : null;
      final list = await _service!.popularNovels(1, filters: filters, context: context);
      developer.log('[PluginBrowser] Successfully received ${list.length} novels from "${widget.pluginName}"');
      if (mounted) {
        _setNovelCollections(list);
      }
    } catch (e, stack) {
      developer.log('[PluginBrowser] ERROR loading popular for "${widget.pluginName}": $e\n$stack');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'failed_load_popular'.translate}: $e')),
        );
        _clearNovels();
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _search(String term) async {
    term = term.trim();
    if (_service == null || _loading || term.isEmpty) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      developer.log('[PluginBrowser] Searching "$term" in "${widget.pluginName}"...');
      final list = await _service!.searchNovels(term, 1);
      developer.log('[PluginBrowser] Search for "$term" returned ${list.length} results from "${widget.pluginName}"');
      if (mounted) {
        _setNovelCollections(list);
      }
    } catch (e, stack) {
      developer.log('[PluginBrowser] ERROR searching "$term" in "${widget.pluginName}": $e\n$stack');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'failed_search'.translate}: $e')),
        );
        _clearNovels();
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _setNovelCollections(List<Novel> list) {
    setState(() {
      _novels = list;
    });
  }

  void _clearNovels() {
    setState(() {
      _novels = [];
    });
  }

  Future<void> _importOpdsBook(Novel novel) async {
    if (_service == null) return;
    setState(() => _importingMap[novel.id] = true);

    try {
      final importedNovel = await _service!.parseNovel(novel.id);
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.addOrUpdateNovel(importedNovel);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('downloaded_and_imported'.translateParams({'title': novel.title})),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_import_book'.translateParams({'error': e.toString()})),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _importingMap[novel.id] = false);
      }
    }
  }

  Widget _buildNovelGridItem(Novel novel) {
    final theme = Theme.of(context);
    final isOpds = widget.pluginName.contains('OPDS') || (novel.genres is List && novel.genres.contains('OPDS'));
    final isNav = novel.genres is List && novel.genres.contains('NAV');
    final isImporting = _importingMap[novel.id] == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (isOpds) {
            if (isNav) {
              _navHistory.add(novel.id);
              await _loadPopular(subUrl: novel.id);
            } else {
              await _importOpdsBook(novel);
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => NovelDetailScreen(novel: novel)),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: kCoverHeight,
                    width: double.infinity,
                    child: isNav
                        ? Container(
                            color: theme.colorScheme.surfaceContainerHigh,
                            child: Center(
                              child: Icon(
                                Icons.folder_special_rounded,
                                color: theme.colorScheme.primary,
                                size: 48,
                              ),
                            ),
                          )
                        : OptimizedNetworkImage(
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
                if (isOpds && !isNav)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: isImporting
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.file_download_rounded, color: Colors.white, size: 18),
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                              onPressed: () => _importOpdsBook(novel),
                            ),
                    ),
                  ),
              ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async {
        if (_navHistory.isNotEmpty) {
          _navHistory.removeLast();
          final prevUrl = _navHistory.isNotEmpty ? _navHistory.last : null;
          await _loadPopular(subUrl: prevUrl);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.pluginName),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _loadPopular(),
              tooltip: 'reload_page'.translate,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'search_novels_hint'.translate,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            _loadPopular();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  filled: true,
                ),
                onSubmitted: _search,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _novels.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.import_contacts_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage != null ? _errorMessage! : 'no_novels_stored'.translate,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => _loadPopular(),
                                  icon: const Icon(Icons.refresh),
                                  label: Text('retry'.translate),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _novels.length,
                          itemBuilder: (context, index) => _buildNovelGridItem(_novels[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
