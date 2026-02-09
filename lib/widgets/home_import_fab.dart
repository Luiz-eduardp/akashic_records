import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:file_picker/file_picker.dart';
import 'package:akashic_records/services/epub_import_service.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/models/model.dart';

typedef OnImportSuccess = void Function(Novel novel);
typedef OnImportError = void Function(String error);

class HomeImportFab extends StatefulWidget {
  final OnImportSuccess onSuccess;
  final OnImportError onError;
  final VoidCallback? onImportStart;
  final VoidCallback? onImportEnd;

  const HomeImportFab({
    super.key,
    required this.onSuccess,
    required this.onError,
    this.onImportStart,
    this.onImportEnd,
  });

  @override
  State<HomeImportFab> createState() => _HomeImportFabState();
}

class _HomeImportFabState extends State<HomeImportFab> {
  bool _importing = false;

  Future<void> _handleImport() async {
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
      widget.onImportStart?.call();

      final novel = await EpubImportService().importFromFile(path);
      if (novel != null && mounted) {
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
        widget.onSuccess(novel);
      }
    } catch (e) {
      widget.onError('failed_to_import_epub'.translate);
    } finally {
      if (mounted) {
        setState(() => _importing = false);
        widget.onImportEnd?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = kBottomNavigationBarHeight +
        MediaQuery.of(context).padding.bottom +
        20.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad, right: 16.0),
      child: FloatingActionButton(
        onPressed: _handleImport,
        tooltip: 'import_epub'.translate,
        child: _importing
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
  }
}
