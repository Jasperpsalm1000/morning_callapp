
import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Speaks questions out loud and listens to the answers.
class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _ready = false;
  String _heard = '';
  Completer<String>? _completer;

  /// Prepares speaking and listening.
  Future<bool> init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.awaitSpeakCompletion(true);

      _ready = await _stt.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _finish();
          }
        },
        onError: (error) {
          _finish();
        },
      );

      return _ready;
    } catch (_) {
      _ready = false;
      return false;
    }
  }

  /// Completes the current listening operation.
  void _finish() {
    final completer = _completer;

    if (completer != null && !completer.isCompleted) {
      completer.complete(_heard);
    }
  }

  /// Speaks a sentence and waits for speech output to finish.
  Future<void> speak(String text) async {
    try {
      await _tts.speak(text).timeout(
        const Duration(seconds: 30),
        onTimeout: () => null,
      );
    } catch (_) {
      // Prevent speech output failures from crashing the app.
    }
  }

  /// Listens and returns the recognized words.
  /// Returns an empty string if listening is unavailable or fails.
  Future<String> listen({int seconds = 25}) async {
    if (!_ready || seconds <= 0) {
      return '';
    }

    _heard = '';

    final completer = Completer<String>();
    _completer = completer;

    try {
      await _stt.listen(
        onResult: (result) {
          _heard = result.recognizedWords;

          if (result.finalResult) {
            _finish();
          }
        },
        listenOptions: SpeechListenOptions(
          listenFor: Duration(seconds: seconds),
          pauseFor: const Duration(seconds: 4),
        ),
      );

      return await completer.future.timeout(
        Duration(seconds: seconds + 3),
        onTimeout: () => _heard,
      );
    } catch (_) {
      return _heard;
    } finally {
      if (identical(_completer, completer)) {
        _completer = null;
      }
    }
  }

  /// Stops speaking and listening.
  Future<void> stop() async {
    await _tts.stop();
    await _stt.cancel();
    _finish();
  }

  /// Releases speech resources.
  Future<void> dispose() async {
    await stop();
    _ready = false;
  }
}
