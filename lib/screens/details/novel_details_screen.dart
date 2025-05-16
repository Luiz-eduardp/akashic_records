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
import 'package:akashic_records/widgets/skeleton/loading_details_skeleton.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/widgets/favorite_list_dialog.dart';

class NovelDetailsScreen extends StatefulWidget {
  final Novel novel;

  const NovelDetailsScreen({super.key, required this.novel});

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen>
    with AutomaticKeepAliveClientMixin {
  String? lastReadChapterId;
  int? lastReadChapterIndex;
  String? errorMessage;
  Novel? _detailedNovel;
  final _novelDetailsLoadingController = StreamController<Novel?>.broadcast();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _novelDetailsLoadingController.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _loadDetailedNovel();
      await _loadLastReadChapter(prefs);
    } catch (e, stacktrace) {
      _novelDetailsLoadingController.addError(
        'Erro ao carregar detalhes da novel: $e'.translate,
      );
      debugPrint("Erro ao carregar detalhes da novel: $e\n$stacktrace");
      if (mounted) {
        setState(() {
          errorMessage = 'Erro ao carregar detalhes da novel: $e'.translate;
        });
      }
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadDetailedNovel() async {
    _novelDetailsLoadingController.add(null);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[widget.novel.pluginId];

      if (plugin == null) {
        _novelDetailsLoadingController.addError(
          'Plugin não encontrado para esta novel.'.translate,
        );
        if (mounted) {
          setState(() {
            errorMessage = 'Plugin não encontrado para esta novel.'.translate;
          });
        }
        return;
      }

      final detailedNovelData = await loadNovelWithTimeout(
        () => plugin.parseNovel(widget.novel.id),
        timeoutDuration: const Duration(seconds: 30),
      );

      if (detailedNovelData != null) {
        detailedNovelData.pluginId = widget.novel.pluginId;
        _novelDetailsLoadingController.add(detailedNovelData);
        if (mounted) {
          setState(() {
            _detailedNovel = detailedNovelData;
          });
        }
      } else {
        _novelDetailsLoadingController.addError(
          'Falha ao carregar detalhes da novel do plugin.'.translate,
        );
        if (mounted) {
          setState(() {
            errorMessage =
                'Falha ao carregar detalhes da novel do plugin.'.translate;
          });
        }
      }
    } catch (e) {
      _novelDetailsLoadingController.addError(
        'Erro ao carregar detalhes da novel: $e'.translate,
      );
      if (mounted) {
        setState(() {
          errorMessage = 'Erro ao carregar detalhes da novel: $e'.translate;
        });
      }
    }
  }

  Future<void> _loadLastReadChapter(SharedPreferences prefs) async {
    if (_detailedNovel == null) return;

    final lastReadChapterIdPref = prefs.getString(
      'lastRead_${widget.novel.id}',
    );

    if (lastReadChapterIdPref != null && _detailedNovel!.chapters.isNotEmpty) {
      final index = _detailedNovel!.chapters.indexWhere(
        (chapter) => chapter.id == lastReadChapterIdPref,
      );
      if (mounted) {
        setState(() {
          lastReadChapterId = lastReadChapterIdPref;
          lastReadChapterIndex = index == -1 ? null : index;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          lastReadChapterId = null;
          lastReadChapterIndex = null;
        });
      }
    }
  }

  Future<void> _saveLastReadChapter(
    String chapterId,
    SharedPreferences prefs,
  ) async {
    await prefs.setString('lastRead_${widget.novel.id}', chapterId);

    int? index;
    if (_detailedNovel != null) {
      index = _detailedNovel!.chapters.indexWhere(
        (chapter) => chapter.id == chapterId,
      );
    }

    if (mounted) {
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
      SharedPreferences.getInstance().then((prefs) {
        _saveLastReadChapter(targetChapterId!, prefs);
      });
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
        if (mounted) {
          SharedPreferences.getInstance().then((prefs) {
            _loadLastReadChapter(prefs);
          });
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
    super.build(context);
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);
    final novelToCheck = _detailedNovel ?? widget.novel;
    final bool isCurrentlyFavorite = appState.isNovelFavorite(novelToCheck);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.novel.pluginId),
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
          0.7,
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          IconButton(
            icon: Icon(
              isCurrentlyFavorite ? Icons.edit : Icons.favorite_border,
              color:
                  isCurrentlyFavorite
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              showFavoriteListDialog(context, _detailedNovel ?? widget.novel);
            },
            tooltip: 'Gerenciar listas de favoritos'.translate,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: StreamBuilder<Novel?>(
          stream: _novelDetailsLoadingController.stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ErrorMessageWidget(
                    errorMessage: snapshot.error.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.data == null && _detailedNovel == null) {
              return const LoadingDetailsSkeletonWidget();
            }
            final novelToDisplay = snapshot.data ?? widget.novel;

            return NovelDetailsWidget(
              key: ValueKey(
                novelToDisplay.id + novelToDisplay.chapters.length.toString(),
              ),
              novel: novelToDisplay,
              lastReadChapterId: lastReadChapterId,
              lastReadChapterIndex: lastReadChapterIndex,
              loadingErrorMessage: errorMessage,
              onContinueReading:
                  lastReadChapterId != null && lastReadChapterIndex != null
                      ? () {
                        if (lastReadChapterIndex! <
                            novelToDisplay.chapters.length) {
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
                SharedPreferences.getInstance().then((prefs) {
                  _saveLastReadChapter(chapterId, prefs).then((_) {
                    _navigateToReader(chapterId: chapterId);
                  });
                });
              },
              onRetryLoad: () => _loadDetailedNovel(),
            );
          },
        ),
      ),
    );
  }
}
