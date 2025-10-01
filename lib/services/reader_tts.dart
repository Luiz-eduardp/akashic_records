import 'dart:async';
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
  Completer<void>? _chunkCompleter;
  bool _isSpeaking = false;

  Future<void> _init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.8);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (_) {}
    } catch (_) {}
    _tts.setStartHandler(() {
      try {
        if (onStart != null) onStart!();
        _isSpeaking = true;
      } catch (_) {}
    });
    _tts.setCompletionHandler(() {
      try {
        if (onComplete != null) onComplete!();
        _isSpeaking = false;
        try {
          _chunkCompleter?.complete();
        } catch (_) {}
        _chunkCompleter = null;
      } catch (_) {}
    });
    _tts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      _isSpeaking = false;
      try {
        _chunkCompleter?.completeError(msg ?? 'tts_error');
      } catch (_) {}
      _chunkCompleter = null;
    });
  }

  Future<void> speak(String text, {String? lang}) async {
    try {
      if (lang != null) await _tts.setLanguage(lang);
      final t = text.trim();
      if (t.isEmpty) return;

      final chunks = _chunkText(t, 800);
      try {
        await _tts.stop();
      } catch (_) {}

      for (final chunk in chunks) {
        _chunkCompleter = Completer<void>();
        try {
          await _tts.speak(chunk);
        } catch (e) {
          debugPrint('Failed to send chunk to TTS: $e');
          _chunkCompleter = null;
          continue;
        }
        try {
          await _chunkCompleter!.future.timeout(const Duration(minutes: 2));
        } catch (e) {
          debugPrint('Chunk speak timeout/error: $e');
        } finally {
          _chunkCompleter = null;
        }
      }
    } catch (e) {
      debugPrint('Failed to speak: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      try {
        await _tts.pause();
      } catch (_) {
        await _tts.stop();
      }
      _isSpeaking = false;
    } catch (_) {}
  }

  Future<void> resume() async {
    try {
      _isSpeaking = true;
    } catch (_) {}
  }

  Future<bool> isPlaying() async {
    return Future.value(_isSpeaking);
  }

  Future<void> setRate(double rate) async {
    try {
      await _tts.setSpeechRate(rate);
    } catch (_) {}
  }

  Future<void> setVolume(double volume) async {
    try {
      await _tts.setVolume(volume);
    } catch (_) {}
  }

  Future<void> setPitch(double pitch) async {
    try {
      await _tts.setPitch(pitch);
    } catch (_) {}
  }

  Future<void> setLanguage(String lang) async {
    try {
      await _tts.setLanguage(lang);
    } catch (_) {}
  }

  Future<List<dynamic>?> getLanguages() async {
    try {
      final langs = await _tts.getLanguages;
      return langs;
    } catch (_) {
      return null;
    }
  }

  List<String> _chunkText(String text, int maxLen) {
    final sentences = <String>[];
    final re = RegExp(r'[^.!?]+[.!?]?', multiLine: true);
    for (final m in re.allMatches(text)) {
      final s = m.group(0)?.trim();
      if (s != null && s.isNotEmpty) sentences.add(s);
    }
    if (sentences.isEmpty) return [text];

    final chunks = <String>[];
    var current = StringBuffer();
    for (final s in sentences) {
      if (current.length + s.length + 1 > maxLen) {
        if (current.isNotEmpty) {
          chunks.add(current.toString());
          current = StringBuffer();
        }
      }
      if (current.isNotEmpty) current.write(' ');
      current.write(s);
    }
    if (current.isNotEmpty) chunks.add(current.toString());
    return chunks;
  }
}
