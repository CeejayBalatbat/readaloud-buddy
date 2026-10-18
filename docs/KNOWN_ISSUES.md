# Known issues

Things we found but haven't fixed yet. We fix these in the bug-fixing
round at the end. Add new reports at the bottom of the right section.

## Speech recognition
- **CRASH — fixed in code, needs a check on the phone** (found 2026-10-17,
  Galaxy S25 Ultra, Android 17, 4 KB pages):
  starting to read with Offline (Vosk) kills the app. Tombstone:
  `SIGABRT ... uncaught exception of type kaldi::KaldiFatalError` in
  `libvosk.so Recognizer::SetGrm` ← `org.vosk.Recognizer.setGrammar` ←
  `VoskFlutterPlugin.onMethodCall`. Cause: Vosk refuses a grammar change
  once the recognizer has heard audio ("Can't add ... to already running
  recognizer") and aborts the process; our page-turn / story-start
  grammar swap did exactly that (reproduced on the PC with the same Vosk).
  Not related to 16 KB pages (this phone uses 4 KB pages). **Fix:** at a
  page turn Vosk now ends the utterance first (`FinalResult`, keeping its
  words), at a story start it resets, and the plugin's `setGrammar`
  always resets first; the tests' fake Vosk refuses mid-utterance grammar
  changes like the real one.
- **Safety net (added):** any error Vosk *reports* (model missing, init
  failing, a refused call) switches the story to tap-to-read on the spot
  (the phone recognizer was removed in Phase 5b), with a small note, and
  Vosk stays off (Settings shows why, with "Try offline again"). A crash *inside* Vosk's native code (C++
  abort, like the one above) can't be caught by Dart or Java: that run
  still closes, but at the next start the app sees it crashed while Vosk
  was running (Android 11+ exit reason; on older phones any exit during
  Vosk counts) and turns Vosk off. Truly isolating Vosk would mean running
  it in a separate Android process.
- **16 KB pages — fixed:** vosk-android 0.3.47's `libvosk.so` was 4 KB
  aligned; 0.3.75 (with JNA 5.18.1) is 16 KB aligned, so the app now uses
  it. `libsqlite3.so` and `libdartjni.so` (jni) were already 16 KB
  aligned, so those packages didn't need updating. The Vulkan validation
  layer is only in debug builds (Flutter's debug engine), never release.
  `python tools/check_apk.py <apk>` checks all of this (ELF LOAD ≥ 16 KB,
  zipalign -P 16, no validation layer); the arm64 release APK passes.
  Debug APKs still contain the validation layer; Android's 16 KB warning
  on a debug install can come from it.
- **Vosk (now the only recognizer) is untested on a real phone.** It
  builds (debug and release APKs) and its logic is tested with a fake
  engine. On this PC, with a synthetic voice reading page 1 of S01,
  grammar mode showed each word a median **240 ms** after it ended (90%:
  350 ms), vs 330 ms with the full vocabulary, at about 1/7 of the CPU.
  **Needs:** the speed meter's numbers from the phone.
- **The microphone permission is now asked by our own code**
  (`MainActivity.kt`, channel `readaloud/mic`), since `speech_to_text`
  (which used to ask) was removed. Untested on a phone: check that the
  permission question appears on the first English story and that
  "Mic is off" → tapping the mic asks again.
- **Vosk doesn't score misreads as "misread".** A word that isn't on the
  page comes out as `[unk]`, which keeps the hint timer going but isn't
  scored, so a real misread shows up as hints and then `correctAfterHint`
  or `skipped`. Both are miscues, but a misread is never labelled
  `misread` by the microphone (only by a long-press in tap-to-read).
- **Grammar mode can still hear a misread as another word on the same
  page** (e.g. "bat" heard as "cat" when "cat" is on the page). `[unk]`
  catches most other words, but not those.
- **A page turn swaps Vosk's grammar during a ~100 ms pause**, so the very
  start of a word said exactly then could be lost.
- The first Vosk start after installing unzips the model (a few seconds,
  about 70 MB of phone storage). Buddy shows "Getting ready…" meanwhile.
- 3 story words aren't in the Vosk model (jen, marco, turon); `[unk]` there
  is recorded as `unsure` (never against the child).
- **Filipino model license: CC BY-NC-SA 4.0 (non-commercial use
  only).** `vosk-model-tl-ph-generic-0.6` is © 2020 Federico Ang. OK for
  this school project; selling the app (or anything commercial) would need
  a different Filipino model or the author's permission. Share-alike also
  applies to changed versions of the model itself.
- **The Filipino model is big:** 314 MB download, 775 MB unpacked, about
  860 MB of memory while in use (measured on a Galaxy S25 Ultra: unpack
  1.8 s, load 0.6 s, 0.06 × real time, 92.6% of words found on TTS
  speech). Phones with less than ~1.2 GB free memory fall back to tapping.
  **Only tested on one high-end phone;** a mid-range phone (4 GB RAM) is
  the real test.
- **Filipino uses free text (no grammar mode):** a misread shows up as a
  `misread` (unlike English, where Vosk only knows the page's words), but
  the model can also hear a correct word wrongly. Names it doesn't know
  well were the most common misses in the benchmark (*Mimi* heard as
  "mommy", *Biyaya* as "baae"). Measured only with the phone's TTS voice,
  not with children.
- Filipino spelling variants (*lumpiya*/lumpia, *letse*/leche, …) are
  treated as the same word (AGENT_SPEC §1). One possible false match:
  *linggo* and *lingo* become the same.
- Downloading over mobile data uses 314 MB; the screen recommends Wi-Fi
  but doesn't detect the connection type.
- `packages/vosk_flutter` is a vendored copy of the official plugin
  (updated for Dart 3) using vosk-android 0.3.47; 0.3.75 exists and may be
  faster, but needs the plugin's Java code checked first.
- **The app is bigger:** the arm64 release APK is 69.8 MB
  (`flutter build apk --release --split-per-abi`), 39 MB of it the model.
- The model (39 MB) isn't in git: run `python tools/get_vosk_model.py`
  before building, or "Offline (Vosk)" reports the mic as not ready.
- The Filipino TTS voice for hints may be missing on some phones (Buddy
  then stays quiet).
- The speed meter's "said" time is each word's start time in Vosk's audio
  (exact, but doesn't include the phone's ~tens of ms of microphone
  buffering).
- The release manifest no longer asks for the INTERNET permission (the
  app is offline; debug builds still add it for Flutter's tools).

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

## Reading score and recommendations (Phase 5b)
- **The numbers are a first guess, not research-validated.** The score
  formula (AGENT_SPEC §5), the prediction (§9) and the book difficulty
  (§11) were tuned on our 20 books and a *pretend* child
  (`test/agent/score_loop_test.dart`). They need checking against real
  children's readings: Buddy's brain logs predicted vs actual accuracy
  for every story, so that data will show how far off it is.
- **CRLA cut-offs are the same for every grade.** "Reading at Grade
  Level" means score ≥ 80 whatever the child's grade; the real CRLA judges
  against the child's own grade. The grade is saved, so cut-offs per grade
  could be added in `agent_config.dart`.
- **The library is small at the bottom.** English has only 3 books below
  difficulty 20 and Filipino 2, so a beginning reader's shelf has 2–3
  books, and a reader under about 15 gets "Let's read these together" with
  books predicted too hard. More easy books (with `tools/add_stories.py`)
  fix this.
- **A shelf can have fewer than 4 books** (e.g. score 20: only 2 are just
  right and none is easy yet). Buddy never fills it with a book it expects
  to be too hard.
- **The reading-check passage uses the whole book's difficulty,** though
  the child reads only its opening (~25 words, so shorter than the book).
- **Old readers were converted** from levels 1–4 to scores 10/30/50/70
  (database version 2). Their first stories will move the score quickly.
- **Filipino readers' check is tapped,** so their starting score is only
  as good as the tapping.
- Word tags for new words come from rules (`tools/storylib.py`, 93% the
  same as the starter tags); check the tags `add_stories.py` prints.

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

