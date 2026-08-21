import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingStatsService {
  static const String _wpmKey = 'reading_stats_wpm';
  static const String _totalTimeKey = 'reading_stats_total_seconds';
  static const String _totalWordsKey = 'reading_stats_total_words';
  static const int defaultWpm = 200;

  double _currentWpm = 200.0;
  int _sessionStartTime = 0;
  int _wordsReadInSession = 0;

  double get currentWpm => _currentWpm;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentWpm = prefs.getDouble(_wpmKey) ?? 200.0;
      if (_currentWpm < 60 || _currentWpm > 1000) {
        _currentWpm = 200.0;
      }
    } catch (_) {
      _currentWpm = 200.0;
    }
  }

  void startSession() {
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    _wordsReadInSession = 0;
  }

  void recordProgress(int wordsRead) {
    if (_sessionStartTime <= 0 || wordsRead <= 0) return;
    _wordsReadInSession += wordsRead;
  }

  Future<void> endSessionAndRecalculate() async {
    if (_sessionStartTime <= 0 || _wordsReadInSession <= 10) return;

    final elapsedMs = DateTime.now().millisecondsSinceEpoch - _sessionStartTime;
    final elapsedMinutes = elapsedMs / 60000.0;
    final elapsedSeconds = (elapsedMs / 1000.0).round();

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentSeconds = prefs.getInt(_totalTimeKey) ?? 0;
      final currentWords = prefs.getInt(_totalWordsKey) ?? 0;
      await prefs.setInt(_totalTimeKey, currentSeconds + elapsedSeconds);
      await prefs.setInt(_totalWordsKey, currentWords + _wordsReadInSession);

      if (elapsedMinutes >= 0.5) {
        final calculatedWpm = _wordsReadInSession / elapsedMinutes;
        if (calculatedWpm >= 60 && calculatedWpm <= 800) {
          _currentWpm = (_currentWpm * 0.7) + (calculatedWpm * 0.3);
          await prefs.setDouble(_wpmKey, _currentWpm);
        }
      }
    } catch (_) {}
  }

  int estimateChapterMinutes(int chapterWordCount, double scrollProgress) {
    final remainingWords = max(0, (chapterWordCount * (1.0 - scrollProgress)).round());
    final minutes = (remainingWords / max(1.0, _currentWpm)).ceil();
    return max(1, minutes);
  }

  int estimateBookMinutes(int totalBookWordCount, double overallProgress) {
    final remainingWords = max(0, (totalBookWordCount * (1.0 - overallProgress)).round());
    final minutes = (remainingWords / max(1.0, _currentWpm)).ceil();
    return max(1, minutes);
  }

  static int countWords(String text) {
    if (text.isEmpty) return 0;
    final cleanText = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final matches = RegExp(r'\S+').allMatches(cleanText);
    return matches.length;
  }
}
