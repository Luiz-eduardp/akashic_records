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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
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
        (current.description.isNotEmpty || current.author.isNotEmpty)) {
      _applyFilters();
      return;
    }

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
      debugPrint(
        'Failed to fetch full novel details for ${(novel ?? widget.novel).id}: $e',
      );
    } finally {
      setState(() => _loadingDetails = false);
    }
  }

  Widget _buildLoadingSkeleton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor =
        isDark
            ? theme.colorScheme.surface.withOpacity(0.6)
            : theme.colorScheme.surface.withOpacity(0.3);
    final highlightColor =
        isDark
            ? theme.colorScheme.background.withOpacity(0.2)
            : theme.colorScheme.background.withOpacity(0.12);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton.rect(
                      height: 24,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    const SizedBox(height: 8),
                    LoadingSkeleton.rect(
                      height: 16,
                      width: 150,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    const SizedBox(height: 16),
                    LoadingSkeleton.rect(
                      height: 12,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    const SizedBox(height: 6),
                    LoadingSkeleton.rect(
                      height: 12,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    const SizedBox(height: 6),
                    LoadingSkeleton.rect(
                      height: 12,
                      width: 200,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          LoadingSkeleton.rect(
            height: 48,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),

          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            separatorBuilder: (_, __) => const Divider(height: 16),
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
                        ),
                        const SizedBox(height: 6),
                        LoadingSkeleton.rect(
                          height: 12,
                          width: 100,
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
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _loadingDetails || _loadingReadStates;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text((novel ?? widget.novel).title),
        actions: [
          if (!isLoading)
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
                      duration: const Duration(milliseconds: 1500),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${'failed_update_favorite'.translate}: $e',
                      ),
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

          if (!isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'search_chapters_hint'.translate,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      onChanged: (v) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 200),
                          () {
                            setState(() {
                              _search = v;
                              _applyFilters();
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message:
                        _asc
                            ? 'sort_ascending'.translate
                            : 'sort_descending'.translate,
                    child: IconButton(
                      icon: Icon(
                        _asc ? Icons.arrow_upward : Icons.arrow_downward,
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
                  ),
                ],
              ),
            ),

          Expanded(
            child:
                isLoading
                    ? _buildLoadingSkeleton()
                    : (filtered.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'no_chapters_found'.translate,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
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
                              if (svc != null) {
                                try {
                                  final content = await svc.parseChapter(ch.id);
                                  ch.content = content;
                                  novel ??= current;
                                  final db = await NovelDatabase.getInstance();
                                  await db.upsertNovel(novel ?? widget.novel);
                                } catch (e) {
                                  debugPrint(
                                    'Failed to parse chapter ${ch.id}: $e',
                                  );
                                }
                              }
                            }

                            final absoluteIndex = (novel ?? widget.novel)
                                .chapters
                                .indexWhere((c) => c.id == ch.id);

                            await Navigator.pushNamed(
                              context,
                              '/reader',
                              arguments: {
                                'novel': novel ?? widget.novel,
                                'chapterIndex':
                                    absoluteIndex >= 0 ? absoluteIndex : 0,
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
                              (novel ?? widget.novel).id,
                              ch.id,
                              !isRead,
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
