import 'dart:async';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/screens/reader/reader_screen.dart';
import 'package:akashic_records/screens/details/novel_details_widget.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/widgets/error_message_widget.dart';
import 'package:akashic_records/helpers/novel_loading_helper.dart';
import 'package:akashic_records/screens/details/loading_details_skeleton_widget.dart';
import 'package:akashic_records/i18n/i18n.dart';

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
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFavoriteStatus();
    await _loadDetailedNovel();
    _loadLastReadChapter();
  }

  String _getFavoriteKey() {
    return 'favorite_${widget.novel.pluginId}_${widget.novel.id}';
  }

  Future<void> _loadDetailedNovel() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[widget.novel.pluginId];

      if (plugin == null) {
        setState(() {
          errorMessage = 'Plugin não encontrado para esta novel.'.translate;
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
          errorMessage =
              'Falha ao carregar detalhes da novel do plugin.'.translate;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao carregar detalhes da novel: $e'.translate;
      });
      debugPrint("Erro ao carregar detalhes da novel: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadLastReadChapter() async {
    if (_detailedNovel == null) return;

    final lastReadChapterId = _prefs.getString('lastRead_${widget.novel.id}');

    if (lastReadChapterId != null) {
      final index = _detailedNovel!.chapters.indexWhere(
        (chapter) => chapter.id == lastReadChapterId,
      );

      setState(() {
        this.lastReadChapterId = lastReadChapterId;
        lastReadChapterIndex = index == -1 ? null : index;
      });
    }
  }

  Future<void> _loadFavoriteStatus() async {
    setState(() {
      isFavorite = _prefs.getBool(_getFavoriteKey()) ?? false;
    });
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
      lastReadChapterIndex = _detailedNovel?.chapters.indexWhere(
        (chapter) => chapter.id == chapterId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.novel.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? theme.colorScheme.primary : null,
            ),
            onPressed: _toggleFavorite,
            tooltip:
                isFavorite
                    ? 'Remover dos Favoritos'.translate
                    : 'Adicionar aos Favoritos'.translate,
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBody(theme),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (isLoading) {
      return const LoadingDetailsSkeletonWidget();
    } else if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ErrorMessageWidget(errorMessage: errorMessage!),
        ),
      );
    } else if (_detailedNovel == null) {
      return Center(
        child: Text(
          "Detalhes não encontrados".translate,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else {
      return NovelDetailsWidget(
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
                          (context) => ReaderScreen(novelId: widget.novel.id),
                    ),
                  );
                }
                : null,
        onChapterTap: (chapterId) {
          _saveLastReadChapter(chapterId);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReaderScreen(novelId: widget.novel.id),
            ),
          );
        },
      );
    }
  }
}
