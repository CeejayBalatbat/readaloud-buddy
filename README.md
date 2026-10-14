# ReadAloud Buddy

An Android app (Flutter) where a child aged 5–9 reads a short story aloud and an intelligent agent ("Buddy") listens, gives hints, and adapts the reading level. CS 403 – Intelligent Agents project, SDG 4.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/](docs/) for the tech stack, the full brief, agent spec, screens and build plan.

## Run it

```sh
flutter pub get
flutter run        # with an Android emulator or phone connected
flutter test       # unit + widget tests
```

## Project layout

| Folder | What lives there |
|---|---|
| `lib/agent/` | Buddy's rules – pure Dart, no Flutter imports (Phase 1) |
| `lib/data/` | Story models, database, repositories |
| `lib/speech/` | `SpeechService` interface + fake and Android implementations (Phases 3–4) |
| `lib/ui/screens/`, `lib/ui/widgets/`, `lib/ui/theme/` | Screens, shared widgets, colors and theme |
| `assets/data/` | `stories.json` (20 stories) and `sound_patterns.json` |
| `test/` | Tests; agent rule tests go in `test/agent/` |

## Known limitations

- **Speech recognition may need internet.** The app uses Android's built-in recognizer (`speech_to_text`). It tries on-device recognition first and falls back to online recognition. On-device support depends on the phone and on downloaded language packs; Filipino (`fil-PH`) is often online-only. Fully offline speech (Vosk) is a later phase. No audio is ever stored or uploaded by the app itself.
- **Fonts download on first launch.** Nunito/Lexend come from `google_fonts` and are fetched once, then cached. Before release they should be bundled as assets so the app looks right fully offline.
