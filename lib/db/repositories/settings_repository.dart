import 'package:sqflite/sqflite.dart';
import '../database_tables.dart';

class SettingsRepository {
  final Database _db;

  SettingsRepository(this._db);

  Future<void> setSetting(String key, String value) async {
    await _db.insert(DatabaseTables.settings, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final rows = await _db.query(
      DatabaseTables.settings,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<Map<String, String>> getAllSettings() async {
    final rows = await _db.query(DatabaseTables.settings);
    return {for (var r in rows) (r['key'] as String): (r['value'] as String)};
  }

  Future<void> deleteSettings(List<String> keys) async {
    for (final key in keys) {
      await _db.delete(
        DatabaseTables.settings,
        where: 'key = ?',
        whereArgs: [key],
      );
    }
  }
}
