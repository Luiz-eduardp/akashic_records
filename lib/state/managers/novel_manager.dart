import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/db/novel_database.dart';

class NovelManager {
  final NovelDatabase _db;
  List<Novel> _localNovels = [];

  NovelManager(this._db);

  List<Novel> get localNovels => List.unmodifiable(_localNovels);

  List<Novel> get favoriteNovels =>
      _localNovels.where((n) => n.isFavorite == true).toList();

  Future<void> initialize() async {
    _localNovels = await _db.getAllNovels();
  }

  Future<void> addOrUpdateNovel(Novel novel) async {
    await _db.upsertNovel(novel);
    await refreshLocalNovels();
  }

  Future<void> toggleFavorite(String id, {bool? value}) async {
    final idx = _localNovels.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    final novel = _localNovels[idx];
    novel.isFavorite = value ?? !novel.isFavorite;
    await _db.upsertNovel(novel);
    await refreshLocalNovels();
  }

  Future<void> removeNovel(String id) async {
    await _db.deleteNovel(id);
    _localNovels = await _db.getAllNovels();
  }

  Future<void> refreshLocalNovels() async {
    _localNovels = await _db.getAllNovels();
  }

  Novel? getNovelById(String id) {
    try {
      return _localNovels.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }
}
