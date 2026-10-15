import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/data/db/app_database.dart';
import 'package:readaloud_buddy/data/repositories/learner_repository.dart';
import 'package:readaloud_buddy/data/repositories/progress_repository.dart';
import 'package:readaloud_buddy/data/repositories/session_repository.dart';
import 'package:readaloud_buddy/data/repositories/settings_repository.dart';
import 'package:readaloud_buddy/data/story.dart';

Duration s(num seconds) => Duration(milliseconds: (seconds * 1000).round());

/// A fake reading of [story]: every word read 1 s apart, except the
/// second word, which is misread.
List<WordOutcome> fakeReading(Story story) {
  final t = ReadingTracker(words: story.words, language: story.language);
  for (var i = 0; i < story.words.length; i++) {
    t.onWordHeard(i == 1 ? 'banana' : story.words[i].word, s(i + 1));
  }
  return t.outcomes;
}

SessionScores scoresFor(List<WordOutcome> words, {int questionsCorrect = 3}) =>
    SessionScores.fromResults(words,
        readingSeconds: 40, questionsCorrect: questionsCorrect);

PhilIriLevel classify(SessionScores sc) => const PhilIriClassifier()
    .classify(accuracy: sc.accuracy, comprehension: sc.comprehension)
    .overall;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final stories =
      parseStories(File('assets/data/stories.json').readAsStringSync());
  final s01 = stories.firstWhere((s) => s.id == 'S01');

  late AppDatabase db;
  late LearnerRepository learners;
  late SessionRepository sessions;
  late ProgressRepository progress;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    learners = LearnerRepository(db);
    sessions = SessionRepository(db);
    progress = ProgressRepository(db);
  });
  tearDown(() => db.close());

  test('creates a learner, saves a fake session, and reloads it from disk',
      () async {
    final dir = await Directory.systemTemp.createTemp('readaloud_db_test');
    final file = File('${dir.path}/test.sqlite');
    try {
      // --- First "app run": create a reader and save one story reading.
      var fileDb = AppDatabase(NativeDatabase(file));
      final mia = await LearnerRepository(fileDb)
          .create(nickname: 'Mia', grade: 1, languages: 'EN');

      final words = fakeReading(s01);
      final scores = scoresFor(words, questionsCorrect: 2);
      final level = classify(scores);
      final (decision, _) =
          LevelState(level: mia.currentLevel).apply(level);
      final sessionId = await SessionRepository(fileDb).saveStory(
        learnerId: mia.id,
        storyId: s01.id,
        startedAt: DateTime(2026, 10, 15, 9),
        scores: scores,
        level: level,
        decision: decision,
        words: words,
      );
      await fileDb.close();

      // --- Second "app run": open the same file and read everything back.
      fileDb = AppDatabase(NativeDatabase(file));
      final reloaded = await LearnerRepository(fileDb).byId(mia.id);
      expect(reloaded!.nickname, 'Mia');

      final record = await SessionRepository(fileDb).byId(sessionId);
      expect(record, isNotNull);
      final saved = record!.session;
      expect(saved.learnerId, mia.id);
      expect(saved.storyId, 'S01');
      expect(saved.type, SessionType.story);
      expect(saved.wordsTotal, s01.words.length);
      expect(saved.wordsCorrect, s01.words.length - 1);
      expect(saved.miscues, 1);
      expect(saved.accuracy, closeTo(scores.accuracy, 1e-12));
      expect(saved.wcpm, closeTo(scores.wcpm, 1e-12));
      expect(saved.comprehension, closeTo(2 / 3, 1e-12));
      expect(saved.philiriLevel, level);
      expect(saved.agentDecision, decision.move);

      expect(record.words, hasLength(s01.words.length));
      expect([for (final w in record.words) w.position],
          [for (final w in s01.words) w.position]);
      expect(record.words[1].word, s01.words[1].word);
      expect(record.words[1].result, WordResult.misread);
      expect(record.words[0].result, WordResult.correct);
      expect(record.words[0].responseMs, 1000);
      await fileDb.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  group('learners', () {
    test('stores nickname + generated id only, with sensible defaults',
        () async {
      final l = await learners.create(
          nickname: '  Juan ', grade: 2, languages: 'EN,FIL');
      expect(l.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(l.nickname, 'Juan');
      expect(l.languageList, ['EN', 'FIL']);
      expect(l.currentLevel, 1);
      expect(l.startHintLevel, 1);
      expect(l.hintWait(), 5);
    });

    test('rejects an empty nickname, a bad grade or a bad language', () {
      expect(() => learners.create(nickname: ' ', grade: 1, languages: 'EN'),
          throwsArgumentError);
      expect(() => learners.create(nickname: 'A', grade: 4, languages: 'EN'),
          throwsArgumentError);
      expect(() => learners.create(nickname: 'A', grade: 1, languages: 'ES'),
          throwsArgumentError);
    });

    test('settings changes, level and stars are saved', () async {
      final l = await learners.create(nickname: 'Ana', grade: 0, languages: 'FIL');
      await learners.update(l.copyWith(dyslexiaMode: true, textScale: 1.3));
      await learners.setLevel(l.id, 3);
      await learners.addStars(l.id, 2);
      await learners.addStars(l.id, 3);
      final again = (await learners.byId(l.id))!;
      expect((again.dyslexiaMode, again.textScale), (true, 1.3));
      expect(again.hintWait(), 8); // dyslexia mode -> 8 s
      expect((again.currentLevel, again.stars), (3, 5));
    });

    test('several readers on one phone are listed oldest first', () async {
      // Same clock second for both: order must still be stable.
      final repo = LearnerRepository(db, clock: () => DateTime(2026, 10, 1));
      await repo.create(nickname: 'First', grade: 1, languages: 'EN');
      await repo.create(nickname: 'Second', grade: 1, languages: 'EN');
      expect([for (final l in await learners.all()) l.nickname],
          ['First', 'Second']);
    });

    test('deleting a reader deletes all of their data', () async {
      final l = await learners.create(nickname: 'Bo', grade: 1, languages: 'EN');
      final words = fakeReading(s01);
      final sc = scoresFor(words);
      await sessions.saveStory(
        learnerId: l.id,
        storyId: 'S01',
        startedAt: DateTime(2026),
        scores: sc,
        level: classify(sc),
        decision: LevelState(level: 1).apply(classify(sc)).$1,
        words: words,
      );
      await progress.saveMastery(
          l.id, SoundMastery()..observe('EN-TH', correct: true));
      await learners.delete(l.id);
      expect(await db.select(db.sessions).get(), isEmpty);
      expect(await db.select(db.wordEvents).get(), isEmpty);
      expect(await db.select(db.masteryEntries).get(), isEmpty);
    });
  });

  group('sessions', () {
    test('a story session also saves the learner\'s new level', () async {
      final l = await learners.create(nickname: 'Up', grade: 2, languages: 'EN');
      const decision = LevelDecision(
          move: LevelMove.up, levelBefore: 1, levelAfter: 2);
      final words = fakeReading(s01);
      await sessions.saveStory(
        learnerId: l.id,
        storyId: 'S01',
        startedAt: DateTime(2026),
        scores: scoresFor(words),
        level: PhilIriLevel.independent,
        decision: decision,
        words: words,
      );
      expect((await learners.byId(l.id))!.currentLevel, 2);
    });

    test('nothing is saved if part of the save fails (unknown learner)',
        () async {
      final words = fakeReading(s01);
      await expectLater(
        sessions.saveStory(
          learnerId: 'no-such-learner',
          storyId: 'S01',
          startedAt: DateTime(2026),
          scores: scoresFor(words),
          level: PhilIriLevel.independent,
          decision: const LevelDecision(
              move: LevelMove.stay, levelBefore: 1, levelAfter: 1),
          words: words,
        ),
        throwsA(anything),
      );
      expect(await db.select(db.sessions).get(), isEmpty);
      expect(await db.select(db.wordEvents).get(), isEmpty);
    });

    test('recent sessions are newest first; recentStoryIds gives the last 3',
        () async {
      final l = await learners.create(nickname: 'R', grade: 1, languages: 'EN');
      for (final (i, id) in ['S01', 'S02', 'S03', 'S05'].indexed) {
        await _story(sessions, l.id, id, DateTime(2026, 10, 1 + i),
            PhilIriLevel.instructional, LevelMove.stay, 1);
      }
      expect(await sessions.recentStoryIds(l.id), ['S05', 'S03', 'S02']);
      expect((await sessions.recent(l.id, limit: 1)).single.storyId, 'S05');
    });
  });

  group('level state rebuilt from saved sessions (§5, §6)', () {
    test('placement result at the start level counts as the first result',
        () async {
      final l = await learners.create(nickname: 'P', grade: 2, languages: 'EN');
      final placement = PlacementCheck();
      for (final (i, r) in [
        PhilIriLevel.independent,
        PhilIriLevel.independent,
        PhilIriLevel.frustration,
      ].indexed) {
        placement.record(r);
        await _placement(sessions, l.id, DateTime(2026, 10, 1, 9, i), r, i + 1);
      }
      await learners.setLevel(l.id, placement.startLevel);

      final state = await sessions.levelState(l.id);
      final expected = placement.toLevelState();
      expect(state.level, expected.level);
      expect(state.resultsAtLevel, expected.resultsAtLevel);
      // ...so one more Independent story moves the child up.
      expect(state.apply(PhilIriLevel.independent).$1.move, LevelMove.up);
    });

    test('only results since the last level change count', () async {
      final l = await learners.create(nickname: 'Q', grade: 2, languages: 'EN');
      await learners.setLevel(l.id, 3);
      await _story(sessions, l.id, 'S06', DateTime(2026, 10, 1),
          PhilIriLevel.independent, LevelMove.stay, 2);
      await _story(sessions, l.id, 'S07', DateTime(2026, 10, 2),
          PhilIriLevel.independent, LevelMove.up, 2, after: 3);
      await _story(sessions, l.id, 'S11', DateTime(2026, 10, 3),
          PhilIriLevel.instructional, LevelMove.stay, 3);
      final state = await sessions.levelState(l.id);
      expect(state.level, 3);
      expect(state.resultsAtLevel, [PhilIriLevel.instructional]);
    });

    test('summaries for the teacher flag list practised patterns', () async {
      final l = await learners.create(nickname: 'T', grade: 1, languages: 'EN');
      final words = fakeReading(s01);
      final sc = scoresFor(words);
      await sessions.saveStory(
        learnerId: l.id,
        storyId: 'S01',
        startedAt: DateTime(2026),
        scores: sc,
        level: classify(sc),
        decision: LevelState(level: 1).apply(classify(sc)).$1,
        words: words,
      );
      final summary = (await sessions.summaries(l.id)).single;
      expect(summary.level, classify(sc));
      expect(summary.patternsPracticed,
          {for (final w in s01.words) w.primaryPattern});
    });
  });

  group('progress', () {
    late Learner l;
    setUp(() async =>
        l = await learners.create(nickname: 'M', grade: 1, languages: 'EN'));

    test('sound mastery round-trips exactly', () async {
      final m = SoundMastery()
        ..observe('EN-TH', correct: true)
        ..observe('EN-TH', correct: false)
        ..observe('EN-SH', correct: true);
      await progress.saveMastery(l.id, m);
      final back = await progress.loadMastery(l.id);
      expect(back.of('EN-TH'), m.of('EN-TH'));
      expect(back.observationsOf('EN-TH'), 2);
      expect(back.of('EN-SH'), m.of('EN-SH'));
      expect(back.of('EN-CH'), 0.35); // never seen -> p0
    });

    test('only changed patterns get a new updated_at', () async {
      var clock = DateTime(2026, 10, 1);
      final repo = ProgressRepository(db, clock: () => clock);
      final m = SoundMastery()
        ..observe('EN-TH', correct: true)
        ..observe('EN-SH', correct: true);
      await repo.saveMastery(l.id, m);
      clock = DateTime(2026, 10, 2);
      m.observe('EN-SH', correct: true);
      await repo.saveMastery(l.id, m);
      final rows = {
        for (final r in await db.select(db.masteryEntries).get())
          r.patternCode: r.updatedAt,
      };
      expect(rows['EN-TH'], DateTime(2026, 10, 1));
      expect(rows['EN-SH'], DateTime(2026, 10, 2));
    });

    test('tricky words round-trip and keep the date they were added',
        () async {
      var clock = DateTime(2026, 10, 1);
      final repo = ProgressRepository(db, clock: () => clock);
      final t = TrickyWords()
        ..recordActivity([_outcome('ship', WordResult.misread)]);
      await repo.saveTrickyWords(l.id, t);

      clock = DateTime(2026, 10, 5);
      final loaded = await repo.loadTrickyWords(l.id)
        ..recordActivity([
          _outcome('ship', WordResult.correct),
          _outcome('three', WordResult.skipped),
        ]);
      await repo.saveTrickyWords(l.id, loaded);

      final rows = {
        for (final r in await repo.trickyWordEntries(l.id)) r.word: r,
      };
      expect(rows['ship']!.cleanReads, 1);
      expect(rows['ship']!.addedAt, DateTime(2026, 10, 1));
      expect(rows['three']!.addedAt, DateTime(2026, 10, 5));

      // A second clean read removes "ship" from the saved list too.
      final again = await repo.loadTrickyWords(l.id)
        ..recordActivity([_outcome('ship', WordResult.correct)]);
      await repo.saveTrickyWords(l.id, again);
      expect([for (final r in await repo.trickyWordEntries(l.id)) r.word],
          ['three']);
    });

    test('hint stats round-trip and still drive the start level', () async {
      final h = HintStats({1: (10, 2), 2: (10, 8)});
      await progress.saveHintStats(l.id, h);
      final back = await progress.loadHintStats(l.id);
      expect((back.uses(1), back.successes(1)), (10, 2));
      expect(back.startLevel(), 2);
    });

    test('flags are added once and can be marked seen', () async {
      await progress.addFlags(l.id, ['EN-TH still needs help']);
      await progress.addFlags(l.id, ['EN-TH still needs help']);
      expect(await progress.unseenFlags(l.id), hasLength(1));
      await progress.markFlagsSeen(l.id);
      expect(await progress.unseenFlags(l.id), isEmpty);
    });
  });

  test('settings: set, overwrite, read and remove', () async {
    final settings = SettingsRepository(db);
    expect(await settings.get(SettingKeys.parentPin), isNull);
    await settings.set(SettingKeys.parentPin, '1234');
    await settings.set(SettingKeys.parentPin, '4321');
    expect(await settings.get(SettingKeys.parentPin), '4321');
    await settings.remove(SettingKeys.parentPin);
    expect(await settings.get(SettingKeys.parentPin), isNull);
  });
}

WordOutcome _outcome(String word, WordResult r) => WordOutcome(
      position: 1,
      word: word,
      patterns: const ['EN-SH'],
      primaryPattern: 'EN-SH',
      result: r,
    );

const _noScores = SessionScores(
  wordsTotal: 0,
  wordsCorrect: 0,
  hesitations: 0,
  miscues: 0,
  skips: 0,
  unsureWords: 0,
  hintsGiven: 0,
  readingSeconds: 0,
  questionsCorrect: 0,
  questionsTotal: 3,
);

Future<void> _story(SessionRepository repo, String learnerId, String storyId,
        DateTime at, PhilIriLevel level, LevelMove move, int before,
        {int? after}) =>
    repo.saveStory(
      learnerId: learnerId,
      storyId: storyId,
      startedAt: at,
      scores: _noScores,
      level: level,
      decision: LevelDecision(
          move: move, levelBefore: before, levelAfter: after ?? before),
      words: const [],
    );

Future<void> _placement(SessionRepository repo, String learnerId, DateTime at,
        PhilIriLevel level, int passageLevel) =>
    repo.savePlacementPassage(
      learnerId: learnerId,
      storyId: 'P$passageLevel',
      startedAt: at,
      scores: _noScores,
      level: level,
      passageLevel: passageLevel,
      words: const [],
    );
