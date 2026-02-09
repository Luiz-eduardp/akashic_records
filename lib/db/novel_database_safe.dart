import 'dart:async';
import 'package:akashic_records/models/model.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'database_initialization.dart';
import 'repositories/settings_repository.dart';
import 'repositories/novel_repository.dart';
import 'repositories/plugin_repository.dart';
import 'repositories/chapter_repository.dart';
import 'repositories/epub_repository.dart';

class NovelDatabase {
  static final NovelDatabase _instance = NovelDatabase._internal();
  static Database? _database;
  static DatabaseService? _service;

  late SettingsRepository settings;
  late NovelRepository novels;
  late PluginRepository plugins;
  late ChapterRepository chapters;
  late EpubRepository epubs;

  NovelDatabase._internal();

  static Future<NovelDatabase> getInstance() async {
    if (_database == null) {
      _database = await DatabaseInitialization.initializeDatabase();
      _service = DatabaseService(_database!);
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

  bool get isHealthy => _service?.isHealthy ?? false;
  String? get lastHealthError => _service?.lastHealthError;

  Future<void> setSetting(String key, String value) async {
    try {
      await _runWithTimeout(() => settings.setSetting(key, value));
    } catch (e) {
      _handleError('setSetting', e);
    }
  }

  Future<String?> getSetting(String key) async {
    try {
      return await _runWithTimeout(() => settings.getSetting(key));
    } catch (e) {
      _handleError('getSetting', e);
      return null;
    }
  }

  Future<Map<String, String>> getAllSettings() async {
    try {
      return await _runWithTimeout(() => settings.getAllSettings());
    } catch (e) {
      _handleError('getAllSettings', e);
      return {};
    }
  }

  Future<void> setPluginEnabled(String id, bool enabled) async {
    try {
      await _runWithTimeout(() => plugins.setPluginEnabled(id, enabled));
    } catch (e) {
      _handleError('setPluginEnabled', e);
    }
  }

  Future<Map<String, bool>> getAllPluginStates() async {
    try {
      return await _runWithTimeout(() => plugins.getAllPluginStates());
    } catch (e) {
      _handleError('getAllPluginStates', e);
      return {};
    }
  }

  Future<void> setPluginPrefs(String id, Map<String, dynamic> prefs) async {
    try {
      await _runWithTimeout(() => plugins.setPluginPrefs(id, prefs));
    } catch (e) {
      _handleError('setPluginPrefs', e);
    }
  }

  Future<Map<String, dynamic>?> getPluginPrefs(String id) async {
    try {
      return await _runWithTimeout(() => plugins.getPluginPrefs(id));
    } catch (e) {
      _handleError('getPluginPrefs', e);
      return null;
    }
  }

  Future<void> setChapterRead(String novelId, String chapterId, bool read) =>
      _runWithTimeout(() => chapters.setChapterRead(novelId, chapterId, read));

  Future<Set<String>> getReadChaptersForNovel(String novelId) async {
    try {
      return await _runWithTimeout(
        () => chapters.getReadChaptersForNovel(novelId),
      );
    } catch (e) {
      _handleError('getReadChaptersForNovel', e);
      return {};
    }
  }

  Future<void> saveChapterOffline({
    required String novelId,
    required String chapterId,
    required String title,
    required String content,
    required String savedAt,
  }) => _runWithTimeout(
    () => chapters.saveChapterOffline(
      novelId: novelId,
      chapterId: chapterId,
      title: title,
      content: content,
      savedAt: savedAt,
    ),
  );

  Future<List<Map<String, dynamic>>> getSavedChaptersForNovel(
    String novelId,
  ) async {
    try {
      return await _runWithTimeout(
        () => chapters.getSavedChaptersForNovel(novelId),
      );
    } catch (e) {
      _handleError('getSavedChaptersForNovel', e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSavedChapter(
    String novelId,
    String chapterId,
  ) async {
    try {
      return await _runWithTimeout(
        () => chapters.getSavedChapter(novelId, chapterId),
      );
    } catch (e) {
      _handleError('getSavedChapter', e);
      return null;
    }
  }

  Future<bool> isChapterSaved(String novelId, String chapterId) async {
    try {
      return await _runWithTimeout(
        () => chapters.isChapterSaved(novelId, chapterId),
      );
    } catch (e) {
      _handleError('isChapterSaved', e);
      return false;
    }
  }

  Future<void> deleteSavedChapter(String novelId, String chapterId) =>
      _runWithTimeout(() => chapters.deleteSavedChapter(novelId, chapterId));

  Future<void> upsertLocalEpub({
    required String id,
    required String filePath,
    required String title,
    required String author,
    required String description,
    required String coverPath,
    required List<Map<String, dynamic>> chapters,
    required String importedAt,
  }) => _runWithTimeout(
    () => epubs.upsertLocalEpub(
      id: id,
      filePath: filePath,
      title: title,
      author: author,
      description: description,
      coverPath: coverPath,
      chapters: chapters,
      importedAt: importedAt,
    ),
  );

  Future<List<Map<String, dynamic>>> getAllLocalEpubs() async {
    try {
      return await _runWithTimeout(() => epubs.getAllLocalEpubs());
    } catch (e) {
      _handleError('getAllLocalEpubs', e);
      return [];
    }
  }

  Future<void> deleteLocalEpub(String id) =>
      _runWithTimeout(() => epubs.deleteLocalEpub(id));

  Future<void> upsertNovel(Novel novel) =>
      _runWithTimeout(() => novels.upsertNovel(novel));

  Future<List<Novel>> getAllNovels() async {
    try {
      return await _runWithTimeout(() => novels.getAllNovels());
    } catch (e) {
      _handleError('getAllNovels', e);
      return [];
    }
  }

  Future<void> deleteNovel(String id) =>
      _runWithTimeout(() => novels.deleteNovel(id));

  Future<T> _runWithTimeout<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 2,
  }) async {
    int retries = 0;
    while (retries < maxRetries) {
      try {
        return await operation().timeout(timeout);
      } catch (e) {
        retries++;
        if (retries >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 100 * retries));
      }
    }
    throw Exception('Operation failed after $maxRetries retries');
  }

  void _handleError(String operation, dynamic error) {
    final message = 'Database error in $operation: $error';
    if (error is TimeoutException) {
      print('[TIMEOUT] $message');
    } else {
      print('[ERROR] $message');
    }
  }

  Future<void> pruneOldData() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      await _database?.delete(
        'saved_chapters',
        where: 'savedAt < ?',
        whereArgs: [thirtyDaysAgo.toIso8601String()],
      );
    } catch (e) {
      print('[PRUNE ERROR] $e');
    }
  }

  Future<void> optimize() async {
    try {
      await _database?.execute('VACUUM');
      await pruneOldData();
    } catch (e) {
      print('[OPTIMIZE ERROR] $e');
    }
  }

  Map<String, dynamic> getStats() {
    return {
      'healthy': isHealthy,
      'lastError': lastHealthError,
      'activeConnections': _service?.activeConnections ?? 0,
      'cacheSize': _service?.cacheSize ?? 0,
    };
  }

  void dispose() {
    _service?.dispose();
    _database?.close();
    _database = null;
    _service = null;
  }
}
