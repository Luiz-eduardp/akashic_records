import 'package:flutter/material.dart';
import 'dart:io';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/i18n/i18n.dart';

class LocalEpubsScreen extends StatefulWidget {
  const LocalEpubsScreen({super.key});

  @override
  State<LocalEpubsScreen> createState() => _LocalEpubsScreenState();
}

class _LocalEpubsScreenState extends State<LocalEpubsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await NovelDatabase.getInstance();
    final list = await db.getAllLocalEpubs();
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Map<String, int> _metrics() {
    final totalEpubs = _items.length;
    var totalChapters = 0;
    for (final it in _items) {
      final ch = it['chapters'] as List<dynamic>?;
      if (ch != null) totalChapters += ch.length;
    }
    return {'epubs': totalEpubs, 'chapters': totalChapters};
  }

  Future<void> _openEpub(Map<String, dynamic> item) async {
    final chapters =
        (item['chapters'] as List<dynamic>)
            .map((c) => Chapter.fromMap(c as Map<String, dynamic>))
            .toList();

    final novel = Novel(
      id: item['id'] as String,
      title: item['title'] as String,
      coverImageUrl: item['coverPath'] as String? ?? '',
      author: item['author'] as String? ?? '',
      description: item['description'] as String? ?? '',
      chapters: chapters,
      pluginId: 'local_epub',
      genres: [],
      isFavorite: false,
    );

    try {
      final db = await NovelDatabase.getInstance();
      final key = 'local_epub_last_${novel.id}';
      final lastId = await db.getSetting(key);
      int idx = 0;
      if (lastId != null && lastId.isNotEmpty) {
        final found = novel.chapters.indexWhere((c) => c.id == lastId);
        if (found != -1) idx = found;
      }
      Navigator.of(
        context,
      ).pushNamed('/reader', arguments: {'novel': novel, 'chapterIndex': idx});
    } catch (e) {
      Navigator.of(
        context,
      ).pushNamed('/reader', arguments: {'novel': novel, 'chapterIndex': 0});
    }
  }

  Future<void> _deleteEpub(
    String id, {
    String? filePath,
    String? coverPath,
  }) async {
    final db = await NovelDatabase.getInstance();
    await db.deleteLocalEpub(id);
    try {
      if (filePath != null && filePath.isNotEmpty) {
        final f = File(filePath);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
    try {
      if (coverPath != null &&
          coverPath.isNotEmpty &&
          !coverPath.startsWith('http')) {
        final cf = File(coverPath);
        if (await cf.exists()) await cf.delete();
      }
    } catch (_) {}
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('local_epubs'.translate)),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? Center(child: Text('local_epubs_empty'.translate))
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_metrics()['epubs']} ${'local_epubs'.translate}',
                        ),
                        Text(
                          '${_metrics()['chapters']} ${'chapters'.translate}',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final cover = (item['coverPath'] as String?) ?? '';
                        return Dismissible(
                          key: Key(item['id'] as String),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (dir) async {
                            final res = await showDialog<bool>(
                              context: context,
                              builder:
                                  (ctx) => AlertDialog(
                                    title: Text(
                                      'confirm_delete_epub_title'.translate,
                                    ),
                                    content: Text(
                                      'confirm_delete_epub_message'.translate,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(ctx).pop(false),
                                        child: Text('confirm_cancel'.translate),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(ctx).pop(true),
                                        child: Text('confirm_delete'.translate),
                                      ),
                                    ],
                                  ),
                            );
                            return res == true;
                          },
                          onDismissed: (_) async {
                            await _deleteEpub(
                              item['id'] as String,
                              filePath: item['filePath'] as String?,
                              coverPath: item['coverPath'] as String?,
                            );
                          },
                          child: ListTile(
                            leading:
                                cover.isNotEmpty
                                    ? (cover.startsWith('http')
                                        ? Image.network(
                                          cover,
                                          width: 48,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (c, e, s) =>
                                                  const SizedBox.shrink(),
                                        )
                                        : Image.file(
                                          File(cover),
                                          width: 48,
                                          height: 64,
                                          fit: BoxFit.cover,
                                        ))
                                    : const SizedBox(width: 48, height: 64),
                            title: Text(item['title'] as String? ?? ''),
                            subtitle: Text(item['author'] as String? ?? ''),
                            onTap: () => _openEpub(item),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () => _openEpub(item),
                                  tooltip: 'open_in_reader'.translate,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (ctx) => AlertDialog(
                                            title: Text(
                                              'confirm_delete_epub_title'
                                                  .translate,
                                            ),
                                            content: Text(
                                              'confirm_delete_epub_message'
                                                  .translate,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.of(
                                                      ctx,
                                                    ).pop(false),
                                                child: Text(
                                                  'confirm_cancel'.translate,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.of(
                                                      ctx,
                                                    ).pop(true),
                                                child: Text(
                                                  'confirm_delete'.translate,
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (confirm == true) {
                                      await _deleteEpub(
                                        item['id'] as String,
                                        filePath: item['filePath'] as String?,
                                        coverPath: item['coverPath'] as String?,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
