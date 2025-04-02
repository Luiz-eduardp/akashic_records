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
  List<Chapter> _displayedChapters = [];
  int _page = 1;
  final int _pageSize = 20;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _displayedChapters = _getInitialChapters();
    _scrollController.addListener(_onScroll);
  }

  List<Chapter> _getInitialChapters() {
    List<Chapter> reversedChapters = widget.chapters.reversed.toList();
    int endIndex = _page * _pageSize;
    if (endIndex > reversedChapters.length) {
      endIndex = reversedChapters.length;
    }
    return reversedChapters.sublist(0, endIndex);
  }


  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreChapters();
    }
  }

  Future<void> _loadMoreChapters() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    List<Chapter> newChapters = await _fetchChaptersFromApi(_page + 1, _pageSize);

    setState(() {
      _displayedChapters.addAll(newChapters);
      _page++;
      _isLoading = false;
    });
  }

  Future<List<Chapter>> _fetchChaptersFromApi(int page, int pageSize) async {
     await Future.delayed(const Duration(milliseconds: 500));
    List<Chapter> reversedChapters = widget.chapters.reversed.toList();
    int startIndex = (page - 1) * pageSize;
    int endIndex = startIndex + pageSize;
    if (startIndex >= reversedChapters.length) {
      return [];
    }
    endIndex =
        endIndex > reversedChapters.length ? reversedChapters.length : endIndex;
    return reversedChapters.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 400,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _displayedChapters.length + (_isLoading ? 1 : 0),
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            if (index < _displayedChapters.length) {
              final chapter = _displayedChapters[index];
              final isLastRead = chapter.id == widget.lastReadChapterId;

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
                                chapter.title,
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
              return _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Container();
            }
          },
        ),
      ),
    );
  }
}