import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/novel_detail_screen.dart';
import 'package:akashic_records/db/novel_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalWordsRead = 0;
  int _totalChaptersRead = 0;
  AppState? _appStateRef;

  Future<void> _loadStats() async {
    final appState = _appStateRef;
    if (appState == null) return;
    final db = await NovelDatabase.getInstance();
    int words = 0;
    int chapters = 0;
    for (final novel in appState.localNovels) {
      final readSet = await db.getReadChaptersForNovel(novel.id);
      chapters += readSet.length;
      for (final ch in novel.chapters) {
        if (readSet.contains(ch.id) &&
            ch.content != null &&
            ch.content!.trim().isNotEmpty) {
          final text = ch.content!.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
          final cnt =
              text
                  .split(RegExp(r'\s+'))
                  .where((w) => w.trim().isNotEmpty)
                  .length;
          words += cnt;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _totalWordsRead = words;
      _totalChaptersRead = chapters;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appStateRef = Provider.of<AppState>(context, listen: false);
      _loadStats();
      _appStateRef?.addListener(_loadStats);
    });
  }

  @override
  void dispose() {
    try {
      _appStateRef?.removeListener(_loadStats);
      _appStateRef = null;
    } catch (_) {}
    super.dispose();
  }

  int _chapterIndexForNovel(Novel novel) {
    final lastId = novel.lastReadChapterId;
    if (lastId == null) return 0;
    final idx = novel.chapters.indexWhere((c) => c.id == lastId);
    if (idx == -1) return 0;
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final favorites = appState.favoriteNovels;

    return Scaffold(
      appBar: AppBar(title: Text('app_title'.translate)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'words_read'.translate,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$_totalWordsRead',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'chapters_read'.translate,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$_totalChaptersRead',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'favorites'.translate,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${favorites.length}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (favorites.isNotEmpty) ...[
              Text(
                'favorites'.translate,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (ctx, i) {
                    final Novel n = favorites[i];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NovelDetailScreen(novel: n),
                          ),
                        );
                      },
                      onLongPress: () {
                        final idx = _chapterIndexForNovel(n);
                        Navigator.pushNamed(
                          context,
                          '/reader',
                          arguments: {'novel': n, 'chapterIndex': idx},
                        );
                      },
                      child: SizedBox(
                        width: 110,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child:
                                    n.coverImageUrl.isNotEmpty
                                        ? Image.network(
                                          n.coverImageUrl,
                                          width: 110,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => Container(
                                                color: Colors.grey,
                                                width: 110,
                                                height: 120,
                                              ),
                                        )
                                        : Container(
                                          color: Colors.grey,
                                          width: 110,
                                        ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              n.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: favorites.length,
                ),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              'last_novels'.translate,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  appState.localNovels.isEmpty
                      ? Center(child: Text('no_novels_stored'.translate))
                      : ListView.builder(
                        itemCount: appState.localNovels.length,
                        itemBuilder: (context, index) {
                          final Novel novel = appState.localNovels[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child:
                                  novel.coverImageUrl.isNotEmpty
                                      ? Image.network(
                                        novel.coverImageUrl,
                                        width: 48,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => Container(
                                              width: 48,
                                              height: 64,
                                              color: Colors.grey,
                                            ),
                                      )
                                      : Container(
                                        width: 48,
                                        height: 64,
                                        color: Colors.grey,
                                      ),
                            ),
                            title: Text(novel.title),
                            subtitle: Text(novel.author),
                            onTap: () {
                              final idx = _chapterIndexForNovel(novel);
                              Navigator.pushNamed(
                                context,
                                '/reader',
                                arguments: {
                                  'novel': novel,
                                  'chapterIndex': idx,
                                },
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/plugins');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
