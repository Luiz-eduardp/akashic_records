import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/i18n/i18n.dart';

class ChapterListWidget extends StatefulWidget {
  final List<Chapter> chapters;
  final Function(String) onChapterTap;

  const ChapterListWidget({
    super.key,
    required this.chapters,
    required this.onChapterTap,
  });

  @override
  _ChapterListWidgetState createState() => _ChapterListWidgetState();
}

class _ChapterListWidgetState extends State<ChapterListWidget> {
  List<Chapter> _chapters = [];
  List<Chapter> _displayedChapters = [];
  bool _isAscending = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final ScrollController _scrollController = ScrollController();
  int _firstItemIndex = 0;
  final int _pageSize = 20;
  bool _isLoadingMore = false;
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    _mounted = true;
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
    _mounted = false;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _resetPagination() {
    _firstItemIndex = 0;
    _displayedChapters.clear();
    _loadInitialChapters();
  }

  void _loadInitialChapters() {
    if (!_mounted) return;

    _displayedChapters = _chapters.sublist(
      0,
      _pageSize.clamp(0, _chapters.length),
    );
    if (_mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingMore) {
      _loadMoreChapters();
    }
  }

  Future<void> _loadMoreChapters() async {
    if (_isLoadingMore || !_mounted) return;
    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 200));

    _firstItemIndex += _pageSize;
    final int endIndex = (_firstItemIndex + _pageSize).clamp(
      0,
      _chapters.length,
    );

    if (_firstItemIndex < _chapters.length) {
      if (_mounted) {
        setState(() {
          _displayedChapters.addAll(
            _chapters.sublist(_firstItemIndex, endIndex),
          );
          _isLoadingMore = false;
        });
      }
    } else {
      if (_mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _sortChapters() {
    if (!_mounted) return;

    _displayedChapters = List.from(_chapters);

    _displayedChapters.sort((a, b) {
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

    if (_mounted) {
      setState(() {});
    }
  }

  void _toggleSortOrder() {
    if (!_mounted) return;
    setState(() {
      _isAscending = !_isAscending;
      _sortChapters();
    });
  }

  void _searchChapters() {
    if (!_mounted) return;

    String query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _sortChapters();
    } else {
      if (_mounted) {
        setState(() {
          _displayedChapters =
              _chapters.where((chapter) {
                return chapter.title.toLowerCase().contains(query) ||
                    (chapter.chapterNumber != null &&
                        chapter.chapterNumber!.toString().contains(query));
              }).toList();
          _displayedChapters.sort((a, b) {
            if (_isAscending) {
              return (a.chapterNumber ?? double.infinity).compareTo(
                b.chapterNumber ?? double.infinity,
              );
            } else {
              return (b.chapterNumber ?? double.infinity).compareTo(
                a.chapterNumber ?? double.infinity,
              );
            }
          });
        });
      }
    }
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
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    onChanged: (_) => _searchChapters(),
                  ),
                ),
                SizedBox(width: 8.0),
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
              child: RefreshIndicator(
                onRefresh: () async {
                  _resetPagination();
                  _searchChapters();
                  await Future.delayed(Duration(seconds: 1));
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount:
                      _displayedChapters.length + (_isLoadingMore ? 1 : 0),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    if (index < _displayedChapters.length) {
                      final chapter = _displayedChapters[index];

                      FontWeight fontWeight = FontWeight.normal;

                      String chapterDisplay = chapter.title;
                      if (chapter.chapterNumber != null) {
                        chapterDisplay =
                            "${chapter.chapterNumber}: ${chapter.title}";
                      }
                      return Card(
                        elevation: 1.5,
                        margin: EdgeInsets.symmetric(vertical: 4.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8.0),
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                widget.onChapterTap(chapter.id);
                              });
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
                                            color: theme.colorScheme.onSurface,
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
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
