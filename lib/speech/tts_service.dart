import 'package:flutter_tts/flutter_tts.dart';

import 'speech_service.dart';

/// Buddy's voice: reads hints and questions aloud with the phone's
/// built-in text-to-speech (works offline when the voice is installed).
abstract class TtsService {
  /// [language] is "EN" or "FIL". Completes when Buddy has finished talking.
  Future<void> speak(String text, {required String language, bool slow});
  Future<void> stop();
}

class FlutterTtsService implements TtsService {
  FlutterTtsService() {
    // Make speak() wait until the sentence has been said, so the mic can
    // ignore Buddy's voice for exactly that long.
    _tts.awaitSpeakCompletion(true).catchError((_) => null);
  }

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
      // A short tail so the end of Buddy's voice isn't heard as reading.
      await Future<void>.delayed(const Duration(milliseconds: 300));
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

/// Buddy says [text] while the microphone ignores what it hears, so
/// Buddy's own voice is not taken as the child reading.
Future<void> speakOverMic(
  TtsService tts,
  SpeechService speech,
  String text, {
  required String language,
  bool slow = false,
}) async {
  speech.mute(true);
  try {
    await tts.speak(text, language: language, slow: slow);
  } finally {
    speech.mute(false);
  }
}
