import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/services/plugin_registry.dart';

enum DownloadStatus { queued, downloading, completed, failed }

class DownloadItem {
  final String novelId;
  final Chapter chapter;
  DownloadStatus status;
  String? errorMessage;
  DateTime addedAt;

  DownloadItem({
    required this.novelId,
    required this.chapter,
    this.status = DownloadStatus.queued,
    this.errorMessage,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  String get id => '${novelId}_${chapter.id}';
}

class DownloadQueueService {
  static final DownloadQueueService _instance = DownloadQueueService._internal();

  factory DownloadQueueService() => _instance;

  DownloadQueueService._internal();

  final List<DownloadItem> _queue = [];
  bool _isProcessing = false;

  List<DownloadItem> get queue => List.unmodifiable(_queue);
  bool get isProcessing => _isProcessing;
  int get pendingCount => _queue.where((d) => d.status == DownloadStatus.queued).length;
  int get downloadingCount => _queue.where((d) => d.status == DownloadStatus.downloading).length;

  void addToQueue(String novelId, Chapter chapter) {
    final existingIdx = _queue.indexWhere((d) => d.id == '${novelId}_${chapter.id}');
    if (existingIdx == -1) {
      _queue.add(DownloadItem(novelId: novelId, chapter: chapter));
    }
  }

  void removeFromQueue(String novelId, String chapterId) {
    _queue.removeWhere((d) => d.novelId == novelId && d.chapter.id == chapterId);
  }

  Future<void> processQueue(Novel Function(String) getNovelById) async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final item = _queue.firstWhere(
        (d) => d.status == DownloadStatus.queued,
        orElse: () => _queue.first,
      );

      if (item.status != DownloadStatus.queued) {
        _queue.removeAt(_queue.indexOf(item));
        continue;
      }

      try {
        item.status = DownloadStatus.downloading;

        final novel = getNovelById(item.novelId);
        final svc = PluginRegistry.get(novel.pluginId);
        if (svc == null) {
          throw Exception('Plugin not found');
        }

        String content = item.chapter.content ?? '';
        if (content.isEmpty) {
          content = await svc.parseChapter(item.chapter.id).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Timeout fetching chapter'),
          );
        }

        item.chapter.content = content;

        final db = await NovelDatabase.getInstance();
        await db.saveChapterOffline(
          novelId: item.novelId,
          chapterId: item.chapter.id,
          title: item.chapter.title,
          content: content,
          savedAt: DateTime.now().toIso8601String(),
        );

        item.status = DownloadStatus.completed;
      } catch (e) {
        item.status = DownloadStatus.failed;
        item.errorMessage = e.toString();
      }

      _queue.removeAt(_queue.indexOf(item));
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _isProcessing = false;
  }

  void clearCompleted() {
    _queue.removeWhere((d) => d.status == DownloadStatus.completed);
  }

  void clearFailed() {
    _queue.removeWhere((d) => d.status == DownloadStatus.failed);
  }

  void clearAll() {
    _queue.clear();
  }

  DownloadItem? getItemStatus(String novelId, String chapterId) {
    try {
      return _queue.firstWhere((d) => d.novelId == novelId && d.chapter.id == chapterId);
    } catch (_) {
      return null;
    }
  }
}
