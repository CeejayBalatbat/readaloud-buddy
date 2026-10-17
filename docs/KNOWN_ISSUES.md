# Known issues

Things we found but haven't fixed yet. We fix these in the bug-fixing
round at the end. Add new reports at the bottom of the right section.

## Speech recognition
- **Vosk (now the default) is untested on a real phone.** It builds
  (debug and release APKs) and its logic is tested with a fake engine. On
  this PC, with a synthetic voice reading page 1 of S01, grammar mode
  showed each word a median **240 ms** after it ended (90%: 350 ms), vs
  330 ms with the full vocabulary, at about 1/7 of the CPU. **Needs:** the
  speed meter's numbers from the phone, Vosk vs Phone recognizer on the
  same page.
- **Recognition felt slow with the phone recognizer** (reported). That
  path is unchanged; it is now the "Phone recognizer" fallback.
- **Vosk doesn't score misreads as "misread".** A word that isn't on the
  page comes out as `[unk]`, which keeps the hint timer going but isn't
  scored, so a real misread shows up as hints and then `correctAfterHint`
  or `skipped`. Both are miscues, but the per-word label differs from the
  phone recognizer's.
- **Grammar mode can still hear a misread as another word on the same
  page** (e.g. "bat" heard as "cat" when "cat" is on the page). `[unk]`
  catches most other words, but not those.
- **A page turn swaps Vosk's grammar during a ~100 ms pause**, so the very
  start of a word said exactly then could be lost.
- The first Vosk start after installing unzips the model (a few seconds,
  about 70 MB of phone storage). Buddy shows "Getting ready…" meanwhile.
- 3 story words aren't in the Vosk model (jen, marco, turon); `[unk]` there
  is recorded as `unsure` (never against the child).
- No small Filipino Vosk model exists. The only one is 314 MB, has a
  fixed vocabulary (no grammar mode) and a non-commercial license
  (CC-BY-NC-SA), so Filipino uses the phone recognizer or tap to read.
- `packages/vosk_flutter` is a vendored copy of the official plugin
  (updated for Dart 3) using vosk-android 0.3.47; 0.3.75 exists and may be
  faster, but needs the plugin's Java code checked first.
- **The app is bigger:** the arm64 release APK is 69.8 MB
  (`flutter build apk --release --split-per-abi`), 39 MB of it the model.
- The model (39 MB) isn't in git: run `python tools/get_vosk_model.py`
  before building, or "Offline (Vosk)" reports the mic as not ready.
- **Phone recognizer only:** words said while it restarts after ~1 s of
  silence are lost ("Mic off while restarting" in the speed meter); some
  phones beep at each restart.
- **Filipino recognition is untested on a real phone.** fil-PH usually has
  no on-device model, so it falls back to online recognition (needs
  internet). The Filipino TTS voice for hints may also be missing on some
  phones (Buddy then stays quiet).
- The speed meter's "said" time differs by recognizer: Vosk uses each
  word's start time in the audio (exact, but doesn't include the phone's
  ~tens of ms of microphone buffering); the phone recognizer uses when the
  mic got loud, so for words read without a pause it counts from the start
  of the phrase and overestimates.

## Hints and phonics
- **TTS rime spellings are unchecked on a real voice** (e.g. "ed" for
  thread, "ont" for want, "oo" for through). Listen for any that sound
  wrong; fixes go in `tools/gen_phonics.py`.
- "honest": the hint highlights the silent **h** as the start, while the
  keyword (octopus 🐙) matches the vowel sound.
- **W keyword changed to window 🪟 for all W words** (went, wet, with…),
  not just "when" and "walked". Revert in `tools/gen_phonics.py` if only
  those two were meant.
- The sound-clip hook (`assets/sounds/<PHONEME>.mp3`) needs an audio
  player package before it does anything.

## Reading check (placement)
- No Help button. With Hints = "Only when I tap Help", a child gets no
  hints at all during the reading check.
- It always uses automatic hints and never shows the page review, whatever
  the Reading feedback setting is.

## Read first, review after
- Words read correctly *after* a hint (via Help) are not in the page
  review; only misread and skipped words are.

## Phase 5 and the weekly summary
- Some keyword/emoji pictures are newer emoji (🪺 nest, 🪟 window, 🪑 chair,
  🪁 kite, 🧃 juice, 🪀). Phones on Android 10 or older may show an empty
  box instead.
- Games don't count toward the streak or today's minutes; only reading does.
- "Build the word" has no picture of the word (the mockup shows one); it
  shows a speaker and Buddy says the word.
- The weekly summary covers the last 7 days (today and the 6 days before),
  not a calendar week.
- Printing tricky words uses Android's print dialog (print or save as PDF);
  untested on a real phone and printer.

