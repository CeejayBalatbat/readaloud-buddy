import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/agent.dart';
import 'speech_service.dart';
import 'tts_service.dart';

/// Recorded phonics clips (`assets/sounds/<id>.mp3`, ids from
/// [Phonics.sounds] and `rime_<letters>`). See assets/sounds/README.md.
abstract class SoundClips {
  /// Plays clip [id] and completes when it has finished. Returns false if
  /// there is no such clip, so the caller can use text-to-speech instead.
  Future<bool> play(String id);
}

/// No clips recorded yet: every sound falls back to text-to-speech.
class NoSoundClips implements SoundClips {
  const NoSoundClips();
  @override
  Future<bool> play(String id) async => false;
}

final soundClipsProvider = Provider<SoundClips>((ref) => const NoSoundClips());

/// Says [hint] piece by piece ("huh… ad… had"): each piece from its
/// recorded clip when there is one, otherwise with text-to-speech. The
/// microphone ignores everything heard meanwhile, so Buddy's voice is not
/// taken as the child reading.
Future<void> speakHint(
  TtsService tts,
  SpeechService speech,
  Hint hint, {
  required String language,
  SoundClips clips = const NoSoundClips(),
}) async {
  speech.mute(true);
  try {
    for (final part in hint.speech) {
      final clip = part.clip;
      if (clip != null && await clips.play(clip)) continue;
      await tts.speak(part.tts, language: language, slow: true);
    }
  } finally {
    speech.mute(false);
  }
}
