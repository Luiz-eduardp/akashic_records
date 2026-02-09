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
  }) async {
    await _db.insert(DatabaseTables.localEpubs, {
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
    final rows = await _db.query(
      DatabaseTables.localEpubs,
      orderBy: 'importedAt DESC',
    );
    return rows.map((r) {
      final map = Map<String, dynamic>.from(r);
      map['chapters'] = json.decode(map['chapters'] as String);
      return map;
    }).toList();
  }

  Future<void> deleteLocalEpub(String id) async {
    await _db.delete(
      DatabaseTables.localEpubs,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
