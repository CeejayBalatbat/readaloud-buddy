import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/phonics.dart';
import 'package:readaloud_buddy/app/current_learner.dart';
import 'package:readaloud_buddy/app/home_data.dart';
import 'package:readaloud_buddy/app/reading_controller.dart';
import 'package:readaloud_buddy/data/database_providers.dart';
import 'package:readaloud_buddy/data/db/app_database.dart';
import 'package:readaloud_buddy/data/sound_patterns.dart';
import 'package:readaloud_buddy/data/story.dart';
import 'package:readaloud_buddy/data/story_providers.dart';
import 'package:readaloud_buddy/speech/fake_speech_service.dart';
import 'package:readaloud_buddy/speech/speech_providers.dart';
import 'package:readaloud_buddy/speech/speech_service.dart';
import 'package:readaloud_buddy/speech/tts_service.dart';
import 'package:readaloud_buddy/speech/vosk_health.dart';
import 'package:readaloud_buddy/ui/theme/app_theme.dart';

/// Shared setup for screen tests: real Nunito font, phone-sized screen,
/// in-memory database, tap-to-read speech, silent TTS and a manual clock.
class TestApp {
  TestApp({SpeechService? speechService}) {
    _speechService = speechService;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  final db = AppDatabase(NativeDatabase.memory());
  final speech = FakeSpeechService();
  SpeechService? _speechService;
  final tts = SilentTtsService();
  final clock = ManualClock();
  final _shotKey = GlobalKey();

  static final List<Story> stories =
      parseStories(File('assets/data/stories.json').readAsStringSync());
  static Story story(String id) => stories.firstWhere((s) => s.id == id);

  static final PhonicsDictionary phonics =
      PhonicsDictionary.parse(File('assets/data/phonics.json').readAsStringSync());

  static bool _fontsLoaded = false;

  /// Loads the bundled Nunito and Lexend so text renders like on the phone.
  static Future<void> loadFonts() async {
    if (_fontsLoaded) return;
    final loader = FontLoader('Nunito');
    for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
      loader.addFont(rootBundle.load('assets/fonts/Nunito-$w.ttf'));
    }
    await loader.load();
    final lexend = FontLoader('Lexend');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      lexend.addFont(rootBundle.load('assets/fonts/Lexend-$w.ttf'));
    }
    await lexend.load();
    _fontsLoaded = true;
  }

  /// "Now" for greetings, streaks and today's minutes.
  DateTime now = DateTime(2026, 10, 15, 15, 30);

  /// Created on first use, so tests can set up data before [pump].
  late final ProviderContainer container = ProviderContainer(overrides: [
    nowProvider.overrideWithValue(() => now),
    appDatabaseProvider.overrideWithValue(db),
    speechServiceProvider.overrideWith((ref, language) => _speechService ?? speech),
    ttsServiceProvider.overrideWithValue(tts),
    readingClockProvider.overrideWithValue(() => clock),
    storiesProvider.overrideWith((ref) async => stories),
    phonicsProvider.overrideWith((ref) async => phonics),
    soundPatternsProvider.overrideWith((ref) async =>
        parseSoundPatterns(File('assets/data/sound_patterns.json').readAsStringSync())),
    voskMissingWordsProvider.overrideWith((ref) async => const <String>{}),
    exitInfoProvider.overrideWithValue(const NoExitInfo()),
  ]);

  Future<void> pump(WidgetTester tester, Widget home) async {
    await loadFonts();
    // The app loads this on the splash screen, before any story opens.
    await tester.runAsync(() => container.read(phonicsProvider.future));
    await tester.runAsync(() => container.read(predictorProvider.future));
    await tester.runAsync(() => container.read(currentLearnerProvider.future));
    // The mockups are drawn for a 390 × 844 phone.
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });

    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: _shotKey,
        child: MaterialApp(
          theme: buildAppTheme(),
          debugShowCheckedModeBanner: false,
          home: home,
        ),
      ),
    ));
    await tester.pump();
  }

  /// Moves reading time forward and lets the hint timer run.
  Future<void> wait(WidgetTester tester, double seconds) async {
    clock.advance(Duration(milliseconds: (seconds * 1000).round()));
    await tester.pump(const Duration(milliseconds: 250));
  }

  /// Saves a PNG of the screen when run with
  /// `--dart-define=SCREENSHOT_DIR=<folder>`; does nothing otherwise.
  Future<void> screenshot(WidgetTester tester, String name) async {
    const dir = String.fromEnvironment('SCREENSHOT_DIR');
    if (dir.isEmpty) return;
    // Let the SVGs finish decoding before taking the picture.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }
}

/// Android has no record of how the last run ended.
class NoExitInfo implements ExitInfo {
  const NoExitInfo();
  @override
  Future<AppExit?> lastExit() async => null;
}
