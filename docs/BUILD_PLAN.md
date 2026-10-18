# Build Plan

Work one phase at a time. Each phase ends with: it builds, tests pass, I tried it on the emulator/phone, and it's committed.

## Phase 0 – Project setup
Flutter project `readaloud_buddy`, Android only. Folders: `lib/agent`, `lib/data`, `lib/speech`, `lib/ui/screens`, `lib/ui/widgets`, `test/agent`. Add packages (riverpod, drift or sqflite, speech_to_text, flutter_tts, google_fonts). Load `stories.json` and show a list of story titles. Theme with the colors from SCREENS.md.
**Done when:** app runs and lists 20 stories.

## Phase 1 – Agent core (pure Dart) + tests
Implement every section of AGENT_SPEC.md in `lib/agent/`: word-result scoring, session scores, Phil-IRI classifier, level decisions, placement, BKT mastery, tricky words, story selection, hint ladder logic, teacher flag. Unit tests for each, including rows from `docs/dataset/Sessions.csv`.
**Done when:** `flutter test` passes and I can read a short summary of each rule's test.

## Phase 2 – Local database
Tables from DATA_MODEL.md, repository classes, save/load learners, sessions, word events, mastery.
**Done when:** a test creates a learner, saves a fake session, reloads it.

## Phase 3 – Child UI with fake speech
Screens 1, 3, 4, 5, 6, 7, 8 using `FakeSpeechService` (tap a word = read correctly, long-press = misread, wait = hesitation/hint). Wire to the agent and database so results, levels and mastery really update. *(Levels were replaced by the reading score in Phase 5b.)*
**Done when:** I can set up a reader, read a story by tapping, see hints, answer questions, and see Buddy's plan change my level.

## Phase 4 – Real speech recognition
`SpeechServiceAndroid` with `speech_to_text` (en-US, fil-PH), partial results, word alignment (AGENT_SPEC §1), auto-restart when the recognizer stops on silence. Placement check (screen 2). Hint audio with flutter_tts.
**Done when:** I can read a Level 1 story aloud on my phone and the words turn green as I read.

## Phase 5 – Games, settings, polish
Screen 9 (build-the-word), screen 10 (dyslexia mode, text size, contrast, read aloud, hint wait, multiple readers, parent PIN), Buddy pet growth, stars, streak, daily minutes.
**Done when:** a full day of use works end to end, offline.

## Phase 5b – Cleanup and reading-score redesign (October 2026)
One commit per step; each step builds and its tests pass.
1. **Docs:** AGENT_SPEC (§5 reading score + CRLA profiles, §6 reading check sets the score, §9 recommendation by prediction, §11 book difficulty, speech notes), SCREENS, DATA_MODEL, this plan, `docs/ADDING_STORIES.md`.
2. **Speech cleanup:** Vosk is the only recognizer (English). Remove the Android phone recognizer (`speech_to_text`) and its setting; the microphone permission is asked through a small channel in `MainActivity`. Filipino stories use tap-to-read with a small note. Tap-to-read becomes a hidden developer/demo switch (long-press "How Buddy listens"). Crash protection stays; when Vosk is off, stories use tap-to-read.
3. **Story tools:** `tools/storylib.py` (word tagging, difficulty, validation), `tools/story_difficulty.py`, `tools/add_stories.py`, `tools/check_stories.py`. Every story in `stories.json` gets `difficulty` (0–100).
4. **Agent core (pure Dart) + tests:** reading score and profiles (§5), reading check (§6), accuracy prediction with error learning and the shelf (§9). Old level decisions and placement levels are removed.
5. *(Committed together with step 4: the shelf's inputs changed, so the app had to switch over in the same step to keep building.)* **App:** database schema v2 with a migration (reading score, prediction correction, predicted accuracy per session), session service, shelf, reading check, results, settings, weekly summary and Buddy's brain use the new rules. `level` is removed from `stories.json`.
**Done when:** `flutter test` passes; a new reader's reading check sets a score; the shelf shows "just right" books + one re-read; Buddy's brain shows predicted vs actual accuracy; a story added with `tools/add_stories.py` appears on the shelf.

## Phase 5c – Filipino speech with Vosk (October 2026)
1. **Measure first** on a real phone (`integration_test/filipino_model_benchmark_test.dart`): unpack and load time, memory, speed, words found.
2. **Docs:** AGENT_SPEC (Filipino spelling variants, the Filipino model, when it falls back), SCREENS (5c), BUILD_PLAN, README and KNOWN_ISSUES (license: CC BY-NC-SA, non-commercial).
3. **Model store:** download with progress, resume, size + MD5 check, unpack, delete; copied zip or folder; free space check.
4. **Speech:** per-language Vosk engines sharing the microphone, free-text mode for Filipino, spelling variants, per-language crash protection, memory / load-time / speed limits.
5. **Screens:** Filipino setup screen (5c), Settings part, reading note.
**Done when:** a Filipino story on the phone downloads the model once, then words light up as they are read; too-heavy phones fall back to tapping with a reason in Settings.

## Phase 6 – Later
~~Parent weekly summary (11)~~ (built early), Firebase sync, teacher web dashboard (12–13), ~~Vosk offline speech~~ (done), ~~Filipino speech recognition~~ (Phase 5c), more stories (with `tools/add_stories.py`).
