import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database_tables.dart';

class EpubRepository {
  final Database _db;

  EpubRepository(this._db);

  Future<void> upsertLocalEpub({
    required String id,
    required String filePath,
    required String title,
    required String author,
    required String description,
    required String coverPath,
    required List<Map<String, dynamic>> chapters,
    required String importedAt,
    String format = 'epub',
  }) async {
    final sanitizedChapters = chapters.map((c) {
      return {
        'id': c['id'],
        'title': c['title'],
        'releaseDate': c['releaseDate'],
        'chapterNumber': c['chapterNumber'],
      };
    }).toList();

    final chaptersJson = json.encode(sanitizedChapters);

    try {
      await _db.insert(DatabaseTables.localDocuments, {
        'id': id,
        'filePath': filePath,
        'title': title,
        'author': author,
        'description': description,
        'coverPath': coverPath,
        'format': format,
        'chapters': chaptersJson,
        'importedAt': importedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      await _db.insert(DatabaseTables.localEpubs, {
        'id': id,
        'filePath': filePath,
        'title': title,
        'author': author,
        'description': description,
        'coverPath': coverPath,
        'chapters': chaptersJson,
        'importedAt': importedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> saveReadingProgress({
    required String documentId,
    String? chapterId,
    double progressPercent = 0.0,
  }) async {
    try {
      await _db.insert(
        DatabaseTables.readingProgress,
        {
          'documentId': documentId,
          'chapterId': chapterId ?? '',
          'progressPercent': progressPercent,
          'lastReadAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<Map<String, double>> getReadingProgressMap() async {
    final result = <String, double>{};
    try {
      final rows = await _db.query(DatabaseTables.readingProgress);
      for (final r in rows) {
        final docId = r['documentId'] as String?;
        final pct = (r['progressPercent'] as num?)?.toDouble() ?? 0.0;
        if (docId != null && docId.isNotEmpty) {
          result[docId] = pct;
        }
      }
    } catch (_) {}
    return result;
  }

  Future<List<Map<String, dynamic>>> getAllLocalEpubs() async {
    try {
      await _db.execute("UPDATE ${DatabaseTables.localDocuments} SET chapters = '[]' WHERE LENGTH(chapters) > 20000;");
      await _db.execute("UPDATE ${DatabaseTables.localEpubs} SET chapters = '[]' WHERE LENGTH(chapters) > 20000;");
    } catch (_) {}

    List<Map<String, dynamic>> rows = [];
    try {
      rows = await _db.query(
        DatabaseTables.localDocuments,
        orderBy: 'importedAt DESC',
      );
    } catch (_) {
      try {
        rows = await _db.query(
          DatabaseTables.localEpubs,
          orderBy: 'importedAt DESC',
        );
      } catch (_) {}
    }

    final progressMap = await getReadingProgressMap();

    return rows.map((r) {
      final map = Map<String, dynamic>.from(r);
      if (map['chapters'] != null && map['chapters'] is String) {
        try {
          map['chapters'] = json.decode(map['chapters'] as String);
        } catch (_) {
          map['chapters'] = [];
        }
      }
      final docId = map['id'] as String? ?? '';
      map['format'] = map['format'] ?? 'epub';
      map['progressPercent'] = progressMap[docId] ?? 0.0;
      return map;
    }).toList();
  }

  Future<void> deleteLocalEpub(String id) async {
    try {
      await _db.delete(
        DatabaseTables.localDocuments,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (_) {}
    try {
      await _db.delete(
        DatabaseTables.localEpubs,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (_) {}
    try {
      await _db.delete(
        DatabaseTables.readingProgress,
        where: 'documentId = ?',
        whereArgs: [id],
      );
    } catch (_) {}
  }
}
