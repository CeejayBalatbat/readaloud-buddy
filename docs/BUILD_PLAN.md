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
Screens 1, 3, 4, 5, 6, 7, 8 using `FakeSpeechService` (tap a word = read correctly, long-press = misread, wait = hesitation/hint). Wire to the agent and database so results, levels and mastery really update.
**Done when:** I can set up a reader, read a story by tapping, see hints, answer questions, and see Buddy's plan change my level.

## Phase 4 – Real speech recognition
`SpeechServiceAndroid` with `speech_to_text` (en-US, fil-PH), partial results, word alignment (AGENT_SPEC §1), auto-restart when the recognizer stops on silence. Placement check (screen 2). Hint audio with flutter_tts.
**Done when:** I can read a Level 1 story aloud on my phone and the words turn green as I read.

## Phase 5 – Games, settings, polish
Screen 9 (build-the-word), screen 10 (dyslexia mode, text size, contrast, read aloud, hint wait, multiple readers, parent PIN), Buddy pet growth, stars, streak, daily minutes.
**Done when:** a full day of use works end to end, offline.

## Phase 6 – Later
~~Parent weekly summary (11)~~ (built early), Firebase sync, teacher web dashboard (12–13), Vosk offline speech, more stories.
