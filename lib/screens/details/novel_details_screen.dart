import 'dart:async';
import 'package:akashic_records/helpers/novel_loading_helper.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/novel.dart';
import 'package:akashic_records/services/plugins/novelmania_service.dart';
import 'package:akashic_records/services/plugins/tsundoku_service.dart';
import 'package:akashic_records/services/plugins/saikaiscans_service.dart';
import 'package:akashic_records/screens/reader/reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/services/plugins/centralnovel_service.dart';
import 'package:akashic_records/screens/details/novel_details_widget.dart';
import 'package:akashic_records/screens/details/loading_details_skeleton_widget.dart';
import 'package:akashic_records/widgets/error_message_widget.dart';

class NovelDetailsScreen extends StatefulWidget {
  final String novelId;
  final Set<String> selectedPlugins;
  final String pluginId;

  const NovelDetailsScreen({
    super.key,
    required this.novelId,
    required this.selectedPlugins,
    required this.pluginId,
  });

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
  Novel? novel;
  bool isLoading = true;
  String? errorMessage;
  final NovelMania novelMania = NovelMania();
  final Tsundoku tsundoku = Tsundoku();
  final SaikaiScans saikaiscans = SaikaiScans();
  final CentralNovel centralNovel = CentralNovel();
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
      switch (widget.pluginId) {
        case 'NovelMania':
          novel = await loadNovelWithTimeout(
            () => novelMania.parseNovel(widget.novelId),
          );
          break;
        case 'Tsundoku':
          novel = await loadNovelWithTimeout(
            () => tsundoku.parseNovel(widget.novelId),
          );
          break;
        case 'SaikaiScans':
          print('Loading SaikaiScans novel with slug: ${widget.novelId}');
          novel = await loadNovelWithTimeout(
            () => saikaiscans.parseNovel(widget.novelId),
          );
          break;
        case 'CentralNovel':
          novel = await loadNovelWithTimeout(
            () => centralNovel.parseNovel(widget.novelId),
          );
          break;
        default:
          errorMessage =
              'Plugin inválido para carregar os detalhes da novel. Plugin ID: ${widget.pluginId}';
      }

      if (novel != null) {
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
                        lastReadChapterId != null
                            ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ReaderScreen(
                                        novelId: widget.novelId,
                                        selectedPlugins: widget.selectedPlugins,
                                        pluginId: widget.pluginId,
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
                              (context) => ReaderScreen(
                                novelId: widget.novelId,
                                selectedPlugins: widget.selectedPlugins,
                                pluginId: widget.pluginId,
                              ),
                        ),
                      );
                    },
                  )),
    );
  }
}
