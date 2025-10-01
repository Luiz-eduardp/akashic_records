import 'dart:async';
import 'dart:convert';
import 'package:akashic_records/models/model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class NovelDatabase {
  static final NovelDatabase _instance = NovelDatabase._internal();
  static Database? _database;

  NovelDatabase._internal();

  static Future<NovelDatabase> getInstance() async {
    if (_database == null) {
      await _instance._initDb();
    }
    return _instance;
  }

  Future<void> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'akashic_records.db');
    _database = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
            CREATE TABLE IF NOT EXISTS novels (
              id TEXT PRIMARY KEY,
              pluginId TEXT,
              title TEXT,
              coverImageUrl TEXT,
              author TEXT,
              description TEXT,
              genres TEXT,
              status INTEGER,
              shouldShowNumberOfChapters INTEGER,
              chapters TEXT,
              isFavorite INTEGER DEFAULT 0,
              lastChecked TEXT,
              lastKnownChapterCount INTEGER DEFAULT 0,
              lastReadChapterId TEXT
            )
          ''');
        await db.execute('''
              CREATE TABLE IF NOT EXISTS plugins (
                id TEXT PRIMARY KEY,
                enabled INTEGER DEFAULT 1,
                prefs TEXT
              )
            ''');
        await db.execute('''
              CREATE TABLE IF NOT EXISTS local_epubs (
                id TEXT PRIMARY KEY,
                filePath TEXT,
                title TEXT,
                author TEXT,
                description TEXT,
                coverPath TEXT,
                chapters TEXT,
                importedAt TEXT
              )
            ''');
        await db.execute('''
              CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT
              )
            ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE novels ADD COLUMN isFavorite INTEGER DEFAULT 0',
          );
          await db.execute('ALTER TABLE novels ADD COLUMN lastChecked TEXT');
          await db.execute(
            'ALTER TABLE novels ADD COLUMN lastKnownChapterCount INTEGER DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE novels ADD COLUMN lastReadChapterId TEXT',
          );
        }
        if (oldVersion < 3) {
          await db.execute('''
              CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT
              )
            ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
              CREATE TABLE IF NOT EXISTS local_epubs (
                id TEXT PRIMARY KEY,
                filePath TEXT,
                title TEXT,
                author TEXT,
                description TEXT,
                coverPath TEXT,
                chapters TEXT,
                importedAt TEXT
              )
            ''');
        }
      },
    );
  }

  Future<void> setPluginEnabled(String id, bool enabled) async {
    final db = _database!;
    await db.insert('plugins', {
      'id': id,
      'enabled': enabled ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, bool>> getAllPluginStates() async {
    final db = _database!;
    final rows = await db.query('plugins');
    final Map<String, bool> map = {};
    for (final r in rows) {
      map[r['id'] as String] = (r['enabled'] as int) == 1;
    }
    return map;
  }

  Future<void> setPluginPrefs(String id, Map<String, dynamic> prefs) async {
    final db = _database!;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plugins (
        id TEXT PRIMARY KEY,
        enabled INTEGER DEFAULT 1,
        prefs TEXT
      )
    ''');
    await db.insert('plugins', {
      'id': id,
      'enabled': 1,
      'prefs': json.encode(prefs),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getPluginPrefs(String id) async {
    final db = _database!;
    final rows = await db.query(
      'plugins',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    final prefsStr = r['prefs'] as String?;
    if (prefsStr == null) return null;
    try {
      return json.decode(prefsStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setSetting(String key, String value) async {
    final db = _database!;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = _database!;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = _database!;
    final rows = await db.query('settings');
    final Map<String, String> out = {};
    for (final r in rows) {
      out[r['key'] as String] = r['value'] as String;
    }
    return out;
  }

  Future<void> setChapterRead(
    String novelId,
    String chapterId,
    bool read,
  ) async {
    final db = _database!;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chapter_reads (
        novelId TEXT,
        chapterId TEXT,
        read INTEGER,
        PRIMARY KEY (novelId, chapterId)
      )
    ''');
    if (read) {
      await db.insert('chapter_reads', {
        'novelId': novelId,
        'chapterId': chapterId,
        'read': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete(
        'chapter_reads',
        where: 'novelId = ? AND chapterId = ?',
        whereArgs: [novelId, chapterId],
      );
    }
  }

  Future<Set<String>> getReadChaptersForNovel(String novelId) async {
    final db = _database!;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chapter_reads (
        novelId TEXT,
        chapterId TEXT,
        read INTEGER,
        PRIMARY KEY (novelId, chapterId)
      )
    ''');
    final rows = await db.query(
      'chapter_reads',
      where: 'novelId = ? AND read = 1',
      whereArgs: [novelId],
    );
    return rows.map((r) => r['chapterId'] as String).toSet();
  }

  Future<void> upsertNovel(Novel novel) async {
    final db = _database!;
    final map = novel.toMap();
    map['chapters'] = json.encode(map['chapters']);
    map['genres'] = json.encode(map['genres']);
    map['isFavorite'] = (novel.isFavorite) ? 1 : 0;
    map['shouldShowNumberOfChapters'] =
        novel.shouldShowNumberOfChapters ? 1 : 0;
    map['status'] = novel.status.index;
    map['lastChecked'] = novel.lastChecked;
    map['lastKnownChapterCount'] = novel.lastKnownChapterCount;
    map['lastReadChapterId'] = novel.lastReadChapterId;
    await db.insert(
      'novels',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertLocalEpub({
    required String id,
    required String filePath,
    required String title,
    required String author,
    required String description,
    required String coverPath,
    required List<Map<String, dynamic>> chapters,
    required String importedAt,
  }) async {
    final db = _database!;
    await db.insert('local_epubs', {
      'id': id,
      'filePath': filePath,
      'title': title,
      'author': author,
      'description': description,
      'coverPath': coverPath,
      'chapters': json.encode(chapters),
      'importedAt': importedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllLocalEpubs() async {
    final db = _database!;
    final rows = await db.query('local_epubs', orderBy: 'importedAt DESC');
    return rows.map((r) {
      final map = Map<String, dynamic>.from(r);
      map['chapters'] = json.decode(map['chapters'] as String);
      return map;
    }).toList();
  }

  Future<void> deleteLocalEpub(String id) async {
    final db = _database!;
    await db.delete('local_epubs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Novel>> getAllNovels() async {
    final db = _database!;
    final rows = await db.query('novels');
    return rows.map((r) {
      final map = Map<String, dynamic>.from(r);
      map['chapters'] = json.decode(map['chapters'] as String);
      map['genres'] = json.decode(map['genres'] as String);
      if (map.containsKey('isFavorite') && map['isFavorite'] is int) {
        map['isFavorite'] = (map['isFavorite'] as int) == 1;
      }
      if (map.containsKey('shouldShowNumberOfChapters') &&
          map['shouldShowNumberOfChapters'] is int) {
        map['shouldShowNumberOfChapters'] =
            (map['shouldShowNumberOfChapters'] as int) == 1;
      }
      if (!map.containsKey('lastKnownChapterCount')) {
        map['lastKnownChapterCount'] = 0;
      }
      if (!map.containsKey('lastReadChapterId')) {
        map['lastReadChapterId'] = null;
      }
      return Novel.fromMap(map);
    }).toList();
  }

  Future<void> deleteNovel(String id) async {
    final db = _database!;
    await db.delete('novels', where: 'id = ?', whereArgs: [id]);
  }
}
