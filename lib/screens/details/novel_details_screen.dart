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
import 'package:akashic_records/widgets/favorite_list_dialog.dart';

class NovelDetailsScreen extends StatefulWidget {
  final Novel novel;

  const NovelDetailsScreen({super.key, required this.novel});

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
  late SharedPreferences _prefs;
  String? lastReadChapterId;
  int? lastReadChapterIndex;
  bool isLoading = true;
  String? errorMessage;
  Novel? _detailedNovel;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _init();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadDetailedNovel();
    if (_detailedNovel != null && _isMounted) {
      await _loadLastReadChapter();
    }
  }

  Future<void> _loadDetailedNovel() async {
    if (!_isMounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[widget.novel.pluginId];

      if (plugin == null) {
        if (_isMounted) {
          setState(() {
            errorMessage = 'Plugin não encontrado para esta novel.'.translate;
            isLoading = false;
          });
        }
        return;
      }

      final detailedNovelData = await loadNovelWithTimeout(
        () => plugin.parseNovel(widget.novel.id),
        timeoutDuration: const Duration(seconds: 30),
      );

      if (!_isMounted) return;

      if (detailedNovelData != null) {
        detailedNovelData.pluginId = widget.novel.pluginId;
        setState(() {
          _detailedNovel = detailedNovelData;
        });
      } else {
        setState(() {
          errorMessage =
              'Falha ao carregar detalhes da novel do plugin.'.translate;
        });
      }
    } catch (e, stacktrace) {
      if (!_isMounted) return;
      setState(() {
        errorMessage = 'Erro ao carregar detalhes da novel: $e'.translate;
      });
      debugPrint("Erro ao carregar detalhes da novel: $e\n$stacktrace");
    } finally {
      if (_isMounted && isLoading) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLastReadChapter() async {
    if (_detailedNovel == null || !_isMounted) return;

    final lastReadChapterIdPref = _prefs.getString(
      'lastRead_${widget.novel.id}',
    );

    if (lastReadChapterIdPref != null && _detailedNovel!.chapters.isNotEmpty) {
      final index = _detailedNovel!.chapters.indexWhere(
        (chapter) => chapter.id == lastReadChapterIdPref,
      );
      if (_isMounted) {
        setState(() {
          lastReadChapterId = lastReadChapterIdPref;
          lastReadChapterIndex = index == -1 ? null : index;
        });
      }
    } else if (_isMounted) {
      setState(() {
        lastReadChapterId = null;
        lastReadChapterIndex = null;
      });
    }
  }

  Future<void> _saveLastReadChapter(String chapterId) async {
    if (!_isMounted) return;
    await _prefs.setString('lastRead_${widget.novel.id}', chapterId);

    int? index;
    if (_detailedNovel != null) {
      index = _detailedNovel!.chapters.indexWhere(
        (chapter) => chapter.id == chapterId,
      );
    }

    if (_isMounted) {
      setState(() {
        lastReadChapterId = chapterId;
        lastReadChapterIndex = (index != null && index != -1) ? index : null;
      });
    }
  }

  void _navigateToReader({String? chapterId}) {
    if (!mounted || _detailedNovel == null) return;

    String? targetChapterId = chapterId ?? lastReadChapterId;

    if (targetChapterId == null && _detailedNovel!.chapters.isNotEmpty) {
      targetChapterId = _detailedNovel!.chapters.first.id;
      _saveLastReadChapter(targetChapterId);
    }

    if (targetChapterId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ReaderScreen(
                novelId: _detailedNovel!.id,
                pluginId: _detailedNovel!.pluginId,
                initialChapterId: targetChapterId,
              ),
        ),
      ).then((_) {
        if (_isMounted && mounted) {
          _loadLastReadChapter();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Nenhum capítulo disponível para leitura.".translate),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);
    final novelToCheck = _detailedNovel ?? widget.novel;
    final bool isCurrentlyFavorite = appState.isNovelFavorite(novelToCheck);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.novel.pluginId),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        actions: [
          IconButton(
            icon: Icon(
              isCurrentlyFavorite ? Icons.edit : Icons.favorite_border,
              color:
                  isCurrentlyFavorite
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
            onPressed: () {
              showFavoriteListDialog(context, _detailedNovel ?? widget.novel);
            },
            tooltip: 'Gerenciar listas de favoritos'.translate,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBody(theme),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final novelToDisplay = _detailedNovel ?? widget.novel;

    if (isLoading) {
      return const LoadingDetailsSkeletonWidget();
    } else if (errorMessage != null && _detailedNovel == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ErrorMessageWidget(
            errorMessage: errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontSize: 16,
            ),
          ),
        ),
      );
    } else {
      return NovelDetailsWidget(
        key: ValueKey(
          novelToDisplay.id + novelToDisplay.chapters.length.toString(),
        ),
        novel: novelToDisplay,
        lastReadChapterId: lastReadChapterId,
        lastReadChapterIndex: lastReadChapterIndex,
        loadingErrorMessage:
            (_detailedNovel == null && errorMessage != null)
                ? errorMessage
                : null,
        onContinueReading:
            lastReadChapterId != null && lastReadChapterIndex != null
                ? () {
                  if (lastReadChapterIndex! < novelToDisplay.chapters.length) {
                    _navigateToReader();
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Capítulo salvo não encontrado.".translate,
                          ),
                        ),
                      );
                    }
                    setState(() {
                      lastReadChapterId = null;
                      lastReadChapterIndex = null;
                    });
                  }
                }
                : null,
        onChapterTap: (chapterId) {
          _saveLastReadChapter(chapterId).then((_) {
            _navigateToReader(chapterId: chapterId);
          });
        },
        onRetryLoad:
            (errorMessage != null && _detailedNovel == null)
                ? () => _loadDetailedNovel()
                : null,
      );
    }
  }
}
