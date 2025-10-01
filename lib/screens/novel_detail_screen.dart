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

  @override
  void initState() {
    super.initState();
    novel = widget.novel;
    chapters = List.from(novel!.chapters);
    filtered = List.from(chapters);
    _loadReadStates();
    _ensureDetails();
  }

  Future<void> _loadReadStates() async {
    setState(() => _loadingReadStates = true);
    try {
      final db = await NovelDatabase.getInstance();
      final set = await db.getReadChaptersForNovel((novel ?? widget.novel).id);
      setState(() => readChapters = set);
    } catch (e) {
      setState(() => readChapters = {});
    } finally {
      setState(() => _loadingReadStates = false);
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
    setState(() => filtered = list);
  }

  Future<void> _ensureDetails() async {
    final current = novel ?? widget.novel;
    if (current.chapters.isNotEmpty &&
        (current.description.isNotEmpty || current.author.isNotEmpty))
      return;
    final svc = PluginRegistry.get(current.pluginId);
    if (svc == null) return;
    setState(() => _loadingDetails = true);
    try {
      final full = await svc
          .parseNovel(current.id)
          .timeout(const Duration(seconds: 20));
      novel ??= current;
      novel!.title = full.title;
      novel!.coverImageUrl = full.coverImageUrl;
      novel!.author = full.author;
      novel!.description = full.description;
      novel!.genres = full.genres;
      novel!.chapters = full.chapters;
      chapters = List.from(novel!.chapters);
      _applyFilters();
      final db = await NovelDatabase.getInstance();
      await db.upsertNovel(novel ?? widget.novel);
    } catch (e) {
      print(
        'Failed to fetch full novel details for ${(novel ?? widget.novel).id}: $e',
      );
    } finally {
      setState(() => _loadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text((novel ?? widget.novel).title),
        actions: [
          IconButton(
            tooltip: 'favorites'.translate,
            icon: Icon(
              (novel ?? widget.novel).isFavorite
                  ? Icons.star
                  : Icons.star_border,
            ),
            onPressed: () async {
              final appState = Provider.of<AppState>(context, listen: false);
              final id = (novel ?? widget.novel).id;
              try {
                final exists = appState.localNovels.any((n) => n.id == id);
                if (!exists) {
                  final toSave = novel ?? widget.novel;
                  toSave.isFavorite = true;
                  await appState.addOrUpdateNovel(toSave);
                } else {
                  await appState.toggleFavorite(id);
                }

                final updated = appState.localNovels.firstWhere(
                  (n) => n.id == id,
                  orElse: () => novel ?? widget.novel,
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
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${'failed_update_favorite'.translate}: $e'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          NovelHeader(novel: novel ?? widget.novel, loading: _loadingDetails),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'search_chapters_hint'.translate,
                    ),
                    onChanged: (v) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 200),
                        () {
                          _search = v;
                          _applyFilters();
                        },
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(_asc ? Icons.sort_by_alpha : Icons.sort),
                  onPressed: () {
                    setState(() {
                      _asc = !_asc;
                      _applyFilters();
                    });
                  },
                ),
                IconButton(
                  tooltip: 'mark_all_read'.translate,
                  icon: const Icon(Icons.done_all),
                  onPressed: () async {
                    final appState = Provider.of<AppState>(
                      context,
                      listen: false,
                    );
                    for (final ch in chapters) {
                      await appState.setChapterRead(
                        (novel ?? widget.novel).id,
                        ch.id,
                        true,
                      );
                    }
                    await _loadReadStates();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child:
                (_loadingDetails || _loadingReadStates)
                    ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const LoadingSkeleton.square(
                                width: 96,
                                height: 140,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    LoadingSkeleton.rect(height: 20),
                                    SizedBox(height: 8),
                                    LoadingSkeleton.rect(
                                      height: 14,
                                      width: 120,
                                    ),
                                    SizedBox(height: 12),
                                    LoadingSkeleton.rect(height: 12),
                                    SizedBox(height: 6),
                                    LoadingSkeleton.rect(height: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 6,
                            separatorBuilder:
                                (_, __) => const Divider(height: 18),
                            itemBuilder: (ctx, i) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const LoadingSkeleton.circle(
                                    width: 36,
                                    height: 36,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        LoadingSkeleton.rect(height: 14),
                                        SizedBox(height: 6),
                                        LoadingSkeleton.rect(
                                          height: 12,
                                          width: 140,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const LoadingSkeleton.rect(
                                    width: 40,
                                    height: 12,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    )
                    : (filtered.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'no_chapters_found'.translate,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        )
                        : ChapterList(
                          chapters: filtered,
                          readChapters: readChapters,
                          onTap: (ch, index) async {
                            if (ch.content == null || ch.content!.isEmpty) {
                              final current = novel ?? widget.novel;
                              final svc = PluginRegistry.get(current.pluginId);
                              String content = '';
                              if (svc != null) {
                                try {
                                  content = await svc.parseChapter(ch.id);
                                  ch.content = content;
                                  novel ??= current;
                                  final db = await NovelDatabase.getInstance();
                                  await db.upsertNovel(novel ?? widget.novel);
                                } catch (e) {
                                  print('Failed to parse chapter ${ch.id}: $e');
                                }
                              }
                            }
                            await Navigator.pushNamed(
                              context,
                              '/reader',
                              arguments: {
                                'novel': novel ?? widget.novel,
                                'chapterIndex': index,
                              },
                            );
                            await _loadReadStates();
                          },
                        )),
          ),
        ],
      ),
    );
  }
}
