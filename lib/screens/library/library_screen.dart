import 'package:akashic_records/models/novel.dart';
import 'package:akashic_records/screens/details/novel_details_screen.dart';
import 'package:akashic_records/screens/library/search_bar_widget.dart';
import 'package:akashic_records/screens/library/novel_grid_widget.dart';
import 'package:akashic_records/services/plugins/ptbr/centralnovel_service.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/services/plugins/ptbr/novelmania_service.dart';
import 'package:akashic_records/services/plugins/ptbr/tsundoku_service.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/screens/library/novel_filter_sort_widget.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Novel> novels = [];
  final NovelMania novelMania = NovelMania();
  final Tsundoku tsundoku = Tsundoku();
  final CentralNovel centralnovel = CentralNovel();
  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();
  String _searchTerm = "";
  Map<String, dynamic> _filters = {};
  List<Novel> allNovels = [];
  Set<String> _previousPlugins = {};

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _scrollController.addListener(_scrollListener);
    _loadNovels();
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

  Future<void> _initializeFilters() async {
    Map<String, dynamic> initialFilters = {};
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.selectedPlugins.contains('NovelMania')) {
      initialFilters.addAll(novelMania.filters);
    }
    if (appState.selectedPlugins.contains('Tsundoku')) {
      initialFilters.addAll(tsundoku.filters);
    }
    if (appState.selectedPlugins.contains('CentralNovel')) {
      initialFilters.addAll(centralnovel.filters);
    }
    if (mounted) {
      setState(() {
        _filters = initialFilters;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreNovels();
    }
  }

  Future<void> _loadNovels({bool search = false}) async {
    if (isLoading) return;

    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      List<Novel> newNovels = [];
      final appState = Provider.of<AppState>(context, listen: false);

      if (appState.selectedPlugins.contains('NovelMania')) {
        final novelManiaNovels = await novelMania.popularNovels(
          currentPage,
          filters: _filters,
        );
        print('novelManiaNovels: $novelManiaNovels');
        newNovels.addAll(novelManiaNovels);
      }
      if (appState.selectedPlugins.contains('Tsundoku')) {
        final tsundokuNovels = await tsundoku.popularNovels(
          currentPage,
          filters: _filters,
        );
        newNovels.addAll(tsundokuNovels);
      }
      if (appState.selectedPlugins.contains('CentralNovel')) {
        final centralNovelNovels = await centralnovel.popularNovels(
          currentPage,
          filters: _filters,
        );
        newNovels.addAll(centralNovelNovels);
      }

      for (final novel in newNovels) {
        if (!allNovels.any((existingNovel) => existingNovel.id == novel.id)) {
          allNovels.add(novel);
        }
      }

      if (mounted) {
        setState(() {
          if (search) {
            novels = allNovels
                    .where(
                      (novel) => novel.title.toLowerCase().contains(
                        _searchTerm.toLowerCase(),
                      ),
                    )
                    .toList();
          } else {
            novels = allNovels;
          }

          if (search && novels.isEmpty) {
            hasMore = false;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Erro ao carregar novels: $e';
          hasMore = false;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreNovels() async {
    if (isLoading || !hasMore) return;
    currentPage++;
    await _loadNovels(search: _searchTerm.isNotEmpty);
  }

  Future<void> _refreshNovels() async {
    if (mounted) {
      setState(() {
        allNovels.clear();
        novels.clear();
        currentPage = 1;
        hasMore = true;
      });
    }
    await _loadNovels(search: _searchTerm.isNotEmpty);
  }

  String getPluginIdForNovel(Novel novel) {
    final appState = Provider.of<AppState>(context, listen: false);

    if (novel.id.startsWith('/novels/') &&
        appState.selectedPlugins.contains('NovelMania')) {
      return 'NovelMania';
    } else if (novel.id.startsWith('/manga/') &&
        appState.selectedPlugins.contains('Tsundoku')) {
      return 'Tsundoku';
    } else if (novel.id.startsWith('/series/') &&
        appState.selectedPlugins.contains('CentralNovel')) {
      return 'CentralNovel';
    }
    return '';
  }

  Future<void> _onFilterChanged(Map<String, dynamic> newFilters) async {
    if (mounted) {
      setState(() {
        _filters = newFilters;
        novels.clear();
        allNovels.clear();
        currentPage = 1;
        hasMore = true;
      });
    }
    await _loadNovels();
  }

  void _handleNovelTap(Novel novel, String pluginId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NovelDetailsScreen(
          novelId: novel.id,
          pluginId: pluginId,
          selectedPlugins: Provider.of<AppState>(context, listen: false).selectedPlugins,
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return NovelFilterSortWidget(
          filters: _filters,
          onFilterChanged: _onFilterChanged,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SearchBarWidget(
            onSearch: (term) {
              if (mounted) {
                setState(() {
                  _searchTerm = term;
                });
              }
              _loadNovels(search: true);
            },
            onFilterPressed: () => _showFilterModal(context),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshNovels,
              child: NovelGridWidget(
                novels: novels,
                isLoading: isLoading,
                errorMessage: errorMessage,
                scrollController: _scrollController,
                onNovelTap: _handleNovelTap,
                getPluginIdForNovel: getPluginIdForNovel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}