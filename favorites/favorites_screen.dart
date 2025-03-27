// ignore_for_file: unused_import, unused_local_variable, avoid_print

import 'dart:async'; // Importante para o Timeout
import 'package:akashic_records/helpers/novel_loading_helper.dart';
import 'package:akashic_records/main.dart';
import 'package:akashic_records/screens/favorites/favorite_grid_widget.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/novel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/services/plugins/novelmania_service.dart';
import 'package:akashic_records/services/plugins/tsundoku_service.dart';
//import 'package:akashic_records/widgets/novel_card.dart'; // Não precisa mais aqui
import 'package:akashic_records/screens/details/novel_details_screen.dart';
import 'package:akashic_records/services/plugins/centralnovel_service.dart';
import 'package:akashic_records/screens/favorites/favorites_screen.dart'; // Importa o novo widget
import 'package:akashic_records/widgets/loading_indicator_widget.dart'; // Importa o widget de loading
import 'package:akashic_records/widgets/error_message_widget.dart';  // Importa o widget de erro

class FavoritesScreen extends StatefulWidget {
  final Set<String> selectedPlugins;

  const FavoritesScreen({super.key, required this.selectedPlugins});

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

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFavorites();
  }


  Future<void> _loadFavorites() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
       favoriteNovels.clear(); // Limpa a lista antes de carregar
    });

  try {
    final keys = _prefs.getKeys();
    final favoriteKeys = keys.where((key) => key.startsWith('favorite_'));

    final List<Future<void>> loadFutures = []; // Lista de Futures

    for (final key in favoriteKeys) {
      if (_prefs.getBool(key) == true) {
        final novelId = key.substring('favorite_'.length);
        loadFutures.add(_loadFavoriteNovel(novelId)); // Adiciona à lista
      }
    }

      await Future.wait(loadFutures); // Espera *todas* as novels carregarem.

    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao carregar favoritos: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Função para carregar uma única novel (agora assíncrona)
  Future<void> _loadFavoriteNovel(String novelId) async {

    String pluginId = '';
    Novel? novel;

    if (widget.selectedPlugins.contains('NovelMania')) {
      novel = await loadNovelWithTimeout(() => novelMania.parseNovel(novelId)); // Usa o helper com timeout
      if(novel != null) pluginId = 'NovelMania';
    }
    if (novel == null && widget.selectedPlugins.contains('Tsundoku')) {
      novel = await loadNovelWithTimeout(() => tsundoku.parseNovel(novelId));
      if(novel != null) pluginId = 'Tsundoku';
    }
    if (novel == null && widget.selectedPlugins.contains('CentralNovel')) {
      novel = await loadNovelWithTimeout(() => centralNovel.parseNovel(novelId));
       if(novel != null) pluginId = centralNovel.id;
    }

    if (novel != null) {
      setState(() {  // setState *dentro* do loop, mas apenas se a novel for carregada
        favoriteNovels.add(novel!);
      });
    }
}



  String getPluginIdForNovel(Novel novel) {
    if (widget.selectedPlugins.contains('NovelMania') &&
        novel.id.startsWith('/novels')) {
      return 'NovelMania';
    } else if (widget.selectedPlugins.contains('Tsundoku') &&
        novel.id.startsWith('/manga')) {
      return 'Tsundoku';
    } else if (widget.selectedPlugins.contains('CentralNovel') &&
        novel.id.startsWith('/series')) {
      return 'CentralNovel';
    }
    return '';
  }

   void _handleNovelTap(Novel novel, String pluginId) { // Função para o toque
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NovelDetailsScreen(
          novelId: novel.id,
          selectedPlugins: widget.selectedPlugins,
          pluginId: pluginId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const LoadingIndicatorWidget() // Usa o widget de loading
          : errorMessage != null
              ? ErrorMessageWidget(errorMessage: errorMessage!) // Usa o widget de erro
              : FavoriteGridWidget( // Usa o novo widget
                  favoriteNovels: favoriteNovels,
                  onNovelTap: _handleNovelTap, // Passa o callback
                  getPluginIdForNovel: getPluginIdForNovel,
                  onRefresh: _loadFavorites
                ),
    );
  }
}