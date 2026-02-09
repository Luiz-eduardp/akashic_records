import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/db/novel_database.dart';

class ChapterManager {
  final NovelDatabase _db;

  ChapterManager(this._db);

  Future<void> setChapterRead(
    String novelId,
    String chapterId,
    bool read,
  ) async {
    await _db.chapters.setChapterRead(novelId, chapterId, read);
  }

  Future<Set<String>> getReadChaptersForNovel(String novelId) =>
      _db.chapters.getReadChaptersForNovel(novelId);

  Future<void> saveChapterOffline(String novelId, Chapter chapter) async {
    await _db.chapters.saveChapterOffline(
      novelId: novelId,
      chapterId: chapter.id,
      title: chapter.title,
      content: chapter.content ?? '',
      savedAt: DateTime.now().toIso8601String(),
    );
  }

  Future<List<Map<String, dynamic>>> getSavedChaptersForNovel(
    String novelId,
  ) async {
    try {
      return await _db.chapters.getSavedChaptersForNovel(novelId);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSavedChapter(
    String novelId,
    String chapterId,
  ) async {
    try {
      return await _db.chapters.getSavedChapter(novelId, chapterId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isChapterSaved(String novelId, String chapterId) async {
    try {
      return await _db.chapters.isChapterSaved(novelId, chapterId);
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteSavedChapter(String novelId, String chapterId) async {
    try {
      await _db.chapters.deleteSavedChapter(novelId, chapterId);
    } catch (_) {}
  }
}
