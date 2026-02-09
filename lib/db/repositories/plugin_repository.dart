import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database_tables.dart';

class PluginRepository {
  final Database _db;

  PluginRepository(this._db);

  Future<void> setPluginEnabled(String id, bool enabled) async {
    await _db.insert(DatabaseTables.plugins, {
      'id': id,
      'enabled': enabled ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> isPluginEnabled(String id) async {
    final rows = await _db.query(
      DatabaseTables.plugins,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return true;
    return (rows.first['enabled'] as int) == 1;
  }

  Future<Map<String, bool>> getAllPluginStates() async {
    final rows = await _db.query(DatabaseTables.plugins);
    return {
      for (var r in rows) (r['id'] as String): ((r['enabled'] as int) == 1),
    };
  }

  Future<void> setPluginPrefs(String id, Map<String, dynamic> prefs) async {
    await _db.insert(DatabaseTables.plugins, {
      'id': id,
      'enabled': 1,
      'prefs': json.encode(prefs),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getPluginPrefs(String id) async {
    final rows = await _db.query(
      DatabaseTables.plugins,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final prefsStr = rows.first['prefs'] as String?;
    if (prefsStr == null) return null;
    try {
      return json.decode(prefsStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
