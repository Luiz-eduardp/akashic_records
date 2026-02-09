import 'package:akashic_records/db/novel_database.dart';

class ReleaseManager {
  final NovelDatabase _db;

  String? _latestReleaseTag;
  String? _latestReleaseUrl;
  String? _lastShownReleaseTag;
  DateTime? _lastShownDate;

  ReleaseManager(this._db);

  String? get latestReleaseTag => _latestReleaseTag;
  String? get latestReleaseUrl => _latestReleaseUrl;

  Future<void> loadLatestReleaseInfo() async {
    try {
      _latestReleaseTag = await _db.settings.getSetting('latest_release_tag');
      _latestReleaseUrl = await _db.settings.getSetting('latest_release_url');
      _lastShownReleaseTag = await _db.settings.getSetting(
        'last_shown_release_tag',
      );

      final dateStr = await _db.settings.getSetting('last_shown_release_date');
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          _lastShownDate = DateTime.parse(dateStr);
        } catch (_) {
          _lastShownDate = null;
        }
      }
    } catch (_) {}
  }

  Future<void> saveLatestReleaseInfo(String tag, String url) async {
    _latestReleaseTag = tag;
    _latestReleaseUrl = url;
    try {
      await _db.settings.setSetting('latest_release_tag', tag);
      await _db.settings.setSetting('latest_release_url', url);
    } catch (_) {}
  }

  bool shouldShowReleaseNotes(String tag) {
    if (_lastShownReleaseTag == null) return true;
    if (_lastShownReleaseTag != tag) return true;
    if (_lastShownDate == null) return true;
    return !_isSameDay(DateTime.now(), _lastShownDate!);
  }

  Future<void> markReleaseNotesShown(String tag) async {
    _lastShownReleaseTag = tag;
    _lastShownDate = DateTime.now();
    try {
      await _db.settings.setSetting('last_shown_release_tag', tag);
      await _db.settings.setSetting(
        'last_shown_release_date',
        _lastShownDate!.toIso8601String(),
      );
    } catch (_) {}
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
