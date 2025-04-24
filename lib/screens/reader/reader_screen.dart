import 'dart:async';
import 'dart:convert';

import 'package:akashic_records/screens/reader/settings/reader_settings_modal_widget.dart';
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
import 'package:akashic_records/widgets/loading_indicator_widget.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/screens/reader/chapter_list_widget.dart';

class ReaderScreen extends StatefulWidget {
  final String pluginId;
  final String novelId;
  final String? chapterId;

  const ReaderScreen({
    super.key,
    required this.pluginId,
    required this.novelId,
    this.chapterId,
  });

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
  final bool _isFetchingNextChapter = false;
  bool _isUiVisible = true;
  Timer? _hideUiTimer;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences().then((_) {
      _loadNovel();
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _hideUiTimer?.cancel();
    _tapTimer?.cancel();
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _loadLastReadChapter() async {
    _lastReadChapterId = _prefs.getString('lastRead_${widget.novelId}');

    if (novel != null) {
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
        setState(() {
          if (!_mounted) return;
          errorMessage = 'Erro: Nenhum capítulo encontrado.'.translate;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNovel() async {
    setState(() {
      _mounted = true;
      isLoading = true;
      errorMessage = null;
      novel = null;
      currentChapter = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[widget.pluginId];

      if (plugin != null) {
        novel = await loadNovelWithTimeout(
          () => plugin.parseNovel(widget.novelId),
        );

        if (novel != null) {
          novel!.pluginId = widget.pluginId;

          novel!.chapters.sort((a, b) {
            return (a.chapterNumber ?? 0).compareTo(b.chapterNumber ?? 0);
          });

          if (widget.chapterId != null) {
            currentChapterIndex = novel!.chapters.indexWhere(
              (chapter) => chapter.id == widget.chapterId,
            );
            if (currentChapterIndex != -1) {
              currentChapter = novel!.chapters[currentChapterIndex];
              await _loadChapterContent();
            } else {
              await _loadLastReadChapter();
            }
          } else {
            await _loadLastReadChapter();
          }
        } else {
          setState(() {
            errorMessage = 'Novel não encontrada.'.translate;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Plugin não encontrado.'.translate;
        });
      }
    } catch (e) {
      setState(() {
        if (!_mounted) return;
        errorMessage = 'Erro ao carregar novel: $e'.translate;
        isLoading = false;
      });
    } finally {
      setState(() {
        if (!_mounted) return;
        isLoading = false;
      });
    }
  }

  Future<void> _loadChapterContent() async {
    if (novel == null || currentChapter == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[novel!.pluginId];

      if (plugin != null) {
        final content = await plugin.parseChapter(currentChapter!.id);

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
        _saveLastReadChapter(currentChapter!.id);
        _addToHistory();
      } else {
        setState(() {
          if (!_mounted) return;
          errorMessage = 'Erro: Plugin inválido.'.translate;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        if (!_mounted) return;
        errorMessage = 'Erro ao carregar capítulo: $e'.translate;
        isLoading = false;
      });
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
    setState(() {
      isLoading = true;
      currentChapterIndex = novel!.chapters.indexWhere(
        (chapter) => chapter.id == chapterId,
      );
      currentChapter = novel!.chapters[currentChapterIndex];
    });
    _loadChapterContent();
    Navigator.pop(context);
  }

  void _onMarkAsRead(String chapterId) {
    print('Capítulo marcado como lido: $chapterId');
  }

  void _toggleUiVisibility() {
    if (_tapTimer?.isActive ?? false) {
      return;
    }

    setState(() {
      _isUiVisible = !_isUiVisible;
    });

    if (_isUiVisible) {
      _startUiHideTimer();
    } else {
      _hideUiTimer?.cancel();
    }

    _tapTimer = Timer(const Duration(milliseconds: 200), () {});
  }

  void _startUiHideTimer() {
    _hideUiTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _isUiVisible = false;
      });
    });
  }

  Future<void> _addToHistory() async {
    if (novel == null || currentChapter == null) return;

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
        child: GestureDetector(
          onTap: _toggleUiVisibility,
          child:
              _isUiVisible
                  ? ReaderAppBar(
                    title:
                        isLoading ||
                                errorMessage != null ||
                                currentChapter == null
                            ? null
                            : currentChapter!.title,
                    readerSettings: appState.readerSettings,
                    onSettingsPressed: () => _showSettingsModal(context),
                  )
                  : AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: _toggleUiVisibility,
                    ),
                  ),
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
      body:
          isLoading
              ? const Center(child: LoadingIndicatorWidget())
              : errorMessage != null
              ? Center(child: ErrorMessageWidget(errorMessage: errorMessage!))
              : Column(
                children: [
                  Expanded(
                    child: ChapterDisplay(
                      chapterContent: currentChapter?.content,
                      readerSettings: appState.readerSettings,
                    ),
                  ),
                  if (_isUiVisible)
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
              ),
    );
  }

  Future<void> _saveLastReadChapter(String chapterId) async {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    await _prefs.setString('lastRead_${widget.novelId}_$timestamp', chapterId);
  }
}
