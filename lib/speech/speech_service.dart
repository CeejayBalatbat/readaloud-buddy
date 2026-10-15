import 'package:flutter/foundation.dart';

/// One word the recognizer heard.
class HeardWord {
  const HeardWord(this.text, {this.confidence});

  final String text;

  /// 0–1, or null when the recognizer gives none (common on Android).
  final double? confidence;
}

enum MicStatus {
  off,
  starting,
  listening,

  /// The microphone permission was refused.
  noPermission,

  /// No recognizer for this language on the phone (or it failed to start).
  unavailable,
}

/// What the recognizer is doing, for the mic button and Buddy's brain.
@immutable
class SpeechState {
  const SpeechState({
    this.status = MicStatus.off,
    this.onDevice,
    this.transcript = '',
    this.restarts = 0,
    this.lastError,
  });

  final MicStatus status;

  /// true = recognizing on the phone, false = online, null = unknown.
  final bool? onDevice;

  /// The latest (partial) transcript of the current utterance.
  final String transcript;

  /// How many times listening restarted after the recognizer stopped.
  final int restarts;
  final String? lastError;

  SpeechState copyWith({
    MicStatus? status,
    bool? onDevice,
    String? transcript,
    int? restarts,
    String? lastError,
  }) =>
      SpeechState(
        status: status ?? this.status,
        onDevice: onDevice ?? this.onDevice,
        transcript: transcript ?? this.transcript,
        restarts: restarts ?? this.restarts,
        lastError: lastError ?? this.lastError,
      );
}

/// Turns the child's voice into words. The reading screen only talks to
/// this interface, so the Android recognizer ([AndroidSpeechService]),
/// a future offline one (Vosk) and [FakeSpeechService] are interchangeable.
abstract class SpeechService {
  /// New words, one at a time, in the order they were heard.
  Stream<HeardWord> get words;

  ValueListenable<SpeechState> get state;

  bool get isListening;

  /// [language] is the story language: "EN" or "FIL".
  Future<void> start({required String language});
  Future<void> stop();

  /// The word the child should say next. Lets the recognizer pass on a
  /// still-changing last word early when it already matches.
  set expectedWord(String? word);

  /// While true (e.g. Buddy is speaking a hint), heard words are dropped
  /// so Buddy's own voice is not taken as the child's reading.
  void mute(bool muted);

  void dispose();
}
