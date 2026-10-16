# Phonics sound clips (optional, not recorded yet)

Hints say **sounds, not letter names** ("had" → *huh… ad… had*). Each piece
of a hint has a clip id. Until a clip exists, the app says the piece with
text-to-speech using the spelling in `lib/agent/phonics.dart`
(`Phonics.sounds`). TTS can only get close to a pure sound, so recorded
clips are the real fix.

## Adding clips
1. Record each sound as `assets/sounds/<id>.mp3`: short (under 1 s), a
   clear pure sound (*mmm*, *sss*, not *muh*), with no silence before or after.
2. Add `- assets/sounds/` under `flutter: assets:` in `pubspec.yaml`.
3. Add an audio player package (e.g. `audioplayers`) and implement
   `SoundClips` in `lib/speech/hint_voice.dart`: `play(id)` plays
   `sounds/<id>.mp3` and returns `true`, or returns `false` if that file is
   missing. Override `soundClipsProvider` with it. Clips you haven't
   recorded yet still fall back to TTS.

## Sound ids (`Phonics.sounds`)
- Consonants: `b c d f g h j k l m n p r s t v w x y z qu`
- Digraphs: `th sh ch wh ph ck kn wr`
- Short vowels: `a_short e_short i_short o_short u_short schwa`
- Long vowels / teams: `a_long e_long i_long o_long u_long oo ow oy aw`
- r-controlled: `ar or er`

## Rime ids (`rime_<letters>`)
The ending of a one-syllable word after its first sounds, e.g.
`rime_ad.mp3` for "had", "dad". The 20 stories use 144 rimes. Start with
the common word families (`at ad an ap ig ip in it en ed et ot op ug un
ill ell ake ate ite ike ight ing`); the rest keep using TTS until recorded. Some letters are said differently in different words (`ow` in
*now* vs *grow*, `ead` in *thread* vs *read*); TTS uses one spelling for
both, so a clip, or a word-specific entry in `Phonics._irregular`, fixes
that.

Filipino hints use syllables (*ba… ta… bata*) and need no clips.
