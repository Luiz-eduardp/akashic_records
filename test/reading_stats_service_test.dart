import 'package:flutter_test/flutter_test.dart';
import 'package:akashic_records/services/reading_stats_service.dart';

void main() {
  group('ReadingStatsService Tests', () {
    test('countWords accurately counts words', () {
      expect(ReadingStatsService.countWords('The quick brown fox jumps over the lazy dog'), 9);
      expect(ReadingStatsService.countWords('<p>Hello <b>world</b></p>'), 2);
      expect(ReadingStatsService.countWords(''), 0);
    });

    test('estimateChapterMinutes calculates correct remaining time', () {
      final service = ReadingStatsService();
      expect(service.estimateChapterMinutes(1000, 0.0), 5);
      expect(service.estimateChapterMinutes(1000, 0.5), 3);
      expect(service.estimateChapterMinutes(1000, 1.0), 1);
    });
  });
}
