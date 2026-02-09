import 'package:flutter/material.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/db/novel_database.dart';

class HomeStatsHandler {
  final VoidCallback onStatsUpdated;
  
  int _totalWordsRead = 0;
  int _totalChaptersRead = 0;
  int _localEpubCount = 0;
  int _localEpubChapters = 0;
  List<Map<String, dynamic>> _recentReadChapters = [];

  int get totalWordsRead => _totalWordsRead;
  int get totalChaptersRead => _totalChaptersRead;
  int get localEpubCount => _localEpubCount;
  int get localEpubChapters => _localEpubChapters;
  List<Map<String, dynamic>> get recentReadChapters => _recentReadChapters;

  HomeStatsHandler({required this.onStatsUpdated});

  Future<void> loadStats(AppState appState) async {
    final db = await NovelDatabase.getInstance();
    int words = 0;
    int chapters = 0;
    final recent = <Map<String, dynamic>>[];

    for (final novel in appState.localNovels) {
      final readSet = await db.getReadChaptersForNovel(novel.id);
      chapters += readSet.length;

      for (final ch in novel.chapters) {
        if (readSet.contains(ch.id) &&
            ch.content != null &&
            ch.content!.isNotEmpty) {
          final text = ch.content!.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
          words +=
              text
                  .split(RegExp(r'\s+'))
                  .where((w) => w.trim().isNotEmpty)
                  .length;
        }
      }

      for (var i = 0; i < novel.chapters.length; i++) {
        if (readSet.contains(novel.chapters[i].id)) {
          recent.add({
            'novel': novel,
            'chapter': novel.chapters[i],
            'index': i,
          });
        }
      }
    }

    final localEpubs = await db.getAllLocalEpubs();
    int chaptersTotal = 0;
    for (final it in localEpubs) {
      final ch = it['chapters'] as List?;
      if (ch != null) chaptersTotal += ch.length;
    }

    _totalWordsRead = words;
    _totalChaptersRead = chapters;
    _localEpubCount = localEpubs.length;
    _localEpubChapters = chaptersTotal;
    _recentReadChapters = recent.reversed.toList();

    onStatsUpdated();
  }
}
