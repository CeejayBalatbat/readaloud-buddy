import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/app/current_learner.dart';
import 'package:readaloud_buddy/data/db/app_database.dart';
import 'package:readaloud_buddy/data/repositories/learner_repository.dart';
import 'package:readaloud_buddy/data/repositories/settings_repository.dart';
import 'package:readaloud_buddy/speech/speech_providers.dart';
import 'package:readaloud_buddy/ui/screens/home_shell.dart';
import 'package:readaloud_buddy/ui/screens/read_along_screen.dart';
import 'package:readaloud_buddy/ui/theme/reading_style.dart';

import 'test_app.dart';

void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<TestApp> withReader(WidgetTester tester,
      {bool dyslexia = false, String? pin}) async {
    final app = TestApp();
    await tester.runAsync(() async {
      final repo = LearnerRepository(app.db);
      final mia = await repo.create(nickname: 'Mia', grade: 2, languages: 'EN');
      if (dyslexia) await repo.update(mia.copyWith(dyslexiaMode: true));
      await app.container.read(currentLearnerProvider.notifier).select(mia.id);
      if (pin != null) await SettingsRepository(app.db).set(SettingKeys.parentPin, pin);
    });
    return app;
  }

  Future<Learner> reader(WidgetTester tester, TestApp app) async =>
      (await tester.runAsync(() => LearnerRepository(app.db).all()))!.single;

  TextStyle styleOf(WidgetTester tester, String word) =>
      tester.widget<Text>(find.text(word).first).style!;

  group('ReadingStyle', () {
    test('dyslexia mode: Lexend, wider spacing, cream page', () {
      const normal = ReadingStyle();
      const dys = ReadingStyle(dyslexia: true);
      expect(normal.fontFamily, 'Nunito');
      expect(dys.fontFamily, 'Lexend');
      expect(dys.wordGap, greaterThan(normal.wordGap));
      expect(dys.letterSpacing, greaterThan(0));
      expect(dys.page, isNot(normal.page));
    });

    test('high contrast: black on white; text size scales the font', () {
      const hc = ReadingStyle(highContrast: true, scale: 1.4);
      expect(hc.ink, const Color(0xFF000000));
      expect(hc.page, const Color(0xFFFFFFFF));
      expect(hc.text(20).fontSize, 28);
    });
  });

  testWidgets('Settings is screen 10: preview + comfort switches save',
      (tester) async {
    final app = await withReader(tester);
    await app.pump(tester, const HomeShell());
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    expect(find.text('Reading comfort'), findsOneWidget);
    expect(find.text('🔒 Grown-up'), findsOneWidget);
    expect(styleOf(tester, 'kite').fontFamily, 'Nunito');

    await tester.tap(find.byType(Switch).first); // dyslexia-friendly mode
    await settle(tester);
    expect((await reader(tester, app)).dyslexiaMode, isTrue);
    expect(styleOf(tester, 'kite').fontFamily, 'Lexend'); // live preview
    expect(find.text('8 sec'), findsOneWidget); // automatic wait in dyslexia mode
    await app.screenshot(tester, 's10_comfort');

    await tester.tap(find.byType(Switch).at(1)); // high contrast
    await settle(tester);
    expect((await reader(tester, app)).highContrast, isTrue);
  });

  testWidgets('text size and hint wait sliders save on the reader',
      (tester) async {
    final app = await withReader(tester);
    await app.pump(tester, const HomeShell());
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    final sliders = find.byType(Slider);
    await tester.drag(sliders.first, const Offset(400, 0)); // all the way right
    await settle(tester);
    expect((await reader(tester, app)).textScale, textScales.last);
    expect(find.text('Extra large'), findsOneWidget);

    await tester.drag(sliders.at(1), const Offset(400, 0));
    await settle(tester);
    expect((await reader(tester, app)).hintWaitSec, 12);
    await tester.tap(find.text('Use automatic'));
    await settle(tester);
    expect((await reader(tester, app)).hintWaitSec, isNull);
  });

  testWidgets('How Buddy listens: Offline (Vosk) by default; choices save',
      (tester) async {
    final app = await withReader(tester);
    await app.pump(tester, const HomeShell());
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    final phone = find.text('🎤 Phone recognizer');
    await tester.scrollUntilVisible(phone, 300);
    await settle(tester);
    expect(app.container.read(speechModeProvider).value, SpeechMode.vosk);
    await tester.tap(phone);
    await settle(tester);
    expect(app.container.read(speechModeProvider).value, SpeechMode.voice);
    final saved = await tester.runAsync(
        () => SettingsRepository(app.db).get(SettingKeys.speechMode));
    expect(saved, 'voice');
  });

  testWidgets('with a PIN, Settings asks for it; a wrong one is refused',
      (tester) async {
    final app = await withReader(tester, pin: '2468');
    await app.pump(tester, const HomeShell());
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    expect(find.text('Grown-ups only'), findsOneWidget);
    expect(find.text('Reading comfort'), findsNothing);
    for (final d in ['1', '1', '1', '1']) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
    expect(find.text("That's not it. Try again."), findsOneWidget);
    for (final d in ['2', '4', '6', '8']) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
    await settle(tester);
    expect(find.text('Reading comfort'), findsOneWidget);
    // Leaving Settings locks it again.
    await tester.tap(find.text('Home'));
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    expect(find.text('Grown-ups only'), findsOneWidget);
  });

  testWidgets('a parent sets a PIN from Settings', (tester) async {
    final app = await withReader(tester);
    await app.pump(tester, const HomeShell());
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    final setPin = find.text('Set PIN');
    await tester.scrollUntilVisible(setPin, 300);
    await tester.tap(setPin);
    await settle(tester);
    for (var round = 0; round < 2; round++) {
      for (final d in ['1', '3', '5', '7']) {
        await tester.tap(find.text(d).last);
        await tester.pump();
      }
      await settle(tester);
    }
    final saved = await tester.runAsync(
        () => SettingsRepository(app.db).get(SettingKeys.parentPin));
    expect(saved, '1357');
  });

  testWidgets("the story uses the reader's style: Lexend on a cream page",
      (tester) async {
    final app = await withReader(tester, dyslexia: true);
    await app.pump(
        tester, ReadAlongScreen(story: TestApp.story('S06'), onFinished: (_) {}));
    await settle(tester);
    expect(styleOf(tester, 'Mia').fontFamily, 'Lexend');
    await app.screenshot(tester, 's05_dyslexia');
  });

  testWidgets('"Read instructions aloud" off: Buddy shows but does not say them',
      (tester) async {
    final app = await withReader(tester);
    await app.pump(
        tester,
        ReadAlongScreen(
            story: TestApp.story('S06'), readAloud: false, onFinished: (_) {}));
    // Review mode: read page 1 with a miss so the review intro appears.
    await tester.longPress(find.bySemanticsLabel('Mia'));
    await tester.pump();
    for (final w in TestApp.story('S06').words.skip(1).take(11)) {
      app.speech.hear(w.word);
      await tester.pump();
    }
    expect(find.text('Next page →'), findsOneWidget);
    expect(app.tts.spoken, isEmpty);
  });
}
