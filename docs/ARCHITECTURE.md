# ReadAloud Buddy

A school project (CS 403 – Intelligent Agents) that we also want to turn into a real, working app.

**What it is:** an Android app (Flutter) where a child aged 5–9 reads a short story aloud. Speech recognition follows along word by word. An intelligent agent ("Buddy") scores the reading, gives the smallest helpful hint when the child is stuck, keeps a 0–100 reading score (shown to grown-ups as a DepEd CRLA profile, to children as a friendly rank), tracks which sounds they struggle with, and picks the next story by predicting how many words the child will read correctly. Parents get a weekly summary; teachers get a dashboard (later phase).

**Why:** SDG 4 (Quality Education). ~91% of Filipino 10-year-olds can't read and understand a simple text ("learning poverty"). Kids need daily read-aloud practice with feedback, and teachers with 40+ students can't listen to everyone.

## Documents
- `docs/PROJECT_BRIEF.md` – users, features, scope, what's in/out of the MVP
- `docs/AGENT_SPEC.md` – the agent rules and formulas
- `docs/SCREENS.md` + `docs/mockups/s01.png … s13.png` – the approved UI design.
- `docs/DATA_MODEL.md` – local database tables
- `docs/BUILD_PLAN.md` – phases. Work one phase at a time.
- `assets/data/stories.json` – the stories (EN + FIL) with tagged words, questions and a 0–100 difficulty. This is the app's content. Add stories with `tools/add_stories.py` (`docs/ADDING_STORIES.md`).
- `docs/dataset/*.csv` – simulated reading data; use it as test fixtures for the agent.

## Tech stack (decided)
- Flutter + Dart, Android first. State management: Riverpod.
- Local storage: SQLite via `drift` (or `sqflite` if drift causes trouble). Everything works offline.
- Speech: Vosk offline (English) is the only recognizer, behind a `SpeechService` interface. Filipino stories use tap-to-read for now. `FakeSpeechService` (tap-to-read) is also a hidden developer/demo option and is used by tests.
- Text-to-speech for hints: `flutter_tts`.
- Fonts: Nunito (UI), Lexend (dyslexia mode) via `google_fonts` or bundled assets.
- Teacher dashboard + cloud sync (Firebase) are a **later phase**, not MVP.

## Architecture rules
- The agent lives in `lib/agent/` as **pure Dart with no Flutter imports**, so it is fully unit-testable. UI calls the agent; the agent never touches widgets.
- Every agent rule in `AGENT_SPEC.md` gets a unit test in `test/agent/`.
- All tunable numbers (thresholds, BKT params, hint wait time) live in one file: `lib/agent/agent_config.dart`.
- Privacy: never store or upload audio. Learners are stored by nickname + generated id only.
- Child-facing UI: big tap targets (min 56dp), one main action per screen, spoken instructions, no typing for the child, no ads, no purchases.
