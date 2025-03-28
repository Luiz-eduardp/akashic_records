import 'dart:convert';
import 'package:akashic_records/helpers/novel_loading_helper.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/services/plugins/ptbr/novelmania_service.dart';
import 'package:akashic_records/services/plugins/ptbr/tsundoku_service.dart';
import 'package:akashic_records/screens/details/novel_details_screen.dart';
import 'package:akashic_records/services/plugins/ptbr/centralnovel_service.dart';
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
  final NovelMania novelMania = NovelMania();
  final Tsundoku tsundoku = Tsundoku();
  final CentralNovel centralNovel = CentralNovel();
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

      if (!forceRefresh) {
        List<Novel> cachedNovels = [];
        for (final key in favoriteKeys) {
          if (_prefs.getBool(key) == true) {
            final novelId = key.substring('favorite_'.length);
            final cachedNovelJson = _prefs.getString('novelData_$novelId');
            if (cachedNovelJson != null) {
              final cachedNovelMap =
                  jsonDecode(cachedNovelJson) as Map<String, dynamic>;
              bool isValidPlugin = false;
              final appState = Provider.of<AppState>(context, listen: false);
              for (var pluginId in appState.selectedPlugins) {
                if (novelId.startsWith(getPrefixForPlugin(pluginId))) {
                  isValidPlugin = true;
                  break;
                }
              }
              if (isValidPlugin) {
                cachedNovels.add(Novel.fromMap(cachedNovelMap));
              } else {
                await _prefs.remove(key);
                await _prefs.remove('novelData_$novelId');
              }
            }
          }
        }

        if (cachedNovels.isNotEmpty) {
          if (_mounted) {
            setState(() {
              favoriteNovels = cachedNovels;
              isLoading = false;
            });
            return;
          }
        }
      }

      final List<Future<void>> loadFutures = [];
      final appState = Provider.of<AppState>(context, listen: false);
      for (final key in favoriteKeys) {
        if (_prefs.getBool(key) == true) {
          final novelId = key.substring('favorite_'.length);
          loadFutures.add(_loadFavoriteNovel(novelId, appState));
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

  String getPrefixForPlugin(String pluginId) {
    switch (pluginId) {
      case 'NovelMania':
        return '/novels/';
      case 'Tsundoku':
      case 'SaikaiScans':
        return '/manga/';
      case 'CentralNovel':
        return '/series/';
      default:
        return '';
    }
  }

  Future<void> _loadFavoriteNovel(String novelId, AppState appState) async {
    Novel? novel;
    if (appState.selectedPlugins.contains('NovelMania') &&
        novelId.startsWith('/novels/')) {
      novel = await loadNovelWithTimeout(() => novelMania.parseNovel(novelId));
    }
    if (novel == null &&
        appState.selectedPlugins.contains('Tsundoku') &&
        novelId.startsWith('/manga/')) {
      novel = await loadNovelWithTimeout(() => tsundoku.parseNovel(novelId));
    }
    if (novel == null &&
        appState.selectedPlugins.contains('CentralNovel') &&
        novelId.startsWith('/series/')) {
      novel = await loadNovelWithTimeout(
        () => centralNovel.parseNovel(novelId),
      );
    }

    if (novel != null && _mounted) {
      final novelMap = novel.toMap();
      final novelJson = jsonEncode(novelMap);
      await _prefs.setString('novelData_$novelId', novelJson);

      setState(() {
        favoriteNovels.add(novel!);
      });
    }
  }

  String getPluginIdForNovel(Novel novel) {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.selectedPlugins.contains('NovelMania') &&
        novel.id.startsWith('/novels')) {
      return 'NovelMania';
    } else if (appState.selectedPlugins.contains('Tsundoku') &&
        novel.id.startsWith('/manga')) {
      return 'Tsundoku';
    } else if (appState.selectedPlugins.contains('CentralNovel') &&
        novel.id.startsWith('/series')) {
      return 'CentralNovel';
    }
    return '';
  }

  void _handleNovelTap(Novel novel, String pluginId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NovelDetailsScreen(
              novelId: novel.id,
              pluginId: pluginId,
              selectedPlugins:
                  Provider.of<AppState>(context, listen: false).selectedPlugins,
            ),
      ),
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
                getPluginIdForNovel: getPluginIdForNovel,
                onRefresh: () => _loadFavorites(true),
              ),
    );
  }
}
