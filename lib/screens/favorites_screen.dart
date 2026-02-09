import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/widgets/optimized_network_image.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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
    );
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
          const SliverToBoxAdapter(
            child: SizedBox(height: 15),
          ),
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
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: MediaQuery.of(context).size.width < 600 ? 180 : 200,
                  mainAxisExtent: 310,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final n = results[i];
                  return _buildNovelGridCard(context, n);
                }, childCount: results.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildNovelGridCard(BuildContext context, dynamic novel) {
    final theme = Theme.of(context);
    final hasRead = novel.lastReadChapterId != null;

    double progress = 0;
    if (novel.chapters.isNotEmpty && hasRead) {
      final lastIdx = novel.chapters.indexWhere(
        (c) => c.id == novel.lastReadChapterId,
      );
      if (lastIdx >= 0) {
        progress = (lastIdx + 1) / novel.chapters.length;
      }
    }

    return Dismissible(
      key: Key('fav_${novel.id}'),
      direction: DismissDirection.up,
      onDismissed: (_) => _removeFromFavorites(context, novel),
      child: GestureDetector(
        onTap: () => _goToDetails(context, novel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: OptimizedNetworkImage(
                      novel.coverImageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: Container(
                        color: theme.colorScheme.surfaceVariant,
                      ),
                    ),
                  ),
                  if (hasRead && progress > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FloatingActionButton.small(
                      heroTag: 'play_${novel.id}',
                      backgroundColor: theme.colorScheme.primary,
                      onPressed: () => _continueReading(context, novel),
                      child: Icon(
                        hasRead ? Icons.play_arrow : Icons.menu_book,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              novel.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              novel.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (hasRead && progress > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
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
