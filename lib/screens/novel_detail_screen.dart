import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:akashic_records/widgets/chapter_list.dart';
import 'package:akashic_records/widgets/novel_header.dart';
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
    final db = await NovelDatabase.getInstance();
    final set = await db.getReadChaptersForNovel((novel ?? widget.novel).id);
    setState(() => readChapters = set);
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
                await appState.toggleFavorite(id);
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
                      (novel ?? widget.novel).isFavorite
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
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search chapters...',
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
                  icon: const Icon(Icons.done_all),
                  onPressed: () async {
                    final db = await NovelDatabase.getInstance();
                    for (final ch in chapters)
                      await db.setChapterRead(
                        (novel ?? widget.novel).id,
                        ch.id,
                        true,
                      );
                    await _loadReadStates();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ChapterList(
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
            ),
          ),
        ],
      ),
    );
  }
}
