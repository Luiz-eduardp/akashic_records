import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:provider/provider.dart';
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
  bool _loading = false;
  final Map<String, List<String>> _cachedChapters = {};
  final Map<String, int> _dynamicUnread = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshDynamicUnread();
      await _check();
    });
  }

  Future<void> _check() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.checkForUpdates();

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
                            final delta = _dynamicUnread[n.id] ?? 0;
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
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                n.title,
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.titleMedium,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          if (delta > 0) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 64,
                                              height: double.infinity,
                                              decoration: BoxDecoration(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.2),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                (delta > 99) ? '99+' : '$delta',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .onPrimary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
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
