# Sound clips (optional, none bundled)

Hints never say isolated sounds with text-to-speech: TTS can't say a
pure sound ("s" comes out as "suh"). Level 1 says a **keyword** instead
("It starts like… hat 🎩"); see `assets/data/phonics.json` and
AGENT_SPEC §2.

Recorded clips can replace the keyword later. If
`assets/sounds/<PHONEME>.mp3` exists for **every** sound of a word's
onset (CMU phonemes, e.g. `HH.mp3` for "had", `S.mp3` + `T.mp3` + `R.mp3`
for "strong"), level 1 plays them instead of saying the keyword.

To turn it on:
1. Add the clips: short, pure sounds (*sss*, *mmm*, not *suh*), no silence
   around them. Names are CMU phonemes: `B CH D DH F G HH JH K L M N NG P R
   S SH T TH V W Y Z ZH` (and vowels `AA AE AH AO AW AY EH ER EY IH IY OW
   OY UH UW` if wanted).
2. Add `- assets/sounds/` under `flutter: assets:` in `pubspec.yaml`.
3. Add an audio player package (e.g. `audioplayers`) and implement
   `SoundClips` in `lib/speech/hint_voice.dart` (`has` checks the asset
   exists, `play` plays it and waits until it ends). Override
   `soundClipsProvider` with it.
