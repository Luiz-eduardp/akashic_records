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

enum NovelDisplayMode {
  popular,
  all,
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Novel> novels = []; // Novels to display in the current mode
  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;
  final int itemsPerPage = 20;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();
  String _searchTerm = "";
  List<Novel> allNovels = []; // All novels from all plugins
  Set<String> _previousPlugins = {};

  final _searchTextController = BehaviorSubject<String>();

  bool _mounted = false;
  bool _isListView = false;
  Set<String> _hiddenNovelIds = {};
  CancelableOperation? _currentSearchOperation;
  NovelDisplayMode _displayMode = NovelDisplayMode
      .popular; // Current display mode (popular or all)

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context);

    if (_previousPlugins != appState.selectedPlugins) {
      _previousPlugins = Set<String>.from(appState.selectedPlugins);
      _refreshNovels();
      // No need to call updateNovels here anymore, _refreshNovels handles it based on display mode
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchTextController.close();
    _currentSearchOperation?.cancel();
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

      final List<dynamic> novelList = decodedJson is List
          ? decodedJson
          : (decodedJson is Map ? [decodedJson] : []);

      setState(() {
        allNovels = novelList.map((json) => Novel.fromMap(json)).toList();
        _filterNovelsForDisplay(); // Initial filtering based on display mode
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
      _loadDataBasedOnMode(); // Load initial data based on display mode
    } on FileSystemException catch (e) {
      if (kDebugMode) {
        print("Error reading file: $e");
      }
      setState(() {
        errorMessage = "Erro ao ler o arquivo.".translate;
      });
      _loadDataBasedOnMode(); // Load initial data based on display mode
    } catch (e) {
      if (kDebugMode) {
        print("Unexpected error: $e");
      }
      setState(() {
        errorMessage = "Erro inesperado: ${e.toString()}".translate;
      });
      _loadDataBasedOnMode(); // Load initial data based on display mode
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
            print(
                'Erro ao carregar todas as novels do plugin $pluginName: $e'); //More specific error message
            //Consider showing a user-friendly error message about this plugin
          }
        }
      }

      // Filter new novels against existing allNovels
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

      //Filter hidden novels
      List<Novel> filteredNovels = actuallyNewNovels.where((novel) {
        final novelIdentifier = "${novel.pluginId}-${novel.id}";
        return !_hiddenNovelIds.contains(novelIdentifier);
      }).toList();

      if (_mounted) {
        setState(() {
          novels = filteredNovels; //Display the new novels immediately
          isLoading = false;
          hasMore =
              false; //  Since you fetched ALL novels, there's no more to load
        });
      }
      await _saveNovelsToJSON();
    } catch (e) {
      if (_mounted) {
        setState(() {
          errorMessage = 'Erro ao carregar todas as novels: ${e.toString()}'
              .translate; // More specific error message
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
    if (isLoading) return; // Prevent multiple updates at once

    allNovels.clear(); // Clear existing allNovels list
    novels.clear(); //Clear displayed novels

    if (_displayMode ==
        NovelDisplayMode.popular) //Load popular novels logic
    {
      currentPage = 1; //Reset pagination
      hasMore = true;
      _loadPopularNovels();
    } else //Load all novels logic
    {
      _loadAllNovels();
    }

    await _saveNovelsToJSON(); //Save changes

    setState(() {}); //Refresh UI
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

      List<Novel> filteredNovels = actuallyNewNovels.where((novel) {
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
          errorMessage = 'Erro ao carregar novels populares: ${e.toString()}'
              .translate; // More specific message
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

      List<Novel> filteredSearchResults = actuallyNewNovels.where((novel) {
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

    bool shouldLoadData = true; //Flag for whether to load data

    if (_searchTerm.isEmpty) {
      //  Clear only if not searching
      novels.clear();
    } else {
      //If searching, cancel popular novels loading
      shouldLoadData = false;
      _searchNovels(_searchTerm); //Perform a search instead
    }

    if (shouldLoadData) {
      //Load the selected novels (either popular or all)
      await _loadDataBasedOnMode();
    }

    await _saveNovelsToJSON(); //Persist state
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
        novels.clear(); // Clear current novels
        currentPage = 1; // Reset pagination
        hasMore = true; // Reset hasMore flag
      });
      _loadDataBasedOnMode(); //Load data based on mode
    }
  }

  void _filterNovelsForDisplay() {
    //Apply hidden novel filtering to allNovels and update the display list
    List<Novel> filteredNovels = allNovels.where((novel) {
      final novelIdentifier = "${novel.pluginId}-${novel.id}";
      return !_hiddenNovelIds.contains(novelIdentifier);
    }).toList();

    if (_displayMode == NovelDisplayMode.popular) {
      //Display all popular filtered novels
      setState(() {
        novels = filteredNovels;
      });
    } else {
      //Display ALL novels (and apply the filter)
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
            _buildDisplayModeButtons(), // Display mode buttons

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

  Widget _buildDisplayModeButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _displayMode == NovelDisplayMode.popular
                  ? Theme.of(context).colorScheme.primary
                  : null,
              foregroundColor: _displayMode == NovelDisplayMode.popular
                  ? Theme.of(context).colorScheme.onPrimary
                  : null,
            ),
            onPressed: () => _changeDisplayMode(NovelDisplayMode.popular),
            child: Text('Populares'.translate),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _displayMode == NovelDisplayMode.all
                  ? Theme.of(context).colorScheme.primary
                  : null,
              foregroundColor: _displayMode == NovelDisplayMode.all
                  ? Theme.of(context).colorScheme.onPrimary
                  : null,
            ),
            onPressed: () => _changeDisplayMode(NovelDisplayMode.all),
            child: Text('Todas'.translate),
          ),
        ],
      ),
    );
  }

  Widget _buildNovelDisplay() {
    if (isLoading && novels.isEmpty) {
      //Skeleton Loading
      return _isListView
          ? ListView.builder(
              controller: _scrollController,
              itemCount: 5,
              itemBuilder: (context, index) =>
                  const NovelTileSkeletonWidget(), //List Skeleton
            )
          : NovelGridSkeletonWidget(
              itemCount: 4); // Grid Skeleton
    } else {
      if (novels.isEmpty && !isLoading && errorMessage == null) {
        return Center(
          child: Text(
              "Nenhuma novel encontrada.".translate, //Empty State message
              style: TextStyle(fontSize: 16)),
        );
      }

      if (_isListView) {
        //List View
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
        //Grid View
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