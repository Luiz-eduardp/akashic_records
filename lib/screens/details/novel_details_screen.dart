// ignore_for_file: empty_catches

import 'dart:async';
import 'package:akashic_records/helpers/novel_loading_helper.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/screens/reader/reader_screen.dart';
import 'package:akashic_records/screens/details/novel_details_widget.dart';
import 'package:akashic_records/screens/details/loading_details_skeleton_widget.dart';
import 'package:akashic_records/widgets/error_message_widget.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/models/plugin_service.dart';

class NovelDetailsScreen extends StatefulWidget {
  final String novelId;

  const NovelDetailsScreen({super.key, required this.novelId});

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
  Novel? novel;
  bool isLoading = true;
  String? errorMessage;
  bool isFavorite = false;
  late SharedPreferences _prefs;
  String? lastReadChapterId;
  bool _mounted = false;
  int? lastReadChapterIndex;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadNovelData();
  }

  Future<void> _loadNovelData() async {
    _mounted = true;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final loadPrefsFuture = Future.wait<dynamic>([
      _loadFavoriteStatus(),
      Future.value(_prefs.getString('lastRead_${widget.novelId}')),
    ]);

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      PluginService? plugin;

      for (final pluginName in appState.pluginServices.keys) {
        final p = appState.pluginServices[pluginName];
        try {
          final tempNovel = await loadNovelWithTimeout(
            () async => p?.parseNovel(widget.novelId),
          );
          if (tempNovel != null) {
            plugin = p;
            novel = tempNovel;
            break;
          }
        } catch (e) {
         
        }
      }

      if (plugin != null && novel != null) {
        final prefsResults = await loadPrefsFuture;
        lastReadChapterId = prefsResults[1] as String?;

        if (lastReadChapterId != null) {
          lastReadChapterIndex = novel!.chapters.indexWhere(
            (chapter) => chapter.id == lastReadChapterId,
          );
          if (lastReadChapterIndex == -1) {
            lastReadChapterIndex = null;
            lastReadChapterId = null;
          }
        }
      } else {
        errorMessage = 'Novel não encontrada em nenhum plugin selecionado.';
      }
    } catch (e) {
      errorMessage = 'Erro ao carregar detalhes da novel: $e';
      print(e);
    } finally {
      if (_mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFavoriteStatus() async {
    isFavorite = _prefs.getBool('favorite_${widget.novelId}') ?? false;
  }

  Future<void> _saveFavoriteStatus() async {
    await _prefs.setBool('favorite_${widget.novelId}', isFavorite);
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    _saveFavoriteStatus();
  }

  Future<void> _saveLastReadChapter(String chapterId) async {
    await _prefs.setString('lastRead_${widget.novelId}', chapterId);
    setState(() {
      lastReadChapterId = chapterId;
      if (novel != null) {
        lastReadChapterIndex = novel!.chapters.indexWhere(
          (chapter) => chapter.id == chapterId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title:
            isLoading
                ? const Text("Carregando...")
                : Text(novel?.title ?? 'Erro'),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body:
          isLoading
              ? const LoadingDetailsSkeletonWidget()
              : errorMessage != null
              ? ErrorMessageWidget(errorMessage: errorMessage!)
              : (novel == null
                  ? const Center(
                    child: Text(
                      'Novel não encontrada em nenhum plugin selecionado',
                    ),
                  )
                  : NovelDetailsWidget(
                    novel: novel!,
                    lastReadChapterId: lastReadChapterId,
                    lastReadChapterIndex: lastReadChapterIndex,
                    onContinueReading:
                        lastReadChapterId != null && novel != null
                            ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          ReaderScreen(novelId: widget.novelId),
                                ),
                              );
                            }
                            : null,
                    onChapterTap: (chapterId) {
                      _saveLastReadChapter(chapterId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ReaderScreen(novelId: widget.novelId),
                        ),
                      );
                    },
                  )),
    );
  }
}
