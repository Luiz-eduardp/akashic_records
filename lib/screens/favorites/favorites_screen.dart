import 'package:akashic_records/helpers/novel_loading_helper.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/screens/details/novel_details_screen.dart';
import 'package:akashic_records/screens/favorites/favorite_grid_widget.dart';
import 'package:akashic_records/widgets/loading_indicator_widget.dart';
import 'package:akashic_records/widgets/error_message_widget.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Novel> favoriteNovels = [];
  bool isLoading = true;
  String? errorMessage;
  late SharedPreferences _prefs;
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _initSharedPreferences();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFavorites(false);
  }

  Future<void> _loadFavorites(bool forceRefresh) async {
    if (!_mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      favoriteNovels.clear();
    });

    try {
      final keys = _prefs.getKeys();
      final favoriteKeys = keys.where((key) => key.startsWith('favorite_'));

      final appState = Provider.of<AppState>(context, listen: false);

      final List<Future<Novel?>> novelFutures =
          favoriteKeys.where((key) => _prefs.getBool(key) == true).map((key) {
            final parts = key.substring('favorite_'.length).split('_');
            final pluginId = parts[0];
            final novelId = parts.sublist(1).join('_');
            return _loadFavoriteNovel(novelId, appState, pluginId);
          }).toList();

      final List<Novel?> loadedNovels = await Future.wait(novelFutures);

      final List<Novel> validNovels = loadedNovels.whereType<Novel>().toList();

      if (_mounted) {
        setState(() {
          favoriteNovels = validNovels;
        });
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          errorMessage = 'Erro ao carregar favoritos: $e';
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

  Future<Novel?> _loadFavoriteNovel(
    String novelId,
    AppState appState,
    String pluginId,
  ) async {
    final plugin = appState.pluginServices[pluginId];
    if (plugin == null) {
      return null;
    }

    try {
      final novel = await loadNovelWithTimeout(
        () => plugin.parseNovel(novelId),
      );
      if (novel != null) {
        novel.pluginId = pluginId;
        return novel;
      }
    } catch (e) {
      debugPrint(
        'Erro ao carregar detalhes da novel com o plugin ${plugin.name}: $e',
      );
      return null;
    }
    return null;
  }

  void _handleNovelTap(Novel novel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NovelDetailsScreen(novel: novel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(),
      ),
      floatingActionButton:
          favoriteNovels.isNotEmpty && !isLoading
              ? FloatingActionButton(
                onPressed: () => _loadFavorites(true),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                tooltip: 'Recarregar Favoritos',
                child: const Icon(Icons.refresh),
              )
              : null,
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: LoadingIndicatorWidget());
    } else if (errorMessage != null) {
      return Center(child: ErrorMessageWidget(errorMessage: errorMessage!));
    } else if (favoriteNovels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.favorite_border,
              size: 60,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 10),
            Text(
              'Nenhuma novel adicionada aos favoritos.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: () => _loadFavorites(true),
        color: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return FavoriteGridWidget(
              favoriteNovels: favoriteNovels,
              onNovelTap: _handleNovelTap,
              onRefresh: () async {
                return;
              },
            );
          },
        ),
      );
    }
  }
}
