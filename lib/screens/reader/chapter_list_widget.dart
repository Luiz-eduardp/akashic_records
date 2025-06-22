import 'dart:async';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/models/model.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ChapterListWidget extends StatefulWidget {
  final List<Chapter> chapters;
  final Function(String) onChapterTap;
  final String novelId;
  final void Function(String chapterId) onMarkAsRead;

  const ChapterListWidget({
    super.key,
    required this.chapters,
    required this.onChapterTap,
    required this.novelId,
    required this.onMarkAsRead,
  });

  @override
  _ChapterListWidgetState createState() => _ChapterListWidgetState();
}

class _ChapterListWidgetState extends State<ChapterListWidget> {
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
  late final _searchDebouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _chapters = List.from(widget.chapters);
    _sortChapters();
    _loadInitialChapters();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant ChapterListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chapters != oldWidget.chapters) {
      _chapters = List.from(widget.chapters);
      _sortChapters();
      _filterChapters();
      _resetPagination();
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
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebouncer.run(() {
      _sortChapters();
    });
  }

  void _filterChapters() {
    final query = _searchController.text.toLowerCase();
    final filteredChapters =
        _chapters.where((chapter) {
          return chapter.title.toLowerCase().contains(query) ||
              (chapter.chapterNumber?.toString().contains(query) ?? false);
        }).toList();
    _displayedChapters.add(filteredChapters);
  }

  void _resetPagination() {
    _displayedChapters.add([]);
    _loadInitialChapters();
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

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _sortChapters() {
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
    _displayedChapters.add(filteredChapters);
  }

  void _toggleSortOrder() {
    setState(() {
      _isAscending = !_isAscending;
      _sortChapters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    focusNode: _searchFocusNode,
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Pesquisar Capítulo'.translate,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 14.0,
                      ),
                    ),
                    onChanged: (_) => _sortChapters(),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(
                    _isAscending ? Icons.arrow_downward : Icons.arrow_upward,
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
                        color: theme.colorScheme.primary,
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
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 5),

                          child: InkWell(
                            onTap: () {
                              widget.onChapterTap(chapter.id);
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
                                      '${chapter.chapterNumber != null ? '${chapter.chapterNumber}: ' : ''}${chapter.title}${chapter.releaseDate != null ? ' - ${chapter.releaseDate}' : ''}',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Carregando mais capítulos...'.translate,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
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

class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
