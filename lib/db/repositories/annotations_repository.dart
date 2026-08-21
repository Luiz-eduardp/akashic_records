import 'package:sqflite/sqflite.dart';
import '../database_tables.dart';

class Annotation {
  final String id;
  final String novelId;
  final String chapterId;
  final String selectedText;
  final String note;
  final String colorHex;
  final String createdAt;

  Annotation({
    required this.id,
    required this.novelId,
    required this.chapterId,
    required this.selectedText,
    required this.note,
    required this.colorHex,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'novelId': novelId,
      'chapterId': chapterId,
      'selectedText': selectedText,
      'note': note,
      'colorHex': colorHex,
      'createdAt': createdAt,
    };
  }

  factory Annotation.fromMap(Map<String, dynamic> map) {
    return Annotation(
      id: map['id'] as String,
      novelId: map['novelId'] as String,
      chapterId: map['chapterId'] as String? ?? '',
      selectedText: map['selectedText'] as String? ?? '',
      note: map['note'] as String? ?? '',
      colorHex: map['colorHex'] as String? ?? '#FDE047',
      createdAt: map['createdAt'] as String? ?? '',
    );
  }
}

class AnnotationsRepository {
  final Database _db;

  AnnotationsRepository(this._db);

  Future<void> addAnnotation(Annotation annotation) async {
    await _db.insert(
      DatabaseTables.annotations,
      annotation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Annotation>> getAnnotationsForNovel(String novelId) async {
    final rows = await _db.query(
      DatabaseTables.annotations,
      where: 'novelId = ?',
      whereArgs: [novelId],
      orderBy: 'createdAt DESC',
    );
    return rows.map((r) => Annotation.fromMap(r)).toList();
  }

  Future<void> deleteAnnotation(String id) async {
    await _db.delete(
      DatabaseTables.annotations,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
