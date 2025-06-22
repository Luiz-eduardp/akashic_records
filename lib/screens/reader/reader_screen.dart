import 'dart:async';
import 'dart:convert';

import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/reader/chapter_display_widget.dart';
import 'package:akashic_records/screens/reader/chapter_list_widget.dart';
import 'package:akashic_records/screens/reader/chapter_navigation_widget.dart';
import 'package:akashic_records/screens/reader/reader_app_bar_widget.dart';
import 'package:akashic_records/screens/reader/settings/reader_settings_modal_widget.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/widgets/error_message_widget.dart';
import 'package:akashic_records/widgets/skeleton/chapterdisplay_skeleton.dart';
import 'package:akashic_records/helpers/novel_loading_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/dom.dart' show Document;
import 'package:html/parser.dart' show parse;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ReaderScreen extends StatefulWidget {
  final String pluginId;
  final String novelId;
  final String? chapterId;

  const ReaderScreen({
    super.key,
    required this.pluginId,
    required this.novelId,
    this.chapterId,
    String? initialChapterId,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with SingleTickerProviderStateMixin {
  Novel? novel;
  Chapter? currentChapter;
  int currentChapterIndex = 0;
  bool isLoading = true;
  String? errorMessage;
  String? _lastReadChapterId;
  int? _wordCount;
  final ValueNotifier<double> _scrollPercentage = ValueNotifier<double>(0.0);
  Set<String> _readChapterIds = {};

  bool _isUiHidden = true;

  late AnimationController _visibilityController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _isUiHidden = true;
    _enterFullScreen();
    _loadData();
    _loadReadChapters();
    WakelockPlus.enable();

    _scrollPercentage.addListener(_handleScroll);

    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeInOut,
    );

    if (_isUiHidden) {
      _visibilityController.value = 0.0;
    } else {
      _visibilityController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _exitFullScreen();
    WakelockPlus.disable();
    _scrollPercentage.removeListener(_handleScroll);
    _scrollPercentage.dispose();
    _visibilityController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollPercentage.value >= 0.99 && currentChapter != null) {
      if (!_readChapterIds.contains(currentChapter!.id)) {
        _onMarkAsRead(currentChapter!.id);
      }
    }
  }

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive, overlays: []);
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _handleToggleUiVisibility() {
    setState(() {
      _isUiHidden = !_isUiHidden;
    });

    if (_isUiHidden) {
      _visibilityController.reverse();
      _enterFullScreen();
    } else {
      _visibilityController.forward();
      _exitFullScreen();
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _loadNovel();
      await _loadLastReadChapter(prefs);
      _updateWordCount();
    } catch (e, stacktrace) {
      if (mounted) {
        setState(() {
          errorMessage = 'Erro ao carregar dados: $e'.translate;
        });
      }
      debugPrint("Erro ao carregar dados: $e\n$stacktrace");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNovel() async {
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
        if (mounted) {
          setState(() {
            errorMessage = 'Plugin não encontrado.'.translate;
          });
        }
        return;
      }

      final loadedNovel = await loadNovelWithTimeout(
        () => plugin.parseNovel(widget.novelId),
      );

      if (loadedNovel == null) {
        if (mounted) {
          setState(() {
            errorMessage = 'Novel não encontrada.'.translate;
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

          if (currentChapter!.content == null ||
              currentChapter!.content!.isEmpty) {
            novel = loadedNovel;
            await _loadChapterContent();
          } else {
            novel = loadedNovel;
            setState(() {
              _updateWordCount();
            });
          }
        } else {
          novel = loadedNovel;
          await _loadLastReadChapter(await SharedPreferences.getInstance());
        }
      } else {
        novel = loadedNovel;
        await _loadLastReadChapter(await SharedPreferences.getInstance());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Erro ao carregar novel: $e'.translate;
        });
      }
    }
  }

  Future<void> _loadChapterContent() async {
    if (novel == null || currentChapter == null || !mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final plugin = appState.pluginServices[novel!.pluginId];

      if (plugin == null) {
        if (mounted) {
          setState(() {
            errorMessage = 'Erro: Plugin inválido.'.translate;
          });
        }
        return;
      }

      final content = await plugin.parseChapter(currentChapter!.id);

      if (content == null) {
        if (mounted) {
          setState(() {
            errorMessage =
                'Erro: Falha ao carregar o conteúdo do capítulo.'.translate;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          currentChapter = Chapter(
            id: currentChapter!.id,
            title: currentChapter!.title,
            content: content as String?,
            chapterNumber: null,
            order: 0,
          );
          isLoading = false;
          _updateWordCount();
        });
      }
      final prefs = await SharedPreferences.getInstance();
      _saveLastReadChapter(currentChapter!.id, prefs);
      _addToHistory();
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Erro ao carregar capítulo: $e'.translate;
        });
      }
    }
  }

  Future<void> _loadLastReadChapter(SharedPreferences prefs) async {
    if (novel == null) return;

    final lastReadChapterIdPref = prefs.getString('lastRead_${widget.novelId}');

    if (lastReadChapterIdPref != null) {
      currentChapterIndex = novel!.chapters.indexWhere(
        (chapter) => chapter.id == lastReadChapterIdPref,
      );
      if (currentChapterIndex == -1) {
        currentChapterIndex = 0;
      }
    } else {
      currentChapterIndex = 0;
    }

    if (novel!.chapters.isNotEmpty) {
      currentChapter = novel!.chapters[currentChapterIndex];
      if (currentChapter!.content == null || currentChapter!.content!.isEmpty) {
        await _loadChapterContent();
      }
    } else {
      if (mounted) {
        setState(() {
          errorMessage = 'Erro: Nenhum capítulo encontrado.'.translate;
        });
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveLastReadChapter(
    String chapterId,
    SharedPreferences prefs,
  ) async {
    await prefs.setString('lastRead_${widget.novelId}', chapterId);
  }

  Future<void> _loadReadChapters() async {
    final prefs = await SharedPreferences.getInstance();
    final readChaptersKey = 'readChapters_${widget.novelId}';
    final readChaptersString = prefs.getString(readChaptersKey) ?? '[]';
    try {
      final List<dynamic> readChaptersList = jsonDecode(readChaptersString);
      setState(() {
        _readChapterIds = Set<String>.from(readChaptersList);
      });
    } catch (e) {
      debugPrint("Erro ao carregar capítulos lidos: $e");
      setState(() {
        _readChapterIds = {};
      });
    }
  }

  Future<void> _saveReadChapters() async {
    final prefs = await SharedPreferences.getInstance();
    final readChaptersKey = 'readChapters_${widget.novelId}';
    final readChaptersList = _readChapterIds.toList();
    await prefs.setString(readChaptersKey, jsonEncode(readChaptersList));
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
      if (currentChapter!.content == null || currentChapter!.content!.isEmpty) {
        _loadChapterContent();
      } else {
        setState(() {
          isLoading = false;
          _updateWordCount();
        });
      }
    }
  }

  void _goToNextChapter() {
    if (novel != null && currentChapterIndex < novel!.chapters.length - 1) {
      setState(() {
        isLoading = true;
        currentChapterIndex++;
        currentChapter = novel!.chapters[currentChapterIndex];
      });
      if (currentChapter!.content == null || currentChapter!.content!.isEmpty) {
        _loadChapterContent();
      } else {
        setState(() {
          isLoading = false;
          _updateWordCount();
        });
      }
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

    if (currentChapter!.content == null || currentChapter!.content!.isEmpty) {
      _loadChapterContent();
    } else {
      setState(() {
        isLoading = false;
        _updateWordCount();
      });
    }
    Navigator.pop(context);
  }

  void _onMarkAsRead(String chapterId) {
    setState(() {
      if (_readChapterIds.contains(chapterId)) {
        _readChapterIds.remove(chapterId);
      } else {
        _readChapterIds.add(chapterId);
      }
    });
    _saveReadChapters();
  }

  Future<void> _addToHistory() async {
    if (novel == null || currentChapter == null || !mounted) return;

    final historyKey = 'history_${widget.novelId}';
    final historyString = await SharedPreferences.getInstance().then(
      (prefs) => prefs.getString(historyKey) ?? '[]',
    );
    List<dynamic> history = List.from(jsonDecode(historyString));

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
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(historyKey, jsonEncode(history)),
    );
  }

  void _updateWordCount() {
    if (currentChapter?.content != null) {
      Document document = parse(currentChapter!.content);
      String text = document.body!.text;
      setState(() {
        _wordCount = text.split(' ').length;
      });
    } else {
      setState(() {
        _wordCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: appState.readerSettings.backgroundColor,
      appBar:
          _isUiHidden
              ? null
              : PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight * 2),
                child: ValueListenableBuilder<double>(
                  valueListenable: _scrollPercentage,
                  builder: (context, percentage, child) {
                    return ReaderAppBar(
                      title:
                          isLoading ||
                                  errorMessage != null ||
                                  currentChapter == null
                              ? null
                              : currentChapter!.title,
                      readerSettings: appState.readerSettings,
                      onSettingsPressed: () => _showSettingsModal(context),
                      wordCount: _wordCount,
                      scrollPercentage: percentage,
                      scrollController: ScrollController(),
                      appBarColor: colorScheme.surfaceContainerHighest
                          .withOpacity(0.7),
                    );
                  },
                ),
              ),
      endDrawer:
          _isUiHidden
              ? null
              : novel != null
              ? Drawer(
                backgroundColor: colorScheme.surfaceVariant,
                child: ChapterListWidget(
                  chapters: novel!.chapters,
                  onChapterTap: _onChapterTap,
                  novelId: widget.novelId,
                  onMarkAsRead: _onMarkAsRead,
                  readChapterIds: _readChapterIds,
                ),
              )
              : null,
      body: Stack(
        children: [
          Builder(
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
                        chapterId: currentChapter!.id,
                        scrollPercentageNotifier: _scrollPercentage,
                        onToggleUiVisibility: _handleToggleUiVisibility,
                      ),
                    ),
                    FadeTransition(
                      opacity: _animation,
                      child: SizeTransition(
                        sizeFactor: _animation,
                        axis: Axis.vertical,
                        child: ChapterNavigation(
                          onPreviousChapter: _goToPreviousChapter,
                          onNextChapter: _goToNextChapter,
                          isLoading: isLoading,
                          readerSettings: appState.readerSettings,
                          currentChapterIndex: currentChapterIndex,
                          chapters: novel!.chapters,
                          novelId: widget.novelId,
                          onChapterTap: _onChapterTap,
                          lastReadChapterId: _lastReadChapterId,
                          readChapterIds: _readChapterIds,
                          onMarkAsRead: _onMarkAsRead,
                          navigationColor: colorScheme.surfaceContainer,
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
