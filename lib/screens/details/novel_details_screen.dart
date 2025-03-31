import 'dart:async';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/screens/reader/reader_screen.dart';
import 'package:akashic_records/screens/details/novel_details_widget.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/widgets/error_message_widget.dart';
import 'package:akashic_records/widgets/loading_indicator_widget.dart';
import 'package:akashic_records/helpers/novel_loading_helper.dart';

class NovelDetailsScreen extends StatefulWidget {
  final Novel novel;

  const NovelDetailsScreen({super.key, required this.novel});

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
  bool isFavorite = false;
  late SharedPreferences _prefs;
  String? lastReadChapterId;
  int? lastReadChapterIndex;
  bool isLoading = false;
  String? errorMessage;
  Novel? _detailedNovel;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    _loadDetailedNovel();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFavoriteStatus();
    _loadLastReadChapter();
  }

  String _getFavoriteKey() {
    return 'favorite_${widget.novel.pluginId}_${widget.novel.id}';
  }

  Future<void> _loadDetailedNovel() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      _detailedNovel = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[widget.novel.pluginId];

      if (plugin == null) {
        setState(() {
          errorMessage = 'Plugin não encontrado para esta novel.';
          isLoading = false;
        });
        return;
      }

      final detailedNovel = await loadNovelWithTimeout(
        () => plugin.parseNovel(widget.novel.id),
      );

      if (detailedNovel != null) {
        detailedNovel.pluginId = widget.novel.pluginId;
        setState(() {
          _detailedNovel = detailedNovel;
        });
      } else {
        setState(() {
          errorMessage = 'Falha ao carregar detalhes da novel do plugin.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao carregar detalhes da novel: $e';
      });
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadLastReadChapter() async {
    final lastReadChapterId = _prefs.getString('lastRead_${widget.novel.id}');

    if (lastReadChapterId != null && _detailedNovel != null) {
      setState(() {
        this.lastReadChapterId = lastReadChapterId;
        lastReadChapterIndex = _detailedNovel!.chapters.indexWhere(
          (chapter) => chapter.id == lastReadChapterId,
        );
        if (lastReadChapterIndex == -1) {
          lastReadChapterIndex = null;
          this.lastReadChapterId = null;
        }
      });
    }
  }

  Future<void> _loadFavoriteStatus() async {
    isFavorite = _prefs.getBool(_getFavoriteKey()) ?? false;
  }

  Future<void> _saveFavoriteStatus() async {
    await _prefs.setBool(_getFavoriteKey(), isFavorite);
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    _saveFavoriteStatus();
  }

  Future<void> _saveLastReadChapter(String chapterId) async {
    await _prefs.setString('lastRead_${widget.novel.id}', chapterId);
    setState(() {
      lastReadChapterId = chapterId;
      if (_detailedNovel != null) {
        lastReadChapterIndex = _detailedNovel!.chapters.indexWhere(
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
        title: Text(widget.novel.title),
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
              ? const LoadingIndicatorWidget()
              : errorMessage != null
              ? ErrorMessageWidget(errorMessage: errorMessage!)
              : (_detailedNovel == null
                  ? const Center(child: Text("Detalhes não encontrados"))
                  : NovelDetailsWidget(
                    novel: _detailedNovel!,
                    lastReadChapterId: lastReadChapterId,
                    lastReadChapterIndex: lastReadChapterIndex,
                    onContinueReading:
                        lastReadChapterId != null
                            ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ReaderScreen(
                                        novelId: widget.novel.id,
                                      ),
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
                                  ReaderScreen(novelId: widget.novel.id),
                        ),
                      );
                    },
                  )),
    );
  }
}
