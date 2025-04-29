import 'dart:async';
import 'dart:convert';

import 'package:akashic_records/screens/reader/settings/reader_settings_modal_widget.dart';
import 'package:akashic_records/widgets/skeleton/chapterdisplay_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/screens/reader/chapter_display_widget.dart';
import 'package:akashic_records/screens/reader/chapter_navigation_widget.dart';
import 'package:akashic_records/screens/reader/reader_app_bar_widget.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/helpers/novel_loading_helper.dart';
import 'package:akashic_records/widgets/error_message_widget.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/screens/reader/chapter_list_widget.dart';

class ReaderScreen extends StatefulWidget {
  final String pluginId;
  final String novelId;
  final String? chapterId;

  const ReaderScreen({
    Key? key,
    required this.pluginId,
    required this.novelId,
    this.chapterId,
    String? initialChapterId,
  }) : super(key: key);

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  Novel? novel;
  Chapter? currentChapter;
  int currentChapterIndex = 0;
  bool isLoading = true;
  String? errorMessage;
  late SharedPreferences _prefs;
  String? _lastReadChapterId;
  bool _mounted = false;
  bool _isFetchingNextChapter = false;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadNovel();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadLastReadChapter() async {
    if (novel == null || !_mounted) return;

    _lastReadChapterId = _prefs.getString('lastRead_${widget.novelId}');

    if (_lastReadChapterId != null) {
      currentChapterIndex = novel!.chapters.indexWhere(
        (chapter) => chapter.id == _lastReadChapterId,
      );
      if (currentChapterIndex == -1) {
        currentChapterIndex = 0;
      }
    } else {
      currentChapterIndex = 0;
    }

    if (novel!.chapters.isNotEmpty) {
      currentChapter = novel!.chapters[currentChapterIndex];
      await _loadChapterContent();
    } else {
      if (_mounted) {
        setState(() {
          errorMessage = 'Erro: Nenhum capítulo encontrado.'.translate;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNovel() async {
    if (!_mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      novel = null;
      currentChapter = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[widget.pluginId];

      if (plugin == null) {
        if (_mounted) {
          setState(() {
            errorMessage = 'Plugin não encontrado.'.translate;
            isLoading = false;
          });
        }
        return;
      }

      final loadedNovel = await loadNovelWithTimeout(
        () => plugin.parseNovel(widget.novelId),
      );

      if (loadedNovel == null) {
        if (_mounted) {
          setState(() {
            errorMessage = 'Novel não encontrada.'.translate;
            isLoading = false;
          });
        }
        return;
      }

      loadedNovel.pluginId = widget.pluginId;
      loadedNovel.chapters.sort(
        (a, b) => (a.chapterNumber ?? 0).compareTo(b.chapterNumber ?? 0),
      );

      if (widget.chapterId != null) {
        final chapterIndex = loadedNovel.chapters.indexWhere(
          (chapter) => chapter.id == widget.chapterId,
        );
        if (chapterIndex != -1) {
          currentChapterIndex = chapterIndex;
          currentChapter = loadedNovel.chapters[currentChapterIndex];
          novel = loadedNovel;
          await _loadChapterContent();
        } else {
          novel = loadedNovel;
          await _loadLastReadChapter();
        }
      } else {
        novel = loadedNovel;
        await _loadLastReadChapter();
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          errorMessage = 'Erro ao carregar novel: $e'.translate;
          isLoading = false;
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

  Future<void> _loadChapterContent() async {
    if (novel == null || currentChapter == null || !_mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[novel!.pluginId];

      if (plugin == null) {
        if (_mounted) {
          setState(() {
            errorMessage = 'Erro: Plugin inválido.'.translate;
            isLoading = false;
          });
        }
        return;
      }

      final content = await plugin.parseChapter(currentChapter!.id);

      if (content == null) {
        if (_mounted) {
          setState(() {
            errorMessage =
                'Erro: Falha ao carregar o conteúdo do capítulo.'.translate;
            isLoading = false;
          });
        }
        return;
      }

      if (_mounted) {
        setState(() {
          currentChapter = Chapter(
            id: currentChapter!.id,
            title: currentChapter!.title,
            content: content as String?,
            chapterNumber: null,
            order: 0,
          );
          isLoading = false;
        });
      }
      _saveLastReadChapter(currentChapter!.id);
      _addToHistory();
    } catch (e) {
      if (_mounted) {
        setState(() {
          errorMessage = 'Erro ao carregar capítulo: $e'.translate;
          isLoading = false;
        });
      }
    }
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const ReaderSettingsModal();
      },
    );
  }

  void _goToPreviousChapter() {
    if (currentChapterIndex > 0) {
      setState(() {
        isLoading = true;
        currentChapterIndex--;
        currentChapter = novel!.chapters[currentChapterIndex];
      });
      _loadChapterContent();
    }
  }

  void _goToNextChapter() {
    if (novel != null && currentChapterIndex < novel!.chapters.length - 1) {
      setState(() {
        isLoading = true;
        currentChapterIndex++;
        currentChapter = novel!.chapters[currentChapterIndex];
      });
      _loadChapterContent();
    }
  }

  void _onChapterTap(String chapterId) {
    if (novel == null) return;

    final newIndex = novel!.chapters.indexWhere(
      (chapter) => chapter.id == chapterId,
    );
    if (newIndex == -1) return;

    setState(() {
      isLoading = true;
      currentChapterIndex = newIndex;
      currentChapter = novel!.chapters[currentChapterIndex];
    });
    _loadChapterContent();
    Navigator.pop(context);
  }

  void _onMarkAsRead(String chapterId) {
    print('Capítulo marcado como lido: $chapterId');
  }

  Future<void> _addToHistory() async {
    if (novel == null || currentChapter == null || !_mounted) return;

    final historyKey = 'history_${widget.novelId}';
    final historyString = _prefs.getString(historyKey) ?? '[]';
    List<dynamic> history = List<dynamic>.from(jsonDecode(historyString));

    final newItem = {
      'novelId': widget.novelId,
      'novelTitle': novel!.title,
      'chapterId': currentChapter!.id,
      'chapterTitle': currentChapter!.title,
      'pluginId': novel!.pluginId,
    };

    int existingIndex = history.indexWhere(
      (item) => item['chapterId'] == newItem['chapterId'],
    );

    if (existingIndex != -1) {
      history[existingIndex] = {
        ...newItem,
        'lastRead': history[existingIndex]['lastRead'],
      };
    } else {
      history.insert(0, {
        ...newItem,
        'lastRead': DateTime.now().toIso8601String(),
      });
    }

    await _prefs.setString(historyKey, jsonEncode(history));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      backgroundColor: appState.readerSettings.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ReaderAppBar(
          title:
              isLoading || errorMessage != null || currentChapter == null
                  ? null
                  : currentChapter!.title,
          readerSettings: appState.readerSettings,
          onSettingsPressed: () => _showSettingsModal(context),
        ),
      ),
      endDrawer:
          novel != null
              ? Drawer(
                child: ChapterListWidget(
                  chapters: novel!.chapters,
                  onChapterTap: _onChapterTap,
                ),
              )
              : null,
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: ChapterDisplaySkeleton());
          } else if (errorMessage != null) {
            return Center(
              child: ErrorMessageWidget(errorMessage: errorMessage!),
            );
          } else if (novel == null || currentChapter == null) {
            return Center(child: Text("Erro Inesperado".translate));
          } else {
            return Column(
              children: [
                Expanded(
                  child: ChapterDisplay(
                    chapterContent: currentChapter?.content,
                    readerSettings: appState.readerSettings,
                  ),
                ),
                ChapterNavigation(
                  onPreviousChapter: _goToPreviousChapter,
                  onNextChapter: _goToNextChapter,
                  isLoading: isLoading || _isFetchingNextChapter,
                  readerSettings: appState.readerSettings,
                  currentChapterIndex: currentChapterIndex,
                  chapters: novel!.chapters,
                  novelId: widget.novelId,
                  onChapterTap: _onChapterTap,
                  lastReadChapterId: _lastReadChapterId,
                  readChapterIds: const {},
                  onMarkAsRead: _onMarkAsRead,
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Future<void> _saveLastReadChapter(String chapterId) async {
    await _prefs.setString('lastRead_${widget.novelId}', chapterId);
  }
}
