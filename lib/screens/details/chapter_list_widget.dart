import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';

class ChapterListWidget extends StatefulWidget {
  final List<Chapter> chapters;
  final Function(String) onChapterTap;
  final String? lastReadChapterId;

  const ChapterListWidget({
    super.key,
    required this.chapters,
    required this.onChapterTap,
    this.lastReadChapterId,
  });

  @override
  _ChapterListWidgetState createState() => _ChapterListWidgetState();
}

class _ChapterListWidgetState extends State<ChapterListWidget> {
  List<Chapter> _chapters = [];
  List<Chapter> _displayedChapters = [];
  bool _isAscending = false;
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  int _firstItemIndex = 0;
  final int _pageSize = 20;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _chapters = List.from(widget.chapters);
    _sortChapters();
    _loadInitialChapters();

    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ChapterListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chapters != oldWidget.chapters) {
      _chapters = List.from(widget.chapters);
      _sortChapters();
      _searchChapters();
      _resetPagination();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resetPagination() {
    _firstItemIndex = 0;
    _displayedChapters.clear();
    _loadInitialChapters();
  }

  void _loadInitialChapters() {
    _displayedChapters = _chapters.sublist(
      0,
      _pageSize.clamp(0, _chapters.length),
    );
    setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingMore) {
      _loadMoreChapters();
    }
  }

  void _loadMoreChapters() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    await Future.delayed(const Duration(milliseconds: 200));

    _firstItemIndex += _pageSize;
    final int endIndex = (_firstItemIndex + _pageSize).clamp(
      0,
      _chapters.length,
    );

    if (_firstItemIndex < _chapters.length) {
      setState(() {
        _displayedChapters.addAll(_chapters.sublist(_firstItemIndex, endIndex));
        _isLoadingMore = false;
      });
    } else {
      _isLoadingMore = false;
    }
  }

  double? _extractChapterNumber(String chapterId, String title) {
    final chapterIdRegex = RegExp(r'[-/](\d+(\.\d{1,5})?)[-/]?$');
    final chapterIdMatch = chapterIdRegex.firstMatch(chapterId);

    if (chapterIdMatch != null) {
      final chapterNumberString = chapterIdMatch.group(1);
      if (chapterNumberString != null) {
        return double.tryParse(chapterNumberString);
      }
    }

    final titleRegex = RegExp(
      r'(?:Cap(?:ítulo)?\.?\s*)(\d+(\.\d{1,5})?)',
      caseSensitive: false,
    );

    final titleMatch = titleRegex.firstMatch(title);

    if (titleMatch != null) {
      final chapterNumberString = titleMatch.group(1);
      if (chapterNumberString != null) {
        return double.tryParse(chapterNumberString);
      }
    }

    final initialNumberRegex = RegExp(r'^(\d+(\.\d{1,5})?)');
    final initialNumberMatch = initialNumberRegex.firstMatch(title);

    if (initialNumberMatch != null) {
      final initialNumberString = initialNumberMatch.group(1);
      if (initialNumberString != null) {
        return double.tryParse(initialNumberString);
      }
    }
    return null;
  }

  void _sortChapters() {
    _displayedChapters = List.from(_chapters);

    List<MapEntry<Chapter, double?>> chapterNumbers =
        _displayedChapters.map((chapter) {
          final chapterNumber = _extractChapterNumber(
            chapter.id,
            chapter.title,
          );
          return MapEntry(chapter, chapterNumber);
        }).toList();

    chapterNumbers.sort((a, b) {
      final aNumber = a.value;
      final bNumber = b.value;

      if (aNumber != null && bNumber != null) {
        return _isAscending
            ? aNumber.compareTo(bNumber)
            : bNumber.compareTo(aNumber);
      } else if (aNumber != null) {
        return _isAscending ? -1 : 1;
      } else if (bNumber != null) {
        return _isAscending ? 1 : -1;
      } else {
        return 0;
      }
    });

    _displayedChapters = chapterNumbers.map((entry) => entry.key).toList();

    setState(() {});
  }

  void _toggleSortOrder() {
    setState(() {
      _isAscending = !_isAscending;
      _sortChapters();
    });
  }

  void _searchChapters() {
    String query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _sortChapters();
    } else {
      setState(() {
        _displayedChapters =
            _chapters
                .where((chapter) => chapter.title.toLowerCase().contains(query))
                .toList();
        if (_isAscending) {
          _displayedChapters.sort((a, b) => a.title.compareTo(b.title));
        } else {
          _displayedChapters.sort((a, b) => b.title.compareTo(a.title));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Pesquisar Capítulo',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => _searchChapters(),
                ),
              ),
              IconButton(
                icon: Icon(
                  _isAscending ? Icons.arrow_downward : Icons.arrow_upward,
                ),
                onPressed: _toggleSortOrder,
                tooltip:
                    _isAscending ? 'Ordenar Decrescente' : 'Ordenar Crescente',
              ),
            ],
          ),
        ),
        SizedBox(
          height: 400,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _displayedChapters.length + (_isLoadingMore ? 1 : 0),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                if (index < _displayedChapters.length) {
                  final chapter = _displayedChapters[index];
                  final isLastRead = chapter.id == widget.lastReadChapterId;

                  final chapterNumber = _extractChapterNumber(
                    chapter.id,
                    chapter.title,
                  );

                  String displayTitle =
                      chapterNumber != null
                          ? (chapterNumber % 1 == 0
                              ? chapterNumber.toInt().toString()
                              : chapterNumber.toString())
                          : chapter.title;

                  return Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.onChapterTap(chapter.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayTitle,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight:
                                          isLastRead
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          isLastRead
                                              ? theme.colorScheme.secondary
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (isLastRead)
                                  Icon(
                                    Icons.bookmark,
                                    color: theme.colorScheme.secondary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (index < _displayedChapters.length - 1)
                        Divider(height: 1, color: theme.dividerColor),
                    ],
                  );
                } else {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
