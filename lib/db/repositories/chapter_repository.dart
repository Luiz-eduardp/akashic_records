import 'package:sqflite/sqflite.dart';
import '../database_tables.dart';

class ChapterRepository {
  final Database _db;

  ChapterRepository(this._db);

  Future<void> setChapterRead(
    String novelId,
    String chapterId,
    bool read,
  ) async {
    if (read) {
      await _db.insert(DatabaseTables.chapterReads, {
        'novelId': novelId,
        'chapterId': chapterId,
        'read': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await _db.delete(
        DatabaseTables.chapterReads,
        where: 'novelId = ? AND chapterId = ?',
        whereArgs: [novelId, chapterId],
      );
    }
  }

  Future<Set<String>> getReadChaptersForNovel(String novelId) async {
    final rows = await _db.query(
      DatabaseTables.chapterReads,
      where: 'novelId = ? AND read = 1',
      whereArgs: [novelId],
    );
    return rows.map((r) => r['chapterId'] as String).toSet();
  }

  Future<void> saveChapterOffline({
    required String novelId,
    required String chapterId,
    required String title,
    required String content,
    required String savedAt,
  }) async {
    await _db.insert(DatabaseTables.savedChapters, {
      'novelId': novelId,
      'chapterId': chapterId,
      'title': title,
      'content': content,
      'savedAt': savedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getSavedChaptersForNovel(
    String novelId,
  ) async {
    final rows = await _db.query(
      DatabaseTables.savedChapters,
      where: 'novelId = ?',
      whereArgs: [novelId],
      orderBy: 'savedAt DESC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<Map<String, dynamic>?> getSavedChapter(
    String novelId,
    String chapterId,
  ) async {
    final rows = await _db.query(
      DatabaseTables.savedChapters,
      where: 'novelId = ? AND chapterId = ?',
      whereArgs: [novelId, chapterId],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<bool> isChapterSaved(String novelId, String chapterId) async {
    final rows = await _db.query(
      DatabaseTables.savedChapters,
      where: 'novelId = ? AND chapterId = ?',
      whereArgs: [novelId, chapterId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> deleteSavedChapter(String novelId, String chapterId) async {
    await _db.delete(
      DatabaseTables.savedChapters,
      where: 'novelId = ? AND chapterId = ?',
      whereArgs: [novelId, chapterId],
    );
  }
}
