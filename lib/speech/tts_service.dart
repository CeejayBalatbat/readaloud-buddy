import 'package:flutter_tts/flutter_tts.dart';

/// Buddy's voice: reads hints and questions aloud with the phone's
/// built-in text-to-speech (works offline when the voice is installed).
abstract class TtsService {
  /// [language] is "EN" or "FIL".
  Future<void> speak(String text, {required String language, bool slow});
  Future<void> stop();
}

class FlutterTtsService implements TtsService {
  final _tts = FlutterTts();

  @override
  Future<void> speak(
    String text, {
    required String language,
    bool slow = false,
  }) async {
    try {
      await _tts.stop();
      await _tts.setLanguage(language == 'FIL' ? 'fil-PH' : 'en-US');
      await _tts.setSpeechRate(slow ? 0.3 : 0.45);
      await _tts.speak(text);
    } catch (_) {
      // No voice installed for this language: stay quiet rather than crash.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

/// For tests: remembers what would have been said.
class SilentTtsService implements TtsService {
  final spoken = <String>[];

  @override
  Future<void> speak(String text, {required String language, bool slow = false}) async =>
      spoken.add(text);

  @override
  Future<void> stop() async {}
}
