import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ReaderTts {
  static final ReaderTts _instance = ReaderTts._internal();
  factory ReaderTts() => _instance;

  ReaderTts._internal() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();
  VoidCallback? onComplete;
  VoidCallback? onStart;

  Future<void> _init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.8);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {}
    _tts.setStartHandler(() {
      try {
        if (onStart != null) onStart!();
      } catch (_) {}
    });
    _tts.setCompletionHandler(() {
      try {
        if (onComplete != null) onComplete!();
      } catch (_) {}
    });
    _tts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
    });
  }

  Future<void> speak(String text, {String? lang}) async {
    try {
      if (lang != null) await _tts.setLanguage(lang);
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      await _tts.speak(text);
    } catch (e) {
      debugPrint('Failed to speak: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> resume() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<bool> isPlaying() async {
    return Future.value(false);
  }
}
