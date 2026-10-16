import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/agent.dart';
import 'speech_service.dart';
import 'tts_service.dart';

/// Recorded sound clips, one per CMU phoneme (`assets/sounds/HH.mp3`,
/// `SH.mp3`, …). None are recorded yet; see assets/sounds/README.md.
abstract class SoundClips {
  /// Whether a clip for [phoneme] exists.
  Future<bool> has(String phoneme);

  /// Plays it and completes when it has finished.
  Future<void> play(String phoneme);
}

/// No clips: every hint is spoken with text-to-speech.
class NoSoundClips implements SoundClips {
  const NoSoundClips();
  @override
  Future<bool> has(String phoneme) async => false;
  @override
  Future<void> play(String phoneme) async {}
}

final soundClipsProvider = Provider<SoundClips>((ref) => const NoSoundClips());

/// Says [hint] piece by piece ("It starts like… hat"). A piece that names
/// sound clips is played from them when every clip exists (the first
/// sound itself instead of the keyword); otherwise it is spoken. The
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
      if (part.clips.isNotEmpty && await _allExist(clips, part.clips)) {
        for (final c in part.clips) {
          await clips.play(c);
        }
        continue;
      }
      await tts.speak(part.tts, language: language, slow: true);
    }
  } finally {
    speech.mute(false);
  }
}

Future<bool> _allExist(SoundClips clips, List<String> phonemes) async {
  for (final p in phonemes) {
    if (!await clips.has(p)) return false;
  }
  return true;
}
