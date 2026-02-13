import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/widgets/novel_grid_card.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/screens/reader/reader_screen.dart';
import 'package:akashic_records/screens/novel_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  final Map<String, int> _unreadCounts = {};
  int _lastFavCount = -1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshUnreadCounts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final newQuery = _searchController.text.trim().toLowerCase();
      if (_query != newQuery) {
        setState(() => _query = newQuery);
      }
    });
  }

  List _filterFavs(List favs) {
    if (_query.isEmpty) return favs;
    return favs.where((n) {
      final t = (n.title ?? '').toString().toLowerCase();
      final a = (n.author ?? '').toString().toLowerCase();
      return t.contains(_query) || a.contains(_query);
    }).toList();
  }

  void _goToDetails(BuildContext context, dynamic novel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NovelDetailScreen(novel: novel)),
    ).then((_) => _refreshUnreadCounts());
  }

  Future<void> _refreshUnreadCounts() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final Map<String, int> counts = {};
    final db = await NovelDatabase.getInstance();
    for (final novel in appState.favoriteNovels) {
      final readSet = await db.getReadChaptersForNovel(novel.id);
      int unread = 0;
      if (novel.chapters.isNotEmpty) {
        for (final ch in novel.chapters) {
          if (!readSet.contains(ch.id)) unread++;
        }
      }
      counts[novel.id] = unread;
    }
    if (!mounted) return;
    setState(() {
      _unreadCounts.clear();
      _unreadCounts.addAll(counts);
      _lastFavCount = appState.favoriteNovels.length;
    });
  }

  void _continueReading(BuildContext context, dynamic novel) {
    HapticFeedback.lightImpact();
    final lastId = novel.lastReadChapterId;
    final lastIndex =
        lastId == null ? 0 : novel.chapters.indexWhere((c) => c.id == lastId);
    final startIndex = lastIndex < 0 ? 0 : lastIndex;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReaderScreen(),
        settings: RouteSettings(
          arguments: {'novel': novel, 'chapterIndex': startIndex},
        ),
      ),
    );
  }

  Future<void> _removeFromFavorites(BuildContext context, dynamic novel) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.toggleFavorite(novel.id);
    await _refreshUnreadCounts();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('removed_from_favorites'.translate),
          action: SnackBarAction(
            label: 'undo'.translate,
            onPressed: () => appState.toggleFavorite(novel.id),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favs = context.select((AppState s) => s.favoriteNovels);
    final results = _filterFavs(favs);

    if (favs.length != _lastFavCount) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _refreshUnreadCounts(),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              'favorites'.translate,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            pinned: true,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 15)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SearchBar(
                controller: _searchController,
                hintText: 'search_favorites_hint'.translate,
                leading: const Icon(Icons.search),
                elevation: WidgetStateProperty.all(0),
                backgroundColor: WidgetStateProperty.all(
                  theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          if (results.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(theme),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 360,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final n = results[i];
                  return _buildNovelGridCard(context, n, i);
                }, childCount: results.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildNovelGridCard(BuildContext context, dynamic novel, int index) {
    return NovelGridCard(
      novel: novel,
      dismissible: true,
      heroTag: 'cover_${novel.id}_$index',
      unreadCount: _unreadCounts[novel.id] ?? 0,
      onTap: () => _goToDetails(context, novel),
      onContinue: () => _continueReading(context, novel),
      onRemove: () => _removeFromFavorites(context, novel),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _query.isNotEmpty ? Icons.search_off : Icons.auto_stories_outlined,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            _query.isNotEmpty
                ? 'no_results_found'.translate
                : 'no_favorites_yet'.translate,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (_query.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'explore_to_add_favorites'.translate,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
