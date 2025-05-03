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
import 'package:akashic_records/widgets/novel_tile.dart';
import 'package:akashic_records/widgets/skeleton/novel_tile_skeleton.dart';
import 'package:akashic_records/widgets/skeleton/novel_grid_skeleton.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView.builder(
          itemCount: appState.selectedPlugins.length,
          itemBuilder: (context, index) {
            final pluginName = appState.selectedPlugins.elementAt(index);
            return PluginCard(pluginName: pluginName);
          },
        ),
      ),
    );
  }
}

class PluginCard extends StatelessWidget {
  final String pluginName;

  const PluginCard({super.key, required this.pluginName});

  @override
  Widget build(BuildContext context) {
    Provider.of<AppState>(context, listen: false);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4.0,
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PluginNovelsScreen(pluginName: pluginName),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pluginName,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }
}

class PluginNovelsScreen extends StatefulWidget {
  final String pluginName;

  const PluginNovelsScreen({super.key, required this.pluginName});

  @override
  State<PluginNovelsScreen> createState() => _PluginNovelsScreenState();
}

class _PluginNovelsScreenState extends State<PluginNovelsScreen> {
  List<Novel> _novels = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _searchTextController = BehaviorSubject<String>();
  List<Novel> _filteredNovels = [];
  bool _isListView = false;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final int _novelsPerPage = 20;
  bool _isInitialLoad = true;

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

  Future<void> _saveViewMode(bool isListView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isListView', isListView);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isInitialLoad = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[widget.pluginName];

      if (plugin != null) {
        final popularNovels = await plugin.popularNovels(1);
        final allNovels = await plugin.getAllNovels();
        final combinedNovels = [...popularNovels, ...allNovels];

        for (final novel in combinedNovels) {
          novel.pluginId = widget.pluginName;
        }

        setState(() {
          _novels = combinedNovels;
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
      if (term.isNotEmpty) {
        final appState = Provider.of<AppState>(context, listen: false);
        final plugin = appState.pluginServices[widget.pluginName];

        if (plugin != null) {
          final searchResults = await plugin.searchNovels(term, 1);
          for (final novel in searchResults) {
            novel.pluginId = widget.pluginName;
          }
          setState(() {
            _filteredNovels = searchResults;
          });
        } else {
          setState(() {
            _errorMessage = 'Plugin não encontrado.'.translate;
          });
        }
      } else {
        setState(() {
          _filteredNovels = List.from(_novels);
        });
      }
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

  void _toggleView() {
    setState(() {
      _isListView = !_isListView;
    });
    _saveViewMode(_isListView);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNovels();
    }
  }

  void _loadMoreNovels() {
    if (_isLoading || _filteredNovels.length >= _novels.length) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 30), () {
      final nextPage = _currentPage + 1;
      final startIndex = _novelsPerPage * _currentPage;
      final endIndex = (_novelsPerPage * (nextPage)).clamp(0, _novels.length);

      final additionalNovels = _novels.sublist(startIndex, endIndex);

      setState(() {
        _filteredNovels = List<Novel>.from(_filteredNovels)
          ..addAll(additionalNovels);
        _currentPage = nextPage;
        _isLoading = false;
      });
    });
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
                    extraActions: [
                      IconButton(
                        icon: Icon(_isListView ? Icons.grid_view : Icons.list),
                        tooltip:
                            _isListView
                                ? 'Mostrar em Grid'
                                : 'Mostrar em Lista',
                        onPressed: _toggleView,
                      ),
                    ],
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

      return _buildNovelListOrGrid(_filteredNovels);
    }
  }

  Widget _buildNovelListOrGrid(List<Novel> novels) {
    if (_isListView) {
      return ListView.builder(
        itemCount: novels.length,
        itemBuilder: (context, index) {
          final novel = novels[index];
          return NovelListTile(
            key: Key('${novel.pluginId}-${novel.id}'),
            novel: novel,
            onTap: () => _handleNovelTap(novel),
            onLongPress: () {},
          );
        },
      );
    } else {
      return NovelGridWidget(
        novels: novels,
        isLoading: false,
        errorMessage: _errorMessage,
        scrollController: _scrollController,
        onNovelTap: _handleNovelTap,
        // ignore: avoid_types_as_parameter_names
        onNovelLongPress: (Novel) {},
      );
    }
  }
}
