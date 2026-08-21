import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:akashic_records/models/model.dart';
import '../database_tables.dart';

class NovelRepository {
  final Database _db;

  NovelRepository(this._db);

  Future<void> upsertNovel(Novel novel) async {
    final map = novel.toMap();

    final sanitizedChapters = novel.chapters.map((c) {
      return {
        'id': c.id,
        'title': c.title,
        'releaseDate': c.releaseDate,
        'chapterNumber': c.chapterNumber,
        'content': (c.content != null && c.content!.length < 500) ? c.content : null,
      };
    }).toList();

    map['chapters'] = json.encode(sanitizedChapters);
    map['genres'] = json.encode(map['genres']);
    map['isFavorite'] = novel.isFavorite ? 1 : 0;
    map['shouldShowNumberOfChapters'] = novel.shouldShowNumberOfChapters ? 1 : 0;
    map['status'] = novel.status.index;

    await _db.insert(
      DatabaseTables.novels,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Novel>> getAllNovels() async {
    try {
      await _db.execute("UPDATE ${DatabaseTables.novels} SET chapters = '[]' WHERE LENGTH(chapters) > 20000;");
      await _db.execute("UPDATE ${DatabaseTables.novels} SET description = SUBSTR(description, 1, 2000) WHERE LENGTH(description) > 20000;");
    } catch (_) {}

    try {
      final rows = await _db.query(DatabaseTables.novels);
      return rows.map(_rowToNovel).toList();
    } catch (e) {
      return _getAndRepairNovels();
    }
  }

  Future<List<Novel>> _getAndRepairNovels() async {
    final list = <Novel>[];
    try {
      final idRows = await _db.rawQuery('SELECT id FROM ${DatabaseTables.novels}');
      for (final idRow in idRows) {
        final id = idRow['id']?.toString();
        if (id == null) continue;

        try {
          final rows = await _db.query(
            DatabaseTables.novels,
            where: 'id = ?',
            whereArgs: [id],
          );
          if (rows.isNotEmpty) {
            list.add(_rowToNovel(rows.first));
          }
        } catch (rowError) {
          try {
            await _db.execute(
              "UPDATE ${DatabaseTables.novels} SET chapters = '[]' WHERE id = ?",
              [id],
            );
            final repairedRows = await _db.query(
              DatabaseTables.novels,
              where: 'id = ?',
              whereArgs: [id],
            );
            if (repairedRows.isNotEmpty) {
              list.add(_rowToNovel(repairedRows.first));
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return list;
  }

  Future<Novel?> getNovel(String id) async {
    try {
      final rows = await _db.query(
        DatabaseTables.novels,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : _rowToNovel(rows.first);
    } catch (e) {
      try {
        await _db.execute(
          "UPDATE ${DatabaseTables.novels} SET chapters = '[]' WHERE id = ?",
          [id],
        );
        final repairedRows = await _db.query(
          DatabaseTables.novels,
          where: 'id = ?',
          whereArgs: [id],
        );
        return repairedRows.isEmpty ? null : _rowToNovel(repairedRows.first);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> deleteNovel(String id) async {
    await _db.delete(DatabaseTables.novels, where: 'id = ?', whereArgs: [id]);
  }

  Novel _rowToNovel(Map<String, dynamic> r) {
    final map = Map<String, dynamic>.from(r);
    try {
      map['chapters'] = json.decode(map['chapters'] as String? ?? '[]');
    } catch (_) {
      map['chapters'] = [];
    }
    try {
      map['genres'] = json.decode(map['genres'] as String? ?? '[]');
    } catch (_) {
      map['genres'] = [];
    }

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
