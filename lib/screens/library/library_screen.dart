import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:akashic_records/widgets/novel_tile.dart';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';

import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/details/novel_details_screen.dart';
import 'package:akashic_records/widgets/skeleton/novel_grid_skeleton.dart';
import 'package:akashic_records/screens/library/search_bar_widget.dart';
import 'package:akashic_records/screens/library/novel_grid_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/widgets/skeleton/novel_tile_skeleton.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

enum NovelDisplayMode { popular, all }

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  List<Novel> novels = [];
  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;
  final int itemsPerPage = 20;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();
  String _searchTerm = "";
  List<Novel> allNovels = [];
  Set<String> _previousPlugins = {};

  final _searchTextController = BehaviorSubject<String>();

  bool _mounted = false;
  bool _isListView = false;
  Set<String> _hiddenNovelIds = {};
  CancelableOperation? _currentSearchOperation;
  NovelDisplayMode _displayMode = NovelDisplayMode.popular;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _scrollController.addListener(_scrollListener);
    _loadViewMode();
    _loadHiddenNovels();
    _loadNovelsFromJSON();

    _searchTextController
        .debounceTime(const Duration(milliseconds: 500))
        .listen(_searchNovels);

    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = _displayMode == NovelDisplayMode.popular ? 0 : 1;
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _changeDisplayMode(
          _tabController.index == 0
              ? NovelDisplayMode.popular
              : NovelDisplayMode.all,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);

    if (_previousPlugins != appState.selectedPlugins) {
      _previousPlugins = Set<String>.from(appState.selectedPlugins);
      _refreshNovels();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchTextController.close();
    _currentSearchOperation?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/novels.json');
  }

  Future<void> _saveNovelsToJSON() async {
    final file = await _localFile;

    final novelList = allNovels.map((novel) => novel.toMap()).toList();
    final jsonString = jsonEncode(novelList);

    try {
      await compute(_writeToFile, {'file': file, 'data': jsonString});
      if (kDebugMode) {
        print("Novels saved to JSON successfully!");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error writing to JSON file: $e");
      }
    }
  }

  static Future<void> _writeToFile(Map<String, dynamic> params) async {
    final File file = params['file'] as File;
    final String data = params['data'] as String;
    await file.writeAsString(data);
  }

  Future<void> _loadNovelsFromJSON() async {
    final file = await _localFile;

    try {
      final jsonString = await file.readAsString();
      final dynamic decodedJson = await compute(jsonDecode, jsonString);

      final List<dynamic> novelList =
          decodedJson is List
              ? decodedJson
              : (decodedJson is Map ? [decodedJson] : []);

      setState(() {
        allNovels = novelList.map((json) => Novel.fromMap(json)).toList();
        _filterNovelsForDisplay();
      });

      if (kDebugMode) {
        print("Novels loaded from JSON successfully!");
      }
    } on FormatException catch (e) {
      if (kDebugMode) {
        print("Error parsing JSON: $e");
      }
      setState(() {
        errorMessage = "Erro ao analisar o arquivo JSON.".translate;
      });
      _loadDataBasedOnMode();
    } on FileSystemException catch (e) {
      if (kDebugMode) {
        print("Error reading file: $e");
      }
      setState(() {
        errorMessage = "Erro ao ler o arquivo.".translate;
      });
      _loadDataBasedOnMode();
    } catch (e) {
      if (kDebugMode) {
        print("Unexpected error: $e");
      }
      setState(() {
        errorMessage = "Erro inesperado: ${e.toString()}".translate;
      });
      _loadDataBasedOnMode();
    }
  }

  Future<void> _loadAllNovels() async {
    if (isLoading) return;

    if (_mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final pluginNames = appState.selectedPlugins;

      List<Novel> allFetchedNovels = [];
      for (final pluginName in pluginNames) {
        final plugin = appState.pluginServices[pluginName];
        if (plugin != null) {
          try {
            final pluginNovels = await plugin.getAllNovels();
            for (final novel in pluginNovels) {
              novel.pluginId = pluginName;
            }
            allFetchedNovels.addAll(pluginNovels);
          } catch (e) {
            print('Erro ao carregar todas as novels do plugin $pluginName: $e');
          }
        }
      }

      final Set<String> seenNovelIds =
          allNovels.map((n) => "${n.id}-${n.pluginId}").toSet();
      List<Novel> actuallyNewNovels = [];
      for (final novel in allFetchedNovels) {
        final novelId = "${novel.id}-${novel.pluginId}";
        if (!seenNovelIds.contains(novelId)) {
          actuallyNewNovels.add(novel);
          allNovels.add(novel);
          seenNovelIds.add(novelId);
        }
      }

      List<Novel> filteredNovels =
          actuallyNewNovels.where((novel) {
            final novelIdentifier = "${novel.pluginId}-${novel.id}";
            return !_hiddenNovelIds.contains(novelIdentifier);
          }).toList();

      if (_mounted) {
        setState(() {
          novels = filteredNovels;
          isLoading = false;
          hasMore = false;
        });
      }
      await _saveNovelsToJSON();
    } catch (e) {
      if (_mounted) {
        setState(() {
          errorMessage =
              'Erro ao carregar todas as novels: ${e.toString()}'.translate;
          isLoading = false;
          hasMore = false;
        });
      }
    }
  }

  Future<void> _loadDataBasedOnMode() async {
    if (_displayMode == NovelDisplayMode.popular) {
      _loadPopularNovels();
    } else {
      _loadAllNovels();
    }
  }

  Future<void> updateNovels() async {
    if (isLoading) return;

    allNovels.clear();
    novels.clear();

    if (_displayMode == NovelDisplayMode.popular) {
      currentPage = 1;
      hasMore = true;
      _loadPopularNovels();
    } else {
      _loadAllNovels();
    }

    await _saveNovelsToJSON();

    setState(() {});
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

  Future<void> _loadHiddenNovels() async {
    final prefs = await SharedPreferences.getInstance();
    final hiddenNovelIdsStringList =
        prefs.getStringList('hiddenNovelIds') ?? [];
    setState(() {
      _hiddenNovelIds = hiddenNovelIdsStringList.toSet();
    });
  }

  Future<void> _saveHiddenNovels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('hiddenNovelIds', _hiddenNovelIds.toList());
  }

  Future<void> _hideNovel(Novel novel) async {
    final novelId = "${novel.pluginId}-${novel.id}";
    setState(() {
      _hiddenNovelIds.add(novelId);
    });
    await _saveHiddenNovels();
    _filterNovelsForDisplay();
  }

  void _scrollListener() {
    double triggerPercentage = 0.8;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * triggerPercentage &&
        hasMore &&
        !isLoading &&
        _displayMode == NovelDisplayMode.popular) {
      if (_searchTerm.isEmpty) {
        _loadMorePopularNovels();
      }
    }
  }

  Future<void> _loadPopularNovels() async {
    if (isLoading) return;

    if (_mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final pluginNames = appState.selectedPlugins;

      final futures =
          pluginNames.map((pluginName) async {
            final plugin = appState.pluginServices[pluginName];
            if (plugin != null) {
              final pluginNovels = await plugin.popularNovels(currentPage);
              for (final novel in pluginNovels) {
                novel.pluginId = pluginName;
              }
              return pluginNovels;
            }
            return <Novel>[];
          }).toList();

      final List<List<Novel>> results = await Future.wait(futures);

      List<Novel> newNovels = results.expand((list) => list).toList();

      final Set<String> seenNovelIds =
          allNovels.map((n) => "${n.id}-${n.pluginId}").toSet();

      List<Novel> actuallyNewNovels = [];
      for (final novel in newNovels) {
        final novelId = "${novel.id}-${novel.pluginId}";
        if (!seenNovelIds.contains(novelId)) {
          actuallyNewNovels.add(novel);
          allNovels.add(novel);
          seenNovelIds.add(novelId);
        }
      }

      List<Novel> filteredNovels =
          actuallyNewNovels.where((novel) {
            final novelIdentifier = "${novel.pluginId}-${novel.id}";
            return !_hiddenNovelIds.contains(novelIdentifier);
          }).toList();

      if (_mounted) {
        setState(() {
          novels.addAll(filteredNovels);
          hasMore = newNovels.length == itemsPerPage;
          isLoading = false;
        });
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          errorMessage =
              'Erro ao carregar novels populares: ${e.toString()}'.translate;
          hasMore = false;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _searchNovels(String term) async {
    _currentSearchOperation?.cancel();

    if (_mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        hasMore = false;
      });
    }

    _currentSearchOperation = CancelableOperation.fromFuture(
      _performSearch(term),
      onCancel: () {
        if (_mounted) {
          setState(() {
            isLoading = false;
            errorMessage = "Pesquisa cancelada.".translate;
          });
        }
      },
    );

    try {
      await _currentSearchOperation!.value;
    } catch (e) {
      if (_mounted && e is! CancelableOperation) {
        setState(() {
          errorMessage = 'Erro ao pesquisar novels: ${e.toString()}'.translate;
          isLoading = false;
        });
      }
    } finally {
      if (_mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _performSearch(String term) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);

      final futures =
          appState.selectedPlugins.map((pluginName) async {
            final plugin = appState.pluginServices[pluginName];
            if (plugin != null) {
              final pluginSearchResults = await plugin.searchNovels(term, 1);
              for (final novel in pluginSearchResults) {
                novel.pluginId = pluginName;
              }
              return pluginSearchResults;
            }
            return <Novel>[];
          }).toList();

      final List<List<Novel>> results = await Future.wait(futures);
      List<Novel> searchResultsTotal = results.expand((list) => list).toList();

      final Set<String> seenNovelIds =
          allNovels.map((n) => "${n.id}-${n.pluginId}").toSet();
      List<Novel> actuallyNewNovels = [];
      for (final novel in searchResultsTotal) {
        final novelId = "${novel.id}-${novel.pluginId}";
        if (!seenNovelIds.contains(novelId)) {
          actuallyNewNovels.add(novel);
          allNovels.add(novel);
          seenNovelIds.add(novelId);
        }
      }

      List<Novel> filteredSearchResults =
          actuallyNewNovels.where((novel) {
            final novelIdentifier = "${novel.pluginId}-${novel.id}";
            return !_hiddenNovelIds.contains(novelIdentifier);
          }).toList();

      if (_mounted) {
        setState(() {
          novels = filteredSearchResults;
          hasMore = false;
        });
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          errorMessage = 'Erro ao pesquisar novels: ${e.toString()}'.translate;
        });
      }
      rethrow;
    }
  }

  Future<void> _loadMorePopularNovels() async {
    if (isLoading || !hasMore) return;
    currentPage++;
    await _loadPopularNovels();
  }

  Future<void> _refreshNovels() async {
    if (_mounted) {
      setState(() {
        currentPage = 1;
        hasMore = true;
        isLoading = false;
      });
    }

    bool shouldLoadData = true;

    if (_searchTerm.isEmpty) {
      novels.clear();
    } else {
      shouldLoadData = false;
      _searchNovels(_searchTerm);
    }

    if (shouldLoadData) {
      await _loadDataBasedOnMode();
    }

    await _saveNovelsToJSON();
  }

  void _handleNovelTap(Novel novel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NovelDetailsScreen(novel: novel)),
    );
  }

  void _onSearchChanged(String term) {
    _searchTerm = term;
    _searchTextController.add(term);
  }

  void _toggleView() {
    setState(() {
      _isListView = !_isListView;
    });
    _saveViewMode(_isListView);
  }

  void _changeDisplayMode(NovelDisplayMode mode) {
    if (_displayMode != mode) {
      setState(() {
        _displayMode = mode;
        novels.clear();
        currentPage = 1;
        hasMore = true;
      });
      _loadDataBasedOnMode();

      _tabController.animateTo(mode == NovelDisplayMode.popular ? 0 : 1);
    }
  }

  void _filterNovelsForDisplay() {
    List<Novel> filteredNovels =
        allNovels.where((novel) {
          final novelIdentifier = "${novel.pluginId}-${novel.id}";
          return !_hiddenNovelIds.contains(novelIdentifier);
        }).toList();

    if (_displayMode == NovelDisplayMode.popular) {
      setState(() {
        novels = filteredNovels;
      });
    } else {
      setState(() {
        novels = filteredNovels;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
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
                        _isListView ? 'Mostrar em Grid' : 'Mostrar em Lista',
                    onPressed: _toggleView,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Atualizar Novels',
                    onPressed: updateNovels,
                  ),
                ],
              ),
            ),
            _buildDisplayModeTabs(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshNovels,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                child: _buildNovelDisplay(),
              ),
            ),
            if (isLoading && novels.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayModeTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: 'Populares'.translate),
          Tab(text: 'Todas as Novels'.translate),
        ],
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.primary,
        ),
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  Widget _buildNovelDisplay() {
    if (isLoading && novels.isEmpty) {
      return _isListView
          ? ListView.builder(
            controller: _scrollController,
            itemCount: 5,
            itemBuilder: (context, index) => const NovelTileSkeletonWidget(),
          )
          : NovelGridSkeletonWidget(itemCount: 4);
    } else {
      if (novels.isEmpty && !isLoading && errorMessage == null) {
        return Center(
          child: Text(
            "Nenhuma novel encontrada.".translate,
            style: TextStyle(fontSize: 16),
          ),
        );
      }

      if (_isListView) {
        return ListView.builder(
          controller: _scrollController,
          itemCount: novels.length,
          itemBuilder: (context, index) {
            final novel = novels[index];
            return NovelListTile(
              key: Key('${novel.pluginId}-${novel.id}'),
              novel: novel,
              onTap: () => _handleNovelTap(novel),
              onLongPress: () => _hideNovel(novel),
            );
          },
        );
      } else {
        return NovelGridWidget(
          novels: novels,
          isLoading: isLoading,
          errorMessage: errorMessage,
          scrollController: _scrollController,
          onNovelTap: _handleNovelTap,
          onNovelLongPress: _hideNovel,
        );
      }
    }
  }
}
