import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/app/home_data.dart';
import 'package:readaloud_buddy/app/session_service.dart';
import 'package:readaloud_buddy/data/db/app_database.dart';
import 'package:readaloud_buddy/data/repositories/learner_repository.dart';
import 'package:readaloud_buddy/data/repositories/progress_repository.dart';
import 'package:readaloud_buddy/data/repositories/session_repository.dart';
import 'package:readaloud_buddy/data/story.dart';

import '../agent/fixtures.dart' show loadPatternDifficulty;

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
  final s06 = stories.firstWhere((s) => s.id == 'S06'); // difficulty 38, 45 words
  final predictor = AccuracyPredictor(patternDifficulty: loadPatternDifficulty());

  late AppDatabase db;
  late SessionService service;
  late Learner mia;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = SessionService(db, predictor: predictor);
    mia = await LearnerRepository(db)
        .create(nickname: 'Mia', grade: 2, languages: 'EN', readingScore: 30);
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

  test('every 5th story grows Buddy a new leaf', () async {
    final leaves = [for (var i = 0; i < 6; i++) (await finish(read(s06), 2)).newLeaf];
    expect(leaves, [false, false, false, false, true, false]);
  });

  test('Buddy growth: a leaf per 5 stories, stages Baby → Super', () {
    expect(const BuddyGrowth(4).leaves, 0);
    expect(const BuddyGrowth(4).stageName, 'Baby Buddy');
    expect(const BuddyGrowth(5).leaves, 1);
    expect(const BuddyGrowth(5).stageName, 'Little Buddy');
    expect(const BuddyGrowth(15).stageName, 'Big Buddy');
    expect(const BuddyGrowth(30).stageName, 'Super Buddy');
    expect(const BuddyGrowth(10).justGotLeaf, isTrue);
    expect(const BuddyGrowth(0).justGotLeaf, isFalse);
  });

  test('a perfect reading: Independent, 3 stars, the score goes up (§5)', () async {
    final out = await finish(read(s06), 3);
    expect(out.scores.accuracy, 1.0);
    expect(out.scores.wcpm, 45);
    expect(out.philiri.overall, PhilIriLevel.independent);
    expect(out.stars, 3);
    expect(out.score.before, 30);
    expect(out.score.after, greaterThan(30));
    expect(out.score.evidence.difficulty, s06.difficulty);
    final learner = (await LearnerRepository(db).byId(mia.id))!;
    expect(learner.stars, 3);
    expect(learner.readingScore, out.score.after);

    // Strong readings carry Mia into the next profile; Buddy celebrates.
    var next = out;
    while (const ReadingScorer().profileOf(next.score.after) == ReadingProfile.highEmerging) {
      next = await finish(read(s06), 3);
    }
    expect(next.plan, 'Wow! You grew into a 🍃 Leaf reader! Hooray!');
  });

  test('a hard reading: the score goes down, tricky words are added', () async {
    final out = await finish(read(s06, misread: {0, 3, 6, 9, 12, 15}), 1);
    expect(out.philiri.word, PhilIriLevel.frustration);
    expect(out.stars, 1);
    expect(out.score.after, lessThan(30));
    expect(out.newTrickyWords, contains('mia'));
    expect((await LearnerRepository(db).byId(mia.id))!.readingScore, out.score.after);
  });

  test('prediction (§9): made before the reading, saved, and learned from', () async {
    final expected = predictor.accuracy(s06, SoundMastery(), score: 30, bias: 1.6);
    final out = await finish(read(s06, misread: {for (var i = 0; i < 36; i += 3) i}), 1);
    expect(out.predictedAccuracy, closeTo(expected, 1e-12));
    expect(out.biasBefore, 1.6);
    // Mia read worse than predicted, so Buddy's next guesses come down.
    expect(out.scores.accuracy, lessThan(out.predictedAccuracy));
    expect(out.biasAfter, lessThan(out.biasBefore));
    expect((await LearnerRepository(db).byId(mia.id))!.bias(), out.biasAfter);
    final saved = await SessionRepository(db).byId(out.sessionId);
    expect(saved!.session.predictedAccuracy, closeTo(expected, 1e-12));
    expect((saved.session.scoreBefore, saved.session.scoreAfter),
        (out.score.before, out.score.after));
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

  group('reading check (§6)', () {
    test('passages are the opening sentences of the chosen books', () {
      for (final lang in ['EN', 'FIL']) {
        final check = ReadingCheck(stories: stories, language: lang);
        while (!check.isDone) {
          final story = check.nextStory!;
          final p = placementPassage(story);
          check.record(story, accuracy: 0.99, wcpm: 60);
          expect(p.story.language, lang);
          expect(p.words, isNotEmpty);
          expect(p.words.length, lessThanOrEqualTo(25), reason: p.story.id);
          // Ends at the end of a sentence.
          final last = p.story.text.split(' ')[p.words.length - 1];
          expect(last, matches(RegExp(r'[.!?]["”’]?$')), reason: p.story.id);
        }
      }
    });

    test('a passage is saved and classified by word accuracy only; it sets the score',
        () async {
      final check = ReadingCheck(stories: stories, language: 'EN');
      final p = placementPassage(check.nextStory!);
      final t = ReadingTracker(words: p.words, language: 'EN');
      for (final (i, w) in p.words.indexed) {
        t.onWordHeard(i < 3 ? 'zzxq' : w.word, Duration(seconds: i + 1));
      }
      final out = await service.savePlacementPassage(
        learner: mia,
        check: check,
        passage: p,
        outcomes: t.outcomes,
        readingSeconds: 20,
        hintAttempts: const [],
        startedAt: DateTime(2026, 10, 15, 9),
      );
      expect(out.passage.wordLevel, PhilIriLevel.frustration); // 3 misreads in ~15
      expect(check.isDone, isTrue);
      final saved = (await SessionRepository(db).recent(mia.id)).single;
      expect(saved.type, SessionType.placement);
      expect(saved.predictedAccuracy, isNull);
      expect(saved.scoreAfter, out.passage.evidence.value);

      await service.finishPlacement(mia, check);
      final score = (await LearnerRepository(db).byId(mia.id))!.readingScore;
      expect(score, check.startScore);
      expect(const ReadingScorer().profileOf(score), ReadingProfile.lowEmerging);
    });
  });

  test('two Frustration sessions out of three flag the teacher', () async {
    await finish(read(s06, misread: {0, 3, 6, 9, 12, 15}), 0);
    final out = await finish(read(s06, misread: {0, 3, 6, 9, 12, 15}), 0);
    expect(out.flags, isNotEmpty);
    expect(await ProgressRepository(db).unseenFlags(mia.id), isNotEmpty);
  });
}
