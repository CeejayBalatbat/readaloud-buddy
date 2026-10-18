# ReadAloud Buddy

An Android app (Flutter) where a child aged 5–9 reads a short story aloud and an intelligent agent ("Buddy") listens, gives hints, keeps a 0–100 reading score (DepEd CRLA profiles for grown-ups, friendly ranks for children) and recommends books by predicting how many words the child will read correctly. CS 403 – Intelligent Agents project, SDG 4.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/](docs/) for the tech stack, the full brief, agent spec, screens and build plan.

## Run it

```sh
python tools/get_vosk_model.py   # once: downloads the offline English speech model (39 MB)
flutter pub get
flutter run        # with an Android emulator or phone connected
flutter test       # unit + widget tests
```

The speech model isn't in git (it's 39 MB); `get_vosk_model.py` downloads it
from alphacephei.com, checks its MD5 and puts it in `assets/models/`, where
the build bundles it. Without it the app still runs, but "Offline (Vosk)"
says the mic isn't ready; pick another option in Settings.

To install a smaller app on a phone, build one APK per phone type:

```sh
flutter build apk --release --split-per-abi
# most phones: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## How Buddy listens

English stories use **Vosk offline** (small English model, on the phone,
never needs internet). It listens only for the words on the current page
(grammar mode) plus `[unk]`, continuously, with no restart gaps.

**Filipino stories use Vosk too**, with the `vosk-model-tl-ph-generic-0.6`
model (314 MB download, 775 MB on the phone, about 860 MB of memory while
in use). It is not in the APK: the app downloads it the first time a
Filipino story opens (internet needed once, MD5-checked), or you can copy
the zip onto the phone (see `docs/AGENT_SPEC.md`, "Speech recognition").
It has no grammar mode, so it hears free text and Buddy matches it against
the page. On phones where it is too heavy, Filipino falls back to tap to
read by itself, and Settings says why.

> ⚠️ **License:** the Filipino model is © 2020 Federico Ang, licensed
> **CC BY-NC-SA 4.0 — non-commercial use only** (share-alike, with
> attribution). It is fine for this school project; a commercial release
> would need another Filipino model or the author's permission. The
> English model and the app's own code don't have this limit.

If Vosk fails or crashes on a phone, stories switch to tap to read and
Settings → How Buddy listens shows why, with "Try offline again".
**Tap to read for every story** is a hidden developer/demo switch:
long-press the "How Buddy listens" card.

`packages/vosk_flutter` is a vendored copy of the official `vosk_flutter`
plugin (Apache 2.0), updated for Dart 3; see its README for the changes.

## Project layout

| Folder | What lives there |
|---|---|
| `lib/agent/` | Buddy's rules – pure Dart, no Flutter imports (Phase 1) |
| `lib/data/` | Story models, database, repositories |
| `lib/speech/` | `SpeechService` interface + Vosk and tap-to-read implementations |
| `packages/vosk_flutter/` | Vendored Vosk plugin (see its README) |
| `tools/` | `add_stories.py` (add books, see `docs/ADDING_STORIES.md`), `check_stories.py`, `story_difficulty.py`, `gen_phonics.py` (hint data), `get_vosk_model.py`, `check_vosk_vocab.py` |
| `lib/ui/screens/`, `lib/ui/widgets/`, `lib/ui/theme/` | Screens, shared widgets, colors and theme |
| `assets/data/` | `stories.json` (the books, each with a 0–100 difficulty), `sound_patterns.json`, `phonics.json`, `vosk_vocab.json` |
| `assets/models/` | The Vosk model zip (downloaded, not in git) |
| `test/` | Tests; agent rule tests go in `test/agent/` |

## Known limitations

- **The app is fully offline.** No audio is ever stored or uploaded.
- **Filipino listening needs a one-time download** (314 MB) or a copied zip, and about 1.1 GB of free space while installing. Its model is non-commercial (CC BY-NC-SA 4.0).
- **Fonts:** Nunito and Lexend (dyslexia mode) are bundled in `assets/fonts`.
- See [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md) for everything found but not fixed yet.
