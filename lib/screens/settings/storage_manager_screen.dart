import 'package:flutter/material.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'dart:math' as math;

class StorageManagerScreen extends StatefulWidget {
  const StorageManagerScreen({super.key});

  @override
  State<StorageManagerScreen> createState() => _StorageManagerScreenState();
}

class _StorageManagerScreenState extends State<StorageManagerScreen> {
  List<Novel> _novels = [];
  final Map<String, Set<String>> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = await NovelDatabase.getInstance();
    final all = await db.getAllNovels();
    for (final n in all) {
      _selected.putIfAbsent(n.id, () => <String>{});
    }
    setState(() {
      _novels = all;
      _loading = false;
    });
  }

  void _toggleSelection(String novelId, String chapterId) {
    final set = _selected.putIfAbsent(novelId, () => <String>{});
    if (set.contains(chapterId))
      set.remove(chapterId);
    else
      set.add(chapterId);
    setState(() {});
  }

  Future<void> _deleteSelected() async {
    int tot = 0;
    for (final n in _novels) {
      final sel = _selected[n.id];
      if (sel == null || sel.isEmpty) continue;
      for (final c in n.chapters) {
        if (sel.contains(c.id) &&
            c.content != null &&
            c.content!.trim().isNotEmpty)
          tot++;
      }
    }
    if (tot == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('storage_manager_empty'.translate)),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('confirm'.translate),
            content: Text(
              '${'storage_manager_sub'.translate}\n\n${'delete_selected'.translate}: $tot',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('cancel'.translate),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('confirm'.translate),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    final db = await NovelDatabase.getInstance();
    int deleted = 0;
    for (final n in _novels) {
      final sel = _selected[n.id];
      if (sel == null || sel.isEmpty) continue;
      bool changed = false;
      for (final c in n.chapters) {
        if (sel.contains(c.id) &&
            c.content != null &&
            c.content!.trim().isNotEmpty) {
          c.content = '';
          deleted++;
          changed = true;
        }
      }
      if (changed) await db.upsertNovel(n);
      _selected[n.id] = <String>{};
    }
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'storage_manager_deleted'.translate +
              (deleted > 0 ? ' ($deleted)' : ''),
        ),
      ),
    );
  }

  Future<void> _clearNovelStorage(Novel novel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('confirm'.translate),
            content: Text(
              '${'storage_manager_sub'.translate}\n\n${novel.title}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('cancel'.translate),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('confirm'.translate),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    final db = await NovelDatabase.getInstance();
    int count = 0;
    for (final ch in novel.chapters) {
      if (ch.content != null && ch.content!.trim().isNotEmpty) {
        ch.content = '';
        count++;
      }
    }
    await db.upsertNovel(novel);
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'storage_manager_deleted'.translate + (count > 0 ? ' ($count)' : ''),
        ),
      ),
    );
  }

  Future<void> _deleteSelectedForNovel(Novel novel) async {
    final toDelete = _selected[novel.id];
    if (toDelete == null || toDelete.isEmpty) return;
    final db = await NovelDatabase.getInstance();
    for (final ch in novel.chapters) {
      if (toDelete.contains(ch.id)) ch.content = '';
    }
    await db.upsertNovel(novel);
    await _load();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('storage_manager_deleted'.translate)),
    );
  }

  void _openChaptersModal(BuildContext context, Novel novel) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(novel.title),
          content: SizedBox(
            width: double.maxFinite,
            height: math.min(480, MediaQuery.of(context).size.height * 0.7),
            child: ListView.builder(
              itemCount: novel.chapters.length,
              itemExtent: 56,
              itemBuilder: (cctx, idx) {
                final ch = novel.chapters[idx];
                final sel = _selected[novel.id]?.contains(ch.id) ?? false;
                final hasContent =
                    ch.content != null && ch.content!.trim().isNotEmpty;
                return ListTile(
                  dense: true,
                  leading: Checkbox(
                    value: sel,
                    onChanged:
                        (_) =>
                            setState(() => _toggleSelection(novel.id, ch.id)),
                  ),
                  title: Text(
                    ch.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing:
                      hasContent
                          ? const Icon(Icons.download_done, size: 18)
                          : const SizedBox.shrink(),
                  onTap:
                      () => setState(() => _toggleSelection(novel.id, ch.id)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _selected[novel.id] = <String>{};
                setState(() {});
              },
              child: Text('clear_selection'.translate),
            ),
            ElevatedButton(
              onPressed: () => _deleteSelectedForNovel(novel),
              child: Text('delete_selected'.translate),
            ),
          ],
        );
      },
    );
  }

  bool _anySelected() {
    for (final s in _selected.values) if (s.isNotEmpty) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('storage_manager_title'.translate),
        actions: [
          IconButton(
            tooltip: 'select_all'.translate,
            icon: const Icon(Icons.select_all),
            onPressed: () {
              for (final n in _novels) {
                _selected[n.id] = n.chapters.map((c) => c.id).toSet();
              }
              setState(() {});
            },
          ),
          IconButton(
            tooltip: 'clear_selection'.translate,
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              for (final k in _selected.keys) _selected[k] = <String>{};
              setState(() {});
            },
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _novels.isEmpty
              ? Center(child: Text('storage_manager_empty'.translate))
              : ListView.builder(
                itemCount: _novels.length,
                itemBuilder: (ctx, i) {
                  final n = _novels[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(n.title),
                      subtitle: Text(
                        '${n.author} • ${n.numberOfChapters} ${'chapters_short'.translate}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'storage_manager_sub'.translate,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _clearNovelStorage(n),
                          ),
                          TextButton(
                            child: Text('details'.translate),
                            onPressed: () => _openChaptersModal(context, n),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _anySelected() ? _deleteSelected : null,
                icon: const Icon(Icons.delete),
                label: Text('delete_selected'.translate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
