import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/widgets/safe_network_image.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'dart:async';

class OfflineLibraryScreen extends StatefulWidget {
  const OfflineLibraryScreen({super.key});

  @override
  State<OfflineLibraryScreen> createState() => _OfflineLibraryScreenState();
}

class _OfflineLibraryScreenState extends State<OfflineLibraryScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  Future<List<Map<String, dynamic>>> _load() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final novels = appState.localNovels;
    final List<Map<String, dynamic>> out = [];
    for (final n in novels) {
      try {
        final saved = await appState.getSavedChaptersForNovel(n.id);
        if (saved.isNotEmpty) {
          out.add({'novel': n, 'saved': saved});
        }
      } catch (_) {}
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('offline_library'.translate),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'no_offline_chapters'.translate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (c, i) {
              final novel = items[i]['novel'] as Novel;
              final saved = items[i]['saved'] as List<dynamic>;
              
              return RepaintBoundary(
                child: _OfflineNovelCard(
                  novel: novel,
                  saved: saved,
                  onDelete: () => setState(() => _future = _load()),
                  onDeleteAll: () => setState(() => _future = _load()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OfflineNovelCard extends StatefulWidget {
  final Novel novel;
  final List<dynamic> saved;
  final VoidCallback onDelete;
  final VoidCallback onDeleteAll;

  const _OfflineNovelCard({
    required this.novel,
    required this.saved,
    required this.onDelete,
    required this.onDeleteAll,
  });

  @override
  State<_OfflineNovelCard> createState() => _OfflineNovelCardState();
}

class _OfflineNovelCardState extends State<_OfflineNovelCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final totalSize = widget.saved.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ExpansionTile(
        onExpansionChanged: (value) {
          setState(() => _isExpanded = value);
        },
        leading: _buildCoverImage(),
        title: Text(widget.novel.title),
        subtitle: Text('$totalSize ${'chapters_saved'.translate}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete_all') {
              _showDeleteAllConfirm(context, widget.novel);
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'delete_all',
              child: Row(
                children: const [
                  Icon(Icons.delete_outline, size: 20),
                  SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
        children: [
          if (_isExpanded)
            SizedBox(
              height: 300,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.saved.length,
                      itemBuilder: (c, idx) {
                        return _buildChapterTile(context, idx);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: _onStartReading,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow, size: 18),
                            const SizedBox(width: 8),
                            Text('start_reading'.translate),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    if (widget.novel.coverImageUrl.isEmpty) {
      return Container(
        width: 48,
        height: 64,
        color: Colors.grey[300],
        child: const Icon(Icons.book),
      );
    }
    return SafeNetworkImage(
      url: widget.novel.coverImageUrl,
      width: 48,
      height: 64,
      fit: BoxFit.cover,
    );
  }

  Widget _buildChapterTile(BuildContext context, int idx) {
    final ch = widget.saved[idx];
    final chapterId = ch['chapterId'] as String;
    final title = ch['title'] as String? ?? 'Chapter $idx';
    final chapterNum = idx + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#$chapterNum',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => _showDeleteConfirm(
              context,
              widget.novel,
              chapterId,
              title,
            ),
            tooltip: 'delete'.translate,
          ),
        ],
      ),
    );
  }

  Future<void> _onStartReading() async {
    final absIdx = widget.novel.chapters.indexWhere(
      (c) => c.id == widget.saved.first['chapterId'],
    );
    final openIdx = absIdx >= 0 ? absIdx : 0;

    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final savedChapter = await appState.getSavedChapter(
        widget.novel.id,
        widget.saved.first['chapterId'] as String,
      );
      if (savedChapter != null) {
        if (openIdx >= 0 && openIdx < widget.novel.chapters.length) {
          widget.novel.chapters[openIdx].content =
              savedChapter['content'] as String?;
        }
      }
    } catch (_) {}

    if (mounted) {
      Navigator.pushNamed(
        context,
        '/reader',
        arguments: {
          'novel': widget.novel,
          'chapterIndex': openIdx,
        },
      );
    }
  }

  void _showDeleteConfirm(
    BuildContext context,
    Novel novel,
    String chapterId,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deletar "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.translate),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.deleteSavedChapter(novel.id, chapterId);
              widget.onDelete();
              if (mounted) {
                setState(() {});
              }
            },
            child: Text('delete'.translate),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirm(BuildContext context, Novel novel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deletar todos os capítulos salvos de "${novel.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.translate),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = await NovelDatabase.getInstance();
              final saved = await Provider.of<AppState>(context, listen: false)
                  .getSavedChaptersForNovel(novel.id);
              for (final ch in saved) {
                await db.deleteSavedChapter(
                  novel.id,
                  ch['chapterId'] as String,
                );
              }
              widget.onDeleteAll();
            },
            child: Text('delete'.translate),
          ),
        ],
      ),
    );
  }
}
