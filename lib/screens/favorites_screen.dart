import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_query != _searchController.text.trim().toLowerCase()) {
        setState(() {
          _query = _searchController.text.trim().toLowerCase();
        });
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
    final lastIndex =
        novel.lastReadChapterId == null
            ? 0
            : novel.chapters.indexWhere((c) => c.id == novel.lastReadChapterId);
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final favs = state.favoriteNovels;
        final results = _filterFavs(favs);

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              'favorites'.translate,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 24),
                    hintText: 'search_favorites_hint'.translate,
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child:
                    results.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bookmark_border,
                                  size: 60,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _query.isNotEmpty
                                      ? 'no_results_found'.translate
                                      : 'no_novels_stored'.translate,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          itemCount: results.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final n = results[i];
                            return _buildFavoriteNovelCard(context, n);
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavoriteNovelCard(BuildContext context, dynamic novel) {
    final theme = Theme.of(context);
    final lastRead = novel.lastReadChapterId != null;

    return InkWell(
      onTap: () => _goToDetails(context, novel),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoverImage(novel.coverImageUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      novel.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      novel.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${novel.numberOfChapters} ${'chapters_short'.translate}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (lastRead)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'continue_reading'.translate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'details'.translate,
                    onPressed: () => _goToDetails(context, novel),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        lastRead ? Icons.play_arrow : Icons.menu_book,
                        color: theme.colorScheme.onPrimary,
                      ),
                      tooltip:
                          lastRead
                              ? 'continue_reading'.translate
                              : 'start_reading'.translate,
                      onPressed: () => _continueReading(context, novel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(String imageUrl) {
    const double width = 80;
    const double height = 120;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child:
          imageUrl.isNotEmpty
              ? Image.network(
                imageUrl,
                width: width,
                height: height,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder:
                    (_, __, ___) => Center(
                      child: Icon(
                        Icons.book,
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
              )
              : Center(
                child: Icon(
                  Icons.book,
                  size: 40,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
    );
  }
}
