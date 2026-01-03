import 'dart:convert';
import 'dart:io';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/models/model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  static const String _dbName = 'akashic_records.db';
  static const String _backupFolder = 'backups';

  Future<Directory> _ensureBackupDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(join(dir.path, _backupFolder));
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    return backupDir;
  }

  String _timestamp() {
    final now = DateTime.now().toIso8601String();
    return now.replaceAll(RegExp(r'[:-]'), '').replaceAll('.', '');
  }

  Future<bool> performDailyBackup({bool force = false}) async {
    final db = await NovelDatabase.getInstance();
    try {
      final last = await db.getSetting('last_backup_date');
      final today = DateTime.now().toIso8601String().split('T').first;
      if (!force && last == today) return false;

      final backupDir = await _ensureBackupDir();

      try {
        final databasesPath = await getDatabasesPath();
        final src = File(join(databasesPath, _dbName));
        if (await src.exists()) {
          final dest = join(
            backupDir.path,
            'akashic_records_${_timestamp()}.db',
          );
          await src.copy(dest);
        }
      } catch (e) {}

      final Map<String, dynamic> out = {};
      try {
        out['settings'] = await db.getAllSettings();
      } catch (_) {}
      try {
        out['local_epubs'] = await db.getAllLocalEpubs();
      } catch (_) {}
      try {
        final novels = await db.getAllNovels();
        out['novels'] = novels.map((n) => n.toMap()).toList();
      } catch (_) {}
      try {
        final pluginStates = await db.getAllPluginStates();
        final Map<String, dynamic> prefs = {};
        for (final id in pluginStates.keys) {
          try {
            final p = await db.getPluginPrefs(id);
            prefs[id] = p;
          } catch (_) {}
        }
        out['plugins'] = {'states': pluginStates, 'prefs': prefs};
      } catch (_) {}

      final jsonFile = File(
        join(backupDir.path, 'backup_${_timestamp()}.json'),
      );
      await jsonFile.writeAsString(jsonEncode(out));

      await db.setSetting(
        'last_backup_date',
        DateTime.now().toIso8601String().split('T').first,
      );
      return true;
    } catch (e) {
      print('performDailyBackup error: $e');
      return false;
    }
  }

  Future<String?> exportBackup(String path) async {
    try {
      final src = File(path);
      if (!await src.exists()) return null;
      final dir = await _ensureBackupDir();
      final exportsDir = Directory(join(dir.path, 'exports'));
      if (!await exportsDir.exists()) await exportsDir.create(recursive: true);
      final name = src.uri.pathSegments.last;
      final destPath = join(exportsDir.path, name);
      await src.copy(destPath);
      return destPath;
    } catch (e) {
      return null;
    }
  }

  Future<List<FileSystemEntity>> listBackups() async {
    final dir = await _ensureBackupDir();
    final list =
        dir.listSync().toList()..sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        );
    return list;
  }

  Future<void> deleteBackup(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {}
  }

  Future<void> restoreDatabaseFromFile(String dbFilePath) async {
    final databasesPath = await getDatabasesPath();
    final dest = join(databasesPath, _dbName);
    try {
      final src = File(dbFilePath);
      if (await src.exists()) {
        await src.copy(dest);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> importJsonBackup(String jsonPath) async {
    final db = await NovelDatabase.getInstance();
    final f = File(jsonPath);
    if (!await f.exists()) return;
    try {
      final content = await f.readAsString();
      final Map<String, dynamic> data =
          jsonDecode(content) as Map<String, dynamic>;
      if (data.containsKey('settings')) {
        final Map<String, dynamic> set = Map<String, dynamic>.from(
          data['settings'] as Map,
        );
        for (final e in set.entries) {
          await db.setSetting(e.key, e.value.toString());
        }
      }
      if (data.containsKey('local_epubs')) {
        final List le = data['local_epubs'] as List;
        for (final it in le) {
          try {
            final m = Map<String, dynamic>.from(it as Map);
            await db.upsertLocalEpub(
              id: m['id'] as String,
              filePath: m['filePath'] as String,
              title: m['title'] as String,
              author: m['author'] as String,
              description: m['description'] as String,
              coverPath: m['coverPath'] as String,
              chapters: List<Map<String, dynamic>>.from(m['chapters'] as List),
              importedAt: m['importedAt'] as String,
            );
          } catch (_) {}
        }
      }
      if (data.containsKey('novels')) {
        final List nv = data['novels'] as List;
        for (final it in nv) {
          try {
            final m = Map<String, dynamic>.from(it as Map);
            final novel = Novel.fromMap(m);
            await db.upsertNovel(novel);
          } catch (_) {}
        }
      }
      if (data.containsKey('plugins')) {
        try {
          final plugins = Map<String, dynamic>.from(data['plugins'] as Map);
          final states = Map<String, dynamic>.from(
            plugins['states'] as Map? ?? {},
          );
          final prefs = Map<String, dynamic>.from(
            plugins['prefs'] as Map? ?? {},
          );
          for (final id in states.keys) {
            await db.setPluginEnabled(
              id,
              (states[id] as int) == 1 || states[id] == true,
            );
          }
          for (final id in prefs.keys) {
            final p = prefs[id];
            if (p != null) {
              await db.setPluginPrefs(id, Map<String, dynamic>.from(p as Map));
            }
          }
        } catch (_) {}
      }
    } catch (e) {}
  }
}
