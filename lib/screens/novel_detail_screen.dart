import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:akashic_records/widgets/chapter_list.dart';
import 'package:akashic_records/widgets/novel_header.dart';
import 'package:akashic_records/widgets/skeleton.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/services/download_queue_service.dart';
import 'package:akashic_records/screens/reader/annotations_manager_screen.dart';
import 'dart:async';

class NovelDetailScreen extends StatefulWidget {
  final Novel novel;
  const NovelDetailScreen({super.key, required this.novel});

  @override
  State<NovelDetailScreen> createState() => _NovelDetailScreenState();
}

class _NovelDetailScreenState extends State<NovelDetailScreen> {
  Novel? novel;
  List<Chapter> chapters = [];
  List<Chapter> filtered = [];
  String _search = '';
  bool _asc = true;
  Set<String> readChapters = {};
  bool _loadingDetails = false;
  bool _loadingReadStates = true;
  Timer? _searchDebounce;
  final Map<String, DownloadStatus> _downloadStatus = {};
  VoidCallback? _queueListener;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    novel = widget.novel;
    chapters = List.from(novel!.chapters);
    filtered = List.from(chapters);
    _loadReadStates();
    _ensureDetails();
    _setupDownloadQueueListener();
  }

  void _setupDownloadQueueListener() {
    final appState = Provider.of<AppState>(context, listen: false);
    _queueListener = () {
      if (mounted) {
        setState(() {
          for (final item in appState.downloadQueue.queue) {
            if (item.novelId == (novel ?? widget.novel).id) {
              _downloadStatus[item.chapter.id] = item.status;
            }
          }
        });
      }
    };
    appState.setOnQueueUpdated(_queueListener!);
  }

  late AppState _appState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appState = Provider.of<AppState>(context, listen: false);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    if (_queueListener != null) {
      _appState.setOnQueueUpdated(null);
    }
    super.dispose();
  }

  Future<void> _loadReadStates() async {
    if (!mounted) return;
    setState(() => _loadingReadStates = true);
    try {
      final db = await NovelDatabase.getInstance();
      final set = await db.getReadChaptersForNovel((novel ?? widget.novel).id);
      if (mounted) {
        setState(() {
          readChapters = set;
          _loadingReadStates = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingReadStates = false);
    }
  }

  void _applyFilters() {
    var list = List.of(chapters);
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((c) => c.title.toLowerCase().contains(q)).toList();
    }
    list.sort(
      (a, b) =>
          _asc
              ? (a.chapterNumber ?? 0).compareTo(b.chapterNumber ?? 0)
              : (b.chapterNumber ?? 0).compareTo(a.chapterNumber ?? 0),
    );
    if (mounted) setState(() => filtered = list);
  }

  Future<void> _ensureDetails() async {
    final current = novel ?? widget.novel;
    final svc = PluginRegistry.get(current.pluginId);
    if (svc == null) {
      _applyFilters();
      return;
    }

    if (mounted) setState(() => _loadingDetails = true);
    try {
      final full = await svc
          .parseNovel(current.id)
          .timeout(const Duration(seconds: 20));

      if (full != null) {
        novel ??= current;
        novel!.title = full.title.isNotEmpty ? full.title : novel!.title;
        novel!.coverImageUrl =
            full.coverImageUrl.isNotEmpty
                ? full.coverImageUrl
                : novel!.coverImageUrl;
        novel!.author = full.author.isNotEmpty ? full.author : novel!.author;
        novel!.description =
            full.description.isNotEmpty ? full.description : novel!.description;
        novel!.genres = full.genres.isNotEmpty ? full.genres : novel!.genres;

        final existingById = {for (var c in novel!.chapters) c.id: c};
        final merged =
            full.chapters.map((c) {
              final existing = existingById[c.id];
              if (existing != null) {
                c.content =
                    (existing.content?.isNotEmpty ?? false)
                        ? existing.content
                        : c.content;
                c.chapterNumber ??= existing.chapterNumber;
              }
              return c;
            }).toList();

        novel!.chapters = merged;
        chapters = List.from(merged);
        _applyFilters();

        final db = await NovelDatabase.getInstance();
        await db.upsertNovel(novel!);
      }
    } catch (e) {
      debugPrint('Error fetching details: $e');
    } finally {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  Future<void> _handleFavoriteToggle() async {
    HapticFeedback.mediumImpact();
    final appState = Provider.of<AppState>(context, listen: false);
    final currentNovel = novel ?? widget.novel;

    try {
      final existingNovel = appState.getNovelById(currentNovel.id);
      final shouldFavorite = !currentNovel.isFavorite;

      if (existingNovel != null) {
        await appState.toggleFavorite(
          currentNovel.id,
          value: shouldFavorite,
        );
      } else {
        currentNovel.isFavorite = shouldFavorite;
        await appState.addOrUpdateNovel(currentNovel);
      }

      final updatedNovel = appState.getNovelById(currentNovel.id);
      setState(() {
        novel = updatedNovel ?? currentNovel;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (updatedNovel ?? currentNovel).isFavorite
                ? 'added_to_favorites'.translate
                : 'removed_from_favorites'.translate,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (_) {}
  }

  void _showDownloadAllDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('confirm'.translate),
            content: Text(
              'confirm_download_all'.translate.replaceFirst(
                '%d',
                chapters.length.toString(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('cancel'.translate),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _downloadAllChapters();
                },
                child: Text('confirm'.translate),
              ),
            ],
          ),
    );
  }

  int _getContinueReadingIndex() {
    final currentNovel = novel ?? widget.novel;
    if (currentNovel.lastReadChapterId == null) return 0;
    final idx = chapters.indexWhere(
      (c) => c.id == currentNovel.lastReadChapterId,
    );
    return idx != -1 ? idx : 0;
  }

  Future<void> _handleDownloadChapter(Chapter ch) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentNovel = novel ?? widget.novel;
    await appState.addChapterToDownloadQueue(currentNovel.id, ch);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'downloading_chapter'.translate.replaceFirst('%s', ch.title),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _handleDownloadMultiple(List<Chapter> chaps) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentNovel = novel ?? widget.novel;
    int count = 0;
    for (final ch in chaps) {
      await appState.addChapterToDownloadQueue(currentNovel.id, ch);
      count++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'chapters_added_to_queue'.translate.replaceFirst(
              '%d',
              count.toString(),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleCancelDownload(String chapterId) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentNovel = novel ?? widget.novel;
    await appState.removeFromDownloadQueue(currentNovel.id, chapterId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('download_cancelled'.translate),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _downloadAllChapters() async {
    final currentNovel = novel ?? widget.novel;
    final appState = Provider.of<AppState>(context, listen: false);

    int count = 0;
    for (final ch in chapters) {
      await appState.addChapterToDownloadQueue(currentNovel.id, ch);
      count++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'chapters_added_to_queue'.translate.replaceFirst(
              '%d',
              count.toString(),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentNovel = novel ?? widget.novel;
    final isLoading = _loadingDetails || _loadingReadStates;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(currentNovel.title),
            centerTitle: true,
            pinned: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(15),
              child: const SizedBox(height: 15),
            ),
            actions: [
              if (chapters.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.cloud_download_outlined),
                  tooltip: 'download_all_chapters'.translate,
                  onPressed: () => _showDownloadAllDialog(),
                ),
              IconButton(
                icon: const Icon(Icons.format_quote_rounded),
                tooltip: 'annotations_title'.translate,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnnotationsManagerScreen(
                        novelId: currentNovel.id,
                        novelTitle: currentNovel.title,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  currentNovel.isFavorite
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color:
                      currentNovel.isFavorite
                          ? theme.colorScheme.primary
                          : null,
                ),
                onPressed: _handleFavoriteToggle,
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                NovelHeader(novel: currentNovel, loading: _loadingDetails),
                const SizedBox(height: 16),],
            ),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverChapterToolbarDelegate(
              child: _buildChapterToolbar(context),
            ),
          ),

          if (isLoading && chapters.isEmpty)
            SliverFillRemaining(child: _buildLoadingSkeleton())
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text('no_chapters_found'.translate)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: ChapterList(
                sliver: true,
                chapters: filtered,
                readChapters: readChapters,
                novelId: currentNovel.id,
                downloadStatus: _downloadStatus,
                onDownload: (ch) async => _handleDownloadChapter(ch),
                onDownloadAll: (chaps) async => _handleDownloadMultiple(chaps),
                onCancelDownload:
                    (chapterId) async => _handleCancelDownload(chapterId),
                onTap: (ch, index) async {
                  final absIdx = chapters.indexWhere((c) => c.id == ch.id);
                  await Navigator.pushNamed(
                    context,
                    '/reader',
                    arguments: {
                      'novel': currentNovel,
                      'chapterIndex': absIdx != -1 ? absIdx : 0,
                    },
                  );
                  _loadReadStates();
                },
                onLongPressToggleRead: (ch, index) async {
                  HapticFeedback.lightImpact();
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  await appState.setChapterRead(
                    currentNovel.id,
                    ch.id,
                    !readChapters.contains(ch.id),
                  );
                  _loadReadStates();
                },
              ),
            ),
        ],
      ),
      floatingActionButton:
          chapters.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: () {
                  final idx = _getContinueReadingIndex();
                  Navigator.pushNamed(
                    context,
                    '/reader',
                    arguments: {'novel': currentNovel, 'chapterIndex': idx},
                  ).then((_) => _loadReadStates());
                },
                icon: const Icon(Icons.play_arrow),
                label: Text('continue_reading'.translate),
              )
              : null,
    );
  }



  Widget _buildChapterToolbar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              controller: _searchController,
              hintText: 'search_chapters_hint'.translate,
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainerHigh,
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (v) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                  setState(() {
                    _search = v;
                    _applyFilters();
                  });
                });
              },
              leading: const Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            icon: Icon(_asc ? Icons.sort_by_alpha : Icons.sort_by_alpha_sharp),
            onPressed: () {
              setState(() {
                _asc = !_asc;
                _applyFilters();
              });
            },
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllRead(context),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('mark_all_read'.translate),
            content: Text('confirm_mark_all_read'.translate),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('cancel'.translate),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('confirm'.translate),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final appState = Provider.of<AppState>(context, listen: false);
      for (final ch in chapters) {
        await appState.setChapterRead((novel ?? widget.novel).id, ch.id, true);
      }
      _loadReadStates();
    }
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(
          10,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LoadingSkeleton.rect(
              height: 60,
              width: double.infinity,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverChapterToolbarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverChapterToolbarDelegate({required this.child});

  @override
  double get minExtent => 70.0;
  @override
  double get maxExtent => 70.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(elevation: overlapsContent ? 4 : 0, child: child);
  }

  @override
  bool shouldRebuild(_SliverChapterToolbarDelegate oldDelegate) => true;
}
