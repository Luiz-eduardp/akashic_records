import 'dart:convert';
import 'package:akashic_records/db/novel_database.dart';

const _defaultReaderPrefs = {
  'presetIndex': 0,
  'fontSize': 18.0,
  'lineHeight': 1.6,
  'fontFamily': 'serif',
  'padding': 12.0,
  'fullscreen': false,
  'align': 'left',
  'focusMode': false,
  'focusBlur': 6,
  'textBrightness': 1.0,
  'fontColor': null,
  'bgColor': null,
};

class ReaderPreferencesManager {
  final NovelDatabase _db;
  late Map<String, dynamic> _prefs;

  ReaderPreferencesManager(this._db);

  Map<String, dynamic> get prefs => Map<String, dynamic>.from(_prefs);

  Future<void> initialize() async {
    try {
      final saved = await _db.settings.getSetting('reader_prefs');
      if (saved != null && saved.isNotEmpty) {
        _prefs = json.decode(saved) as Map<String, dynamic>;
      } else {
        _prefs = Map<String, dynamic>.from(_defaultReaderPrefs);
      }
    } catch (_) {
      _prefs = Map<String, dynamic>.from(_defaultReaderPrefs);
    }
  }

  Future<void> setPreferences(Map<String, dynamic> prefs) async {
    _prefs = Map<String, dynamic>.from(prefs);
    await _db.settings.setSetting('reader_prefs', json.encode(_prefs));
  }

  Map<String, dynamic> getPreferences() => Map<String, dynamic>.from(_prefs);
}
