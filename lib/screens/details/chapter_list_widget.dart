import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

class ChapterListWidget extends StatefulWidget {
  final List<Chapter> chapters;
  final Function(String) onChapterTap;
  final String? lastReadChapterId;
  final Set<String> readChapterIds;
  final Function(String) onMarkAsRead;
  final String novelId;

  const ChapterListWidget({
    super.key,
    required this.chapters,
    required this.onChapterTap,
    this.lastReadChapterId,
    this.readChapterIds = const {},
    required this.onMarkAsRead,
    required this.novelId,
  });

  @override
  _ChapterListWidgetState createState() => _ChapterListWidgetState();
}

class _ChapterListWidgetState extends State<ChapterListWidget>
    with AutomaticKeepAliveClientMixin {
  List<Chapter> _chapters = [];
  final BehaviorSubject<List<Chapter>> _displayedChapters =
      BehaviorSubject<List<Chapter>>.seeded([]);
  bool _isAscending = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 30;
  bool _isLoadingMore = false;
  bool _allChaptersLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _chapters = List.from(widget.chapters);
    _sortAndFilterChapters();
    _scrollController.addListener(_onScroll);

    _searchController.addListener(_onSearchChanged);

    _loadInitialChapters();
  }

  @override
  void didUpdateWidget(covariant ChapterListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chapters != oldWidget.chapters ||
        widget.readChapterIds != oldWidget.readChapterIds) {
      _chapters = List.from(widget.chapters);
      _sortAndFilterChapters();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _displayedChapters.close();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _sortAndFilterChapters();
  }

  void _loadInitialChapters() {
    _allChaptersLoaded = false;
    _displayedChapters.add(_getChaptersForPage(0));
  }

  List<Chapter> _getChaptersForPage(int startIndex) {
    final endIndex = (startIndex + _pageSize).clamp(0, _chapters.length);
    return _chapters.sublist(startIndex, endIndex);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingMore &&
        !_allChaptersLoaded) {
      _loadMoreChapters();
    }
  }

  Future<void> _loadMoreChapters() async {
    if (_isLoadingMore || _allChaptersLoaded) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 200));

    final startIndex = _displayedChapters.value.length;
    final newChapters = _getChaptersForPage(startIndex);
    if (newChapters.isEmpty) {
      _allChaptersLoaded = true;
    } else {
      _displayedChapters.add([..._displayedChapters.value, ...newChapters]);
    }

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _sortAndFilterChapters() {
    final query = _searchController.text.toLowerCase();
    List<Chapter> filteredChapters =
        _chapters
            .where(
              (chapter) =>
                  chapter.title.toLowerCase().contains(query) ||
                  (chapter.chapterNumber?.toString().contains(query) ?? false),
            )
            .toList();

    filteredChapters.sort((a, b) {
      final comparison =
          _isAscending
              ? (a.chapterNumber ?? double.infinity).compareTo(
                b.chapterNumber ?? double.infinity,
              )
              : (b.chapterNumber ?? double.infinity).compareTo(
                a.chapterNumber ?? double.infinity,
              );
      return comparison;
    });

    if (mounted) {
      setState(() {
        _displayedChapters.add(filteredChapters);
      });
    }
  }

  void _toggleSortOrder() {
    setState(() {
      _isAscending = !_isAscending;
      _sortAndFilterChapters();
    });
  }

  Future<void> _addToHistory(Chapter chapter) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = 'history_${widget.novelId}';
    String historyString = prefs.getString(historyKey) ?? '[]';
    List<dynamic> history = List.from(jsonDecode(historyString));

    final newItem = {
      'novelId': widget.novelId,
      'novelTitle': '',
      'chapterId': chapter.id,
      'chapterTitle': chapter.title,
      'pluginId': '',
      'chapterNumber': chapter.chapterNumber,
      'lastRead': DateTime.now().toIso8601String(),
    };

    history.removeWhere((item) => item['chapterId'] == chapter.id);
    history.insert(0, newItem);

    if (history.length > 10) {
      history = history.sublist(0, 10);
    }

    await prefs.setString(historyKey, jsonEncode(history));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final listHeight = screenHeight * 0.8;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 25),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Pesquisar Capítulo'.translate,
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 14.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(
                    _isAscending ? Icons.arrow_downward : Icons.arrow_upward,
                    color: colorScheme.primary,
                  ),
                  onPressed: _toggleSortOrder,
                  tooltip:
                      _isAscending
                          ? 'Ordenar Decrescente'.translate
                          : 'Ordenar Crescente'.translate,
                ),
              ],
            ),
          ),
          SizedBox(
            height: listHeight,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: StreamBuilder<List<Chapter>>(
                stream: _displayedChapters.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    );
                  }

                  final displayedChapters = snapshot.data!;
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        displayedChapters.length + (_isLoadingMore ? 1 : 0),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      if (index < displayedChapters.length) {
                        final chapter = displayedChapters[index];
                        final isLastRead =
                            chapter.id == widget.lastReadChapterId;
                        final isRead = widget.readChapterIds.contains(
                          chapter.id,
                        );
                        final isUnread = !isRead;

                        FontWeight fontWeight = FontWeight.normal;
                        if (isUnread) {
                          fontWeight = FontWeight.w600;
                        }

                        String chapterDisplay = chapter.title;
                        if (chapter.chapterNumber != null) {
                          chapterDisplay =
                              "${chapter.chapterNumber}: ${chapter.title}";
                        }

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          color: theme.colorScheme.surfaceVariant,

                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                widget.onChapterTap(chapter.id);
                                _addToHistory(chapter);
                                _searchFocusNode.unfocus();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14.0,
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$chapterDisplay${chapter.releaseDate != null ? ' - ${chapter.releaseDate}' : ''}',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: fontWeight,
                                              color:
                                                  isLastRead
                                                      ? theme
                                                          .colorScheme
                                                          .primary
                                                      : isRead
                                                      ? theme.disabledColor
                                                      : theme
                                                          .colorScheme
                                                          .onSurface,
                                            ),
                                      ),
                                    ),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(24.0),
                                      onTap: () {
                                        widget.onMarkAsRead(chapter.id);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          widget.readChapterIds.contains(
                                                chapter.id,
                                              )
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color:
                                              widget.readChapterIds.contains(
                                                    chapter.id,
                                                  )
                                                  ? Colors.green
                                                  : theme.disabledColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child:
                                _allChaptersLoaded
                                    ? Text(
                                      'No More Chapters'.translate,
                                      style: theme.textTheme.bodyMedium,
                                    )
                                    : CircularProgressIndicator(
                                      color: theme.colorScheme.primary,
                                    ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
