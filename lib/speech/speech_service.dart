/// One word the recognizer heard.
class HeardWord {
  const HeardWord(this.text, {this.confidence});

  final String text;

  /// 0–1, or null when the recognizer gives none (common on Android).
  final double? confidence;
}

/// Turns the child's voice into words. The reading screen only talks to
/// this interface, so the real recognizer (Phase 4: `speech_to_text`, later
/// Vosk) and [FakeSpeechService] are interchangeable.
abstract class SpeechService {
  /// New words, one at a time, in the order they were heard.
  Stream<HeardWord> get words;

  bool get isListening;

  /// [language] is the story language: "EN" or "FIL".
  Future<void> start({required String language});
  Future<void> stop();
  void dispose();
}
