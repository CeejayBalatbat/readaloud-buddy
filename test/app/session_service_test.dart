import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/app/session_service.dart';
import 'package:readaloud_buddy/data/db/app_database.dart';
import 'package:readaloud_buddy/data/repositories/learner_repository.dart';
import 'package:readaloud_buddy/data/repositories/progress_repository.dart';
import 'package:readaloud_buddy/data/repositories/session_repository.dart';
import 'package:readaloud_buddy/data/story.dart';

/// Reads [story] 1 s per word; words at [misread] positions are misread.
List<WordOutcome> read(Story story, {Set<int> misread = const {}}) {
  final t = ReadingTracker(words: story.words, language: story.language);
  for (var i = 0; i < story.words.length; i++) {
    t.onWordHeard(misread.contains(i) ? 'zzxq' : story.words[i].word,
        Duration(seconds: i + 1));
  }
  return t.outcomes;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final stories =
      parseStories(File('assets/data/stories.json').readAsStringSync());
  final s06 = stories.firstWhere((s) => s.id == 'S06'); // level 2, 45 words

  late AppDatabase db;
  late SessionService service;
  late Learner mia;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = SessionService(db);
    mia = await LearnerRepository(db)
        .create(nickname: 'Mia', grade: 2, languages: 'EN', currentLevel: 2);
  });
  tearDown(() => db.close());

  Future<StoryOutcome> finish(List<WordOutcome> words, int questions,
          {List<HintAttempt> hints = const []}) async =>
      service.finishStory(
        learner: (await LearnerRepository(db).byId(mia.id))!,
        story: s06,
        outcomes: words,
        readingSeconds: 60,
        questionsCorrect: questions,
        hintAttempts: hints,
        startedAt: DateTime(2026, 10, 15, 15),
      );

  test('a perfect reading: Independent, 3 stars, one step from moving up',
      () async {
    final out = await finish(read(s06), 3);
    expect(out.scores.accuracy, 1.0);
    expect(out.scores.wcpm, 45);
    expect(out.philiri.overall, PhilIriLevel.independent);
    expect(out.decision.move, LevelMove.stay);
    expect(out.stars, 3);
    expect(out.plan, contains("move up to Level 3"));
    final learner = await LearnerRepository(db).byId(mia.id);
    expect(learner!.stars, 3);

    // A second Independent story moves Mia up (§5).
    final second = await finish(read(s06), 3);
    expect(second.decision.move, LevelMove.up);
    expect((await LearnerRepository(db).byId(mia.id))!.currentLevel, 3);
  });

  test('a hard reading moves down and adds tricky words', () async {
    final out = await finish(read(s06, misread: {0, 3, 6, 9, 12, 15}), 1);
    expect(out.philiri.word, PhilIriLevel.frustration);
    expect(out.decision.move, LevelMove.down);
    expect(out.stars, 1);
    expect(out.newTrickyWords, contains('mia'));
    expect((await LearnerRepository(db).byId(mia.id))!.currentLevel, 1);
  });

  test('mastery, hint stats and the saved session are all updated', () async {
    final out = await finish(read(s06, misread: {11}), 2, hints: const [
      HintAttempt(level: 1, success: true),
    ]);
    final progress = ProgressRepository(db);
    final mastery = await progress.loadMastery(mia.id);
    expect(mastery.observationsOf('EN-SV'), greaterThan(0));
    expect((await progress.loadHintStats(mia.id)).uses(1), 1);
    final saved = await SessionRepository(db).byId(out.sessionId);
    expect(saved!.words, hasLength(s06.words.length));
    expect(saved.session.questionsCorrect, 2);
    expect(saved.session.philiriLevel, out.philiri.overall);
  });

  test('two Frustration sessions out of three flag the teacher', () async {
    await finish(read(s06, misread: {0, 3, 6, 9, 12, 15}), 0);
    final out = await finish(read(s06, misread: {0, 3, 6, 9, 12, 15}), 0);
    expect(out.flags, isNotEmpty);
    expect(await ProgressRepository(db).unseenFlags(mia.id), isNotEmpty);
  });
}
