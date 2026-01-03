import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:akashic_records/services/epub_import_service.dart';
import 'package:akashic_records/services/backup_service.dart';
import 'package:akashic_records/widgets/home_stats_grid.dart';
import 'package:akashic_records/widgets/home_quick_actions.dart';
import 'package:akashic_records/widgets/favorites_carousel.dart';
import 'package:akashic_records/widgets/recent_read_list.dart';

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
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _setupInitialData();
  }

  void _setupInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appStateRef = Provider.of<AppState>(context, listen: false);
      _loadStats();
      _appStateRef?.addListener(_loadStats);
      _runBackup();
    });
  }

  Future<void> _runBackup() async {
    try {
      final svc = BackupService();
      final performed = await svc.performDailyBackup();
      if (performed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('backup_created'.translate),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

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
            ch.content!.isNotEmpty) {
          final text = ch.content!.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
          words +=
              text
                  .split(RegExp(r'\s+'))
                  .where((w) => w.trim().isNotEmpty)
                  .length;
        }
      }

      for (var i = 0; i < novel.chapters.length; i++) {
        if (readSet.contains(novel.chapters[i].id)) {
          recent.add({
            'novel': novel,
            'chapter': novel.chapters[i],
            'index': i,
          });
        }
      }
    }

    final localEpubs = await db.getAllLocalEpubs();
    int chaptersTotal = 0;
    for (final it in localEpubs) {
      final ch = it['chapters'] as List?;
      if (ch != null) chaptersTotal += ch.length;
    }

    if (!mounted) return;
    setState(() {
      _totalWordsRead = words;
      _totalChaptersRead = chapters;
      _localEpubCount = localEpubs.length;
      _localEpubChapters = chaptersTotal;
      _recentReadChapters = recent.reversed.toList();
    });
  }

  @override
  void dispose() {
    _appStateRef?.removeListener(_loadStats);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              centerTitle: true,
              title: Text(
                'app_title'.translate,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeStatsGrid(
                      totalWordsRead: _totalWordsRead,
                      totalChaptersRead: _totalChaptersRead,
                      favoritesCount: appState.favoriteNovels.length,
                    ),
                    const SizedBox(height: 24),
                    HomeQuickActions(
                      localEpubCount: _localEpubCount,
                      localEpubChapters: _localEpubChapters,
                    ),
                    const SizedBox(height: 24),
                    if (appState.favoriteNovels.isNotEmpty) ...[
                      _buildSectionTitle('favorites'.translate),
                      FavoritesCarousel(favorites: appState.favoriteNovels),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionTitle('last_novels'.translate),
                    RecentReadList(
                      recentReadChapters: _recentReadChapters,
                      onOpenReader: (novel, idx) => _openReader(novel, idx),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Builder(
        builder: (ctx) {
          final bottomPad =
              kBottomNavigationBarHeight +
              MediaQuery.of(ctx).padding.bottom +
              20.0;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomPad, right: 16.0),
            child: FloatingActionButton(
              onPressed: _importEpub,
              tooltip: 'import_epub'.translate,
              child:
                  _importing
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.add_link),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  void _openReader(Novel novel, int index) {
    Navigator.pushNamed(
      context,
      '/reader',
      arguments: {'novel': novel, 'chapterIndex': index},
    );
  }

  Future<void> _importEpub() async {
    if (_importing) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );
      if (result == null || result.files.isEmpty) return;

      final path = result.files.first.path;
      if (path == null) return;

      setState(() => _importing = true);

      final novel = await EpubImportService().importFromFile(path);
      if (novel != null) {
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
        if (mounted) Navigator.pushNamed(context, '/local_epubs');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('failed_to_import_epub'.translate)),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }
}
