import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/novel_detail_screen.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:akashic_records/services/epub_import_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalWordsRead = 0;
  int _totalChaptersRead = 0;
  int _localEpubCount = 0;
  int _localEpubChapters = 0;
  List<Map<String, dynamic>> _recentReadChapters = [];
  AppState? _appStateRef;

  Future<void> _loadStats() async {
    final appState = _appStateRef;
    if (appState == null) return;
    final db = await NovelDatabase.getInstance();
    int words = 0;
    int chapters = 0;
    final recent = <Map<String, dynamic>>[];
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
      for (var i = 0; i < novel.chapters.length; i++) {
        final ch = novel.chapters[i];
        if (readSet.contains(ch.id)) {
          recent.add({'novel': novel, 'chapter': ch, 'index': i});
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _totalWordsRead = words;
      _totalChaptersRead = chapters;
    });
    try {
      final db = await NovelDatabase.getInstance();
      final list = await db.getAllLocalEpubs();
      var chaptersTotal = 0;
      for (final it in list) {
        final ch = it['chapters'] as List<dynamic>?;
        if (ch != null) chaptersTotal += ch.length;
      }
      if (!mounted) return;
      setState(() {
        _localEpubCount = list.length;
        _localEpubChapters = chaptersTotal;
      });
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _recentReadChapters = recent.reversed.toList();
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
    final displayedFavorites = List<Novel>.from(favorites)..shuffle();

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text('app_title'.translate)),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('local_epubs'.translate),
                        const SizedBox(height: 8),
                        Text(
                          '$_localEpubCount ${'local_epubs'.translate}, $_localEpubChapters ${'chapters'.translate}',
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed:
                          () => Navigator.pushNamed(context, '/local_epubs'),
                      child: Text('local_epubs'.translate),
                    ),
                  ],
                ),
              ),
            ),

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
                    final Novel n = displayedFavorites[i];
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
                  itemCount: displayedFavorites.length,
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
                  _recentReadChapters.isEmpty
                      ? Center(child: Text('no_novels_stored'.translate))
                      : ListView.separated(
                        itemCount: _recentReadChapters.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        padding: const EdgeInsets.only(bottom: 120),
                        itemBuilder: (context, index) {
                          final entry = _recentReadChapters[index];
                          final Novel novel = entry['novel'] as Novel;
                          final chapter = entry['chapter'] as Chapter;
                          final chapIndex = entry['index'] as int;
                          return Card(
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child:
                                    novel.coverImageUrl.isNotEmpty
                                        ? Image.network(
                                          novel.coverImageUrl,
                                          width: 64,
                                          height: 84,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => Container(
                                                width: 64,
                                                height: 84,
                                                color: Colors.grey,
                                              ),
                                        )
                                        : Container(
                                          width: 64,
                                          height: 84,
                                          color: Colors.grey,
                                        ),
                              ),
                              title: Text(novel.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(chapter.title),
                                  const SizedBox(height: 4),
                                  Text(
                                    novel.author,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/reader',
                                  arguments: {
                                    'novel': novel,
                                    'chapterIndex': chapIndex,
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['epub'],
            );
            if (result == null || result.files.isEmpty) return;
            final path = result.files.first.path;
            if (path == null) return;
            final scaffold = ScaffoldMessenger.of(context);
            scaffold.showSnackBar(
              SnackBar(content: Text('importing_epub'.translate)),
            );

            final svc = EpubImportService();
            final novel = await svc.importFromFile(path);
            if (novel == null) {
              scaffold.showSnackBar(
                SnackBar(content: Text('failed_to_import_epub'.translate)),
              );
              return;
            }

            final db = await NovelDatabase.getInstance();
            await db.upsertLocalEpub(
              id: novel.id,
              filePath: path,
              title: novel.title,
              author: novel.author,
              description: novel.description,
              coverPath: novel.coverImageUrl,
              chapters: novel.chapters.map((c) => c.toMap()).toList(),
              importedAt: DateTime.now().toIso8601String(),
            );

            scaffold.showSnackBar(
              SnackBar(content: Text('import_success'.translate)),
            );

            Navigator.pushNamed(context, '/local_epubs');
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('failed_to_import_epub'.translate)),
            );
          }
        },
        child: const Icon(Icons.file_open),
      ),
    );
  }
}
