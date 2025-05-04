import 'dart:async';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/details/novel_details_screen.dart';
import 'package:akashic_records/screens/library/novel_grid_widget.dart';
import 'package:akashic_records/screens/library/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'package:akashic_records/widgets/skeleton/novel_tile_skeleton.dart';
import 'package:akashic_records/widgets/skeleton/novel_grid_skeleton.dart';

class PluginNovelsScreen extends StatefulWidget {
  final String pluginName;

  const PluginNovelsScreen({super.key, required this.pluginName});

  @override
  State<PluginNovelsScreen> createState() => _PluginNovelsScreenState();
}

class _PluginNovelsScreenState extends State<PluginNovelsScreen> {
  final List<Novel> _novels = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  final _searchTextController = BehaviorSubject<String>();
  List<Novel> _filteredNovels = [];
  bool _isListView = false;
  final ScrollController _scrollController = ScrollController();
  int _currentPagePopular = 1;
  bool _isInitialLoad = true;
  final Set<String> _loadedNovelKeys = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchTextController
        .debounceTime(const Duration(milliseconds: 500))
        .listen(_searchNovels);
    _scrollController.addListener(_scrollListener);
    _loadViewMode();
  }

  @override
  void dispose() {
    _searchTextController.close();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isListView = prefs.getBool('isListView') ?? false;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isInitialLoad = true;
      _errorMessage = null;
      _loadedNovelKeys.clear();
      _novels.clear();
      _filteredNovels.clear();
      _currentPagePopular = 1;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[widget.pluginName];

      if (plugin != null) {
        List<Novel> popularNovels = await plugin.popularNovels(
          _currentPagePopular,
        );
        for (final novel in popularNovels) {
          novel.pluginId = widget.pluginName;
          if (!_loadedNovelKeys.contains(novel.id)) {
            _novels.add(novel);
            _loadedNovelKeys.add(novel.id);
          }
        }

        List<Novel> allNovels = await plugin.getAllNovels();
        for (final novel in allNovels) {
          novel.pluginId = widget.pluginName;
          if (!_loadedNovelKeys.contains(novel.id)) {
            _novels.add(novel);
            _loadedNovelKeys.add(novel.id);
          }
        }

        setState(() {
          _filteredNovels = List.from(_novels);
        });
      } else {
        setState(() {
          _errorMessage = 'Plugin não encontrado.'.translate;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar novels: ${e.toString()}'.translate;
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isInitialLoad = false;
      });
    }
  }

  Future<void> _searchNovels(String term) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Novel> localResults = [];
      List<Novel> pluginResults = [];

      if (term.isNotEmpty) {
        localResults =
            _novels
                .where(
                  (novel) =>
                      novel.title.toLowerCase().contains(term.toLowerCase()) ==
                      true,
                )
                .toList();

        final appState = Provider.of<AppState>(context, listen: false);
        final plugin = appState.pluginServices[widget.pluginName];

        if (plugin != null) {
          pluginResults = await plugin.searchNovels(term, 1);
          for (final novel in pluginResults) {
            novel.pluginId = widget.pluginName;
          }
        } else {
          setState(() {
            _errorMessage = 'Plugin não encontrado.'.translate;
          });
        }
      } else {
        setState(() {
          _filteredNovels = List.from(_novels);
        });
        return;
      }

      final combinedResults = <Novel>[];
      combinedResults.addAll(pluginResults);

      for (final localNovel in localResults) {
        if (!combinedResults.any(
          (pluginNovel) =>
              pluginNovel.pluginId == localNovel.pluginId &&
              pluginNovel.id == localNovel.id,
        )) {
          combinedResults.add(localNovel);
        }
      }

      setState(() {
        _filteredNovels = combinedResults;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao pesquisar novels: ${e.toString()}'.translate;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleNovelTap(Novel novel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NovelDetailsScreen(novel: novel)),
    );
  }

  void _onSearchChanged(String term) {
    _searchTextController.add(term);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNovels();
    }
  }

  Future<void> _loadMoreNovels() async {
    if (_isLoadingMore || _isLoading || _errorMessage != null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[widget.pluginName];

      if (plugin != null) {
        _currentPagePopular++;
        List<Novel> popularNovels = await plugin.popularNovels(
          _currentPagePopular,
        );
        for (final novel in popularNovels) {
          novel.pluginId = widget.pluginName;
          if (!_loadedNovelKeys.contains(novel.id)) {
            _novels.add(novel);
            _loadedNovelKeys.add(novel.id);
          }
        }

        List<Novel> allNovels = await plugin.getAllNovels();
        for (final novel in allNovels) {
          novel.pluginId = widget.pluginName;
          if (!_loadedNovelKeys.contains(novel.id)) {
            _novels.add(novel);
            _loadedNovelKeys.add(novel.id);
          }
        }

        setState(() {
          _filteredNovels = List.from(_novels);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erro ao carregar mais novels: ${e.toString()}'.translate;
      });
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(widget.pluginName),
        backgroundColor: theme.colorScheme.surface,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBarWidget(
                    onSearch: _onSearchChanged,
                    onFilterPressed: null,
                  ),
                ),
                Expanded(child: _buildNovelDisplay()),
                if (_isLoading && !_isInitialLoad)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                if (_isLoadingMore)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
            if (_isInitialLoad) _buildInitialLoadingOverlay(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialLoadingOverlay(ThemeData theme) {
    return Positioned.fill(
      child: Container(
        color: theme.colorScheme.background.withOpacity(0.8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'O primeiro carregamento pode demorar um pouco devido à quantidade de informações'
                    .translate,
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNovelDisplay() {
    if (_isLoading && _filteredNovels.isEmpty) {
      return _isListView
          ? ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) => const NovelTileSkeletonWidget(),
          )
          : NovelGridSkeletonWidget(itemCount: 4);
    } else {
      if (_filteredNovels.isEmpty && !_isLoading && _errorMessage == null) {
        return Center(
          child: Text(
            "Nenhuma novel encontrada.".translate,
            style: const TextStyle(fontSize: 16),
          ),
        );
      }

      return NovelGridWidget(
        novels: _filteredNovels,
        isListView: _isListView,
        scrollController: _scrollController,
        onNovelTap: _handleNovelTap,
        errorMessage: _errorMessage,
        isLoading: _isLoading || _isLoadingMore,
        onNovelLongPress: (Novel NOVEL) {},
      );
    }
  }
}
