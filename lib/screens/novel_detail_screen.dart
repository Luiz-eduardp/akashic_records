import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:akashic_records/widgets/chapter_list.dart';
import 'package:akashic_records/widgets/novel_header.dart';
import 'package:akashic_records/widgets/skeleton.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/state/app_state.dart';
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

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    novel = widget.novel;
    chapters = List.from(novel!.chapters);
    filtered = List.from(chapters);
    _loadReadStates();
    _ensureDetails();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReadStates() async {
    if (!mounted) return;
    setState(() => _loadingReadStates = true);
    try {
      final db = await NovelDatabase.getInstance();
      final set = await db.getReadChaptersForNovel((novel ?? widget.novel).id);
      if (mounted) setState(() => readChapters = set);
    } catch (e) {
      if (mounted) setState(() => readChapters = {});
    } finally {
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
        if (full.title.isNotEmpty) novel!.title = full.title;
        if (full.coverImageUrl.isNotEmpty)
          novel!.coverImageUrl = full.coverImageUrl;
        if (full.author.isNotEmpty) novel!.author = full.author;
        if (full.description.isNotEmpty) novel!.description = full.description;
        if (full.genres.isNotEmpty) novel!.genres = full.genres;

        final existingById = <String, Chapter>{};
        for (final c in novel!.chapters) {
          existingById[c.id] = c;
        }

        final merged = <Chapter>[];
        for (final c in full.chapters) {
          final existing = existingById[c.id];
          if (existing != null) {
            c.content =
                (existing.content != null && existing.content!.isNotEmpty)
                    ? existing.content
                    : c.content;
            c.chapterNumber = c.chapterNumber ?? existing.chapterNumber;
          }
          merged.add(c);
        }

        novel!.chapters = merged;
        chapters = List.from(novel!.chapters);
        _applyFilters();

        final db = await NovelDatabase.getInstance();
        await db.upsertNovel(novel ?? widget.novel);
      } else {
        _applyFilters();
      }
    } catch (e) {
      debugPrint(
        'Failed to fetch full novel details for ${(novel ?? widget.novel).id}: $e',
      );
      _applyFilters();
    } finally {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  Future<void> _handleFavoriteToggle() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentNovel = novel ?? widget.novel;
    final id = currentNovel.id;
    final wasFavorite = currentNovel.isFavorite;

    try {
      if (!wasFavorite) {
        final toSave = novel ?? widget.novel;
        toSave.isFavorite = true;
        await appState.addOrUpdateNovel(toSave);
      } else {
        await appState.toggleFavorite(id);
      }

      final updated = appState.localNovels.firstWhere(
        (n) => n.id == id,
        orElse: () => currentNovel,
      );

      setState(() {
        novel = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.isFavorite
                ? 'added_to_favorites'.translate
                : 'removed_from_favorites'.translate,
          ),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'failed_update_favorite'.translate}: $e')),
      );
    }
  }

  Widget _buildChapterToolbar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: 'search_chapters_hint'.translate,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHigh,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
              onChanged: (v) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 200), () {
                  setState(() {
                    _search = v;
                    _applyFilters();
                  });
                });
              },
            ),
          ),
          const SizedBox(width: 8),

          Tooltip(
            message:
                _asc ? 'sort_ascending'.translate : 'sort_descending'.translate,
            child: IconButton(
              icon: Icon(
                _asc ? Icons.sort_by_alpha : Icons.sort_by_alpha_sharp,
                color: theme.colorScheme.primary,
              ),
              onPressed: () {
                setState(() {
                  _asc = !_asc;
                  _applyFilters();
                });
              },
            ),
          ),

          Tooltip(
            message: 'mark_all_read'.translate,
            child: IconButton(
              icon: Icon(Icons.done_all, color: theme.colorScheme.secondary),
              onPressed: () async {
                final appState = Provider.of<AppState>(context, listen: false);
                for (final ch in chapters) {
                  await appState.setChapterRead(
                    (novel ?? widget.novel).id,
                    ch.id,
                    true,
                  );
                }
                await _loadReadStates();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('marked_all_chapters_read'.translate),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NovelHeader(novel: novel ?? widget.novel, loading: true),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: LoadingSkeleton.rect(
              height: 48,
              baseColor: baseColor,
              highlightColor: highlightColor,
              borderRadius: BorderRadius.circular(30),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LoadingSkeleton.rect(
                            height: 16,
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                            width: i.isEven ? double.infinity : 200,
                          ),
                          const SizedBox(height: 6),
                          LoadingSkeleton.rect(
                            height: 12,
                            width: 150,
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    LoadingSkeleton.rect(
                      width: 24,
                      height: 24,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _loadingDetails || _loadingReadStates;
    final currentNovel = novel ?? widget.novel;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentNovel.title,
          style: Theme.of(context).textTheme.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!isLoading)
            IconButton(
              tooltip: 'favorites'.translate,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder:
                    (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                child: Icon(
                  currentNovel.isFavorite
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  key: ValueKey<bool>(currentNovel.isFavorite),
                  color:
                      currentNovel.isFavorite
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurface,
                  size: 28,
                ),
              ),
              onPressed: _handleFavoriteToggle,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              NovelHeader(novel: currentNovel, loading: _loadingDetails),
            ]),
          ),

          if (!isLoading)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverChapterToolbarDelegate(
                child: _buildChapterToolbar(context),
              ),
            ),

          if (isLoading)
            SliverList(
              delegate: SliverChildListDelegate([_buildLoadingSkeleton()]),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'no_chapters_found'.translate,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              sliver: ChapterList(
                sliver: true,
                chapters: filtered,
                readChapters: readChapters,
                novelId: currentNovel.id,
                onTap: (ch, index) async {
                  final absoluteIndex = currentNovel.chapters.indexWhere(
                    (c) => c.id == ch.id,
                  );

                  await Navigator.pushNamed(
                    context,
                    '/reader',
                    arguments: {
                      'novel': currentNovel,
                      'chapterIndex': absoluteIndex >= 0 ? absoluteIndex : 0,
                    },
                  );
                  await _loadReadStates();
                },
                onLongPressToggleRead: (ch, index) async {
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  final isRead = readChapters.contains(ch.id);
                  await appState.setChapterRead(
                    currentNovel.id,
                    ch.id,
                    !isRead,
                  );
                  await _loadReadStates();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SliverChapterToolbarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverChapterToolbarDelegate({required this.child});

  @override
  double get minExtent => 64.0;

  @override
  double get maxExtent => 64.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverChapterToolbarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
