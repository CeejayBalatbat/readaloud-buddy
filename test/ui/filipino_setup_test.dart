import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/app/current_learner.dart';
import 'package:readaloud_buddy/data/repositories/learner_repository.dart';
import 'package:readaloud_buddy/speech/filipino_model.dart';
import 'package:readaloud_buddy/speech/model_store.dart';
import 'package:readaloud_buddy/ui/screens/filipino_setup_screen.dart';
import 'package:readaloud_buddy/ui/screens/home_shell.dart';
import 'package:readaloud_buddy/ui/screens/read_along_screen.dart';
import 'package:readaloud_buddy/ui/story_flow.dart';

import 'test_app.dart';

/// A model store whose download the test drives step by step.
class StepStore extends ModelStore {
  StepStore(Directory dir)
      : super(spec: filipinoModel, installDir: () async => dir, copyDir: () async => dir);

  final steps = StreamController<ModelStatus>();
  bool ready = false;
  int downloads = 0;

  @override
  Future<String?> readyPath() async => ready ? '/model' : null;

  @override
  Stream<ModelStatus> download({CancelToken? cancel}) {
    downloads++;
    return steps.stream;
  }

  @override
  Stream<ModelStatus> installCopied() async* {
    yield const ModelStatus(ModelPhase.failed, error: 'No copied file found. Put it in /copy.');
  }

  @override
  Future<void> delete() async => ready = false;
}

void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  late Directory dir;
  late StepStore store;

  TestApp app0() {
    dir = Directory.systemTemp.createTempSync('fil_setup');
    addTearDown(() => dir.deleteSync(recursive: true));
    store = StepStore(dir);
    return TestApp(filipinoStore: store);
  }

  /// Home with a Filipino reader, then tap the first Filipino book.
  Future<TestApp> openFilipinoStory(WidgetTester tester) async {
    final app = app0();
    await tester.runAsync(() async {
      final jojo = await LearnerRepository(app.db)
          .create(nickname: 'Jojo', grade: 1, languages: 'FIL', readingScore: 30);
      await app.container.read(currentLearnerProvider.notifier).select(jojo.id);
    });
    await app.pump(tester, const HomeShell());
    await settle(tester);
    await tester.tap(find.text('Stories'));
    await settle(tester);
    final fil = TestApp.stories.firstWhere(
        (s) => s.language == 'FIL' && find.text(s.title).evaluate().isNotEmpty);
    await tester.tap(find.text(fil.title));
    await settle(tester);
    return app;
  }

  testWidgets('first Filipino story: download with a progress bar, then read', (tester) async {
    final app = await openFilipinoStory(tester);
    expect(find.text('Filipino listening'), findsOneWidget);
    expect(find.textContaining('internet is needed now'), findsOneWidget);
    expect(find.textContaining('CC BY-NC-SA 4.0'), findsOneWidget);

    await tester.tap(find.text('Download (314 MB)'));
    await settle(tester);
    store.steps.add(ModelStatus(ModelPhase.downloading,
        received: 100 * 1024 * 1024, total: filipinoModel.sizeBytes));
    await settle(tester);
    expect(find.text('Downloading… 100 of 314 MB'), findsOneWidget);
    await app.screenshot(tester, 's05c_downloading');

    store.steps.add(const ModelStatus(ModelPhase.verifying));
    await settle(tester);
    expect(find.text('Checking the file…'), findsOneWidget);
    store.ready = true;
    store.steps.add(const ModelStatus(ModelPhase.ready, path: '/model'));
    await store.steps.close();
    await settle(tester);
    expect(find.text('✓ Filipino listening is ready!'), findsOneWidget);
    await tester.tap(find.text("📖 Let's read!"));
    await settle(tester);
    expect(find.text('Help'), findsOneWidget); // the story opened
    expect(app.container.read(filipinoModelProvider).isReady, isTrue);
  });

  testWidgets('a failed download says why and offers Try again', (tester) async {
    await openFilipinoStory(tester);
    await tester.tap(find.text('Download (314 MB)'));
    await settle(tester);
    store.steps.add(const ModelStatus(ModelPhase.failed, error: 'No internet. Connect to Wi-Fi and try again.'));
    await store.steps.close();
    await settle(tester);
    expect(find.text('No internet. Connect to Wi-Fi and try again.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('"Not now" reads by tapping and is not asked again', (tester) async {
    final app = await openFilipinoStory(tester);
    await tester.tap(find.text('Not now (read by tapping)'));
    await settle(tester);
    expect(find.text('Help'), findsOneWidget); // the story opened, tap to read
    expect(find.text(ReadAlongScreenNotes.filipino), findsOneWidget);

    // Next Filipino story: straight in.
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.popUntil((r) => r.isFirst);
    await settle(tester);
    final fil = TestApp.stories.firstWhere(
        (s) => s.language == 'FIL' && find.text(s.title).evaluate().isNotEmpty);
    unawaited(startStory(tester.element(find.text(fil.title)), fil));
    await settle(tester);
    expect(find.text('Filipino listening'), findsNothing);
    expect(store.downloads, 0);
    expect(app.container.read(filipinoSetupDeclinedProvider).value, isTrue);
  });

  testWidgets('copied file: checks the app folder and says where to put it', (tester) async {
    await openFilipinoStory(tester);
    await tester.tap(find.text('Check for a copied file'));
    await settle(tester);
    expect(find.text('No copied file found. Put it in /copy.'), findsOneWidget);
  });

  testWidgets('Settings: set up, and delete to free the space', (tester) async {
    final app = app0();
    store.ready = true;
    await tester.runAsync(() async {
      final mia = await LearnerRepository(app.db).create(nickname: 'Mia', grade: 2, languages: 'EN');
      await app.container.read(currentLearnerProvider.notifier).select(mia.id);
    });
    await app.pump(tester, const HomeShell());
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    final delete = find.textContaining('Delete Filipino listening');
    await tester.scrollUntilVisible(delete, 300);
    await settle(tester);
    expect(find.textContaining('Filipino stories: offline listening'), findsOneWidget);
    await tester.tap(delete);
    await settle(tester);
    expect(find.text('Set up Filipino listening…'), findsOneWidget);
    await tester.tap(find.text('Set up Filipino listening…'));
    await settle(tester);
    expect(find.byType(FilipinoSetupScreen), findsOneWidget);
  });
}
