import 'package:drift/drift.dart';

import '../../agent/agent.dart';

/// Local SQLite tables, one class per table in docs/DATA_MODEL.md.
/// No audio, no full names, no photos, no location.

enum SessionType { placement, story }

@DataClassName('Learner')
class Learners extends Table {
  TextColumn get id => text()(); // uuid
  TextColumn get nickname => text()();
  IntColumn get grade => integer()(); // 0 = Kinder .. 3
  TextColumn get languages => text()(); // "EN", "FIL" or "EN,FIL"
  TextColumn get classCode => text().nullable()();
  /// 0–100 (AGENT_SPEC §5); set by the reading check, updated after
  /// every story.
  RealColumn get readingScore => real().withDefault(const Constant(10.0))();

  /// The accuracy predictions' correction (§9). Null = the config default.
  RealColumn get predictionBias => real().nullable()();
  BoolColumn get dyslexiaMode => boolean().withDefault(const Constant(false))();
  RealColumn get textScale => real().withDefault(const Constant(1.0))();
  BoolColumn get highContrast =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get readAloud => boolean().withDefault(const Constant(true))();

  /// Null = automatic (5 s, or 8 s in dyslexia mode). A number = set by
  /// a parent.
  RealColumn get hintWaitSec => real().nullable()();
  IntColumn get startHintLevel => integer().withDefault(const Constant(1))();
  IntColumn get stars => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReadingSession')
class Sessions extends Table {
  TextColumn get id => text()(); // uuid
  TextColumn get learnerId =>
      text().references(Learners, #id, onDelete: KeyAction.cascade)();
  TextColumn get storyId => text()();
  TextColumn get type => textEnum<SessionType>()();
  DateTimeColumn get startedAt => dateTime()();
  RealColumn get readingSeconds => real()();
  IntColumn get wordsTotal => integer()();
  IntColumn get wordsCorrect => integer()();
  IntColumn get questionsTotal => integer()();
  IntColumn get questionsCorrect => integer()();
  IntColumn get hesitations => integer()();
  IntColumn get miscues => integer()();
  IntColumn get skips => integer()();
  IntColumn get unsureWords => integer()();
  IntColumn get hintsGiven => integer()();
  RealColumn get accuracy => real()();
  RealColumn get wcpm => real()();
  RealColumn get comprehension => real()();
  TextColumn get philiriLevel => textEnum<PhilIriLevel>()();

  /// The book's difficulty (0–100, §11).
  RealColumn get bookDifficulty => real()();

  /// The reading score before and after this story (§5). For a
  /// reading-check passage both are that passage's evidence (§6).
  RealColumn get scoreBefore => real()();
  RealColumn get scoreAfter => real()();

  /// What Buddy predicted the word accuracy would be (§9). Null for
  /// reading-check passages and sessions saved before predictions existed.
  RealColumn get predictedAccuracy => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WordEvent')
class WordEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId =>
      text().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get word => text()();
  TextColumn get primaryPattern => text()();
  TextColumn get result => textEnum<WordResult>()();
  IntColumn get responseMs => integer()();
  IntColumn get hintLevel => integer()();
}

@DataClassName('MasteryEntry')
class MasteryEntries extends Table {
  @override
  String get tableName => 'mastery';

  TextColumn get learnerId =>
      text().references(Learners, #id, onDelete: KeyAction.cascade)();
  TextColumn get patternCode => text()();
  RealColumn get mastery => real()();
  IntColumn get observations => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {learnerId, patternCode};
}

@DataClassName('TrickyWordEntry')
class TrickyWordEntries extends Table {
  @override
  String get tableName => 'tricky_words';

  TextColumn get learnerId =>
      text().references(Learners, #id, onDelete: KeyAction.cascade)();
  TextColumn get word => text()();
  TextColumn get patternCode => text()();
  DateTimeColumn get addedAt => dateTime()();
  IntColumn get cleanReads => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {learnerId, word};
}

@DataClassName('HintStatEntry')
class HintStatEntries extends Table {
  @override
  String get tableName => 'hint_stats';

  TextColumn get learnerId =>
      text().references(Learners, #id, onDelete: KeyAction.cascade)();
  IntColumn get hintLevel => integer()();
  IntColumn get uses => integer()();
  IntColumn get successes => integer()();

  @override
  Set<Column> get primaryKey => {learnerId, hintLevel};
}

@DataClassName('TeacherFlag')
class Flags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get learnerId =>
      text().references(Learners, #id, onDelete: KeyAction.cascade)();
  TextColumn get reason => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get seen => boolean().withDefault(const Constant(false))();
}

/// App-wide key/value settings (parent PIN, consent date, ...).
@DataClassName('Setting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
