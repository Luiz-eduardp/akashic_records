import 'package:akashic_records/db/novel_database.dart';
import 'package:intl/intl.dart';

class DailyReadingStat {
  final String date;
  final int secondsRead;
  final int wordsRead;
  final int chaptersCompleted;

  DailyReadingStat({
    required this.date,
    required this.secondsRead,
    required this.wordsRead,
    required this.chaptersCompleted,
  });
}

class ReadingAnalyticsService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Future<void> recordReadingSession({
    required int seconds,
    required int words,
    bool chapterFinished = false,
  }) async {
    if (seconds <= 0) return;

    final db = await NovelDatabase.getInstance();
    final today = _dateFormat.format(DateTime.now());

    final settings = await db.getAllSettings();
    final keySec = 'stat_sec_$today';
    final keyWords = 'stat_words_$today';
    final keyChaps = 'stat_chaps_$today';

    final currentSec = int.tryParse(settings[keySec] ?? '0') ?? 0;
    final currentWords = int.tryParse(settings[keyWords] ?? '0') ?? 0;
    final currentChaps = int.tryParse(settings[keyChaps] ?? '0') ?? 0;

    await db.setSetting(keySec, (currentSec + seconds).toString());
    await db.setSetting(keyWords, (currentWords + words).toString());
    if (chapterFinished) {
      await db.setSetting(keyChaps, (currentChaps + 1).toString());
    }
  }

  Future<int> calculateReadingStreak() async {
    final db = await NovelDatabase.getInstance();
    final settings = await db.getAllSettings();

    int streak = 0;
    DateTime date = DateTime.now();

    while (true) {
      final dateStr = _dateFormat.format(date);
      final sec = int.tryParse(settings['stat_sec_$dateStr'] ?? '0') ?? 0;
      if (sec > 0) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        if (streak == 0) {
          final yesterdayStr = _dateFormat.format(date.subtract(const Duration(days: 1)));
          final ySec = int.tryParse(settings['stat_sec_$yesterdayStr'] ?? '0') ?? 0;
          if (ySec > 0) {
            streak++;
            date = date.subtract(const Duration(days: 2));
            continue;
          }
        }
        break;
      }
    }

    return streak;
  }

  Future<Map<String, dynamic>> getWeeklySummary() async {
    final db = await NovelDatabase.getInstance();
    final settings = await db.getAllSettings();

    int totalSec = 0;
    int totalWords = 0;
    int totalChapters = 0;

    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final dateStr = _dateFormat.format(day);

      totalSec += int.tryParse(settings['stat_sec_$dateStr'] ?? '0') ?? 0;
      totalWords += int.tryParse(settings['stat_words_$dateStr'] ?? '0') ?? 0;
      totalChapters += int.tryParse(settings['stat_chaps_$dateStr'] ?? '0') ?? 0;
    }

    final minutes = totalSec ~/ 60;
    final wpm = (totalSec > 0 && totalWords > 0) ? (totalWords / (totalSec / 60)).round() : 220;

    return {
      'totalMinutes': minutes,
      'totalWords': totalWords,
      'totalChapters': totalChapters,
      'averageWpm': wpm,
    };
  }
}
