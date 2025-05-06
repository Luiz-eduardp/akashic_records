import 'dart:async';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/details/novel_details_screen.dart';
import 'package:akashic_records/screens/library/novel_grid_widget.dart';
import 'package:akashic_records/screens/library/search_bar_widget.dart';
import 'package:akashic_records/services/local/local_service.dart';
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
  int _currentPage = 1;
  final int _itemsPerPage = 10;
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

  Future<void> _loadData({int? page}) async {
    setState(() {
      _isLoading = true;
      _isInitialLoad = true;
      _errorMessage = null;
      _loadedNovelKeys.clear();
      if (page == null || page == 1) {
        _novels.clear();
        _filteredNovels.clear();
      }
    });

    int pageToLoad = page ?? _currentPage;

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[widget.pluginName];

      if (plugin != null) {
        List<Novel> popularNovels = await plugin.popularNovels(
          pageToLoad,
          context: context,
        );

        for (final novel in popularNovels) {
          novel.pluginId = widget.pluginName;
          if (!_loadedNovelKeys.contains(novel.id)) {
            _novels.add(novel);
            _loadedNovelKeys.add(novel.id);
          }
        }
        _updateFilteredNovels();
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
        localResults = _novels
            .where((novel) =>
                novel.title.toLowerCase().contains(term.toLowerCase()) == true)
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
        if (!combinedResults.any((pluginNovel) =>
            pluginNovel.pluginId == localNovel.pluginId &&
            pluginNovel.id == localNovel.id)) {
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

  void _scrollListener() {}

  List<Novel> _getCurrentPageNovels() {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _filteredNovels.length) {
      return [];
    }

    if (endIndex > _filteredNovels.length) {
      endIndex = _filteredNovels.length;
    }

    return _filteredNovels.sublist(startIndex, endIndex);
  }

  void _goToNextPage() {
    if (!(_isLoading || _errorMessage != null)) {
      setState(() {
        _currentPage++;
        _loadMoreData(page: _currentPage);
      });
    }
  }

  void _goToPreviousPage() {
    if (!(_isLoading || _errorMessage != null) && _currentPage > 1) {
      setState(() {
        _currentPage--;
        _loadMoreData(page: _currentPage);
      });
    }
  }

  void _updateFilteredNovels() {
    setState(() {
      _filteredNovels = List.from(_novels);
    });
  }

  Future<void> _loadMoreData({int? page}) async {
    setState(() {
      _isLoadingMore = true;
      _errorMessage = null;
    });

    int pageToLoad = page ?? _currentPage;

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[widget.pluginName];

      if (plugin != null) {
        List<Novel> newNovels = await plugin.popularNovels(
          pageToLoad,
          context: context,
        );
        setState(() {
          for (final novel in newNovels) {
            novel.pluginId = widget.pluginName;
            if (!_loadedNovelKeys.contains(novel.id)) {
              _novels.add(novel);
              _loadedNovelKeys.add(novel.id);
            }
          }
          _isLoadingMore = false;
          _updateFilteredNovels();
        });
      } else {
        setState(() {
          _errorMessage = 'Plugin não encontrado.'.translate;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erro ao carregar mais novels: ${e.toString()}'.translate;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _deleteNovel(Novel novel) async {
    if (widget.pluginName != 'Dispositivo') return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final dispositivoPlugin =
          appState.pluginServices[widget.pluginName] as Dispositivo;

      if (dispositivoPlugin != null) {
        await dispositivoPlugin.deleteNovel(novel.id);

        // Atualizar a lista local
        setState(() {
          _novels.remove(novel);
          _filteredNovels.remove(novel);
        });

        // Atualizar AppState
        appState.localNovels.removeWhere((n) => n.id == novel.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Novel deletada com sucesso.'.translate),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Plugin Dispositivo não encontrado'.translate;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao deletar novel: ${e.toString()}'.translate;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Provider.of<AppState>(context);

    int totalPages = (_filteredNovels.length / _itemsPerPage).ceil();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(widget.pluginName),
        backgroundColor: theme.colorScheme.surface,
        centerTitle: true,
        actions: [
          if (widget.pluginName == 'Dispositivo')
            IconButton(
              icon: const Icon(Icons.file_upload),
              tooltip: 'Importar Novels'.translate,
              onPressed: () {
                _importNovelsFromDevice();
              },
            ),
        ],
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
                _buildPaginationButtons(totalPages),
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
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: theme.colorScheme.background.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
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

      List<Novel> currentPageNovels = _getCurrentPageNovels();

      return NovelGridWidget(
        novels: currentPageNovels,
        isListView: _isListView,
        scrollController: _scrollController,
        onNovelTap: _handleNovelTap,
        errorMessage: _errorMessage,
        isLoading: _isLoading || _isLoadingMore,
        onNovelLongPress: (Novel novel) {
          if (widget.pluginName == 'Dispositivo') {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Deletar Novel?".translate),
                  content: Text(
                    "Você tem certeza que deseja deletar '${novel.title}'?".translate,
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text("Cancelar".translate),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text("Deletar".translate),
                      onPressed: () {
                        _deleteNovel(novel);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          }
        },
      );
    }
  }

  Widget _buildPaginationButtons(int totalPages) {
    (_filteredNovels.length / _itemsPerPage).ceil();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentPage > 1 ? _goToPreviousPage : null,
            disabledColor: Colors.grey,
          ),
          Text(
            'P'
            '$_currentPage',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed:
                (_isLoading || _errorMessage != null) ||
                        ((_novels.length) < _itemsPerPage)
                    ? null
                    : _goToNextPage,
            disabledColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Future<void> _importNovelsFromDevice() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final dispositivoPlugin =
          appState.pluginServices[widget.pluginName] as Dispositivo;

      if (dispositivoPlugin != null) {
        List<Novel> importedNovels = await dispositivoPlugin.getAllNovels(
          context: context,
        );

        setState(() {
          _novels.clear();
          _novels.addAll(appState.localNovels);
          _updateFilteredNovels();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sucesso ao importar'.translate +
                  ' ' +
                  importedNovels.length.toString() +
                  ' ' +
                  'novels'.translate,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Plugin Dispositivo não encontrado'.translate;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao importar'.translate + ' ' + e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}