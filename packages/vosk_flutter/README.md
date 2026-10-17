# vosk_flutter (vendored)

A copy of the official [vosk_flutter 0.3.48](https://pub.dev/packages/vosk_flutter)
by Alpha Cephei (Apache 2.0, see LICENSE), used by ReadAloud Buddy for
offline speech recognition on Android.

Why vendored: 0.3.48 (the latest, 2023) declares `sdk: <3.0.0` and pins
`http ^0.13` and `archive ^3`, so it cannot be added to a Dart 3 app that
also uses current packages. Changes from the original:

- `pubspec.yaml`: Dart 3; `archive ^4`, `http ^1`; Android only (the app is
  Android-only); dropped the CLI tool and `permission_handler` (the app asks
  for the microphone itself, through speech_to_text).
- `lib/src/vosk_flutter.dart`: `initSpeechService` no longer requests the
  microphone permission (see above).
- `lib/src/generated_vosk_bindings.dart`: the five `Opaque` FFI types are
  `final class` (required by Dart 3).
- `android/build.gradle`: AGP 8 `namespace`, no buildscript/AGP pin (uses
  the app's), Java 17, `vosk-android 0.3.47` from Maven Central, and
  ProGuard consumer rules: keep all of JNA and `org.vosk`, and
  `-dontwarn java.awt.**` (JNA's desktop code; release builds fail without it). Manifest `package` attribute removed.
- Not copied: example app, tests, Gradle wrapper, Linux/Windows parts.

The Java plugin code and the rest of the Dart code are unchanged.
