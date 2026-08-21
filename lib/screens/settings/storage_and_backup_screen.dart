import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/services/backup_service.dart';
import 'package:akashic_records/widgets/m3e/m3e_app_bar.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class StorageAndBackupScreen extends StatefulWidget {
  const StorageAndBackupScreen({super.key});

  @override
  State<StorageAndBackupScreen> createState() => _StorageAndBackupScreenState();
}

class _StorageAndBackupScreenState extends State<StorageAndBackupScreen> {
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

  String _readableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _exportDatabaseToDocuments() async {
    final path = await _svc.exportDatabaseToDocuments();
    if (mounted) {
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('db_exported_success'.translateParams({'path': path}))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('db_export_failed'.translate)),
        );
      }
    }
  }

  Future<void> _createBackup() async {
    final success = await _svc.performDailyBackup(force: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'backup_created'.translate : 'backup_failed'.translate,
          ),
        ),
      );
      _load();
    }
  }

  Future<void> _confirmDelete(String path) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('confirm_delete_title'.translate),
        content: Text('confirm_delete_backup_msg'.translate),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.translate),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('delete'.translate),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _svc.deleteBackup(path);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: M3EAppBar(
        title: 'storage_and_backup_title'.translate,
        subtitle: 'storage_and_backup_sub'.translate,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sd_storage_rounded, color: colorScheme.onPrimaryContainer),
                        const SizedBox(width: 10),
                        Text(
                          'android_direct_export'.translate,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'android_export_desc'.translate,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _exportDatabaseToDocuments,
                      icon: const Icon(Icons.folder_special_rounded),
                      label: Text('export_db_to_documents'.translate),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'local_backups'.translate} (${_backups.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _createBackup,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('new_backup'.translate),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _loading
                ? const Center(child: CircularProgressIndicator())
                : _backups.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'no_local_backups'.translate,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _backups.length,
                        itemBuilder: (ctx, i) {
                          final f = _backups[i];
                          final stat = f.statSync();
                          final name = f.uri.pathSegments.last;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Icon(
                                name.endsWith('.db')
                                    ? Icons.storage_rounded
                                    : Icons.code_rounded,
                              ),
                              title: Text(name),
                              subtitle: Text(
                                '${_fmt(stat.modified)} • ${_readableSize(stat.size)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () => _confirmDelete(f.path),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
