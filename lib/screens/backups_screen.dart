import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/services/backup_service.dart';
import 'package:intl/intl.dart';

class BackupsScreen extends StatefulWidget {
  const BackupsScreen({super.key});

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  final BackupService _svc = BackupService();
  List<FileSystemEntity> _backups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _svc.listBackups();
    setState(() {
      _backups = list;
      _loading = false;
    });
  }

  String _fmt(DateTime d) => DateFormat.yMd().add_Hm().format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('backup_manager'.translate)),
        body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _backups.isEmpty
              ? Center(child: Text('no_backups_found'.translate))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _backups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final f = _backups[i];
                    final stat = f.statSync();
                    final name = f.uri.pathSegments.last;
                    final isDb = name.toLowerCase().endsWith('.db');
                    final isJson = name.toLowerCase().endsWith('.json');
                    return Card(
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text('${_fmt(stat.modified)} • ${_readableSize(stat.size)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isDb)
                              TextButton(
                                onPressed: () => _confirmRestoreDb(f.path),
                                child: Text('restore'.translate),
                              ),
                            if (isJson)
                              TextButton(
                                onPressed: () => _confirmImportJson(f.path),
                                child: Text('import'.translate),
                              ),
                            IconButton(
                              icon: const Icon(Icons.file_upload_outlined),
                              onPressed: () async {
                                final exported = await _svc.exportBackup(f.path);
                                if (exported != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('backup_exported'.translate + ': $exported')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('backup_failed'.translate)),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(f.path),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.backup),
        label: Text('create_backup'.translate),
        onPressed: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('backup_in_progress'.translate)),
          );
          try {
            final databasesPath = await getDatabasesPath();
            final dbPath = join(databasesPath, 'akashic_records.db');
            final dbFile = File(dbPath);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('DB: ${dbFile.path} • exists=${await dbFile.exists()}')),
            );
          } catch (_) {}

          final performed = await _svc.performDailyBackup(force: true);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          if (performed) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('backup_created'.translate)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('backup_failed'.translate)));
          }
          await _load();
        },
      ),
    );
  }

  String _readableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _confirmDelete(String path) async {
      final ok = await showDialog<bool>(
    context: context as BuildContext,
    builder: (_) => AlertDialog(
        title: Text('confirm'.translate),
        content: Text('confirm_delete_backup'.translate),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context as BuildContext, false), child: Text('cancel'.translate)),
          ElevatedButton(onPressed: () => Navigator.pop(context as BuildContext, true), child: Text('delete'.translate)),
        ],
      ),
    );
    if (ok == true) {
      await _svc.deleteBackup(path);
      await _load();
    }
  }

  Future<void> _confirmRestoreDb(String path) async {
    final ok = await showDialog<bool>(
      context: context as BuildContext,
      builder: (_) => AlertDialog(
        title: Text('confirm'.translate),
        content: Text('confirm_restore_message'.translate),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context as BuildContext, false), child: Text('cancel'.translate)),
          ElevatedButton(onPressed: () => Navigator.pop(context as BuildContext, true), child: Text('restore'.translate)),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _svc.restoreDatabaseFromFile(path);
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(SnackBar(content: Text('restore_success'.translate)));
      } catch (e) {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(SnackBar(content: Text('backup_failed'.translate)));
      }
    }
  }

  Future<void> _confirmImportJson(String path) async {
    final ok = await showDialog<bool>(
      context: context as BuildContext,
      builder: (_) => AlertDialog(
        title: Text('confirm'.translate),
        content: Text('import_confirm_message'.translate),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context as BuildContext, false), child: Text('cancel'.translate)),
          ElevatedButton(onPressed: () => Navigator.pop(context as BuildContext, true), child: Text('import'.translate)),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _svc.importJsonBackup(path);
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(SnackBar(content: Text('restore_success'.translate)));
        await _load();
      } catch (e) {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(SnackBar(content: Text('backup_failed'.translate)));
      }
    }
  }
}
