import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:akashic_records/models/model.dart';
import '../database_tables.dart';

class NovelRepository {
  final Database _db;

  NovelRepository(this._db);

  Future<void> upsertNovel(Novel novel) async {
    final map = novel.toMap();
    map['chapters'] = json.encode(map['chapters']);
    map['genres'] = json.encode(map['genres']);
    map['isFavorite'] = novel.isFavorite ? 1 : 0;
    map['shouldShowNumberOfChapters'] =
        novel.shouldShowNumberOfChapters ? 1 : 0;
    map['status'] = novel.status.index;

    await _db.insert(
      DatabaseTables.novels,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Novel>> getAllNovels() async {
    final rows = await _db.query(DatabaseTables.novels);
    return rows.map(_rowToNovel).toList();
  }

  Future<Novel?> getNovel(String id) async {
    final rows = await _db.query(
      DatabaseTables.novels,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _rowToNovel(rows.first);
  }

  Future<void> deleteNovel(String id) async {
    await _db.delete(DatabaseTables.novels, where: 'id = ?', whereArgs: [id]);
  }

  Novel _rowToNovel(Map<String, dynamic> r) {
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
    map.putIfAbsent('lastKnownChapterCount', () => 0);
    map.putIfAbsent('lastReadChapterId', () => null);
    return Novel.fromMap(map);
  }
}
