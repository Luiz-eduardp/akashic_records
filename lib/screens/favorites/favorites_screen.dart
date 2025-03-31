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

      final List<Future<void>> loadFutures = [];
      for (final key in favoriteKeys) {
        if (_prefs.getBool(key) == true) {
          final parts = key.substring('favorite_'.length).split('_');
          final pluginId = parts[0];
          final novelId = parts.sublist(1).join('_');
          loadFutures.add(_loadFavoriteNovel(novelId, appState, pluginId));
        }
      }
      await Future.wait(loadFutures);
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

  Future<void> _loadFavoriteNovel(
    String novelId,
    AppState appState,
    String pluginId,
  ) async {
    Novel? novel;
    final plugin = appState.pluginServices[pluginId];

    if (plugin != null) {
      try {
        final tempNovel = await loadNovelWithTimeout(
          () => plugin.parseNovel(novelId),
        );
        if (tempNovel != null) {
          novel = tempNovel;
          novel.pluginId = pluginId;
        }
      } catch (e) {
        print(
          'Erro ao carregar detalhes da novel com o plugin ${plugin.name}: $e',
        );
      }
    }

    if (novel != null && _mounted) {
      setState(() {
        favoriteNovels.add(novel!);
      });
    }
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
      body:
          isLoading
              ? const LoadingIndicatorWidget()
              : errorMessage != null
              ? ErrorMessageWidget(errorMessage: errorMessage!)
              : FavoriteGridWidget(
                favoriteNovels: favoriteNovels,
                onNovelTap: _handleNovelTap,
                onRefresh: () => _loadFavorites(true),
              ),
    );
  }
}
