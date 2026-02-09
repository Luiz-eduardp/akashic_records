import 'dart:async';
import 'package:akashic_records/models/model.dart';
import 'package:sqflite/sqflite.dart';
import 'database_initialization.dart';
import 'repositories/settings_repository.dart';
import 'repositories/novel_repository.dart';
import 'repositories/plugin_repository.dart';
import 'repositories/chapter_repository.dart';
import 'repositories/epub_repository.dart';

class NovelDatabase {
  static final NovelDatabase _instance = NovelDatabase._internal();
  static Database? _database;

  late SettingsRepository settings;
  late NovelRepository novels;
  late PluginRepository plugins;
  late ChapterRepository chapters;
  late EpubRepository epubs;

  NovelDatabase._internal();

  static Future<NovelDatabase> getInstance() async {
    if (_database == null) {
      _database = await DatabaseInitialization.initializeDatabase();
      _instance._initializeRepositories();
    }
    return _instance;
  }

  void _initializeRepositories() {
    settings = SettingsRepository(_database!);
    novels = NovelRepository(_database!);
    plugins = PluginRepository(_database!);
    chapters = ChapterRepository(_database!);
    epubs = EpubRepository(_database!);
  }

  Future<void> setSetting(String key, String value) =>
      settings.setSetting(key, value);

  Future<String?> getSetting(String key) => settings.getSetting(key);

  Future<Map<String, String>> getAllSettings() => settings.getAllSettings();

  Future<void> setPluginEnabled(String id, bool enabled) =>
      plugins.setPluginEnabled(id, enabled);

  Future<Map<String, bool>> getAllPluginStates() =>
      plugins.getAllPluginStates();

  Future<void> setPluginPrefs(String id, Map<String, dynamic> prefs) =>
      plugins.setPluginPrefs(id, prefs);

  Future<Map<String, dynamic>?> getPluginPrefs(String id) =>
      plugins.getPluginPrefs(id);

  Future<void> setChapterRead(String novelId, String chapterId, bool read) =>
      chapters.setChapterRead(novelId, chapterId, read);

  Future<Set<String>> getReadChaptersForNovel(String novelId) =>
      chapters.getReadChaptersForNovel(novelId);

  Future<void> saveChapterOffline({
    required String novelId,
    required String chapterId,
    required String title,
    required String content,
    required String savedAt,
  }) => chapters.saveChapterOffline(
    novelId: novelId,
    chapterId: chapterId,
    title: title,
    content: content,
    savedAt: savedAt,
  );

  Future<List<Map<String, dynamic>>> getSavedChaptersForNovel(String novelId) =>
      chapters.getSavedChaptersForNovel(novelId);

  Future<Map<String, dynamic>?> getSavedChapter(
    String novelId,
    String chapterId,
  ) => chapters.getSavedChapter(novelId, chapterId);

  Future<bool> isChapterSaved(String novelId, String chapterId) =>
      chapters.isChapterSaved(novelId, chapterId);

  Future<void> deleteSavedChapter(String novelId, String chapterId) =>
      chapters.deleteSavedChapter(novelId, chapterId);

  Future<void> upsertLocalEpub({
    required String id,
    required String filePath,
    required String title,
    required String author,
    required String description,
    required String coverPath,
    required List<Map<String, dynamic>> chapters,
    required String importedAt,
  }) => epubs.upsertLocalEpub(
    id: id,
    filePath: filePath,
    title: title,
    author: author,
    description: description,
    coverPath: coverPath,
    chapters: chapters,
    importedAt: importedAt,
  );

  Future<List<Map<String, dynamic>>> getAllLocalEpubs() =>
      epubs.getAllLocalEpubs();

  Future<void> deleteLocalEpub(String id) => epubs.deleteLocalEpub(id);

  Future<void> upsertNovel(Novel novel) => novels.upsertNovel(novel);

  Future<List<Novel>> getAllNovels() => novels.getAllNovels();

  Future<void> deleteNovel(String id) => novels.deleteNovel(id);

  bool get isHealthy => true;

  String? get lastHealthError => null;

  Future<void> pruneOldData() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      await _database?.delete(
        'saved_chapters',
        where: 'savedAt < ?',
        whereArgs: [thirtyDaysAgo.toIso8601String()],
      );
    } catch (e) {}
  }

  Future<void> optimize() async {
    try {
      await _database?.execute('VACUUM');
      await pruneOldData();
    } catch (e) {}
  }

  void dispose() {
    try {
      _database?.close();
      _database = null;
    } catch (e) {}
  }
}
