import 'dart:async';

import 'package:flutter/material.dart';
import 'package:akashic_records/models/chapter.dart';
import 'package:akashic_records/models/novel.dart';
import 'package:akashic_records/services/plugins/novelmania_service.dart';
import 'package:akashic_records/services/plugins/tsundoku_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/services/plugins/centralnovel_service.dart';
import 'package:akashic_records/screens/reader/reader_settings_modal_widget.dart';
import 'package:akashic_records/screens/reader/chapter_display_widget.dart';
import 'package:akashic_records/screens/reader/chapter_navigation_widget.dart';
import 'package:akashic_records/screens/reader/reader_app_bar_widget.dart';

class ReaderScreen extends StatefulWidget {
  final String novelId;
  final String pluginId;
  final Set<String> selectedPlugins;

  const ReaderScreen({
    super.key,
    required this.novelId,
    required this.pluginId,
    required this.selectedPlugins,
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
  final NovelMania novelMania = NovelMania();
  final Tsundoku tsundoku = Tsundoku();
  final CentralNovel centralNovel = CentralNovel();
  late SharedPreferences _prefs;
  String? _lastReadChapterId;
  bool _mounted = false;
  ReaderSettings _readerSettings = ReaderSettings();
  final ScrollController _scrollController = ScrollController();
  bool _isFetchingNextChapter = false;

  bool _isUiVisible = true;

  Timer? _hideUiTimer;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    _scrollController.addListener(_onScroll);

    _startUiHideTimer();
  }


  @override
  void dispose() {
    _mounted = false;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _hideUiTimer?.cancel();
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadReaderSettings();
    await _loadLastReadChapter();
  }

  Future<void> _loadReaderSettings() async {
    final settingsMap = _prefs.getKeys().fold<Map<String, dynamic>>(
      {},
      (previousValue, key) => {
        ...previousValue,
        if (key.startsWith('reader_')) key.substring(7): _prefs.get(key),
      },
    );

    if (settingsMap.isNotEmpty) {
      setState(() {
        _readerSettings = ReaderSettings.fromMap(settingsMap);
      });
    }
  }

  Future<void> _saveReaderSettings() async {
    final settingsMap = _readerSettings.toMap();
    settingsMap.forEach((key, value) {
      if (value is int) {
        _prefs.setInt('reader_$key', value);
      } else if (value is double) {
        _prefs.setDouble('reader_$key', value);
      } else if (value is String) {
        _prefs.setString('reader_$key', value);
      } else if (value is int?) {
        if (value != null) {
          _prefs.setInt('reader_$key', value);
        }
      }
    });
  }

  Future<void> _loadLastReadChapter() async {
    _lastReadChapterId = _prefs.getString('lastRead_${widget.novelId}');
    await _loadNovel();
  }

  Future<void> _saveLastReadChapter(String chapterId) async {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    await _prefs.setString('lastRead_${widget.novelId}_$timestamp', chapterId);
  }

  Future<void> _loadNovel() async {
    setState(() {
      _mounted = true;
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (widget.pluginId == 'NovelMania') {
        novel = await novelMania.parseNovel(widget.novelId);
      } else if (widget.pluginId == 'Tsundoku') {
        novel = await tsundoku.parseNovel(widget.novelId);
      } else if (widget.pluginId == centralNovel.id) {
        novel = await centralNovel.parseNovel(widget.novelId);
      } else {
        setState(() {
          if (!_mounted) return;
          errorMessage = 'Erro: Plugin inválido.';
          isLoading = false;
        });
        return;
      }

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
          errorMessage = 'Erro: Nenhum capítulo encontrado.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        if (!_mounted) return;
        errorMessage = 'Erro ao carregar novel: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadChapterContent() async {
    if (currentChapter == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      String content;
      if (widget.pluginId == 'NovelMania') {
        content = await novelMania.parseChapter(currentChapter!.id);
      } else if (widget.pluginId == 'Tsundoku') {
        content = await tsundoku.parseChapter(currentChapter!.id);
      } else if (widget.pluginId == centralNovel.id) {
        content = await centralNovel.parseChapter(currentChapter!.id);
      } else {
        setState(() {
          if (!_mounted) return;
          errorMessage = 'Erro: Plugin inválido.';
          isLoading = false;
        });
        return;
      }

      setState(() {
        currentChapter = Chapter(
          id: currentChapter!.id,
          title: currentChapter!.title,
          content: content,
          releaseDate: '',
          chapterNumber: null,
          order: 0,
        );
        isLoading = false;
      });
      _saveLastReadChapter(currentChapter!.id);
    } catch (e) {
      setState(() {
        if (!_mounted) return;
        errorMessage = 'Erro ao carregar capítulo: $e';
        isLoading = false;
      });
    }
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ReaderSettingsModal(
          readerSettings: _readerSettings,
          onSettingsChanged: (newSettings) {
            if (!_mounted) return;
            setState(() {
              _readerSettings = newSettings;
            });
          },
          onSave: _saveReaderSettings,
        );
      },
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadNextChapterIfPossible();
    }

    _resetUiHideTimer();
  }

  Future<void> _loadNextChapterIfPossible() async {
    if (_isFetchingNextChapter ||
        isLoading ||
        (novel?.chapters.isEmpty ?? true) ||
        currentChapterIndex >= (novel?.chapters.length ?? 0) - 1) {
      return;
    }

    setState(() {
      _isFetchingNextChapter = true;
    });

    try {
      final nextChapterIndex = currentChapterIndex + 1;

      if (novel != null && nextChapterIndex < novel!.chapters.length) {
        final nextChapter = novel!.chapters[nextChapterIndex];

        String content;
        if (widget.pluginId == 'NovelMania') {
          content = await novelMania.parseChapter(nextChapter.id);
        } else if (widget.pluginId == 'Tsundoku') {
          content = await tsundoku.parseChapter(nextChapter.id);
        } else if (widget.pluginId == centralNovel.id) {
          content = await centralNovel.parseChapter(nextChapter.id);
        } else {
          setState(() {
            errorMessage = 'Erro: Plugin inválido.';
            isLoading = false;
          });
          return;
        }

        setState(() {
          currentChapter = Chapter(
            id: nextChapter.id,
            title: nextChapter.title,
            content: content,
            releaseDate: '',
            chapterNumber: null,
            order: 0,
          );
          currentChapterIndex = nextChapterIndex;
          _saveLastReadChapter(currentChapter!.id);
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao carregar próximo capítulo: $e';
      });
    } finally {
      setState(() {
        _isFetchingNextChapter = false;
      });
    }
  }

  void _goToPreviousChapter() {
    if (novel != null && currentChapterIndex > 0) {
      setState(() {
        isLoading = true;
        currentChapterIndex--;
        currentChapter = novel!.chapters[currentChapterIndex];
      });
      _loadChapterContent();
    }
  }

  void _toggleUiVisibility() {
    setState(() {
      _isUiVisible = !_isUiVisible;

      if (_isUiVisible) {
        _startUiHideTimer();
      } else {
        _hideUiTimer?.cancel();
      }
    });
  }

  void _startUiHideTimer() {
    _hideUiTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _isUiVisible = false;
      });
    });
  }

  void _resetUiHideTimer() {
    _hideUiTimer?.cancel();
    if (_isUiVisible) {
      _startUiHideTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleUiVisibility,
      child: Scaffold(
        backgroundColor: _readerSettings.backgroundColor,
        appBar:
            _isUiVisible
                ? ReaderAppBar(
                  title:
                      isLoading ||
                              errorMessage != null ||
                              currentChapter == null
                          ? null
                          : currentChapter!.title,
                  readerSettings: _readerSettings,
                  onSettingsPressed: () => _showSettingsModal(context),
                )
                : null,
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : Column(
                  children: [
                    Expanded(
                      child: ChapterDisplay(
                        chapterContent: currentChapter?.content,
                        readerSettings: _readerSettings,
                        scrollController: _scrollController,
                      ),
                    ),

                    if (_isUiVisible)
                      ChapterNavigation(
                        onPreviousChapter: _goToPreviousChapter,
                        onNextChapter: _loadNextChapterIfPossible,
                        isLoading: isLoading || _isFetchingNextChapter,
                        readerSettings: _readerSettings,
                      ),
                  ],
                ),
      ),
    );
  }
}
