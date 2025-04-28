import 'dart:convert';
import 'dart:io';

import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/details/novel_details_screen.dart';
import 'package:akashic_records/widgets/skeleton/novel_grid_skeleton.dart';
import 'package:akashic_records/screens/library/search_bar_widget.dart';
import 'package:akashic_records/screens/library/novel_grid_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'dart:async';
import 'package:akashic_records/widgets/novel_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/widgets/skeleton/novel_tile_skeleton.dart';
import 'package:path_provider/path_provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Novel> novels = [];
  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;
  int itemsPerPage = 20;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();
  String _searchTerm = "";
  List<Novel> allNovels = [];
  Set<String> _previousPlugins = {};
  Timer? _debounce;
  bool _mounted = false;
  bool _isListView = false;
  Set<String> _hiddenNovelIds = {};

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _scrollController.addListener(_scrollListener);
    _loadViewMode();
    _loadHiddenNovels();
    _loadNovelsFromJSON();
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
      await file.writeAsString(jsonString);
      print("Novels saved to JSON successfully!");
    } catch (e) {
      print("Error writing to JSON file: $e");
    }
  }

  Future<void> _loadNovelsFromJSON() async {
    final file = await _localFile;

    try {
      final jsonString = await file.readAsString();
      final List<dynamic> novelList = jsonDecode(jsonString);

      setState(() {
        allNovels = novelList.map((json) => Novel.fromMap(json)).toList();
        novels = List<Novel>.from(allNovels);
      });

      print("Novels loaded from JSON successfully!");
    } catch (e) {
      print("Error reading or parsing JSON file: $e");
      _loadPopularNovels();
    }
  }

  Future<void> _updateNovels() async {
    allNovels.clear();
    novels.clear();

    await _loadPopularNovels();

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
    _refreshNovels();
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
    _debounce?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    double triggerPercentage = 0.8;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * triggerPercentage &&
        hasMore &&
        !isLoading) {
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
      List<Novel> newNovels = [];
      final appState = Provider.of<AppState>(context, listen: false);

      for (final pluginName in appState.selectedPlugins) {
        final plugin = appState.pluginServices[pluginName];
        if (plugin != null) {
          final pluginNovels = await plugin.popularNovels(currentPage);
          for (final novel in pluginNovels) {
            novel.pluginId = pluginName;
          }
          newNovels.addAll(pluginNovels);
        }
      }

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
          errorMessage = 'Erro ao carregar novels: $e'.translate;
          hasMore = false;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _searchNovels(String term) async {
    if (isLoading) return;

    if (_mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        hasMore = false;
      });
    }

    try {
      List<Novel> searchResults = [];
      final appState = Provider.of<AppState>(context, listen: false);

      for (final pluginName in appState.selectedPlugins) {
        final plugin = appState.pluginServices[pluginName];
        if (plugin != null) {
          final pluginSearchResults = await plugin.searchNovels(term, 1);
          for (final novel in pluginSearchResults) {
            novel.pluginId = pluginName;
          }
          searchResults.addAll(pluginSearchResults);
        }
      }
      final Set<String> seenNovelIds =
          allNovels.map((n) => "${n.id}-${n.pluginId}").toSet();
      List<Novel> actuallyNewNovels = [];
      for (final novel in searchResults) {
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
          isLoading = false;
        });
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          errorMessage = 'Erro ao pesquisar novels: $e'.translate;
          isLoading = false;
        });
      }
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
    if (_searchTerm.isEmpty) {
      allNovels.clear();
      novels.clear();
      await _loadPopularNovels();
    } else {
      await _searchNovels(_searchTerm);
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
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_mounted) {
        setState(() {
          currentPage = 1;
          hasMore = false;
        });
      }
      if (term.isNotEmpty) {
        _searchNovels(term);
      } else {
        _refreshNovels();
      }
    });
  }

  void _toggleView() {
    setState(() {
      _isListView = !_isListView;
    });
    _saveViewMode(_isListView);
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
                    onPressed: _updateNovels,
                  ),
                ],
              ),
            ),
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
      if (_isListView) {
        return ListView.builder(
          controller: _scrollController,
          itemCount: novels.length,
          itemBuilder: (context, index) {
            final novel = novels[index];
            return GestureDetector(
              onTap: () => _handleNovelTap(novel),
              child: NovelListTile(
                novel: novel,
                onTap: () => _handleNovelTap(novel),
                onLongPress: () => _hideNovel(novel),
              ),
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
