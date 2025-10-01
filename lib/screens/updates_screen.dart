import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/widgets/chapter_count_badge.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/screens/novel_detail_screen.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'dart:convert';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  Map<String, int> _updates = {};
  bool _loading = false;
  final Map<String, List<String>> _cachedChapters = {};
  final Map<String, int> _dynamicUnread = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshDynamicUnread();
    });
  }

  Future<void> _check() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final updates = await appState.checkForUpdates();

    try {
      final db = await NovelDatabase.getInstance();
      for (final n in appState.favoriteNovels) {
        final ids = n.chapters.map((c) => c.id).toList();
        await db.setSetting('cached_chapters_${n.id}', json.encode(ids));
        _cachedChapters[n.id] = ids;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _updates = updates;
      _loading = false;
    });
  }

  Future<int> _computeUnreadForNovel(dynamic n) async {
    final db = await NovelDatabase.getInstance();
    final readSet = await db.getReadChaptersForNovel(n.id);
    int unread = 0;
    for (final ch in n.chapters) {
      if (!readSet.contains(ch.id)) unread++;
    }
    return unread;
  }

  Future<void> _refreshDynamicUnread() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final favs = List.of(appState.favoriteNovels);
    final Map<String, int> out = {};
    for (final n in favs) {
      try {
        out[n.id] = await _computeUnreadForNovel(n);
      } catch (_) {
        out[n.id] = 0;
      }
    }
    if (!mounted) return;
    setState(() {
      _dynamicUnread.clear();
      _dynamicUnread.addAll(out);
    });
  }

  // badge formatting is handled by ChapterCountBadge

  String _formatTimestamp(String? iso) {
    if (iso == null) return 'never'.translate;
    try {
      final dt = DateTime.tryParse(iso);
      if (dt == null) return iso;
      String two(int n) => n.toString().padLeft(2, '0');
      final d = '${two(dt.day)}/${two(dt.month)}/${dt.year}';
      final t = '${two(dt.hour)}:${two(dt.minute)}';
      return '$d $t';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final favs = List.of(Provider.of<AppState>(context).favoriteNovels)
      ..sort((a, b) => a.title.compareTo(b.title));
    final totalUnread = _dynamicUnread.values.fold<int>(0, (a, b) => a + b);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,

        title: Text('favorites_updates'.translate),
        actions: [
          if (totalUnread > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Chip(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                label: Text('$totalUnread'),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _check,
                icon: const Icon(Icons.refresh),
                label: Text(
                  _loading
                      ? 'checking'.translate
                      : 'check_for_updates'.translate,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final width = constraints.maxWidth;
                  final int columns = width >= 900 ? 3 : (width >= 600 ? 2 : 1);
                  final spacing = 12.0;
                  final cardWidth =
                      (width - (spacing * (columns - 1))) / columns;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children:
                          favs.map((n) {
                            final delta =
                                _dynamicUnread[n.id] ?? _updates[n.id] ?? 0;
                            return SizedBox(
                              width: cardWidth,
                              child: Card(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => NovelDetailScreen(novel: n),
                                      ),
                                    ).then((_) => _refreshDynamicUnread());
                                  },
                                  onLongPress: () {
                                    final lastId = n.lastReadChapterId;
                                    int idx = 0;
                                    if (lastId != null) {
                                      final found = n.chapters.indexWhere(
                                        (c) => c.id == lastId,
                                      );
                                      if (found != -1) idx = found;
                                    }
                                    Navigator.pushNamed(
                                      context,
                                      '/reader',
                                      arguments: {
                                        'novel': n,
                                        'chapterIndex': idx,
                                      },
                                    ).then((_) => _refreshDynamicUnread());
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child:
                                                  n.coverImageUrl.isNotEmpty
                                                      ? Image.network(
                                                        n.coverImageUrl,
                                                        width: 64,
                                                        height: 88,
                                                        fit: BoxFit.cover,
                                                      )
                                                      : Container(
                                                        width: 64,
                                                        height: 88,
                                                        color: Colors.grey,
                                                      ),
                                            ),
                                            if (delta > 0)
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                  ),
                                                  constraints: const BoxConstraints(
                                                      minWidth: 24, maxWidth: 80),
                                                  child: ChapterCountBadge(
                                                    count: delta,
                                                    showPlus: true,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                n.title,
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.titleMedium,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '${'by'.translate} ${n.author}',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${'chapters'.translate}: ${n.lastKnownChapterCount} • ${'last_checked'.translate}: ${_formatTimestamp(n.lastChecked)}',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
