import 'package:akashic_records/db/novel_database.dart';

class PluginManager {
  final NovelDatabase _db;

  PluginManager(this._db);

  Future<bool> getPluginState(String id) async {
    final map = await _db.plugins.getAllPluginStates();
    return map[id] ?? true;
  }

  Future<void> setPluginState(String id, bool enabled) async {
    await _db.plugins.setPluginEnabled(id, enabled);
  }

  Future<void> setPluginPrefs(String id, Map<String, dynamic> prefs) async {
    await _db.plugins.setPluginPrefs(id, prefs);
  }

  Future<Map<String, dynamic>?> getPluginPrefs(String id) async {
    return await _db.plugins.getPluginPrefs(id);
  }

  Future<Map<String, bool>> getAllPluginStates() =>
      _db.plugins.getAllPluginStates();
}
