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

/// A score change from [before] to [after] (the evidence doesn't matter
/// for saving).
ScoreUpdate scoreUpdate(double before, double after) => ScoreUpdate(
      before: before,
      after: after,
      evidence: ScoreEvidence(difficulty: after, accuracyPart: 0, fluencyPart: 0, value: after),
    );

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
      final sessionId = await SessionRepository(fileDb).saveStory(
        learnerId: mia.id,
        storyId: s01.id,
        startedAt: DateTime(2026, 10, 15, 9),
        scores: scores,
        level: level,
        bookDifficulty: s01.difficulty,
        score: scoreUpdate(mia.readingScore, 14.5),
        predictedAccuracy: 0.93,
        predictionBias: 1.4,
        words: words,
      );
      await fileDb.close();

      // --- Second "app run": open the same file and read everything back.
      fileDb = AppDatabase(NativeDatabase(file));
      final reloaded = await LearnerRepository(fileDb).byId(mia.id);
      expect(reloaded!.nickname, 'Mia');
      expect(reloaded.readingScore, 14.5);
      expect(reloaded.bias(), 1.4);

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
      expect(saved.bookDifficulty, s01.difficulty);
      expect((saved.scoreBefore, saved.scoreAfter), (10, 14.5));
      expect(saved.predictedAccuracy, 0.93);

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
      expect(l.readingScore, 10); // until the reading check sets it
      expect(l.predictionBias, isNull);
      expect(l.bias(), 1.6);
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

    test('settings changes, reading score and stars are saved', () async {
      final l = await learners.create(nickname: 'Ana', grade: 0, languages: 'FIL');
      await learners.update(l.copyWith(dyslexiaMode: true, textScale: 1.3));
      await learners.setReadingScore(l.id, 47.5);
      await learners.addStars(l.id, 2);
      await learners.addStars(l.id, 3);
      final again = (await learners.byId(l.id))!;
      expect((again.dyslexiaMode, again.textScale), (true, 1.3));
      expect(again.hintWait(), 8); // dyslexia mode -> 8 s
      expect((again.readingScore, again.stars), (47.5, 5));
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
      await _story(sessions, l.id, 'S01', DateTime(2026), classify(scoresFor(words)),
          words: words);
      await progress.saveMastery(
          l.id, SoundMastery()..observe('EN-TH', correct: true));
      await learners.delete(l.id);
      expect(await db.select(db.sessions).get(), isEmpty);
      expect(await db.select(db.wordEvents).get(), isEmpty);
      expect(await db.select(db.masteryEntries).get(), isEmpty);
    });
  });

  group('sessions', () {
    test("a story session also saves the learner's new score and prediction correction",
        () async {
      final l = await learners.create(nickname: 'Up', grade: 2, languages: 'EN');
      await _story(sessions, l.id, 'S01', DateTime(2026), PhilIriLevel.independent,
          before: 10, after: 21, bias: 1.9);
      final again = (await learners.byId(l.id))!;
      expect(again.readingScore, 21);
      expect(again.bias(), 1.9);
    });

    test('nothing is saved if part of the save fails (unknown learner)',
        () async {
      final words = fakeReading(s01);
      await expectLater(
        _story(sessions, 'no-such-learner', 'S01', DateTime(2026),
            PhilIriLevel.independent, words: words),
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
            PhilIriLevel.instructional);
      }
      expect(await sessions.recentStoryIds(l.id), ['S05', 'S03', 'S02']);
      expect((await sessions.recent(l.id, limit: 1)).single.storyId, 'S05');
    });

    test('best accuracy per story read (not reading-check passages), for the re-read',
        () async {
      final l = await learners.create(nickname: 'B', grade: 1, languages: 'EN');
      await _story(sessions, l.id, 'S01', DateTime(2026, 10, 1), PhilIriLevel.instructional,
          accuracy: 0.91);
      await _story(sessions, l.id, 'S01', DateTime(2026, 10, 2), PhilIriLevel.independent,
          accuracy: 0.98);
      await _story(sessions, l.id, 'S02', DateTime(2026, 10, 3), PhilIriLevel.instructional,
          accuracy: 0.93);
      await _placement(sessions, l.id, 'S03', DateTime(2026, 10, 4), evidence: 25);
      expect(await sessions.bestAccuracies(l.id), {'S01': 0.98, 'S02': 0.93});
    });

    test('a reading-check passage stores its evidence and no prediction', () async {
      final l = await learners.create(nickname: 'P', grade: 1, languages: 'EN');
      await _placement(sessions, l.id, 'S01', DateTime(2026), evidence: 26.75);
      final row = (await sessions.recent(l.id)).single;
      expect(row.type, SessionType.placement);
      expect((row.scoreBefore, row.scoreAfter), (26.75, 26.75));
      expect(row.predictedAccuracy, isNull);
      // The learner's score is only set when the whole check is done.
      expect((await learners.byId(l.id))!.readingScore, 10);
    });

    test('summaries for the teacher flag list practised patterns', () async {
      final l = await learners.create(nickname: 'T', grade: 1, languages: 'EN');
      final words = fakeReading(s01);
      final sc = scoresFor(words);
      await _story(sessions, l.id, 'S01', DateTime(2026), classify(sc), words: words);
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

  test('upgrading from version 1: levels become reading scores', () async {
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute(_version1Schema);
      raw.execute("INSERT INTO learners (id, nickname, grade, languages, current_level, "
          "created_at) VALUES ('a', 'Ana', 1, 'EN', 3, 1760000000)");
      raw.execute("INSERT INTO sessions VALUES ('s1', 'a', 'S06', 'story', 1760000000, 60, "
          "45, 43, 3, 3, 0, 2, 0, 0, 1, 0.955, 43, 1, 'instructional', 'up', 2, 3)");
      raw.execute('PRAGMA user_version = 1');
    }));
    addTearDown(old.close);
    final l = (await LearnerRepository(old).byId('a'))!;
    expect(l.readingScore, 50); // level 3 -> 50
    expect(l.predictionBias, isNull);
    expect(l.nickname, 'Ana');
    final row = (await SessionRepository(old).recent('a')).single;
    expect((row.bookDifficulty, row.scoreBefore, row.scoreAfter), (30, 30, 50));
    expect(row.predictedAccuracy, isNull);
    expect(row.accuracy, 0.955);
    expect(row.philiriLevel, PhilIriLevel.instructional);
  });
}

/// The two tables version 2 changed, as version 1 created them.
const _version1Schema = '''
CREATE TABLE learners (id TEXT NOT NULL PRIMARY KEY, nickname TEXT NOT NULL,
  grade INTEGER NOT NULL, languages TEXT NOT NULL, class_code TEXT NULL,
  current_level INTEGER NOT NULL DEFAULT 1, dyslexia_mode INTEGER NOT NULL DEFAULT 0,
  text_scale REAL NOT NULL DEFAULT 1.0, high_contrast INTEGER NOT NULL DEFAULT 0,
  read_aloud INTEGER NOT NULL DEFAULT 1, hint_wait_sec REAL NULL,
  start_hint_level INTEGER NOT NULL DEFAULT 1, stars INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL);
CREATE TABLE sessions (id TEXT NOT NULL PRIMARY KEY, learner_id TEXT NOT NULL,
  story_id TEXT NOT NULL, type TEXT NOT NULL, started_at INTEGER NOT NULL,
  reading_seconds REAL NOT NULL, words_total INTEGER NOT NULL,
  words_correct INTEGER NOT NULL, questions_total INTEGER NOT NULL,
  questions_correct INTEGER NOT NULL, hesitations INTEGER NOT NULL,
  miscues INTEGER NOT NULL, skips INTEGER NOT NULL, unsure_words INTEGER NOT NULL,
  hints_given INTEGER NOT NULL, accuracy REAL NOT NULL, wcpm REAL NOT NULL,
  comprehension REAL NOT NULL, philiri_level TEXT NOT NULL, agent_decision TEXT NULL,
  level_before INTEGER NOT NULL, level_after INTEGER NOT NULL);
''';

WordOutcome _outcome(String word, WordResult r) => WordOutcome(
      position: 1,
      word: word,
      patterns: const ['EN-SH'],
      primaryPattern: 'EN-SH',
      result: r,
    );

SessionScores _scores({double accuracy = 0}) => SessionScores(
      wordsTotal: 100,
      wordsCorrect: (accuracy * 100).round(),
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
        DateTime at, PhilIriLevel level,
        {double before = 10,
        double after = 12,
        double bias = 1.6,
        double accuracy = 0.95,
        List<WordOutcome> words = const []}) =>
    repo.saveStory(
      learnerId: learnerId,
      storyId: storyId,
      startedAt: at,
      scores: _scores(accuracy: accuracy),
      level: level,
      bookDifficulty: 20,
      score: scoreUpdate(before, after),
      predictedAccuracy: 0.93,
      predictionBias: bias,
      words: words,
    );

Future<void> _placement(SessionRepository repo, String learnerId, String storyId,
        DateTime at, {required double evidence}) =>
    repo.savePlacementPassage(
      learnerId: learnerId,
      storyId: storyId,
      startedAt: at,
      scores: _scores(accuracy: 0.97),
      level: PhilIriLevel.independent,
      bookDifficulty: 18,
      evidence: evidence,
      words: const [],
    );
