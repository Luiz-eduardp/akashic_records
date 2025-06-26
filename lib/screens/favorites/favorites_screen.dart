import 'dart:async';
import 'package:akashic_records/helpers/novel_loading_helper.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/details/novel_details_screen.dart';
import 'package:akashic_records/screens/favorites/favorite_grid_widget.dart';
import 'package:akashic_records/widgets/loading_indicator_widget.dart';
import 'package:akashic_records/widgets/error_message_widget.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/models/favorite_list.dart';
import 'package:akashic_records/widgets/favorite_list_dialog.dart';
import 'package:akashic_records/screens/favorites/manage_lists_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with AutomaticKeepAliveClientMixin {
  Map<String, Novel> _favoriteNovelsMap = {};
  bool _isInitialLoading = true;
  bool _isRefreshingDetails = false;
  String? _errorMessage;
  bool _mounted = false;
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mounted && mounted) {
        _loadFavoritesFromCache();
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadFavoritesFromCache() async {
    if (!_mounted) return;

    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    try {
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      final Set<String> favoriteKeys = appState.getAllFavoriteNovelKeys();

      if (favoriteKeys.isEmpty) {
        if (_mounted) {
          setState(() {
            _favoriteNovelsMap.clear();
            _isInitialLoading = false;
          });
        }
        return;
      }

      final Map<String, Novel> cachedNovels = {};
      for (String key in favoriteKeys) {
        if (!_mounted) return;
        final novelInfo = FavoriteList.compositeKeyToNovel(key);
        if (novelInfo != null) {
          final cachedNovel = await appState.getNovelFromCache(
            novelInfo['pluginId']!,
            novelInfo['novelId']!,
          );
          if (cachedNovel != null) {
            cachedNovels[key] = cachedNovel;
          } else {
            debugPrint("Cache miss for $key");
          }
        }
      }

      if (_mounted) {
        setState(() {
          _favoriteNovelsMap = cachedNovels;
          _isInitialLoading = false;
        });
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () {
          if (_mounted) {
            _refreshDetailsInBackground(false);
          }
        });
      }
    } catch (e, stacktrace) {
      if (_mounted) {
        setState(() {
          _favoriteNovelsMap.clear();
          _errorMessage = 'Erro ao carregar favoritos do cache: $e'.translate;
          _isInitialLoading = false;
        });
        debugPrint("Error loading favorites from cache: $e\n$stacktrace");
      }
    } finally {
      if (_mounted && _isInitialLoading) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _refreshDetailsInBackground(bool forceUIRefresh) async {
    if (!_mounted || _isRefreshingDetails) return;

    if (mounted) {
      setState(() {
        _isRefreshingDetails = true;
      });
    }

    try {
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      final Set<String> favoriteKeys = appState.getAllFavoriteNovelKeys();
      bool dataChanged = false;

      final currentKeys = _favoriteNovelsMap.keys.toSet();
      final keysToFetch = favoriteKeys;

      final List<Future<Novel?>> refreshFutures =
          keysToFetch
              .map((key) {
                final novelInfo = FavoriteList.compositeKeyToNovel(key);
                if (novelInfo != null) {
                  if (!mounted) return Future.value(null);
                  return _loadFavoriteNovelDetails(
                    novelInfo['novelId']!,
                    appState,
                    novelInfo['pluginId']!,
                  );
                }
                return Future.value(null);
              })
              .where((f) => f != null)
              .toList();

      final List<Novel?> refreshedNovels = await Future.wait(refreshFutures);

      if (!_mounted) return;

      final Map<String, Novel> updatedNovelsMap = Map.from(_favoriteNovelsMap);

      for (final refreshedNovel in refreshedNovels.whereType<Novel>()) {
        if (!_mounted) break;
        final key = FavoriteList.novelToCompositeKey(
          refreshedNovel.pluginId,
          refreshedNovel.id,
        );
        final existingNovel = updatedNovelsMap[key];

        bool novelChanged =
            existingNovel == null ||
            existingNovel.title != refreshedNovel.title ||
            existingNovel.coverImageUrl != refreshedNovel.coverImageUrl;

        if (novelChanged) {
          dataChanged = true;
          updatedNovelsMap[key] = refreshedNovel;
          await appState.saveNovelCache(refreshedNovel);
        }
      }

      final keysToRemove = currentKeys.difference(favoriteKeys);
      if (keysToRemove.isNotEmpty) {
        dataChanged = true;
        for (final keyToRemove in keysToRemove) {
          updatedNovelsMap.remove(keyToRemove);
        }
      }

      if (_mounted && (dataChanged || forceUIRefresh)) {
        setState(() {
          _favoriteNovelsMap = updatedNovelsMap;
        });
      }
    } catch (e, stacktrace) {
      if (_mounted) {
        debugPrint("Error refreshing favorite details: $e\n$stacktrace");
      }
    } finally {
      if (_mounted) {
        setState(() {
          _isRefreshingDetails = false;
        });
      }
    }
  }

  Future<Novel?> _loadFavoriteNovelDetails(
    String novelId,
    AppState appState,
    String pluginId,
  ) async {
    final plugin = appState.pluginServices[pluginId];
    if (plugin == null) {
      debugPrint("Plugin not found during detail load: $pluginId");
      return null;
    }
    try {
      final novel = await loadNovelWithTimeout(
        () => plugin.parseNovel(novelId),
        timeoutDuration: const Duration(seconds: 25),
      );
      if (novel != null) {
        novel.pluginId = pluginId;
        return novel;
      }
    } catch (e) {
      debugPrint(
        'Erro ao carregar detalhes da novel ($pluginId/$novelId) para favoritos: $e',
      );
      return null;
    }
    return null;
  }

  void _handleNovelTap(Novel novel) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NovelDetailsScreen(novel: novel)),
    ).then((_) {
      if (_mounted && mounted) {
        _loadFavoritesFromCache();
      }
    });
  }

  void _handleNovelLongPress(Novel novel) {
    if (!mounted) return;
    showFavoriteListDialog(context, novel).then((_) {
      if (_mounted && mounted) {
        _loadFavoritesFromCache();
      }
    });
  }

  Future<void> _handleRefresh() async {
    await _refreshDetailsInBackground(true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Provider.of<AppState>(context);

    final List<Novel> novelsForGrid =
        _favoriteNovelsMap.values.toList()
          ..sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Listas".translate,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_isRefreshingDetails)
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.8),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: "Gerenciar Listas".translate,
            onPressed: () {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageListsScreen(),
                ),
              ).then((_) {
                if (_mounted && mounted) {
                  _loadFavoritesFromCache();
                }
              });
            },
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Atualizar Detalhes dos Favoritos".translate,
            onPressed: _isRefreshingDetails ? null : _handleRefresh,
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        backgroundColor: theme.colorScheme.surface,
        color: theme.colorScheme.primary,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBody(theme, novelsForGrid),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, List<Novel> novelsForGrid) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final allFavoriteKeys = appState.getAllFavoriteNovelKeys();

        if (_isInitialLoading) {
          return const Center(child: LoadingIndicatorWidget());
        } else if (_errorMessage != null) {
          return LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ErrorMessageWidget(errorMessage: _errorMessage!),
                      ),
                    ),
                  ),
                ),
          );
        } else if (novelsForGrid.isEmpty && allFavoriteKeys.isEmpty) {
          return LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.favorite_border,
                            size: 80,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30.0,
                            ),
                            child: Text(
                              'Nenhuma novel adicionada a uma lista de favoritos ainda.'
                                  .translate,
                              style: theme.textTheme.headlineSmall!.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton.icon(
                            icon: const Icon(Icons.list_alt_outlined),
                            label: Text("Gerenciar Listas".translate),
                            onPressed: () {
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ManageListsScreen(),
                                ),
                              ).then((_) {
                                if (_mounted && mounted) {
                                  _loadFavoritesFromCache();
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 24,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          );
        } else {
          return FavoriteGridWidget(
            key: ValueKey(novelsForGrid.length),
            favoriteNovels: novelsForGrid,
            onNovelTap: _handleNovelTap,
            onRefresh: _handleRefresh,
            onNovelLongPress: _handleNovelLongPress,
          );
        }
      },
    );
  }
}
