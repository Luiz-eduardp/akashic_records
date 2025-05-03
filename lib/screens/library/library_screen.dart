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
  const LibraryScreen({Key? key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ValueNotifier<List<Novel>> _displayedNovels =
      ValueNotifier<List<Novel>>([]);

  final ValueNotifier<List<Novel>> _cachedNovels = ValueNotifier<List<Novel>>(
    [],
  );

  bool isLoading = false;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();
  Set<String> _previousPlugins = {};
  final _searchTextController = BehaviorSubject<String>();
  bool _mounted = false;
  bool _isListView = false;
  Set<String> _hiddenNovelIds = {};
  int _currentPage = 0;
  final int _novelsPerPage = 20;
  CancelableOperation? _currentSearchOperation;
  final Set<String> _cachedNovelIds = {};

  bool _isInitialLoad = true;
  double _loadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _scrollController.addListener(_scrollListener);
    _loadViewMode();
    _loadHiddenNovels();
    _loadCachedNovels();
    _searchTextController
        .debounceTime(const Duration(milliseconds: 500))
        .listen(_searchNovels);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);

    if (_previousPlugins != appState.selectedPlugins) {
      _previousPlugins = Set<String>.from(appState.selectedPlugins);
      _refreshNovels(forceRefetch: true);
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchTextController.close();
    _currentSearchOperation?.cancel();
    _cachedNovels.dispose();
    _displayedNovels.dispose();
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

  Future<void> _saveCachedNovels() async {
    final file = await _localFile;
    final sortedNovels = List<Novel>.from(_cachedNovels.value);
    sortedNovels.sort((a, b) => a.title.compareTo(b.title));
    final novelList = sortedNovels.map((novel) => novel.toMap()).toList();
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

  Future<void> _loadCachedNovels() async {
    try {
      final file = await _localFile;
      final jsonString = await file.readAsString();
      final dynamic decodedJson = await compute(jsonDecode, jsonString);

      final List<dynamic> novelList =
          decodedJson is List
              ? decodedJson
              : (decodedJson is Map ? [decodedJson] : []);

      List<Novel> loadedNovels =
          novelList.map((json) => Novel.fromMap(json)).toList();
      loadedNovels.sort((a, b) => a.title.compareTo(b.title));
      _cachedNovels.value = loadedNovels;
      _displayedNovels.value = List.from(loadedNovels);
      _cachedNovelIds.addAll(loadedNovels.map((n) => "${n.id}-${n.pluginId}"));

      _updateNovelCount(loadedNovels.length);

      if (_mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }

      if (kDebugMode) {
        print("Novels loaded from JSON successfully!");
      }
      if (loadedNovels.isEmpty) {
        _loadDataFromPlugins();
      }
    } on FileSystemException catch (e) {
      if (kDebugMode) {
        print("Error reading file: $e");
      }
      if (_mounted) {
        setState(() {
          errorMessage = "Erro ao ler o arquivo.".translate;
          _isInitialLoad = false;
        });
      }
      _loadDataFromPlugins();
    } catch (e) {
      if (kDebugMode) {
        print("Error loading novels from JSON: $e");
      }
      if (_mounted) {
        setState(() {
          errorMessage = "Erro ao carregar novels do cache.".translate;
          _isInitialLoad = false;
        });
      }
      _loadDataFromPlugins();
    } finally {
      if (_mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDataFromPlugins() async {
    if (_mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        _loadProgress = 0.0;
      });
    }

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final pluginNames = appState.selectedPlugins;
      final totalPlugins = pluginNames.length;
      double pluginsLoaded = 0;

      List<Novel> allFetchedNovels = [];
      for (final pluginName in pluginNames) {
        final plugin = appState.pluginServices[pluginName];
        if (plugin != null) {
          try {
            final popularNovels = await plugin.popularNovels(1);
            final allNovels = await plugin.getAllNovels();
            final combinedNovels = [...popularNovels, ...allNovels];
            for (final novel in combinedNovels) {
              novel.pluginId = pluginName;
            }
            allFetchedNovels.addAll(combinedNovels);
          } catch (e) {
            print('Erro ao carregar novels do plugin $pluginName: $e');
          }
        }
        pluginsLoaded++;
        final progress = pluginsLoaded / totalPlugins;
        if (_mounted) {
          setState(() {
            _loadProgress = progress;
          });
        }
      }
      _addNewNovelsToCache(allFetchedNovels);
      _filterNovelsForDisplay();

      if (_mounted) {
        setState(() {
          isLoading = false;
          _isInitialLoad = false;
          _loadProgress = 1.0;
        });
      }
      await _saveCachedNovels();
    } catch (e) {
      if (_mounted) {
        setState(() {
          errorMessage = 'Erro ao carregar novels: ${e.toString()}'.translate;
          isLoading = false;
          _isInitialLoad = false;
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

  void _addNewNovelsToCache(List<Novel> newNovels) {
    List<Novel> actuallyNewNovels = [];
    for (final novel in newNovels) {
      final novelId = "${novel.id}-${novel.pluginId}";
      if (!_cachedNovelIds.contains(novelId)) {
        actuallyNewNovels.add(novel);
        _cachedNovelIds.add(novelId);
      }
    }

    if (actuallyNewNovels.isNotEmpty) {
      _cachedNovels.value = List<Novel>.from(_cachedNovels.value)
        ..addAll(actuallyNewNovels);
      _saveCachedNovels();
      _updateNovelCount(_cachedNovels.value.length);
    }
  }

  Future<void> _searchNovels(String term) async {
    _currentSearchOperation?.cancel();

    if (_mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    _currentSearchOperation = CancelableOperation.fromFuture(
      _performSearch(term),
      onCancel: () {
        if (_mounted) {
          setState(() {
            isLoading = false;
            errorMessage = "Pesquisa cancelada.".translate;
            _displayedNovels.value = List.from(_cachedNovels.value);
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
    List<Novel> searchResults = [];

    if (term.isNotEmpty) {
      List<Novel> cachedSearchResults =
          _cachedNovels.value
              .where(
                (novel) =>
                    novel.title.toLowerCase().contains(term.toLowerCase()),
              )
              .toList();
      searchResults.addAll(cachedSearchResults);

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
        List<Novel> apiSearchResults = results.expand((list) => list).toList();
        _addNewNovelsToCache(apiSearchResults);
        searchResults.addAll(apiSearchResults);
      } catch (e) {
        if (_mounted) {
          setState(() {
            errorMessage =
                'Erro ao pesquisar novels: ${e.toString()}'.translate;
          });
        }
        rethrow;
      }
    }
    _filterNovelsForDisplay(searchTerm: term);
  }

  Future<void> _refreshNovels({bool forceRefetch = false}) async {
    if (_mounted) {
      setState(() {
        isLoading = true;
      });
    }
    try {
      if (forceRefetch) {
        await _loadDataFromPlugins();
      }
    } finally {
      if (_mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNovels();
    }
  }

  void _loadMoreNovels() {
    if (isLoading ||
        _displayedNovels.value.length >= _cachedNovels.value.length) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 30), () {
      final nextPage = _currentPage + 1;
      final startIndex = _novelsPerPage * _currentPage;
      final endIndex = (startIndex + _novelsPerPage).clamp(
        0,
        _cachedNovels.value.length,
      );

      final additionalNovels = _cachedNovels.value.sublist(
        startIndex,
        endIndex,
      );

      _displayedNovels.value = List<Novel>.from(_displayedNovels.value)
        ..addAll(additionalNovels);

      setState(() {
        _currentPage = nextPage;
        isLoading = false;
      });
    });
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

  void _filterNovelsForDisplay({String searchTerm = ""}) {
    List<Novel> filteredNovels =
        _cachedNovels.value.where((novel) {
          final novelIdentifier = "${novel.pluginId}-${novel.id}";
          return !_hiddenNovelIds.contains(novelIdentifier) &&
              novel.title.toLowerCase().contains(searchTerm.toLowerCase());
        }).toList();

    filteredNovels.sort((a, b) => a.title.compareTo(b.title));

    _updateNovelCount(filteredNovels.length);

    if (_mounted) {
      _displayedNovels.value = filteredNovels.take(_novelsPerPage).toList();
    }
  }

  void _updateNovelCount(int count) {
    Provider.of<AppState>(context, listen: false).updateNovelCount(count);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
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
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Atualizar Novels',
                        onPressed: () => _refreshNovels(forceRefetch: true),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _refreshNovels(forceRefetch: true),
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surface,
                    child: _buildNovelDisplay(),
                  ),
                ),
                if (isLoading &&
                    _displayedNovels.value.isNotEmpty &&
                    !_isInitialLoad)
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "O primeiro carregamento pode demorar um pouco devido à quantidade de informações.",
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(value: _loadProgress),
          ],
        ),
      ),
    );
  }

  Widget _buildNovelDisplay() {
    if (isLoading && _displayedNovels.value.isEmpty) {
      return _isListView
          ? ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) => const NovelTileSkeletonWidget(),
          )
          : NovelGridSkeletonWidget(itemCount: 4);
    } else {
      if (_displayedNovels.value.isEmpty &&
          !isLoading &&
          errorMessage == null) {
        return Center(
          child: Text(
            "Nenhuma novel encontrada.".translate,
            style: const TextStyle(fontSize: 16),
          ),
        );
      }

      return ValueListenableBuilder<List<Novel>>(
        valueListenable: _displayedNovels,
        builder: (context, novels, child) {
          return _buildNovelListOrGrid(novels);
        },
      );
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
            onLongPress: () => _hideNovel(novel),
          );
        },
      );
    } else {
      return NovelGridWidget(
        novels: novels,
        isLoading: false,
        errorMessage: errorMessage,
        scrollController: _scrollController,
        onNovelTap: _handleNovelTap,
        onNovelLongPress: _hideNovel,
      );
    }
  }
}
