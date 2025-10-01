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
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final favs = state.favoriteNovels;
        final results = _filterFavs(favs);
        return Scaffold(
          appBar: AppBar(centerTitle: true, title: Text('favorites'.translate)),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _onSearchChanged(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'search_favorites_hint'.translate,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child:
                      results.isEmpty
                          ? Center(child: Text('no_novels_stored'.translate))
                          : ListView.separated(
                            itemCount: results.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final n = results[i];
                              final lastIndex =
                                  n.lastReadChapterId == null
                                      ? 0
                                      : n.chapters.indexWhere(
                                        (c) => c.id == n.lastReadChapterId,
                                      );
                              final startIndex = lastIndex < 0 ? 0 : lastIndex;
                              return Card(
                                clipBehavior: Clip.hardEdge,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    n.coverImageUrl.isNotEmpty
                                        ? Image.network(
                                          n.coverImageUrl,
                                          width: 96,
                                          height: 128,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => Container(
                                                width: 96,
                                                height: 128,
                                                color: Colors.grey,
                                              ),
                                        )
                                        : Container(
                                          width: 96,
                                          height: 128,
                                          color: Colors.grey,
                                        ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${n.author} • ${n.numberOfChapters} ${'chapters_short'.translate}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              children: [
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (_) =>
                                                                NovelDetailScreen(
                                                                  novel: n,
                                                                ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.info_outline,
                                                  ),
                                                  label: Text(
                                                    'details'.translate,
                                                  ),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (_) =>
                                                                const ReaderScreen(),
                                                        settings: RouteSettings(
                                                          arguments: {
                                                            'novel': n,
                                                            'chapterIndex':
                                                                startIndex,
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.play_arrow,
                                                  ),
                                                  label: Text(
                                                    'continue_reading'
                                                        .translate,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
