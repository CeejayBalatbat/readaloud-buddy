import 'package:flutter/foundation.dart';

import 'speech_timing.dart';

/// One word the recognizer heard.
class HeardWord {
  const HeardWord(this.text, {this.confidence});

  final String text;

  /// 0–1, or null when the recognizer gives none.
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
    this.lastError,
    this.speed,
    this.engine,
    this.notice,
    this.loadMs,
  });

  final MicStatus status;

  /// true = recognizing on the phone, false = online, null = unknown.
  final bool? onDevice;

  /// The latest (partial) transcript of the current utterance.
  final String transcript;

  final String? lastError;

  /// Measured delay from speaking to the screen (real mic only).
  final SpeedSummary? speed;

  /// Which recognizer is listening ("Vosk offline"), for Buddy's brain.
  final String? engine;

  /// How long loading the model took (the first time), in ms.
  final int? loadMs;

  /// A short note for the reading screen (e.g. the offline recognizer
  /// failed, so the story switched to tap-to-read).
  final String? notice;

  SpeechState copyWith({
    MicStatus? status,
    bool? onDevice,
    String? transcript,
    String? lastError,
    SpeedSummary? speed,
    String? engine,
    String? notice,
    int? loadMs,
  }) =>
      SpeechState(
        status: status ?? this.status,
        onDevice: onDevice ?? this.onDevice,
        transcript: transcript ?? this.transcript,
        lastError: lastError ?? this.lastError,
        speed: speed ?? this.speed,
        engine: engine ?? this.engine,
        notice: notice ?? this.notice,
        loadMs: loadMs ?? this.loadMs,
      );
}

/// Turns the child's voice into words. The reading screen only talks to
/// this interface, so Vosk ([VoskSpeechService]) and tap-to-read
/// ([FakeSpeechService]) are interchangeable.
abstract class SpeechService {
  /// New words, one at a time, in the order they were heard.
  Stream<HeardWord> get words;

  /// Fires whenever the child's voice is heard, even before it becomes a
  /// whole word (and also for words that don't match). Not while muted.
  Stream<void> get voice;

  /// true when silence means "the mic hears nothing" (a real microphone).
  /// false for tap-to-read, where there is no voice to listen for.
  bool get hearsSilence;

  ValueListenable<SpeechState> get state;

  bool get isListening;

  /// [language] is the story language: "EN" or "FIL".
  Future<void> start({required String language});
  Future<void> stop();

  /// The word the child should say next. Lets the recognizer pass on a
  /// still-changing last word early when it already matches.
  set expectedWord(String? word);

  /// The words the child may read right now (the page, or the review
  /// words). Vosk listens only for these (grammar mode); other recognizers
  /// ignore it.
  set vocabulary(List<String> words);

  /// While true (e.g. Buddy is speaking a hint), heard words are dropped
  /// so Buddy's own voice is not taken as the child's reading.
  void mute(bool muted);

  void dispose();
}
