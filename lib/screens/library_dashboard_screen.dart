import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/services/epub_import_service.dart';
import 'package:akashic_records/widgets/m3e/m3e_app_bar.dart';
import 'package:akashic_records/widgets/m3e/m3e_card.dart';
import 'package:akashic_records/widgets/m3e/m3e_menu_button.dart';
import 'package:akashic_records/widgets/m3e/m3e_responsive_grid.dart';

enum LibraryViewTab { all, favorites, offline }

class LibraryDashboardScreen extends StatefulWidget {
  const LibraryDashboardScreen({super.key});

  @override
  State<LibraryDashboardScreen> createState() => _LibraryDashboardScreenState();
}

class _LibraryDashboardScreenState extends State<LibraryDashboardScreen> {
  LibraryViewTab _selectedTab = LibraryViewTab.all;
  String _formatFilter = 'all';
  List<Map<String, dynamic>> _localDocs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final db = await NovelDatabase.getInstance();
      final docs = await db.getAllLocalEpubs();
      if (mounted) {
        setState(() {
          _localDocs = docs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importFile() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'mobi', 'pdf', 'cbz', 'cbr', 'txt'],
      );
      if (res != null && res.files.single.path != null) {
        final filePath = res.files.single.path!;
        final ext = filePath.split('.').last.toLowerCase();

        final importSvc = EpubImportService();
        final novel = await importSvc.importFromFile(filePath);
        if (novel != null) {
          final db = await NovelDatabase.getInstance();
          await db.upsertLocalEpub(
            id: novel.id,
            filePath: filePath,
            title: novel.title,
            author: novel.author,
            description: novel.description,
            coverPath: novel.coverImageUrl,
            chapters: novel.chapters.map((c) => c.toMap()).toList(),
            importedAt: DateTime.now().toIso8601String(),
            format: ext,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('item_imported'.translateParams({'format': ext.toUpperCase(), 'title': novel.title}))),
            );
          }
          await _loadData();
          await appState.refreshLocalNovels();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'import_error'.translate}: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getDisplayItems(AppState appState) {
    if (_selectedTab == LibraryViewTab.favorites) {
      return appState.favoriteNovels.map((n) {
        return {
          'id': n.id,
          'title': n.title,
          'author': n.author,
          'coverPath': n.coverImageUrl,
          'format': 'novel',
          'isFavorite': true,
          'novel': n,
        };
      }).toList();
    }

    if (_selectedTab == LibraryViewTab.offline) {
      return _localDocs.where((doc) {
        final ch = doc['chapters'] as List?;
        return ch != null && ch.isNotEmpty;
      }).toList();
    }

    final combined = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (final doc in _localDocs) {
      final id = doc['id'] as String;
      seenIds.add(id);
      combined.add(doc);
    }

    for (final fav in appState.favoriteNovels) {
      if (!seenIds.contains(fav.id)) {
        seenIds.add(fav.id);
        combined.add({
          'id': fav.id,
          'title': fav.title,
          'author': fav.author,
          'coverPath': fav.coverImageUrl,
          'format': fav.pluginId == 'local_doc' ? 'epub' : 'novel',
          'isFavorite': true,
          'novel': fav,
        });
      }
    }

    var items = combined;
    if (_formatFilter != 'all') {
      items = items.where((it) {
        final fmt = (it['format'] as String? ?? 'epub').toLowerCase();
        if (_formatFilter == 'manga') {
          return fmt == 'cbz' || fmt == 'cbr';
        }
        return fmt == _formatFilter;
      }).toList();
    }
    return items;
  }

  Future<void> _openDocument(Map<String, dynamic> item) async {
    if (item.containsKey('novel') && item['novel'] is Novel) {
      final novel = item['novel'] as Novel;
      await Navigator.of(context).pushNamed(
        '/reader',
        arguments: {'novel': novel, 'chapterIndex': 0},
      );
      await _loadData();
      return;
    }

    final chapters = (item['chapters'] as List<dynamic>?)
            ?.map((c) => Chapter.fromMap(c as Map<String, dynamic>))
            .toList() ??
        [];

    final novel = Novel(
      id: item['id'] as String,
      title: item['title'] as String,
      coverImageUrl: item['coverPath'] as String? ?? '',
      author: item['author'] as String? ?? '',
      description: item['description'] as String? ?? '',
      chapters: chapters,
      pluginId: 'local_doc',
      genres: [item['format'] as String? ?? 'epub'],
      isFavorite: false,
    );

    await Navigator.of(context).pushNamed(
      '/reader',
      arguments: {'novel': novel, 'chapterIndex': 0},
    );
    await _loadData();
  }

  Future<void> _deleteDocument(String id, {String? filePath, String? coverPath}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('remove_document_title'.translate),
        content: Text('remove_document_confirm'.translate),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.translate),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('remove'.translate),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await NovelDatabase.getInstance();
      await db.deleteLocalEpub(id);
      try {
        if (filePath != null && filePath.isNotEmpty) {
          final f = File(filePath);
          if (await f.exists()) await f.delete();
        }
      } catch (_) {}
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appState = context.watch<AppState>();
    final items = _getDisplayItems(appState);

    final docCount = _localDocs.length;
    final favCount = appState.favoriteNovels.length;

    final docsText = docCount == 1
        ? 'document_singular'.translate
        : 'documents_count'.translateParams({'count': docCount});

    final favsText = favCount == 1
        ? 'favorite_singular'.translate
        : 'favorites_count'.translateParams({'count': favCount});

    final statsSubtitle = 'stats_subtitle'.translateParams({
      'docs': docsText,
      'favs': favsText,
    });

    return Scaffold(
      appBar: M3EAppBar(
        title: 'akashic_reader'.translate,
        subtitle: statsSubtitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: M3ESegmentedMenu<LibraryViewTab>(
                    selectedValue: _selectedTab,
                    options: {
                      LibraryViewTab.all: 'bookshelf_tab'.translate,
                      LibraryViewTab.favorites: 'favorites_tab'.translate,
                      LibraryViewTab.offline: 'offline_tab'.translate,
                    },
                    icons: const {
                      LibraryViewTab.all: Icons.local_library_rounded,
                      LibraryViewTab.favorites: Icons.favorite_rounded,
                      LibraryViewTab.offline: Icons.offline_pin_rounded,
                    },
                    onSelected: (tab) {
                      setState(() => _selectedTab = tab);
                    },
                  ),
                ),
              ],
            ),
          ),

          if (_selectedTab == LibraryViewTab.all)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all'.translate, 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('EPUB', 'epub'),
                    const SizedBox(width: 8),
                    _buildFilterChip('MOBI', 'mobi'),
                    const SizedBox(width: 8),
                    _buildFilterChip('PDF', 'pdf'),
                    const SizedBox(width: 8),
                    _buildFilterChip('manga_cbz'.translate, 'manga'),
                  ],
                ),
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedTab == LibraryViewTab.favorites
                                  ? Icons.favorite_border_rounded
                                  : Icons.library_books_outlined,
                              size: 72,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedTab == LibraryViewTab.favorites
                                  ? 'no_favorites_added'.translate
                                  : _selectedTab == LibraryViewTab.offline
                                      ? 'no_offline_content'.translate
                                      : 'empty_library'.translate,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _importFile,
                              icon: const Icon(Icons.add),
                              label: Text('import_ebook_or_pdf'.translate),
                            ),
                          ],
                        ),
                      )
                    : M3EResponsiveGrid(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 140.0),
                        itemCount: items.length,
                        itemBuilder: (ctx, index) {
                          final item = items[index];
                          final id = item['id'] as String;
                          final title = item['title'] as String;
                          final author = item['author'] as String? ?? '';
                          final cover = item['coverPath'] as String?;
                          final format = item['format'] as String? ?? 'epub';
                          final filePath = item['filePath'] as String?;

                          final progress = (item['progressPercent'] as num?)?.toDouble() ?? 0.0;

                          return M3EDocumentCard(
                            title: title,
                            author: author,
                            coverPath: cover,
                            format: format,
                            progressPercent: progress,
                            onTap: () => _openDocument(item),
                            onLongPress: () => _deleteDocument(
                              id,
                              filePath: filePath,
                              coverPath: cover,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96.0),
        child: FloatingActionButton.extended(
          onPressed: _importFile,
          icon: const Icon(Icons.note_add_rounded),
          label: Text('import_button'.translate),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _formatFilter == value;
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withOpacity(0.4),
        width: 1,
      ),
      onSelected: (_) => setState(() => _formatFilter = value),
    );
  }
}
