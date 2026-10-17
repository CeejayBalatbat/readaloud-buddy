# ReadAloud Buddy

An Android app (Flutter) where a child aged 5–9 reads a short story aloud and an intelligent agent ("Buddy") listens, gives hints, and adapts the reading level. CS 403 – Intelligent Agents project, SDG 4.

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

## How Buddy listens (Settings → How Buddy listens)

| Option | What it is | Internet |
|---|---|---|
| 🎧 **Offline (Vosk)** (default) | Vosk small English model, on the phone. Listens only for the words on the current page (grammar mode) plus `[unk]`, continuously, with no restart gaps. | never |
| 🎤 **Phone recognizer** | Android's recognizer via `speech_to_text`, on-device first, online fallback. | sometimes |
| 👆 **Tap to read** | Tap a word = read, long-press = misread. For testing without speaking. | never |

Filipino stories use the phone recognizer when it knows Filipino (fil-PH),
otherwise tap to read: the only Filipino Vosk model is 314 MB, has a fixed
vocabulary (no grammar mode) and a non-commercial license.

`packages/vosk_flutter` is a vendored copy of the official `vosk_flutter`
plugin (Apache 2.0), updated for Dart 3; see its README for the changes.

## Project layout

| Folder | What lives there |
|---|---|
| `lib/agent/` | Buddy's rules – pure Dart, no Flutter imports (Phase 1) |
| `lib/data/` | Story models, database, repositories |
| `lib/speech/` | `SpeechService` interface + Vosk, Android and tap-to-read implementations |
| `packages/vosk_flutter/` | Vendored Vosk plugin (see its README) |
| `tools/` | `gen_phonics.py` (hint data), `get_vosk_model.py`, `check_vosk_vocab.py` |
| `lib/ui/screens/`, `lib/ui/widgets/`, `lib/ui/theme/` | Screens, shared widgets, colors and theme |
| `assets/data/` | `stories.json` (20 stories), `sound_patterns.json`, `phonics.json`, `vosk_vocab.json` |
| `assets/models/` | The Vosk model zip (downloaded, not in git) |
| `test/` | Tests; agent rule tests go in `test/agent/` |

## Known limitations

- **English is fully offline** with Vosk. The phone recognizer option, and Filipino, may need internet (Filipino `fil-PH` is often online-only). No audio is ever stored or uploaded by the app itself.
- **Some phones beep** each time the phone recognizer restarts after a silence. Vosk listens continuously, so it doesn't.
- **Fonts:** Nunito and Lexend (dyslexia mode) are bundled in `assets/fonts`.
- See [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md) for everything found but not fixed yet.
