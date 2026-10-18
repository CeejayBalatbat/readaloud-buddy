// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LearnersTable extends Learners with TableInfo<$LearnersTable, Learner> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearnersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<int> grade = GeneratedColumn<int>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languagesMeta = const VerificationMeta(
    'languages',
  );
  @override
  late final GeneratedColumn<String> languages = GeneratedColumn<String>(
    'languages',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classCodeMeta = const VerificationMeta(
    'classCode',
  );
  @override
  late final GeneratedColumn<String> classCode = GeneratedColumn<String>(
    'class_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readingScoreMeta = const VerificationMeta(
    'readingScore',
  );
  @override
  late final GeneratedColumn<double> readingScore = GeneratedColumn<double>(
    'reading_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(10.0),
  );
  static const VerificationMeta _predictionBiasMeta = const VerificationMeta(
    'predictionBias',
  );
  @override
  late final GeneratedColumn<double> predictionBias = GeneratedColumn<double>(
    'prediction_bias',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dyslexiaModeMeta = const VerificationMeta(
    'dyslexiaMode',
  );
  @override
  late final GeneratedColumn<bool> dyslexiaMode = GeneratedColumn<bool>(
    'dyslexia_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dyslexia_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _textScaleMeta = const VerificationMeta(
    'textScale',
  );
  @override
  late final GeneratedColumn<double> textScale = GeneratedColumn<double>(
    'text_scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _highContrastMeta = const VerificationMeta(
    'highContrast',
  );
  @override
  late final GeneratedColumn<bool> highContrast = GeneratedColumn<bool>(
    'high_contrast',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("high_contrast" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _readAloudMeta = const VerificationMeta(
    'readAloud',
  );
  @override
  late final GeneratedColumn<bool> readAloud = GeneratedColumn<bool>(
    'read_aloud',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("read_aloud" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _hintWaitSecMeta = const VerificationMeta(
    'hintWaitSec',
  );
  @override
  late final GeneratedColumn<double> hintWaitSec = GeneratedColumn<double>(
    'hint_wait_sec',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startHintLevelMeta = const VerificationMeta(
    'startHintLevel',
  );
  @override
  late final GeneratedColumn<int> startHintLevel = GeneratedColumn<int>(
    'start_hint_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
    'stars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nickname,
    grade,
    languages,
    classCode,
    readingScore,
    predictionBias,
    dyslexiaMode,
    textScale,
    highContrast,
    readAloud,
    hintWaitSec,
    startHintLevel,
    stars,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learners';
  @override
  VerificationContext validateIntegrity(
    Insertable<Learner> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('languages')) {
      context.handle(
        _languagesMeta,
        languages.isAcceptableOrUnknown(data['languages']!, _languagesMeta),
      );
    } else if (isInserting) {
      context.missing(_languagesMeta);
    }
    if (data.containsKey('class_code')) {
      context.handle(
        _classCodeMeta,
        classCode.isAcceptableOrUnknown(data['class_code']!, _classCodeMeta),
      );
    }
    if (data.containsKey('reading_score')) {
      context.handle(
        _readingScoreMeta,
        readingScore.isAcceptableOrUnknown(
          data['reading_score']!,
          _readingScoreMeta,
        ),
      );
    }
    if (data.containsKey('prediction_bias')) {
      context.handle(
        _predictionBiasMeta,
        predictionBias.isAcceptableOrUnknown(
          data['prediction_bias']!,
          _predictionBiasMeta,
        ),
      );
    }
    if (data.containsKey('dyslexia_mode')) {
      context.handle(
        _dyslexiaModeMeta,
        dyslexiaMode.isAcceptableOrUnknown(
          data['dyslexia_mode']!,
          _dyslexiaModeMeta,
        ),
      );
    }
    if (data.containsKey('text_scale')) {
      context.handle(
        _textScaleMeta,
        textScale.isAcceptableOrUnknown(data['text_scale']!, _textScaleMeta),
      );
    }
    if (data.containsKey('high_contrast')) {
      context.handle(
        _highContrastMeta,
        highContrast.isAcceptableOrUnknown(
          data['high_contrast']!,
          _highContrastMeta,
        ),
      );
    }
    if (data.containsKey('read_aloud')) {
      context.handle(
        _readAloudMeta,
        readAloud.isAcceptableOrUnknown(data['read_aloud']!, _readAloudMeta),
      );
    }
    if (data.containsKey('hint_wait_sec')) {
      context.handle(
        _hintWaitSecMeta,
        hintWaitSec.isAcceptableOrUnknown(
          data['hint_wait_sec']!,
          _hintWaitSecMeta,
        ),
      );
    }
    if (data.containsKey('start_hint_level')) {
      context.handle(
        _startHintLevelMeta,
        startHintLevel.isAcceptableOrUnknown(
          data['start_hint_level']!,
          _startHintLevelMeta,
        ),
      );
    }
    if (data.containsKey('stars')) {
      context.handle(
        _starsMeta,
        stars.isAcceptableOrUnknown(data['stars']!, _starsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Learner map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Learner(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade'],
      )!,
      languages: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}languages'],
      )!,
      classCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class_code'],
      ),
      readingScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reading_score'],
      )!,
      predictionBias: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}prediction_bias'],
      ),
      dyslexiaMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dyslexia_mode'],
      )!,
      textScale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}text_scale'],
      )!,
      highContrast: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}high_contrast'],
      )!,
      readAloud: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}read_aloud'],
      )!,
      hintWaitSec: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hint_wait_sec'],
      ),
      startHintLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_hint_level'],
      )!,
      stars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stars'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LearnersTable createAlias(String alias) {
    return $LearnersTable(attachedDatabase, alias);
  }
}

class Learner extends DataClass implements Insertable<Learner> {
  final String id;
  final String nickname;
  final int grade;
  final String languages;
  final String? classCode;

  /// 0–100 (AGENT_SPEC §5); set by the reading check, updated after
  /// every story.
  final double readingScore;

  /// The accuracy predictions' correction (§9). Null = the config default.
  final double? predictionBias;
  final bool dyslexiaMode;
  final double textScale;
  final bool highContrast;
  final bool readAloud;

  /// Null = automatic (5 s, or 8 s in dyslexia mode). A number = set by
  /// a parent.
  final double? hintWaitSec;
  final int startHintLevel;
  final int stars;
  final DateTime createdAt;
  const Learner({
    required this.id,
    required this.nickname,
    required this.grade,
    required this.languages,
    this.classCode,
    required this.readingScore,
    this.predictionBias,
    required this.dyslexiaMode,
    required this.textScale,
    required this.highContrast,
    required this.readAloud,
    this.hintWaitSec,
    required this.startHintLevel,
    required this.stars,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nickname'] = Variable<String>(nickname);
    map['grade'] = Variable<int>(grade);
    map['languages'] = Variable<String>(languages);
    if (!nullToAbsent || classCode != null) {
      map['class_code'] = Variable<String>(classCode);
    }
    map['reading_score'] = Variable<double>(readingScore);
    if (!nullToAbsent || predictionBias != null) {
      map['prediction_bias'] = Variable<double>(predictionBias);
    }
    map['dyslexia_mode'] = Variable<bool>(dyslexiaMode);
    map['text_scale'] = Variable<double>(textScale);
    map['high_contrast'] = Variable<bool>(highContrast);
    map['read_aloud'] = Variable<bool>(readAloud);
    if (!nullToAbsent || hintWaitSec != null) {
      map['hint_wait_sec'] = Variable<double>(hintWaitSec);
    }
    map['start_hint_level'] = Variable<int>(startHintLevel);
    map['stars'] = Variable<int>(stars);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LearnersCompanion toCompanion(bool nullToAbsent) {
    return LearnersCompanion(
      id: Value(id),
      nickname: Value(nickname),
      grade: Value(grade),
      languages: Value(languages),
      classCode: classCode == null && nullToAbsent
          ? const Value.absent()
          : Value(classCode),
      readingScore: Value(readingScore),
      predictionBias: predictionBias == null && nullToAbsent
          ? const Value.absent()
          : Value(predictionBias),
      dyslexiaMode: Value(dyslexiaMode),
      textScale: Value(textScale),
      highContrast: Value(highContrast),
      readAloud: Value(readAloud),
      hintWaitSec: hintWaitSec == null && nullToAbsent
          ? const Value.absent()
          : Value(hintWaitSec),
      startHintLevel: Value(startHintLevel),
      stars: Value(stars),
      createdAt: Value(createdAt),
    );
  }

  factory Learner.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Learner(
      id: serializer.fromJson<String>(json['id']),
      nickname: serializer.fromJson<String>(json['nickname']),
      grade: serializer.fromJson<int>(json['grade']),
      languages: serializer.fromJson<String>(json['languages']),
      classCode: serializer.fromJson<String?>(json['classCode']),
      readingScore: serializer.fromJson<double>(json['readingScore']),
      predictionBias: serializer.fromJson<double?>(json['predictionBias']),
      dyslexiaMode: serializer.fromJson<bool>(json['dyslexiaMode']),
      textScale: serializer.fromJson<double>(json['textScale']),
      highContrast: serializer.fromJson<bool>(json['highContrast']),
      readAloud: serializer.fromJson<bool>(json['readAloud']),
      hintWaitSec: serializer.fromJson<double?>(json['hintWaitSec']),
      startHintLevel: serializer.fromJson<int>(json['startHintLevel']),
      stars: serializer.fromJson<int>(json['stars']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nickname': serializer.toJson<String>(nickname),
      'grade': serializer.toJson<int>(grade),
      'languages': serializer.toJson<String>(languages),
      'classCode': serializer.toJson<String?>(classCode),
      'readingScore': serializer.toJson<double>(readingScore),
      'predictionBias': serializer.toJson<double?>(predictionBias),
      'dyslexiaMode': serializer.toJson<bool>(dyslexiaMode),
      'textScale': serializer.toJson<double>(textScale),
      'highContrast': serializer.toJson<bool>(highContrast),
      'readAloud': serializer.toJson<bool>(readAloud),
      'hintWaitSec': serializer.toJson<double?>(hintWaitSec),
      'startHintLevel': serializer.toJson<int>(startHintLevel),
      'stars': serializer.toJson<int>(stars),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Learner copyWith({
    String? id,
    String? nickname,
    int? grade,
    String? languages,
    Value<String?> classCode = const Value.absent(),
    double? readingScore,
    Value<double?> predictionBias = const Value.absent(),
    bool? dyslexiaMode,
    double? textScale,
    bool? highContrast,
    bool? readAloud,
    Value<double?> hintWaitSec = const Value.absent(),
    int? startHintLevel,
    int? stars,
    DateTime? createdAt,
  }) => Learner(
    id: id ?? this.id,
    nickname: nickname ?? this.nickname,
    grade: grade ?? this.grade,
    languages: languages ?? this.languages,
    classCode: classCode.present ? classCode.value : this.classCode,
    readingScore: readingScore ?? this.readingScore,
    predictionBias: predictionBias.present
        ? predictionBias.value
        : this.predictionBias,
    dyslexiaMode: dyslexiaMode ?? this.dyslexiaMode,
    textScale: textScale ?? this.textScale,
    highContrast: highContrast ?? this.highContrast,
    readAloud: readAloud ?? this.readAloud,
    hintWaitSec: hintWaitSec.present ? hintWaitSec.value : this.hintWaitSec,
    startHintLevel: startHintLevel ?? this.startHintLevel,
    stars: stars ?? this.stars,
    createdAt: createdAt ?? this.createdAt,
  );
  Learner copyWithCompanion(LearnersCompanion data) {
    return Learner(
      id: data.id.present ? data.id.value : this.id,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      grade: data.grade.present ? data.grade.value : this.grade,
      languages: data.languages.present ? data.languages.value : this.languages,
      classCode: data.classCode.present ? data.classCode.value : this.classCode,
      readingScore: data.readingScore.present
          ? data.readingScore.value
          : this.readingScore,
      predictionBias: data.predictionBias.present
          ? data.predictionBias.value
          : this.predictionBias,
      dyslexiaMode: data.dyslexiaMode.present
          ? data.dyslexiaMode.value
          : this.dyslexiaMode,
      textScale: data.textScale.present ? data.textScale.value : this.textScale,
      highContrast: data.highContrast.present
          ? data.highContrast.value
          : this.highContrast,
      readAloud: data.readAloud.present ? data.readAloud.value : this.readAloud,
      hintWaitSec: data.hintWaitSec.present
          ? data.hintWaitSec.value
          : this.hintWaitSec,
      startHintLevel: data.startHintLevel.present
          ? data.startHintLevel.value
          : this.startHintLevel,
      stars: data.stars.present ? data.stars.value : this.stars,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Learner(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('grade: $grade, ')
          ..write('languages: $languages, ')
          ..write('classCode: $classCode, ')
          ..write('readingScore: $readingScore, ')
          ..write('predictionBias: $predictionBias, ')
          ..write('dyslexiaMode: $dyslexiaMode, ')
          ..write('textScale: $textScale, ')
          ..write('highContrast: $highContrast, ')
          ..write('readAloud: $readAloud, ')
          ..write('hintWaitSec: $hintWaitSec, ')
          ..write('startHintLevel: $startHintLevel, ')
          ..write('stars: $stars, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nickname,
    grade,
    languages,
    classCode,
    readingScore,
    predictionBias,
    dyslexiaMode,
    textScale,
    highContrast,
    readAloud,
    hintWaitSec,
    startHintLevel,
    stars,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Learner &&
          other.id == this.id &&
          other.nickname == this.nickname &&
          other.grade == this.grade &&
          other.languages == this.languages &&
          other.classCode == this.classCode &&
          other.readingScore == this.readingScore &&
          other.predictionBias == this.predictionBias &&
          other.dyslexiaMode == this.dyslexiaMode &&
          other.textScale == this.textScale &&
          other.highContrast == this.highContrast &&
          other.readAloud == this.readAloud &&
          other.hintWaitSec == this.hintWaitSec &&
          other.startHintLevel == this.startHintLevel &&
          other.stars == this.stars &&
          other.createdAt == this.createdAt);
}

class LearnersCompanion extends UpdateCompanion<Learner> {
  final Value<String> id;
  final Value<String> nickname;
  final Value<int> grade;
  final Value<String> languages;
  final Value<String?> classCode;
  final Value<double> readingScore;
  final Value<double?> predictionBias;
  final Value<bool> dyslexiaMode;
  final Value<double> textScale;
  final Value<bool> highContrast;
  final Value<bool> readAloud;
  final Value<double?> hintWaitSec;
  final Value<int> startHintLevel;
  final Value<int> stars;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LearnersCompanion({
    this.id = const Value.absent(),
    this.nickname = const Value.absent(),
    this.grade = const Value.absent(),
    this.languages = const Value.absent(),
    this.classCode = const Value.absent(),
    this.readingScore = const Value.absent(),
    this.predictionBias = const Value.absent(),
    this.dyslexiaMode = const Value.absent(),
    this.textScale = const Value.absent(),
    this.highContrast = const Value.absent(),
    this.readAloud = const Value.absent(),
    this.hintWaitSec = const Value.absent(),
    this.startHintLevel = const Value.absent(),
    this.stars = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearnersCompanion.insert({
    required String id,
    required String nickname,
    required int grade,
    required String languages,
    this.classCode = const Value.absent(),
    this.readingScore = const Value.absent(),
    this.predictionBias = const Value.absent(),
    this.dyslexiaMode = const Value.absent(),
    this.textScale = const Value.absent(),
    this.highContrast = const Value.absent(),
    this.readAloud = const Value.absent(),
    this.hintWaitSec = const Value.absent(),
    this.startHintLevel = const Value.absent(),
    this.stars = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nickname = Value(nickname),
       grade = Value(grade),
       languages = Value(languages),
       createdAt = Value(createdAt);
  static Insertable<Learner> custom({
    Expression<String>? id,
    Expression<String>? nickname,
    Expression<int>? grade,
    Expression<String>? languages,
    Expression<String>? classCode,
    Expression<double>? readingScore,
    Expression<double>? predictionBias,
    Expression<bool>? dyslexiaMode,
    Expression<double>? textScale,
    Expression<bool>? highContrast,
    Expression<bool>? readAloud,
    Expression<double>? hintWaitSec,
    Expression<int>? startHintLevel,
    Expression<int>? stars,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nickname != null) 'nickname': nickname,
      if (grade != null) 'grade': grade,
      if (languages != null) 'languages': languages,
      if (classCode != null) 'class_code': classCode,
      if (readingScore != null) 'reading_score': readingScore,
      if (predictionBias != null) 'prediction_bias': predictionBias,
      if (dyslexiaMode != null) 'dyslexia_mode': dyslexiaMode,
      if (textScale != null) 'text_scale': textScale,
      if (highContrast != null) 'high_contrast': highContrast,
      if (readAloud != null) 'read_aloud': readAloud,
      if (hintWaitSec != null) 'hint_wait_sec': hintWaitSec,
      if (startHintLevel != null) 'start_hint_level': startHintLevel,
      if (stars != null) 'stars': stars,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearnersCompanion copyWith({
    Value<String>? id,
    Value<String>? nickname,
    Value<int>? grade,
    Value<String>? languages,
    Value<String?>? classCode,
    Value<double>? readingScore,
    Value<double?>? predictionBias,
    Value<bool>? dyslexiaMode,
    Value<double>? textScale,
    Value<bool>? highContrast,
    Value<bool>? readAloud,
    Value<double?>? hintWaitSec,
    Value<int>? startHintLevel,
    Value<int>? stars,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LearnersCompanion(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      grade: grade ?? this.grade,
      languages: languages ?? this.languages,
      classCode: classCode ?? this.classCode,
      readingScore: readingScore ?? this.readingScore,
      predictionBias: predictionBias ?? this.predictionBias,
      dyslexiaMode: dyslexiaMode ?? this.dyslexiaMode,
      textScale: textScale ?? this.textScale,
      highContrast: highContrast ?? this.highContrast,
      readAloud: readAloud ?? this.readAloud,
      hintWaitSec: hintWaitSec ?? this.hintWaitSec,
      startHintLevel: startHintLevel ?? this.startHintLevel,
      stars: stars ?? this.stars,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (grade.present) {
      map['grade'] = Variable<int>(grade.value);
    }
    if (languages.present) {
      map['languages'] = Variable<String>(languages.value);
    }
    if (classCode.present) {
      map['class_code'] = Variable<String>(classCode.value);
    }
    if (readingScore.present) {
      map['reading_score'] = Variable<double>(readingScore.value);
    }
    if (predictionBias.present) {
      map['prediction_bias'] = Variable<double>(predictionBias.value);
    }
    if (dyslexiaMode.present) {
      map['dyslexia_mode'] = Variable<bool>(dyslexiaMode.value);
    }
    if (textScale.present) {
      map['text_scale'] = Variable<double>(textScale.value);
    }
    if (highContrast.present) {
      map['high_contrast'] = Variable<bool>(highContrast.value);
    }
    if (readAloud.present) {
      map['read_aloud'] = Variable<bool>(readAloud.value);
    }
    if (hintWaitSec.present) {
      map['hint_wait_sec'] = Variable<double>(hintWaitSec.value);
    }
    if (startHintLevel.present) {
      map['start_hint_level'] = Variable<int>(startHintLevel.value);
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearnersCompanion(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('grade: $grade, ')
          ..write('languages: $languages, ')
          ..write('classCode: $classCode, ')
          ..write('readingScore: $readingScore, ')
          ..write('predictionBias: $predictionBias, ')
          ..write('dyslexiaMode: $dyslexiaMode, ')
          ..write('textScale: $textScale, ')
          ..write('highContrast: $highContrast, ')
          ..write('readAloud: $readAloud, ')
          ..write('hintWaitSec: $hintWaitSec, ')
          ..write('startHintLevel: $startHintLevel, ')
          ..write('stars: $stars, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, ReadingSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<String> learnerId = GeneratedColumn<String>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _storyIdMeta = const VerificationMeta(
    'storyId',
  );
  @override
  late final GeneratedColumn<String> storyId = GeneratedColumn<String>(
    'story_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SessionType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SessionType>($SessionsTable.$convertertype);
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingSecondsMeta = const VerificationMeta(
    'readingSeconds',
  );
  @override
  late final GeneratedColumn<double> readingSeconds = GeneratedColumn<double>(
    'reading_seconds',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordsTotalMeta = const VerificationMeta(
    'wordsTotal',
  );
  @override
  late final GeneratedColumn<int> wordsTotal = GeneratedColumn<int>(
    'words_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordsCorrectMeta = const VerificationMeta(
    'wordsCorrect',
  );
  @override
  late final GeneratedColumn<int> wordsCorrect = GeneratedColumn<int>(
    'words_correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionsTotalMeta = const VerificationMeta(
    'questionsTotal',
  );
  @override
  late final GeneratedColumn<int> questionsTotal = GeneratedColumn<int>(
    'questions_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionsCorrectMeta = const VerificationMeta(
    'questionsCorrect',
  );
  @override
  late final GeneratedColumn<int> questionsCorrect = GeneratedColumn<int>(
    'questions_correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hesitationsMeta = const VerificationMeta(
    'hesitations',
  );
  @override
  late final GeneratedColumn<int> hesitations = GeneratedColumn<int>(
    'hesitations',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _miscuesMeta = const VerificationMeta(
    'miscues',
  );
  @override
  late final GeneratedColumn<int> miscues = GeneratedColumn<int>(
    'miscues',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skipsMeta = const VerificationMeta('skips');
  @override
  late final GeneratedColumn<int> skips = GeneratedColumn<int>(
    'skips',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unsureWordsMeta = const VerificationMeta(
    'unsureWords',
  );
  @override
  late final GeneratedColumn<int> unsureWords = GeneratedColumn<int>(
    'unsure_words',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintsGivenMeta = const VerificationMeta(
    'hintsGiven',
  );
  @override
  late final GeneratedColumn<int> hintsGiven = GeneratedColumn<int>(
    'hints_given',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wcpmMeta = const VerificationMeta('wcpm');
  @override
  late final GeneratedColumn<double> wcpm = GeneratedColumn<double>(
    'wcpm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _comprehensionMeta = const VerificationMeta(
    'comprehension',
  );
  @override
  late final GeneratedColumn<double> comprehension = GeneratedColumn<double>(
    'comprehension',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PhilIriLevel, String>
  philiriLevel = GeneratedColumn<String>(
    'philiri_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<PhilIriLevel>($SessionsTable.$converterphiliriLevel);
  static const VerificationMeta _bookDifficultyMeta = const VerificationMeta(
    'bookDifficulty',
  );
  @override
  late final GeneratedColumn<double> bookDifficulty = GeneratedColumn<double>(
    'book_difficulty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreBeforeMeta = const VerificationMeta(
    'scoreBefore',
  );
  @override
  late final GeneratedColumn<double> scoreBefore = GeneratedColumn<double>(
    'score_before',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreAfterMeta = const VerificationMeta(
    'scoreAfter',
  );
  @override
  late final GeneratedColumn<double> scoreAfter = GeneratedColumn<double>(
    'score_after',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _predictedAccuracyMeta = const VerificationMeta(
    'predictedAccuracy',
  );
  @override
  late final GeneratedColumn<double> predictedAccuracy =
      GeneratedColumn<double>(
        'predicted_accuracy',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    learnerId,
    storyId,
    type,
    startedAt,
    readingSeconds,
    wordsTotal,
    wordsCorrect,
    questionsTotal,
    questionsCorrect,
    hesitations,
    miscues,
    skips,
    unsureWords,
    hintsGiven,
    accuracy,
    wcpm,
    comprehension,
    philiriLevel,
    bookDifficulty,
    scoreBefore,
    scoreAfter,
    predictedAccuracy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('story_id')) {
      context.handle(
        _storyIdMeta,
        storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('reading_seconds')) {
      context.handle(
        _readingSecondsMeta,
        readingSeconds.isAcceptableOrUnknown(
          data['reading_seconds']!,
          _readingSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_readingSecondsMeta);
    }
    if (data.containsKey('words_total')) {
      context.handle(
        _wordsTotalMeta,
        wordsTotal.isAcceptableOrUnknown(data['words_total']!, _wordsTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_wordsTotalMeta);
    }
    if (data.containsKey('words_correct')) {
      context.handle(
        _wordsCorrectMeta,
        wordsCorrect.isAcceptableOrUnknown(
          data['words_correct']!,
          _wordsCorrectMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_wordsCorrectMeta);
    }
    if (data.containsKey('questions_total')) {
      context.handle(
        _questionsTotalMeta,
        questionsTotal.isAcceptableOrUnknown(
          data['questions_total']!,
          _questionsTotalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionsTotalMeta);
    }
    if (data.containsKey('questions_correct')) {
      context.handle(
        _questionsCorrectMeta,
        questionsCorrect.isAcceptableOrUnknown(
          data['questions_correct']!,
          _questionsCorrectMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionsCorrectMeta);
    }
    if (data.containsKey('hesitations')) {
      context.handle(
        _hesitationsMeta,
        hesitations.isAcceptableOrUnknown(
          data['hesitations']!,
          _hesitationsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hesitationsMeta);
    }
    if (data.containsKey('miscues')) {
      context.handle(
        _miscuesMeta,
        miscues.isAcceptableOrUnknown(data['miscues']!, _miscuesMeta),
      );
    } else if (isInserting) {
      context.missing(_miscuesMeta);
    }
    if (data.containsKey('skips')) {
      context.handle(
        _skipsMeta,
        skips.isAcceptableOrUnknown(data['skips']!, _skipsMeta),
      );
    } else if (isInserting) {
      context.missing(_skipsMeta);
    }
    if (data.containsKey('unsure_words')) {
      context.handle(
        _unsureWordsMeta,
        unsureWords.isAcceptableOrUnknown(
          data['unsure_words']!,
          _unsureWordsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unsureWordsMeta);
    }
    if (data.containsKey('hints_given')) {
      context.handle(
        _hintsGivenMeta,
        hintsGiven.isAcceptableOrUnknown(data['hints_given']!, _hintsGivenMeta),
      );
    } else if (isInserting) {
      context.missing(_hintsGivenMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    if (data.containsKey('wcpm')) {
      context.handle(
        _wcpmMeta,
        wcpm.isAcceptableOrUnknown(data['wcpm']!, _wcpmMeta),
      );
    } else if (isInserting) {
      context.missing(_wcpmMeta);
    }
    if (data.containsKey('comprehension')) {
      context.handle(
        _comprehensionMeta,
        comprehension.isAcceptableOrUnknown(
          data['comprehension']!,
          _comprehensionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_comprehensionMeta);
    }
    if (data.containsKey('book_difficulty')) {
      context.handle(
        _bookDifficultyMeta,
        bookDifficulty.isAcceptableOrUnknown(
          data['book_difficulty']!,
          _bookDifficultyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bookDifficultyMeta);
    }
    if (data.containsKey('score_before')) {
      context.handle(
        _scoreBeforeMeta,
        scoreBefore.isAcceptableOrUnknown(
          data['score_before']!,
          _scoreBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scoreBeforeMeta);
    }
    if (data.containsKey('score_after')) {
      context.handle(
        _scoreAfterMeta,
        scoreAfter.isAcceptableOrUnknown(data['score_after']!, _scoreAfterMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreAfterMeta);
    }
    if (data.containsKey('predicted_accuracy')) {
      context.handle(
        _predictedAccuracyMeta,
        predictedAccuracy.isAcceptableOrUnknown(
          data['predicted_accuracy']!,
          _predictedAccuracyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learner_id'],
      )!,
      storyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}story_id'],
      )!,
      type: $SessionsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      readingSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reading_seconds'],
      )!,
      wordsTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}words_total'],
      )!,
      wordsCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}words_correct'],
      )!,
      questionsTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}questions_total'],
      )!,
      questionsCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}questions_correct'],
      )!,
      hesitations: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hesitations'],
      )!,
      miscues: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}miscues'],
      )!,
      skips: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skips'],
      )!,
      unsureWords: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unsure_words'],
      )!,
      hintsGiven: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hints_given'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      )!,
      wcpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}wcpm'],
      )!,
      comprehension: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}comprehension'],
      )!,
      philiriLevel: $SessionsTable.$converterphiliriLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}philiri_level'],
        )!,
      ),
      bookDifficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}book_difficulty'],
      )!,
      scoreBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score_before'],
      )!,
      scoreAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score_after'],
      )!,
      predictedAccuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}predicted_accuracy'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SessionType, String, String> $convertertype =
      const EnumNameConverter<SessionType>(SessionType.values);
  static JsonTypeConverter2<PhilIriLevel, String, String>
  $converterphiliriLevel = const EnumNameConverter<PhilIriLevel>(
    PhilIriLevel.values,
  );
}

class ReadingSession extends DataClass implements Insertable<ReadingSession> {
  final String id;
  final String learnerId;
  final String storyId;
  final SessionType type;
  final DateTime startedAt;
  final double readingSeconds;
  final int wordsTotal;
  final int wordsCorrect;
  final int questionsTotal;
  final int questionsCorrect;
  final int hesitations;
  final int miscues;
  final int skips;
  final int unsureWords;
  final int hintsGiven;
  final double accuracy;
  final double wcpm;
  final double comprehension;
  final PhilIriLevel philiriLevel;

  /// The book's difficulty (0–100, §11).
  final double bookDifficulty;

  /// The reading score before and after this story (§5). For a
  /// reading-check passage both are that passage's evidence (§6).
  final double scoreBefore;
  final double scoreAfter;

  /// What Buddy predicted the word accuracy would be (§9). Null for
  /// reading-check passages and sessions saved before predictions existed.
  final double? predictedAccuracy;
  const ReadingSession({
    required this.id,
    required this.learnerId,
    required this.storyId,
    required this.type,
    required this.startedAt,
    required this.readingSeconds,
    required this.wordsTotal,
    required this.wordsCorrect,
    required this.questionsTotal,
    required this.questionsCorrect,
    required this.hesitations,
    required this.miscues,
    required this.skips,
    required this.unsureWords,
    required this.hintsGiven,
    required this.accuracy,
    required this.wcpm,
    required this.comprehension,
    required this.philiriLevel,
    required this.bookDifficulty,
    required this.scoreBefore,
    required this.scoreAfter,
    this.predictedAccuracy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['learner_id'] = Variable<String>(learnerId);
    map['story_id'] = Variable<String>(storyId);
    {
      map['type'] = Variable<String>($SessionsTable.$convertertype.toSql(type));
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['reading_seconds'] = Variable<double>(readingSeconds);
    map['words_total'] = Variable<int>(wordsTotal);
    map['words_correct'] = Variable<int>(wordsCorrect);
    map['questions_total'] = Variable<int>(questionsTotal);
    map['questions_correct'] = Variable<int>(questionsCorrect);
    map['hesitations'] = Variable<int>(hesitations);
    map['miscues'] = Variable<int>(miscues);
    map['skips'] = Variable<int>(skips);
    map['unsure_words'] = Variable<int>(unsureWords);
    map['hints_given'] = Variable<int>(hintsGiven);
    map['accuracy'] = Variable<double>(accuracy);
    map['wcpm'] = Variable<double>(wcpm);
    map['comprehension'] = Variable<double>(comprehension);
    {
      map['philiri_level'] = Variable<String>(
        $SessionsTable.$converterphiliriLevel.toSql(philiriLevel),
      );
    }
    map['book_difficulty'] = Variable<double>(bookDifficulty);
    map['score_before'] = Variable<double>(scoreBefore);
    map['score_after'] = Variable<double>(scoreAfter);
    if (!nullToAbsent || predictedAccuracy != null) {
      map['predicted_accuracy'] = Variable<double>(predictedAccuracy);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      learnerId: Value(learnerId),
      storyId: Value(storyId),
      type: Value(type),
      startedAt: Value(startedAt),
      readingSeconds: Value(readingSeconds),
      wordsTotal: Value(wordsTotal),
      wordsCorrect: Value(wordsCorrect),
      questionsTotal: Value(questionsTotal),
      questionsCorrect: Value(questionsCorrect),
      hesitations: Value(hesitations),
      miscues: Value(miscues),
      skips: Value(skips),
      unsureWords: Value(unsureWords),
      hintsGiven: Value(hintsGiven),
      accuracy: Value(accuracy),
      wcpm: Value(wcpm),
      comprehension: Value(comprehension),
      philiriLevel: Value(philiriLevel),
      bookDifficulty: Value(bookDifficulty),
      scoreBefore: Value(scoreBefore),
      scoreAfter: Value(scoreAfter),
      predictedAccuracy: predictedAccuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(predictedAccuracy),
    );
  }

  factory ReadingSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSession(
      id: serializer.fromJson<String>(json['id']),
      learnerId: serializer.fromJson<String>(json['learnerId']),
      storyId: serializer.fromJson<String>(json['storyId']),
      type: $SessionsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      readingSeconds: serializer.fromJson<double>(json['readingSeconds']),
      wordsTotal: serializer.fromJson<int>(json['wordsTotal']),
      wordsCorrect: serializer.fromJson<int>(json['wordsCorrect']),
      questionsTotal: serializer.fromJson<int>(json['questionsTotal']),
      questionsCorrect: serializer.fromJson<int>(json['questionsCorrect']),
      hesitations: serializer.fromJson<int>(json['hesitations']),
      miscues: serializer.fromJson<int>(json['miscues']),
      skips: serializer.fromJson<int>(json['skips']),
      unsureWords: serializer.fromJson<int>(json['unsureWords']),
      hintsGiven: serializer.fromJson<int>(json['hintsGiven']),
      accuracy: serializer.fromJson<double>(json['accuracy']),
      wcpm: serializer.fromJson<double>(json['wcpm']),
      comprehension: serializer.fromJson<double>(json['comprehension']),
      philiriLevel: $SessionsTable.$converterphiliriLevel.fromJson(
        serializer.fromJson<String>(json['philiriLevel']),
      ),
      bookDifficulty: serializer.fromJson<double>(json['bookDifficulty']),
      scoreBefore: serializer.fromJson<double>(json['scoreBefore']),
      scoreAfter: serializer.fromJson<double>(json['scoreAfter']),
      predictedAccuracy: serializer.fromJson<double?>(
        json['predictedAccuracy'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'learnerId': serializer.toJson<String>(learnerId),
      'storyId': serializer.toJson<String>(storyId),
      'type': serializer.toJson<String>(
        $SessionsTable.$convertertype.toJson(type),
      ),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'readingSeconds': serializer.toJson<double>(readingSeconds),
      'wordsTotal': serializer.toJson<int>(wordsTotal),
      'wordsCorrect': serializer.toJson<int>(wordsCorrect),
      'questionsTotal': serializer.toJson<int>(questionsTotal),
      'questionsCorrect': serializer.toJson<int>(questionsCorrect),
      'hesitations': serializer.toJson<int>(hesitations),
      'miscues': serializer.toJson<int>(miscues),
      'skips': serializer.toJson<int>(skips),
      'unsureWords': serializer.toJson<int>(unsureWords),
      'hintsGiven': serializer.toJson<int>(hintsGiven),
      'accuracy': serializer.toJson<double>(accuracy),
      'wcpm': serializer.toJson<double>(wcpm),
      'comprehension': serializer.toJson<double>(comprehension),
      'philiriLevel': serializer.toJson<String>(
        $SessionsTable.$converterphiliriLevel.toJson(philiriLevel),
      ),
      'bookDifficulty': serializer.toJson<double>(bookDifficulty),
      'scoreBefore': serializer.toJson<double>(scoreBefore),
      'scoreAfter': serializer.toJson<double>(scoreAfter),
      'predictedAccuracy': serializer.toJson<double?>(predictedAccuracy),
    };
  }

  ReadingSession copyWith({
    String? id,
    String? learnerId,
    String? storyId,
    SessionType? type,
    DateTime? startedAt,
    double? readingSeconds,
    int? wordsTotal,
    int? wordsCorrect,
    int? questionsTotal,
    int? questionsCorrect,
    int? hesitations,
    int? miscues,
    int? skips,
    int? unsureWords,
    int? hintsGiven,
    double? accuracy,
    double? wcpm,
    double? comprehension,
    PhilIriLevel? philiriLevel,
    double? bookDifficulty,
    double? scoreBefore,
    double? scoreAfter,
    Value<double?> predictedAccuracy = const Value.absent(),
  }) => ReadingSession(
    id: id ?? this.id,
    learnerId: learnerId ?? this.learnerId,
    storyId: storyId ?? this.storyId,
    type: type ?? this.type,
    startedAt: startedAt ?? this.startedAt,
    readingSeconds: readingSeconds ?? this.readingSeconds,
    wordsTotal: wordsTotal ?? this.wordsTotal,
    wordsCorrect: wordsCorrect ?? this.wordsCorrect,
    questionsTotal: questionsTotal ?? this.questionsTotal,
    questionsCorrect: questionsCorrect ?? this.questionsCorrect,
    hesitations: hesitations ?? this.hesitations,
    miscues: miscues ?? this.miscues,
    skips: skips ?? this.skips,
    unsureWords: unsureWords ?? this.unsureWords,
    hintsGiven: hintsGiven ?? this.hintsGiven,
    accuracy: accuracy ?? this.accuracy,
    wcpm: wcpm ?? this.wcpm,
    comprehension: comprehension ?? this.comprehension,
    philiriLevel: philiriLevel ?? this.philiriLevel,
    bookDifficulty: bookDifficulty ?? this.bookDifficulty,
    scoreBefore: scoreBefore ?? this.scoreBefore,
    scoreAfter: scoreAfter ?? this.scoreAfter,
    predictedAccuracy: predictedAccuracy.present
        ? predictedAccuracy.value
        : this.predictedAccuracy,
  );
  ReadingSession copyWithCompanion(SessionsCompanion data) {
    return ReadingSession(
      id: data.id.present ? data.id.value : this.id,
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      type: data.type.present ? data.type.value : this.type,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      readingSeconds: data.readingSeconds.present
          ? data.readingSeconds.value
          : this.readingSeconds,
      wordsTotal: data.wordsTotal.present
          ? data.wordsTotal.value
          : this.wordsTotal,
      wordsCorrect: data.wordsCorrect.present
          ? data.wordsCorrect.value
          : this.wordsCorrect,
      questionsTotal: data.questionsTotal.present
          ? data.questionsTotal.value
          : this.questionsTotal,
      questionsCorrect: data.questionsCorrect.present
          ? data.questionsCorrect.value
          : this.questionsCorrect,
      hesitations: data.hesitations.present
          ? data.hesitations.value
          : this.hesitations,
      miscues: data.miscues.present ? data.miscues.value : this.miscues,
      skips: data.skips.present ? data.skips.value : this.skips,
      unsureWords: data.unsureWords.present
          ? data.unsureWords.value
          : this.unsureWords,
      hintsGiven: data.hintsGiven.present
          ? data.hintsGiven.value
          : this.hintsGiven,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      wcpm: data.wcpm.present ? data.wcpm.value : this.wcpm,
      comprehension: data.comprehension.present
          ? data.comprehension.value
          : this.comprehension,
      philiriLevel: data.philiriLevel.present
          ? data.philiriLevel.value
          : this.philiriLevel,
      bookDifficulty: data.bookDifficulty.present
          ? data.bookDifficulty.value
          : this.bookDifficulty,
      scoreBefore: data.scoreBefore.present
          ? data.scoreBefore.value
          : this.scoreBefore,
      scoreAfter: data.scoreAfter.present
          ? data.scoreAfter.value
          : this.scoreAfter,
      predictedAccuracy: data.predictedAccuracy.present
          ? data.predictedAccuracy.value
          : this.predictedAccuracy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSession(')
          ..write('id: $id, ')
          ..write('learnerId: $learnerId, ')
          ..write('storyId: $storyId, ')
          ..write('type: $type, ')
          ..write('startedAt: $startedAt, ')
          ..write('readingSeconds: $readingSeconds, ')
          ..write('wordsTotal: $wordsTotal, ')
          ..write('wordsCorrect: $wordsCorrect, ')
          ..write('questionsTotal: $questionsTotal, ')
          ..write('questionsCorrect: $questionsCorrect, ')
          ..write('hesitations: $hesitations, ')
          ..write('miscues: $miscues, ')
          ..write('skips: $skips, ')
          ..write('unsureWords: $unsureWords, ')
          ..write('hintsGiven: $hintsGiven, ')
          ..write('accuracy: $accuracy, ')
          ..write('wcpm: $wcpm, ')
          ..write('comprehension: $comprehension, ')
          ..write('philiriLevel: $philiriLevel, ')
          ..write('bookDifficulty: $bookDifficulty, ')
          ..write('scoreBefore: $scoreBefore, ')
          ..write('scoreAfter: $scoreAfter, ')
          ..write('predictedAccuracy: $predictedAccuracy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    learnerId,
    storyId,
    type,
    startedAt,
    readingSeconds,
    wordsTotal,
    wordsCorrect,
    questionsTotal,
    questionsCorrect,
    hesitations,
    miscues,
    skips,
    unsureWords,
    hintsGiven,
    accuracy,
    wcpm,
    comprehension,
    philiriLevel,
    bookDifficulty,
    scoreBefore,
    scoreAfter,
    predictedAccuracy,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSession &&
          other.id == this.id &&
          other.learnerId == this.learnerId &&
          other.storyId == this.storyId &&
          other.type == this.type &&
          other.startedAt == this.startedAt &&
          other.readingSeconds == this.readingSeconds &&
          other.wordsTotal == this.wordsTotal &&
          other.wordsCorrect == this.wordsCorrect &&
          other.questionsTotal == this.questionsTotal &&
          other.questionsCorrect == this.questionsCorrect &&
          other.hesitations == this.hesitations &&
          other.miscues == this.miscues &&
          other.skips == this.skips &&
          other.unsureWords == this.unsureWords &&
          other.hintsGiven == this.hintsGiven &&
          other.accuracy == this.accuracy &&
          other.wcpm == this.wcpm &&
          other.comprehension == this.comprehension &&
          other.philiriLevel == this.philiriLevel &&
          other.bookDifficulty == this.bookDifficulty &&
          other.scoreBefore == this.scoreBefore &&
          other.scoreAfter == this.scoreAfter &&
          other.predictedAccuracy == this.predictedAccuracy);
}

class SessionsCompanion extends UpdateCompanion<ReadingSession> {
  final Value<String> id;
  final Value<String> learnerId;
  final Value<String> storyId;
  final Value<SessionType> type;
  final Value<DateTime> startedAt;
  final Value<double> readingSeconds;
  final Value<int> wordsTotal;
  final Value<int> wordsCorrect;
  final Value<int> questionsTotal;
  final Value<int> questionsCorrect;
  final Value<int> hesitations;
  final Value<int> miscues;
  final Value<int> skips;
  final Value<int> unsureWords;
  final Value<int> hintsGiven;
  final Value<double> accuracy;
  final Value<double> wcpm;
  final Value<double> comprehension;
  final Value<PhilIriLevel> philiriLevel;
  final Value<double> bookDifficulty;
  final Value<double> scoreBefore;
  final Value<double> scoreAfter;
  final Value<double?> predictedAccuracy;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.learnerId = const Value.absent(),
    this.storyId = const Value.absent(),
    this.type = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.readingSeconds = const Value.absent(),
    this.wordsTotal = const Value.absent(),
    this.wordsCorrect = const Value.absent(),
    this.questionsTotal = const Value.absent(),
    this.questionsCorrect = const Value.absent(),
    this.hesitations = const Value.absent(),
    this.miscues = const Value.absent(),
    this.skips = const Value.absent(),
    this.unsureWords = const Value.absent(),
    this.hintsGiven = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.wcpm = const Value.absent(),
    this.comprehension = const Value.absent(),
    this.philiriLevel = const Value.absent(),
    this.bookDifficulty = const Value.absent(),
    this.scoreBefore = const Value.absent(),
    this.scoreAfter = const Value.absent(),
    this.predictedAccuracy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String learnerId,
    required String storyId,
    required SessionType type,
    required DateTime startedAt,
    required double readingSeconds,
    required int wordsTotal,
    required int wordsCorrect,
    required int questionsTotal,
    required int questionsCorrect,
    required int hesitations,
    required int miscues,
    required int skips,
    required int unsureWords,
    required int hintsGiven,
    required double accuracy,
    required double wcpm,
    required double comprehension,
    required PhilIriLevel philiriLevel,
    required double bookDifficulty,
    required double scoreBefore,
    required double scoreAfter,
    this.predictedAccuracy = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       learnerId = Value(learnerId),
       storyId = Value(storyId),
       type = Value(type),
       startedAt = Value(startedAt),
       readingSeconds = Value(readingSeconds),
       wordsTotal = Value(wordsTotal),
       wordsCorrect = Value(wordsCorrect),
       questionsTotal = Value(questionsTotal),
       questionsCorrect = Value(questionsCorrect),
       hesitations = Value(hesitations),
       miscues = Value(miscues),
       skips = Value(skips),
       unsureWords = Value(unsureWords),
       hintsGiven = Value(hintsGiven),
       accuracy = Value(accuracy),
       wcpm = Value(wcpm),
       comprehension = Value(comprehension),
       philiriLevel = Value(philiriLevel),
       bookDifficulty = Value(bookDifficulty),
       scoreBefore = Value(scoreBefore),
       scoreAfter = Value(scoreAfter);
  static Insertable<ReadingSession> custom({
    Expression<String>? id,
    Expression<String>? learnerId,
    Expression<String>? storyId,
    Expression<String>? type,
    Expression<DateTime>? startedAt,
    Expression<double>? readingSeconds,
    Expression<int>? wordsTotal,
    Expression<int>? wordsCorrect,
    Expression<int>? questionsTotal,
    Expression<int>? questionsCorrect,
    Expression<int>? hesitations,
    Expression<int>? miscues,
    Expression<int>? skips,
    Expression<int>? unsureWords,
    Expression<int>? hintsGiven,
    Expression<double>? accuracy,
    Expression<double>? wcpm,
    Expression<double>? comprehension,
    Expression<String>? philiriLevel,
    Expression<double>? bookDifficulty,
    Expression<double>? scoreBefore,
    Expression<double>? scoreAfter,
    Expression<double>? predictedAccuracy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (learnerId != null) 'learner_id': learnerId,
      if (storyId != null) 'story_id': storyId,
      if (type != null) 'type': type,
      if (startedAt != null) 'started_at': startedAt,
      if (readingSeconds != null) 'reading_seconds': readingSeconds,
      if (wordsTotal != null) 'words_total': wordsTotal,
      if (wordsCorrect != null) 'words_correct': wordsCorrect,
      if (questionsTotal != null) 'questions_total': questionsTotal,
      if (questionsCorrect != null) 'questions_correct': questionsCorrect,
      if (hesitations != null) 'hesitations': hesitations,
      if (miscues != null) 'miscues': miscues,
      if (skips != null) 'skips': skips,
      if (unsureWords != null) 'unsure_words': unsureWords,
      if (hintsGiven != null) 'hints_given': hintsGiven,
      if (accuracy != null) 'accuracy': accuracy,
      if (wcpm != null) 'wcpm': wcpm,
      if (comprehension != null) 'comprehension': comprehension,
      if (philiriLevel != null) 'philiri_level': philiriLevel,
      if (bookDifficulty != null) 'book_difficulty': bookDifficulty,
      if (scoreBefore != null) 'score_before': scoreBefore,
      if (scoreAfter != null) 'score_after': scoreAfter,
      if (predictedAccuracy != null) 'predicted_accuracy': predictedAccuracy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? learnerId,
    Value<String>? storyId,
    Value<SessionType>? type,
    Value<DateTime>? startedAt,
    Value<double>? readingSeconds,
    Value<int>? wordsTotal,
    Value<int>? wordsCorrect,
    Value<int>? questionsTotal,
    Value<int>? questionsCorrect,
    Value<int>? hesitations,
    Value<int>? miscues,
    Value<int>? skips,
    Value<int>? unsureWords,
    Value<int>? hintsGiven,
    Value<double>? accuracy,
    Value<double>? wcpm,
    Value<double>? comprehension,
    Value<PhilIriLevel>? philiriLevel,
    Value<double>? bookDifficulty,
    Value<double>? scoreBefore,
    Value<double>? scoreAfter,
    Value<double?>? predictedAccuracy,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      learnerId: learnerId ?? this.learnerId,
      storyId: storyId ?? this.storyId,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      readingSeconds: readingSeconds ?? this.readingSeconds,
      wordsTotal: wordsTotal ?? this.wordsTotal,
      wordsCorrect: wordsCorrect ?? this.wordsCorrect,
      questionsTotal: questionsTotal ?? this.questionsTotal,
      questionsCorrect: questionsCorrect ?? this.questionsCorrect,
      hesitations: hesitations ?? this.hesitations,
      miscues: miscues ?? this.miscues,
      skips: skips ?? this.skips,
      unsureWords: unsureWords ?? this.unsureWords,
      hintsGiven: hintsGiven ?? this.hintsGiven,
      accuracy: accuracy ?? this.accuracy,
      wcpm: wcpm ?? this.wcpm,
      comprehension: comprehension ?? this.comprehension,
      philiriLevel: philiriLevel ?? this.philiriLevel,
      bookDifficulty: bookDifficulty ?? this.bookDifficulty,
      scoreBefore: scoreBefore ?? this.scoreBefore,
      scoreAfter: scoreAfter ?? this.scoreAfter,
      predictedAccuracy: predictedAccuracy ?? this.predictedAccuracy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (learnerId.present) {
      map['learner_id'] = Variable<String>(learnerId.value);
    }
    if (storyId.present) {
      map['story_id'] = Variable<String>(storyId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $SessionsTable.$convertertype.toSql(type.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (readingSeconds.present) {
      map['reading_seconds'] = Variable<double>(readingSeconds.value);
    }
    if (wordsTotal.present) {
      map['words_total'] = Variable<int>(wordsTotal.value);
    }
    if (wordsCorrect.present) {
      map['words_correct'] = Variable<int>(wordsCorrect.value);
    }
    if (questionsTotal.present) {
      map['questions_total'] = Variable<int>(questionsTotal.value);
    }
    if (questionsCorrect.present) {
      map['questions_correct'] = Variable<int>(questionsCorrect.value);
    }
    if (hesitations.present) {
      map['hesitations'] = Variable<int>(hesitations.value);
    }
    if (miscues.present) {
      map['miscues'] = Variable<int>(miscues.value);
    }
    if (skips.present) {
      map['skips'] = Variable<int>(skips.value);
    }
    if (unsureWords.present) {
      map['unsure_words'] = Variable<int>(unsureWords.value);
    }
    if (hintsGiven.present) {
      map['hints_given'] = Variable<int>(hintsGiven.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (wcpm.present) {
      map['wcpm'] = Variable<double>(wcpm.value);
    }
    if (comprehension.present) {
      map['comprehension'] = Variable<double>(comprehension.value);
    }
    if (philiriLevel.present) {
      map['philiri_level'] = Variable<String>(
        $SessionsTable.$converterphiliriLevel.toSql(philiriLevel.value),
      );
    }
    if (bookDifficulty.present) {
      map['book_difficulty'] = Variable<double>(bookDifficulty.value);
    }
    if (scoreBefore.present) {
      map['score_before'] = Variable<double>(scoreBefore.value);
    }
    if (scoreAfter.present) {
      map['score_after'] = Variable<double>(scoreAfter.value);
    }
    if (predictedAccuracy.present) {
      map['predicted_accuracy'] = Variable<double>(predictedAccuracy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('learnerId: $learnerId, ')
          ..write('storyId: $storyId, ')
          ..write('type: $type, ')
          ..write('startedAt: $startedAt, ')
          ..write('readingSeconds: $readingSeconds, ')
          ..write('wordsTotal: $wordsTotal, ')
          ..write('wordsCorrect: $wordsCorrect, ')
          ..write('questionsTotal: $questionsTotal, ')
          ..write('questionsCorrect: $questionsCorrect, ')
          ..write('hesitations: $hesitations, ')
          ..write('miscues: $miscues, ')
          ..write('skips: $skips, ')
          ..write('unsureWords: $unsureWords, ')
          ..write('hintsGiven: $hintsGiven, ')
          ..write('accuracy: $accuracy, ')
          ..write('wcpm: $wcpm, ')
          ..write('comprehension: $comprehension, ')
          ..write('philiriLevel: $philiriLevel, ')
          ..write('bookDifficulty: $bookDifficulty, ')
          ..write('scoreBefore: $scoreBefore, ')
          ..write('scoreAfter: $scoreAfter, ')
          ..write('predictedAccuracy: $predictedAccuracy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordEventsTable extends WordEvents
    with TableInfo<$WordEventsTable, WordEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _primaryPatternMeta = const VerificationMeta(
    'primaryPattern',
  );
  @override
  late final GeneratedColumn<String> primaryPattern = GeneratedColumn<String>(
    'primary_pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WordResult, String> result =
      GeneratedColumn<String>(
        'result',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WordResult>($WordEventsTable.$converterresult);
  static const VerificationMeta _responseMsMeta = const VerificationMeta(
    'responseMs',
  );
  @override
  late final GeneratedColumn<int> responseMs = GeneratedColumn<int>(
    'response_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintLevelMeta = const VerificationMeta(
    'hintLevel',
  );
  @override
  late final GeneratedColumn<int> hintLevel = GeneratedColumn<int>(
    'hint_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    position,
    word,
    primaryPattern,
    result,
    responseMs,
    hintLevel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('primary_pattern')) {
      context.handle(
        _primaryPatternMeta,
        primaryPattern.isAcceptableOrUnknown(
          data['primary_pattern']!,
          _primaryPatternMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_primaryPatternMeta);
    }
    if (data.containsKey('response_ms')) {
      context.handle(
        _responseMsMeta,
        responseMs.isAcceptableOrUnknown(data['response_ms']!, _responseMsMeta),
      );
    } else if (isInserting) {
      context.missing(_responseMsMeta);
    }
    if (data.containsKey('hint_level')) {
      context.handle(
        _hintLevelMeta,
        hintLevel.isAcceptableOrUnknown(data['hint_level']!, _hintLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_hintLevelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      primaryPattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_pattern'],
      )!,
      result: $WordEventsTable.$converterresult.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}result'],
        )!,
      ),
      responseMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_ms'],
      )!,
      hintLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hint_level'],
      )!,
    );
  }

  @override
  $WordEventsTable createAlias(String alias) {
    return $WordEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WordResult, String, String> $converterresult =
      const EnumNameConverter<WordResult>(WordResult.values);
}

class WordEvent extends DataClass implements Insertable<WordEvent> {
  final int id;
  final String sessionId;
  final int position;
  final String word;
  final String primaryPattern;
  final WordResult result;
  final int responseMs;
  final int hintLevel;
  const WordEvent({
    required this.id,
    required this.sessionId,
    required this.position,
    required this.word,
    required this.primaryPattern,
    required this.result,
    required this.responseMs,
    required this.hintLevel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['position'] = Variable<int>(position);
    map['word'] = Variable<String>(word);
    map['primary_pattern'] = Variable<String>(primaryPattern);
    {
      map['result'] = Variable<String>(
        $WordEventsTable.$converterresult.toSql(result),
      );
    }
    map['response_ms'] = Variable<int>(responseMs);
    map['hint_level'] = Variable<int>(hintLevel);
    return map;
  }

  WordEventsCompanion toCompanion(bool nullToAbsent) {
    return WordEventsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      position: Value(position),
      word: Value(word),
      primaryPattern: Value(primaryPattern),
      result: Value(result),
      responseMs: Value(responseMs),
      hintLevel: Value(hintLevel),
    );
  }

  factory WordEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordEvent(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      position: serializer.fromJson<int>(json['position']),
      word: serializer.fromJson<String>(json['word']),
      primaryPattern: serializer.fromJson<String>(json['primaryPattern']),
      result: $WordEventsTable.$converterresult.fromJson(
        serializer.fromJson<String>(json['result']),
      ),
      responseMs: serializer.fromJson<int>(json['responseMs']),
      hintLevel: serializer.fromJson<int>(json['hintLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'position': serializer.toJson<int>(position),
      'word': serializer.toJson<String>(word),
      'primaryPattern': serializer.toJson<String>(primaryPattern),
      'result': serializer.toJson<String>(
        $WordEventsTable.$converterresult.toJson(result),
      ),
      'responseMs': serializer.toJson<int>(responseMs),
      'hintLevel': serializer.toJson<int>(hintLevel),
    };
  }

  WordEvent copyWith({
    int? id,
    String? sessionId,
    int? position,
    String? word,
    String? primaryPattern,
    WordResult? result,
    int? responseMs,
    int? hintLevel,
  }) => WordEvent(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    position: position ?? this.position,
    word: word ?? this.word,
    primaryPattern: primaryPattern ?? this.primaryPattern,
    result: result ?? this.result,
    responseMs: responseMs ?? this.responseMs,
    hintLevel: hintLevel ?? this.hintLevel,
  );
  WordEvent copyWithCompanion(WordEventsCompanion data) {
    return WordEvent(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      position: data.position.present ? data.position.value : this.position,
      word: data.word.present ? data.word.value : this.word,
      primaryPattern: data.primaryPattern.present
          ? data.primaryPattern.value
          : this.primaryPattern,
      result: data.result.present ? data.result.value : this.result,
      responseMs: data.responseMs.present
          ? data.responseMs.value
          : this.responseMs,
      hintLevel: data.hintLevel.present ? data.hintLevel.value : this.hintLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordEvent(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('position: $position, ')
          ..write('word: $word, ')
          ..write('primaryPattern: $primaryPattern, ')
          ..write('result: $result, ')
          ..write('responseMs: $responseMs, ')
          ..write('hintLevel: $hintLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    position,
    word,
    primaryPattern,
    result,
    responseMs,
    hintLevel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordEvent &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.position == this.position &&
          other.word == this.word &&
          other.primaryPattern == this.primaryPattern &&
          other.result == this.result &&
          other.responseMs == this.responseMs &&
          other.hintLevel == this.hintLevel);
}

class WordEventsCompanion extends UpdateCompanion<WordEvent> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<int> position;
  final Value<String> word;
  final Value<String> primaryPattern;
  final Value<WordResult> result;
  final Value<int> responseMs;
  final Value<int> hintLevel;
  const WordEventsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.position = const Value.absent(),
    this.word = const Value.absent(),
    this.primaryPattern = const Value.absent(),
    this.result = const Value.absent(),
    this.responseMs = const Value.absent(),
    this.hintLevel = const Value.absent(),
  });
  WordEventsCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required int position,
    required String word,
    required String primaryPattern,
    required WordResult result,
    required int responseMs,
    required int hintLevel,
  }) : sessionId = Value(sessionId),
       position = Value(position),
       word = Value(word),
       primaryPattern = Value(primaryPattern),
       result = Value(result),
       responseMs = Value(responseMs),
       hintLevel = Value(hintLevel);
  static Insertable<WordEvent> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<int>? position,
    Expression<String>? word,
    Expression<String>? primaryPattern,
    Expression<String>? result,
    Expression<int>? responseMs,
    Expression<int>? hintLevel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (position != null) 'position': position,
      if (word != null) 'word': word,
      if (primaryPattern != null) 'primary_pattern': primaryPattern,
      if (result != null) 'result': result,
      if (responseMs != null) 'response_ms': responseMs,
      if (hintLevel != null) 'hint_level': hintLevel,
    });
  }

  WordEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<int>? position,
    Value<String>? word,
    Value<String>? primaryPattern,
    Value<WordResult>? result,
    Value<int>? responseMs,
    Value<int>? hintLevel,
  }) {
    return WordEventsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      position: position ?? this.position,
      word: word ?? this.word,
      primaryPattern: primaryPattern ?? this.primaryPattern,
      result: result ?? this.result,
      responseMs: responseMs ?? this.responseMs,
      hintLevel: hintLevel ?? this.hintLevel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (primaryPattern.present) {
      map['primary_pattern'] = Variable<String>(primaryPattern.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(
        $WordEventsTable.$converterresult.toSql(result.value),
      );
    }
    if (responseMs.present) {
      map['response_ms'] = Variable<int>(responseMs.value);
    }
    if (hintLevel.present) {
      map['hint_level'] = Variable<int>(hintLevel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordEventsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('position: $position, ')
          ..write('word: $word, ')
          ..write('primaryPattern: $primaryPattern, ')
          ..write('result: $result, ')
          ..write('responseMs: $responseMs, ')
          ..write('hintLevel: $hintLevel')
          ..write(')'))
        .toString();
  }
}

class $MasteryEntriesTable extends MasteryEntries
    with TableInfo<$MasteryEntriesTable, MasteryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MasteryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<String> learnerId = GeneratedColumn<String>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _patternCodeMeta = const VerificationMeta(
    'patternCode',
  );
  @override
  late final GeneratedColumn<String> patternCode = GeneratedColumn<String>(
    'pattern_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _masteryMeta = const VerificationMeta(
    'mastery',
  );
  @override
  late final GeneratedColumn<double> mastery = GeneratedColumn<double>(
    'mastery',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observationsMeta = const VerificationMeta(
    'observations',
  );
  @override
  late final GeneratedColumn<int> observations = GeneratedColumn<int>(
    'observations',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    learnerId,
    patternCode,
    mastery,
    observations,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mastery';
  @override
  VerificationContext validateIntegrity(
    Insertable<MasteryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('pattern_code')) {
      context.handle(
        _patternCodeMeta,
        patternCode.isAcceptableOrUnknown(
          data['pattern_code']!,
          _patternCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_patternCodeMeta);
    }
    if (data.containsKey('mastery')) {
      context.handle(
        _masteryMeta,
        mastery.isAcceptableOrUnknown(data['mastery']!, _masteryMeta),
      );
    } else if (isInserting) {
      context.missing(_masteryMeta);
    }
    if (data.containsKey('observations')) {
      context.handle(
        _observationsMeta,
        observations.isAcceptableOrUnknown(
          data['observations']!,
          _observationsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_observationsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {learnerId, patternCode};
  @override
  MasteryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MasteryEntry(
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learner_id'],
      )!,
      patternCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern_code'],
      )!,
      mastery: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mastery'],
      )!,
      observations: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}observations'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MasteryEntriesTable createAlias(String alias) {
    return $MasteryEntriesTable(attachedDatabase, alias);
  }
}

class MasteryEntry extends DataClass implements Insertable<MasteryEntry> {
  final String learnerId;
  final String patternCode;
  final double mastery;
  final int observations;
  final DateTime updatedAt;
  const MasteryEntry({
    required this.learnerId,
    required this.patternCode,
    required this.mastery,
    required this.observations,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['learner_id'] = Variable<String>(learnerId);
    map['pattern_code'] = Variable<String>(patternCode);
    map['mastery'] = Variable<double>(mastery);
    map['observations'] = Variable<int>(observations);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MasteryEntriesCompanion toCompanion(bool nullToAbsent) {
    return MasteryEntriesCompanion(
      learnerId: Value(learnerId),
      patternCode: Value(patternCode),
      mastery: Value(mastery),
      observations: Value(observations),
      updatedAt: Value(updatedAt),
    );
  }

  factory MasteryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MasteryEntry(
      learnerId: serializer.fromJson<String>(json['learnerId']),
      patternCode: serializer.fromJson<String>(json['patternCode']),
      mastery: serializer.fromJson<double>(json['mastery']),
      observations: serializer.fromJson<int>(json['observations']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'learnerId': serializer.toJson<String>(learnerId),
      'patternCode': serializer.toJson<String>(patternCode),
      'mastery': serializer.toJson<double>(mastery),
      'observations': serializer.toJson<int>(observations),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MasteryEntry copyWith({
    String? learnerId,
    String? patternCode,
    double? mastery,
    int? observations,
    DateTime? updatedAt,
  }) => MasteryEntry(
    learnerId: learnerId ?? this.learnerId,
    patternCode: patternCode ?? this.patternCode,
    mastery: mastery ?? this.mastery,
    observations: observations ?? this.observations,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MasteryEntry copyWithCompanion(MasteryEntriesCompanion data) {
    return MasteryEntry(
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      patternCode: data.patternCode.present
          ? data.patternCode.value
          : this.patternCode,
      mastery: data.mastery.present ? data.mastery.value : this.mastery,
      observations: data.observations.present
          ? data.observations.value
          : this.observations,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MasteryEntry(')
          ..write('learnerId: $learnerId, ')
          ..write('patternCode: $patternCode, ')
          ..write('mastery: $mastery, ')
          ..write('observations: $observations, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(learnerId, patternCode, mastery, observations, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MasteryEntry &&
          other.learnerId == this.learnerId &&
          other.patternCode == this.patternCode &&
          other.mastery == this.mastery &&
          other.observations == this.observations &&
          other.updatedAt == this.updatedAt);
}

class MasteryEntriesCompanion extends UpdateCompanion<MasteryEntry> {
  final Value<String> learnerId;
  final Value<String> patternCode;
  final Value<double> mastery;
  final Value<int> observations;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MasteryEntriesCompanion({
    this.learnerId = const Value.absent(),
    this.patternCode = const Value.absent(),
    this.mastery = const Value.absent(),
    this.observations = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MasteryEntriesCompanion.insert({
    required String learnerId,
    required String patternCode,
    required double mastery,
    required int observations,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : learnerId = Value(learnerId),
       patternCode = Value(patternCode),
       mastery = Value(mastery),
       observations = Value(observations),
       updatedAt = Value(updatedAt);
  static Insertable<MasteryEntry> custom({
    Expression<String>? learnerId,
    Expression<String>? patternCode,
    Expression<double>? mastery,
    Expression<int>? observations,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (learnerId != null) 'learner_id': learnerId,
      if (patternCode != null) 'pattern_code': patternCode,
      if (mastery != null) 'mastery': mastery,
      if (observations != null) 'observations': observations,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MasteryEntriesCompanion copyWith({
    Value<String>? learnerId,
    Value<String>? patternCode,
    Value<double>? mastery,
    Value<int>? observations,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MasteryEntriesCompanion(
      learnerId: learnerId ?? this.learnerId,
      patternCode: patternCode ?? this.patternCode,
      mastery: mastery ?? this.mastery,
      observations: observations ?? this.observations,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (learnerId.present) {
      map['learner_id'] = Variable<String>(learnerId.value);
    }
    if (patternCode.present) {
      map['pattern_code'] = Variable<String>(patternCode.value);
    }
    if (mastery.present) {
      map['mastery'] = Variable<double>(mastery.value);
    }
    if (observations.present) {
      map['observations'] = Variable<int>(observations.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MasteryEntriesCompanion(')
          ..write('learnerId: $learnerId, ')
          ..write('patternCode: $patternCode, ')
          ..write('mastery: $mastery, ')
          ..write('observations: $observations, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrickyWordEntriesTable extends TrickyWordEntries
    with TableInfo<$TrickyWordEntriesTable, TrickyWordEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrickyWordEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<String> learnerId = GeneratedColumn<String>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patternCodeMeta = const VerificationMeta(
    'patternCode',
  );
  @override
  late final GeneratedColumn<String> patternCode = GeneratedColumn<String>(
    'pattern_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cleanReadsMeta = const VerificationMeta(
    'cleanReads',
  );
  @override
  late final GeneratedColumn<int> cleanReads = GeneratedColumn<int>(
    'clean_reads',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    learnerId,
    word,
    patternCode,
    addedAt,
    cleanReads,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tricky_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrickyWordEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('pattern_code')) {
      context.handle(
        _patternCodeMeta,
        patternCode.isAcceptableOrUnknown(
          data['pattern_code']!,
          _patternCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_patternCodeMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('clean_reads')) {
      context.handle(
        _cleanReadsMeta,
        cleanReads.isAcceptableOrUnknown(data['clean_reads']!, _cleanReadsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {learnerId, word};
  @override
  TrickyWordEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrickyWordEntry(
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learner_id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      patternCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern_code'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      cleanReads: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clean_reads'],
      )!,
    );
  }

  @override
  $TrickyWordEntriesTable createAlias(String alias) {
    return $TrickyWordEntriesTable(attachedDatabase, alias);
  }
}

class TrickyWordEntry extends DataClass implements Insertable<TrickyWordEntry> {
  final String learnerId;
  final String word;
  final String patternCode;
  final DateTime addedAt;
  final int cleanReads;
  const TrickyWordEntry({
    required this.learnerId,
    required this.word,
    required this.patternCode,
    required this.addedAt,
    required this.cleanReads,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['learner_id'] = Variable<String>(learnerId);
    map['word'] = Variable<String>(word);
    map['pattern_code'] = Variable<String>(patternCode);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['clean_reads'] = Variable<int>(cleanReads);
    return map;
  }

  TrickyWordEntriesCompanion toCompanion(bool nullToAbsent) {
    return TrickyWordEntriesCompanion(
      learnerId: Value(learnerId),
      word: Value(word),
      patternCode: Value(patternCode),
      addedAt: Value(addedAt),
      cleanReads: Value(cleanReads),
    );
  }

  factory TrickyWordEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrickyWordEntry(
      learnerId: serializer.fromJson<String>(json['learnerId']),
      word: serializer.fromJson<String>(json['word']),
      patternCode: serializer.fromJson<String>(json['patternCode']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      cleanReads: serializer.fromJson<int>(json['cleanReads']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'learnerId': serializer.toJson<String>(learnerId),
      'word': serializer.toJson<String>(word),
      'patternCode': serializer.toJson<String>(patternCode),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'cleanReads': serializer.toJson<int>(cleanReads),
    };
  }

  TrickyWordEntry copyWith({
    String? learnerId,
    String? word,
    String? patternCode,
    DateTime? addedAt,
    int? cleanReads,
  }) => TrickyWordEntry(
    learnerId: learnerId ?? this.learnerId,
    word: word ?? this.word,
    patternCode: patternCode ?? this.patternCode,
    addedAt: addedAt ?? this.addedAt,
    cleanReads: cleanReads ?? this.cleanReads,
  );
  TrickyWordEntry copyWithCompanion(TrickyWordEntriesCompanion data) {
    return TrickyWordEntry(
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      word: data.word.present ? data.word.value : this.word,
      patternCode: data.patternCode.present
          ? data.patternCode.value
          : this.patternCode,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      cleanReads: data.cleanReads.present
          ? data.cleanReads.value
          : this.cleanReads,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrickyWordEntry(')
          ..write('learnerId: $learnerId, ')
          ..write('word: $word, ')
          ..write('patternCode: $patternCode, ')
          ..write('addedAt: $addedAt, ')
          ..write('cleanReads: $cleanReads')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(learnerId, word, patternCode, addedAt, cleanReads);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrickyWordEntry &&
          other.learnerId == this.learnerId &&
          other.word == this.word &&
          other.patternCode == this.patternCode &&
          other.addedAt == this.addedAt &&
          other.cleanReads == this.cleanReads);
}

class TrickyWordEntriesCompanion extends UpdateCompanion<TrickyWordEntry> {
  final Value<String> learnerId;
  final Value<String> word;
  final Value<String> patternCode;
  final Value<DateTime> addedAt;
  final Value<int> cleanReads;
  final Value<int> rowid;
  const TrickyWordEntriesCompanion({
    this.learnerId = const Value.absent(),
    this.word = const Value.absent(),
    this.patternCode = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.cleanReads = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrickyWordEntriesCompanion.insert({
    required String learnerId,
    required String word,
    required String patternCode,
    required DateTime addedAt,
    this.cleanReads = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : learnerId = Value(learnerId),
       word = Value(word),
       patternCode = Value(patternCode),
       addedAt = Value(addedAt);
  static Insertable<TrickyWordEntry> custom({
    Expression<String>? learnerId,
    Expression<String>? word,
    Expression<String>? patternCode,
    Expression<DateTime>? addedAt,
    Expression<int>? cleanReads,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (learnerId != null) 'learner_id': learnerId,
      if (word != null) 'word': word,
      if (patternCode != null) 'pattern_code': patternCode,
      if (addedAt != null) 'added_at': addedAt,
      if (cleanReads != null) 'clean_reads': cleanReads,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrickyWordEntriesCompanion copyWith({
    Value<String>? learnerId,
    Value<String>? word,
    Value<String>? patternCode,
    Value<DateTime>? addedAt,
    Value<int>? cleanReads,
    Value<int>? rowid,
  }) {
    return TrickyWordEntriesCompanion(
      learnerId: learnerId ?? this.learnerId,
      word: word ?? this.word,
      patternCode: patternCode ?? this.patternCode,
      addedAt: addedAt ?? this.addedAt,
      cleanReads: cleanReads ?? this.cleanReads,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (learnerId.present) {
      map['learner_id'] = Variable<String>(learnerId.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (patternCode.present) {
      map['pattern_code'] = Variable<String>(patternCode.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (cleanReads.present) {
      map['clean_reads'] = Variable<int>(cleanReads.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrickyWordEntriesCompanion(')
          ..write('learnerId: $learnerId, ')
          ..write('word: $word, ')
          ..write('patternCode: $patternCode, ')
          ..write('addedAt: $addedAt, ')
          ..write('cleanReads: $cleanReads, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HintStatEntriesTable extends HintStatEntries
    with TableInfo<$HintStatEntriesTable, HintStatEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HintStatEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<String> learnerId = GeneratedColumn<String>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _hintLevelMeta = const VerificationMeta(
    'hintLevel',
  );
  @override
  late final GeneratedColumn<int> hintLevel = GeneratedColumn<int>(
    'hint_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usesMeta = const VerificationMeta('uses');
  @override
  late final GeneratedColumn<int> uses = GeneratedColumn<int>(
    'uses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _successesMeta = const VerificationMeta(
    'successes',
  );
  @override
  late final GeneratedColumn<int> successes = GeneratedColumn<int>(
    'successes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [learnerId, hintLevel, uses, successes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hint_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<HintStatEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('hint_level')) {
      context.handle(
        _hintLevelMeta,
        hintLevel.isAcceptableOrUnknown(data['hint_level']!, _hintLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_hintLevelMeta);
    }
    if (data.containsKey('uses')) {
      context.handle(
        _usesMeta,
        uses.isAcceptableOrUnknown(data['uses']!, _usesMeta),
      );
    } else if (isInserting) {
      context.missing(_usesMeta);
    }
    if (data.containsKey('successes')) {
      context.handle(
        _successesMeta,
        successes.isAcceptableOrUnknown(data['successes']!, _successesMeta),
      );
    } else if (isInserting) {
      context.missing(_successesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {learnerId, hintLevel};
  @override
  HintStatEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HintStatEntry(
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learner_id'],
      )!,
      hintLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hint_level'],
      )!,
      uses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uses'],
      )!,
      successes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}successes'],
      )!,
    );
  }

  @override
  $HintStatEntriesTable createAlias(String alias) {
    return $HintStatEntriesTable(attachedDatabase, alias);
  }
}

class HintStatEntry extends DataClass implements Insertable<HintStatEntry> {
  final String learnerId;
  final int hintLevel;
  final int uses;
  final int successes;
  const HintStatEntry({
    required this.learnerId,
    required this.hintLevel,
    required this.uses,
    required this.successes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['learner_id'] = Variable<String>(learnerId);
    map['hint_level'] = Variable<int>(hintLevel);
    map['uses'] = Variable<int>(uses);
    map['successes'] = Variable<int>(successes);
    return map;
  }

  HintStatEntriesCompanion toCompanion(bool nullToAbsent) {
    return HintStatEntriesCompanion(
      learnerId: Value(learnerId),
      hintLevel: Value(hintLevel),
      uses: Value(uses),
      successes: Value(successes),
    );
  }

  factory HintStatEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HintStatEntry(
      learnerId: serializer.fromJson<String>(json['learnerId']),
      hintLevel: serializer.fromJson<int>(json['hintLevel']),
      uses: serializer.fromJson<int>(json['uses']),
      successes: serializer.fromJson<int>(json['successes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'learnerId': serializer.toJson<String>(learnerId),
      'hintLevel': serializer.toJson<int>(hintLevel),
      'uses': serializer.toJson<int>(uses),
      'successes': serializer.toJson<int>(successes),
    };
  }

  HintStatEntry copyWith({
    String? learnerId,
    int? hintLevel,
    int? uses,
    int? successes,
  }) => HintStatEntry(
    learnerId: learnerId ?? this.learnerId,
    hintLevel: hintLevel ?? this.hintLevel,
    uses: uses ?? this.uses,
    successes: successes ?? this.successes,
  );
  HintStatEntry copyWithCompanion(HintStatEntriesCompanion data) {
    return HintStatEntry(
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      hintLevel: data.hintLevel.present ? data.hintLevel.value : this.hintLevel,
      uses: data.uses.present ? data.uses.value : this.uses,
      successes: data.successes.present ? data.successes.value : this.successes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HintStatEntry(')
          ..write('learnerId: $learnerId, ')
          ..write('hintLevel: $hintLevel, ')
          ..write('uses: $uses, ')
          ..write('successes: $successes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(learnerId, hintLevel, uses, successes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HintStatEntry &&
          other.learnerId == this.learnerId &&
          other.hintLevel == this.hintLevel &&
          other.uses == this.uses &&
          other.successes == this.successes);
}

class HintStatEntriesCompanion extends UpdateCompanion<HintStatEntry> {
  final Value<String> learnerId;
  final Value<int> hintLevel;
  final Value<int> uses;
  final Value<int> successes;
  final Value<int> rowid;
  const HintStatEntriesCompanion({
    this.learnerId = const Value.absent(),
    this.hintLevel = const Value.absent(),
    this.uses = const Value.absent(),
    this.successes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HintStatEntriesCompanion.insert({
    required String learnerId,
    required int hintLevel,
    required int uses,
    required int successes,
    this.rowid = const Value.absent(),
  }) : learnerId = Value(learnerId),
       hintLevel = Value(hintLevel),
       uses = Value(uses),
       successes = Value(successes);
  static Insertable<HintStatEntry> custom({
    Expression<String>? learnerId,
    Expression<int>? hintLevel,
    Expression<int>? uses,
    Expression<int>? successes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (learnerId != null) 'learner_id': learnerId,
      if (hintLevel != null) 'hint_level': hintLevel,
      if (uses != null) 'uses': uses,
      if (successes != null) 'successes': successes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HintStatEntriesCompanion copyWith({
    Value<String>? learnerId,
    Value<int>? hintLevel,
    Value<int>? uses,
    Value<int>? successes,
    Value<int>? rowid,
  }) {
    return HintStatEntriesCompanion(
      learnerId: learnerId ?? this.learnerId,
      hintLevel: hintLevel ?? this.hintLevel,
      uses: uses ?? this.uses,
      successes: successes ?? this.successes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (learnerId.present) {
      map['learner_id'] = Variable<String>(learnerId.value);
    }
    if (hintLevel.present) {
      map['hint_level'] = Variable<int>(hintLevel.value);
    }
    if (uses.present) {
      map['uses'] = Variable<int>(uses.value);
    }
    if (successes.present) {
      map['successes'] = Variable<int>(successes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HintStatEntriesCompanion(')
          ..write('learnerId: $learnerId, ')
          ..write('hintLevel: $hintLevel, ')
          ..write('uses: $uses, ')
          ..write('successes: $successes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FlagsTable extends Flags with TableInfo<$FlagsTable, TeacherFlag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<String> learnerId = GeneratedColumn<String>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learners (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seenMeta = const VerificationMeta('seen');
  @override
  late final GeneratedColumn<bool> seen = GeneratedColumn<bool>(
    'seen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("seen" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    learnerId,
    reason,
    createdAt,
    seen,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeacherFlag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('seen')) {
      context.handle(
        _seenMeta,
        seen.isAcceptableOrUnknown(data['seen']!, _seenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeacherFlag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeacherFlag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learner_id'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      seen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}seen'],
      )!,
    );
  }

  @override
  $FlagsTable createAlias(String alias) {
    return $FlagsTable(attachedDatabase, alias);
  }
}

class TeacherFlag extends DataClass implements Insertable<TeacherFlag> {
  final int id;
  final String learnerId;
  final String reason;
  final DateTime createdAt;
  final bool seen;
  const TeacherFlag({
    required this.id,
    required this.learnerId,
    required this.reason,
    required this.createdAt,
    required this.seen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['learner_id'] = Variable<String>(learnerId);
    map['reason'] = Variable<String>(reason);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['seen'] = Variable<bool>(seen);
    return map;
  }

  FlagsCompanion toCompanion(bool nullToAbsent) {
    return FlagsCompanion(
      id: Value(id),
      learnerId: Value(learnerId),
      reason: Value(reason),
      createdAt: Value(createdAt),
      seen: Value(seen),
    );
  }

  factory TeacherFlag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeacherFlag(
      id: serializer.fromJson<int>(json['id']),
      learnerId: serializer.fromJson<String>(json['learnerId']),
      reason: serializer.fromJson<String>(json['reason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      seen: serializer.fromJson<bool>(json['seen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'learnerId': serializer.toJson<String>(learnerId),
      'reason': serializer.toJson<String>(reason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'seen': serializer.toJson<bool>(seen),
    };
  }

  TeacherFlag copyWith({
    int? id,
    String? learnerId,
    String? reason,
    DateTime? createdAt,
    bool? seen,
  }) => TeacherFlag(
    id: id ?? this.id,
    learnerId: learnerId ?? this.learnerId,
    reason: reason ?? this.reason,
    createdAt: createdAt ?? this.createdAt,
    seen: seen ?? this.seen,
  );
  TeacherFlag copyWithCompanion(FlagsCompanion data) {
    return TeacherFlag(
      id: data.id.present ? data.id.value : this.id,
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      seen: data.seen.present ? data.seen.value : this.seen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeacherFlag(')
          ..write('id: $id, ')
          ..write('learnerId: $learnerId, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('seen: $seen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, learnerId, reason, createdAt, seen);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeacherFlag &&
          other.id == this.id &&
          other.learnerId == this.learnerId &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt &&
          other.seen == this.seen);
}

class FlagsCompanion extends UpdateCompanion<TeacherFlag> {
  final Value<int> id;
  final Value<String> learnerId;
  final Value<String> reason;
  final Value<DateTime> createdAt;
  final Value<bool> seen;
  const FlagsCompanion({
    this.id = const Value.absent(),
    this.learnerId = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.seen = const Value.absent(),
  });
  FlagsCompanion.insert({
    this.id = const Value.absent(),
    required String learnerId,
    required String reason,
    required DateTime createdAt,
    this.seen = const Value.absent(),
  }) : learnerId = Value(learnerId),
       reason = Value(reason),
       createdAt = Value(createdAt);
  static Insertable<TeacherFlag> custom({
    Expression<int>? id,
    Expression<String>? learnerId,
    Expression<String>? reason,
    Expression<DateTime>? createdAt,
    Expression<bool>? seen,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (learnerId != null) 'learner_id': learnerId,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
      if (seen != null) 'seen': seen,
    });
  }

  FlagsCompanion copyWith({
    Value<int>? id,
    Value<String>? learnerId,
    Value<String>? reason,
    Value<DateTime>? createdAt,
    Value<bool>? seen,
  }) {
    return FlagsCompanion(
      id: id ?? this.id,
      learnerId: learnerId ?? this.learnerId,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      seen: seen ?? this.seen,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (learnerId.present) {
      map['learner_id'] = Variable<String>(learnerId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (seen.present) {
      map['seen'] = Variable<bool>(seen.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlagsCompanion(')
          ..write('id: $id, ')
          ..write('learnerId: $learnerId, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('seen: $seen')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LearnersTable learners = $LearnersTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $WordEventsTable wordEvents = $WordEventsTable(this);
  late final $MasteryEntriesTable masteryEntries = $MasteryEntriesTable(this);
  late final $TrickyWordEntriesTable trickyWordEntries =
      $TrickyWordEntriesTable(this);
  late final $HintStatEntriesTable hintStatEntries = $HintStatEntriesTable(
    this,
  );
  late final $FlagsTable flags = $FlagsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    learners,
    sessions,
    wordEvents,
    masteryEntries,
    trickyWordEntries,
    hintStatEntries,
    flags,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'learners',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('word_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'learners',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('mastery', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'learners',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tricky_words', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'learners',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('hint_stats', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'learners',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('flags', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LearnersTableCreateCompanionBuilder = LearnersCompanion Function({
  required String id,
  required String nickname,
  required int grade,
  required String languages,
  Value<String?> classCode,
  Value<double> readingScore,
  Value<double?> predictionBias,
  Value<bool> dyslexiaMode,
  Value<double> textScale,
  Value<bool> highContrast,
  Value<bool> readAloud,
  Value<double?> hintWaitSec,
  Value<int> startHintLevel,
  Value<int> stars,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$LearnersTableUpdateCompanionBuilder = LearnersCompanion Function({
  Value<String> id,
  Value<String> nickname,
  Value<int> grade,
  Value<String> languages,
  Value<String?> classCode,
  Value<double> readingScore,
  Value<double?> predictionBias,
  Value<bool> dyslexiaMode,
  Value<double> textScale,
  Value<bool> highContrast,
  Value<bool> readAloud,
  Value<double?> hintWaitSec,
  Value<int> startHintLevel,
  Value<int> stars,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$LearnersTableReferences
    extends BaseReferences<_$AppDatabase, $LearnersTable, Learner> {
  $$LearnersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionsTable, List<ReadingSession>>
  _sessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: 'learners__id__sessions__learner_id',
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MasteryEntriesTable, List<MasteryEntry>>
  _masteryEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.masteryEntries,
    aliasName: 'learners__id__mastery__learner_id',
  );

  $$MasteryEntriesTableProcessedTableManager get masteryEntriesRefs {
    final manager = $$MasteryEntriesTableTableManager(
      $_db,
      $_db.masteryEntries,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_masteryEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TrickyWordEntriesTable, List<TrickyWordEntry>>
  _trickyWordEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.trickyWordEntries,
        aliasName: 'learners__id__tricky_words__learner_id',
      );

  $$TrickyWordEntriesTableProcessedTableManager get trickyWordEntriesRefs {
    final manager = $$TrickyWordEntriesTableTableManager(
      $_db,
      $_db.trickyWordEntries,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _trickyWordEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HintStatEntriesTable, List<HintStatEntry>>
  _hintStatEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.hintStatEntries,
    aliasName: 'learners__id__hint_stats__learner_id',
  );

  $$HintStatEntriesTableProcessedTableManager get hintStatEntriesRefs {
    final manager = $$HintStatEntriesTableTableManager(
      $_db,
      $_db.hintStatEntries,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _hintStatEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FlagsTable, List<TeacherFlag>> _flagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.flags,
    aliasName: 'learners__id__flags__learner_id',
  );

  $$FlagsTableProcessedTableManager get flagsRefs {
    final manager = $$FlagsTableTableManager(
      $_db,
      $_db.flags,
    ).filter((f) => f.learnerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_flagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LearnersTableFilterComposer
    extends Composer<_$AppDatabase, $LearnersTable> {
  $$LearnersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languages => $composableBuilder(
    column: $table.languages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classCode => $composableBuilder(
    column: $table.classCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get readingScore => $composableBuilder(
    column: $table.readingScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get predictionBias => $composableBuilder(
    column: $table.predictionBias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dyslexiaMode => $composableBuilder(
    column: $table.dyslexiaMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get textScale => $composableBuilder(
    column: $table.textScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get highContrast => $composableBuilder(
    column: $table.highContrast,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get readAloud => $composableBuilder(
    column: $table.readAloud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hintWaitSec => $composableBuilder(
    column: $table.hintWaitSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startHintLevel => $composableBuilder(
    column: $table.startHintLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> masteryEntriesRefs(
    Expression<bool> Function($$MasteryEntriesTableFilterComposer f) f,
  ) {
    final $$MasteryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.masteryEntries,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MasteryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.masteryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> trickyWordEntriesRefs(
    Expression<bool> Function($$TrickyWordEntriesTableFilterComposer f) f,
  ) {
    final $$TrickyWordEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trickyWordEntries,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrickyWordEntriesTableFilterComposer(
            $db: $db,
            $table: $db.trickyWordEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> hintStatEntriesRefs(
    Expression<bool> Function($$HintStatEntriesTableFilterComposer f) f,
  ) {
    final $$HintStatEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hintStatEntries,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HintStatEntriesTableFilterComposer(
            $db: $db,
            $table: $db.hintStatEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> flagsRefs(
    Expression<bool> Function($$FlagsTableFilterComposer f) f,
  ) {
    final $$FlagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flags,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlagsTableFilterComposer(
            $db: $db,
            $table: $db.flags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LearnersTableOrderingComposer
    extends Composer<_$AppDatabase, $LearnersTable> {
  $$LearnersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languages => $composableBuilder(
    column: $table.languages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classCode => $composableBuilder(
    column: $table.classCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get readingScore => $composableBuilder(
    column: $table.readingScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get predictionBias => $composableBuilder(
    column: $table.predictionBias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dyslexiaMode => $composableBuilder(
    column: $table.dyslexiaMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get textScale => $composableBuilder(
    column: $table.textScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get highContrast => $composableBuilder(
    column: $table.highContrast,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get readAloud => $composableBuilder(
    column: $table.readAloud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hintWaitSec => $composableBuilder(
    column: $table.hintWaitSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startHintLevel => $composableBuilder(
    column: $table.startHintLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearnersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearnersTable> {
  $$LearnersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<int> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get languages =>
      $composableBuilder(column: $table.languages, builder: (column) => column);

  GeneratedColumn<String> get classCode =>
      $composableBuilder(column: $table.classCode, builder: (column) => column);

  GeneratedColumn<double> get readingScore => $composableBuilder(
    column: $table.readingScore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get predictionBias => $composableBuilder(
    column: $table.predictionBias,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dyslexiaMode => $composableBuilder(
    column: $table.dyslexiaMode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get textScale =>
      $composableBuilder(column: $table.textScale, builder: (column) => column);

  GeneratedColumn<bool> get highContrast => $composableBuilder(
    column: $table.highContrast,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get readAloud =>
      $composableBuilder(column: $table.readAloud, builder: (column) => column);

  GeneratedColumn<double> get hintWaitSec => $composableBuilder(
    column: $table.hintWaitSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startHintLevel => $composableBuilder(
    column: $table.startHintLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> masteryEntriesRefs<T extends Object>(
    Expression<T> Function($$MasteryEntriesTableAnnotationComposer a) f,
  ) {
    final $$MasteryEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.masteryEntries,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MasteryEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.masteryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> trickyWordEntriesRefs<T extends Object>(
    Expression<T> Function($$TrickyWordEntriesTableAnnotationComposer a) f,
  ) {
    final $$TrickyWordEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.trickyWordEntries,
          getReferencedColumn: (t) => t.learnerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TrickyWordEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.trickyWordEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> hintStatEntriesRefs<T extends Object>(
    Expression<T> Function($$HintStatEntriesTableAnnotationComposer a) f,
  ) {
    final $$HintStatEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hintStatEntries,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HintStatEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.hintStatEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> flagsRefs<T extends Object>(
    Expression<T> Function($$FlagsTableAnnotationComposer a) f,
  ) {
    final $$FlagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flags,
      getReferencedColumn: (t) => t.learnerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlagsTableAnnotationComposer(
            $db: $db,
            $table: $db.flags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LearnersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearnersTable,
          Learner,
          $$LearnersTableFilterComposer,
          $$LearnersTableOrderingComposer,
          $$LearnersTableAnnotationComposer,
          $$LearnersTableCreateCompanionBuilder,
          $$LearnersTableUpdateCompanionBuilder,
          (Learner, $$LearnersTableReferences),
          Learner,
          PrefetchHooks Function({
            bool sessionsRefs,
            bool masteryEntriesRefs,
            bool trickyWordEntriesRefs,
            bool hintStatEntriesRefs,
            bool flagsRefs,
          })
        > {
  $$LearnersTableTableManager(_$AppDatabase db, $LearnersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearnersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearnersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearnersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<int> grade = const Value.absent(),
                Value<String> languages = const Value.absent(),
                Value<String?> classCode = const Value.absent(),
                Value<double> readingScore = const Value.absent(),
                Value<double?> predictionBias = const Value.absent(),
                Value<bool> dyslexiaMode = const Value.absent(),
                Value<double> textScale = const Value.absent(),
                Value<bool> highContrast = const Value.absent(),
                Value<bool> readAloud = const Value.absent(),
                Value<double?> hintWaitSec = const Value.absent(),
                Value<int> startHintLevel = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearnersCompanion(
                id: id,
                nickname: nickname,
                grade: grade,
                languages: languages,
                classCode: classCode,
                readingScore: readingScore,
                predictionBias: predictionBias,
                dyslexiaMode: dyslexiaMode,
                textScale: textScale,
                highContrast: highContrast,
                readAloud: readAloud,
                hintWaitSec: hintWaitSec,
                startHintLevel: startHintLevel,
                stars: stars,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nickname,
                required int grade,
                required String languages,
                Value<String?> classCode = const Value.absent(),
                Value<double> readingScore = const Value.absent(),
                Value<double?> predictionBias = const Value.absent(),
                Value<bool> dyslexiaMode = const Value.absent(),
                Value<double> textScale = const Value.absent(),
                Value<bool> highContrast = const Value.absent(),
                Value<bool> readAloud = const Value.absent(),
                Value<double?> hintWaitSec = const Value.absent(),
                Value<int> startHintLevel = const Value.absent(),
                Value<int> stars = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LearnersCompanion.insert(
                id: id,
                nickname: nickname,
                grade: grade,
                languages: languages,
                classCode: classCode,
                readingScore: readingScore,
                predictionBias: predictionBias,
                dyslexiaMode: dyslexiaMode,
                textScale: textScale,
                highContrast: highContrast,
                readAloud: readAloud,
                hintWaitSec: hintWaitSec,
                startHintLevel: startHintLevel,
                stars: stars,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LearnersTable, Learner>(table),
                  $$LearnersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sessionsRefs = false,
                masteryEntriesRefs = false,
                trickyWordEntriesRefs = false,
                hintStatEntriesRefs = false,
                flagsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionsRefs) db.sessions,
                    if (masteryEntriesRefs) db.masteryEntries,
                    if (trickyWordEntriesRefs) db.trickyWordEntries,
                    if (hintStatEntriesRefs) db.hintStatEntries,
                    if (flagsRefs) db.flags,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionsRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          ReadingSession
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._sessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (masteryEntriesRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          MasteryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._masteryEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).masteryEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (trickyWordEntriesRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          TrickyWordEntry
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._trickyWordEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).trickyWordEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (hintStatEntriesRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          HintStatEntry
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._hintStatEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).hintStatEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (flagsRefs)
                        await $_getPrefetchedData<
                          Learner,
                          $LearnersTable,
                          TeacherFlag
                        >(
                          currentTable: table,
                          referencedTable: $$LearnersTableReferences
                              ._flagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearnersTableReferences(
                                db,
                                table,
                                p0,
                              ).flagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.learnerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LearnersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearnersTable,
      Learner,
      $$LearnersTableFilterComposer,
      $$LearnersTableOrderingComposer,
      $$LearnersTableAnnotationComposer,
      $$LearnersTableCreateCompanionBuilder,
      $$LearnersTableUpdateCompanionBuilder,
      (Learner, $$LearnersTableReferences),
      Learner,
      PrefetchHooks Function({
        bool sessionsRefs,
        bool masteryEntriesRefs,
        bool trickyWordEntriesRefs,
        bool hintStatEntriesRefs,
        bool flagsRefs,
      })
    >;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  required String learnerId,
  required String storyId,
  required SessionType type,
  required DateTime startedAt,
  required double readingSeconds,
  required int wordsTotal,
  required int wordsCorrect,
  required int questionsTotal,
  required int questionsCorrect,
  required int hesitations,
  required int miscues,
  required int skips,
  required int unsureWords,
  required int hintsGiven,
  required double accuracy,
  required double wcpm,
  required double comprehension,
  required PhilIriLevel philiriLevel,
  required double bookDifficulty,
  required double scoreBefore,
  required double scoreAfter,
  Value<double?> predictedAccuracy,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<String> learnerId,
  Value<String> storyId,
  Value<SessionType> type,
  Value<DateTime> startedAt,
  Value<double> readingSeconds,
  Value<int> wordsTotal,
  Value<int> wordsCorrect,
  Value<int> questionsTotal,
  Value<int> questionsCorrect,
  Value<int> hesitations,
  Value<int> miscues,
  Value<int> skips,
  Value<int> unsureWords,
  Value<int> hintsGiven,
  Value<double> accuracy,
  Value<double> wcpm,
  Value<double> comprehension,
  Value<PhilIriLevel> philiriLevel,
  Value<double> bookDifficulty,
  Value<double> scoreBefore,
  Value<double> scoreAfter,
  Value<double?> predictedAccuracy,
  Value<int> rowid,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, ReadingSession> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LearnersTable _learnerIdTable(_$AppDatabase db) =>
      db.learners.createAlias('sessions__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<String>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WordEventsTable, List<WordEvent>>
  _wordEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wordEvents,
    aliasName: 'sessions__id__word_events__session_id',
  );

  $$WordEventsTableProcessedTableManager get wordEventsRefs {
    final manager = $$WordEventsTableTableManager(
      $_db,
      $_db.wordEvents,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionType, SessionType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get readingSeconds => $composableBuilder(
    column: $table.readingSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordsTotal => $composableBuilder(
    column: $table.wordsTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordsCorrect => $composableBuilder(
    column: $table.wordsCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionsTotal => $composableBuilder(
    column: $table.questionsTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionsCorrect => $composableBuilder(
    column: $table.questionsCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hesitations => $composableBuilder(
    column: $table.hesitations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get miscues => $composableBuilder(
    column: $table.miscues,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skips => $composableBuilder(
    column: $table.skips,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unsureWords => $composableBuilder(
    column: $table.unsureWords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintsGiven => $composableBuilder(
    column: $table.hintsGiven,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get wcpm => $composableBuilder(
    column: $table.wcpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get comprehension => $composableBuilder(
    column: $table.comprehension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PhilIriLevel, PhilIriLevel, String>
  get philiriLevel => $composableBuilder(
    column: $table.philiriLevel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get bookDifficulty => $composableBuilder(
    column: $table.bookDifficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scoreBefore => $composableBuilder(
    column: $table.scoreBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scoreAfter => $composableBuilder(
    column: $table.scoreAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get predictedAccuracy => $composableBuilder(
    column: $table.predictedAccuracy,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> wordEventsRefs(
    Expression<bool> Function($$WordEventsTableFilterComposer f) f,
  ) {
    final $$WordEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordEvents,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordEventsTableFilterComposer(
            $db: $db,
            $table: $db.wordEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get readingSeconds => $composableBuilder(
    column: $table.readingSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordsTotal => $composableBuilder(
    column: $table.wordsTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordsCorrect => $composableBuilder(
    column: $table.wordsCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionsTotal => $composableBuilder(
    column: $table.questionsTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionsCorrect => $composableBuilder(
    column: $table.questionsCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hesitations => $composableBuilder(
    column: $table.hesitations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get miscues => $composableBuilder(
    column: $table.miscues,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skips => $composableBuilder(
    column: $table.skips,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unsureWords => $composableBuilder(
    column: $table.unsureWords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintsGiven => $composableBuilder(
    column: $table.hintsGiven,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get wcpm => $composableBuilder(
    column: $table.wcpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get comprehension => $composableBuilder(
    column: $table.comprehension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get philiriLevel => $composableBuilder(
    column: $table.philiriLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bookDifficulty => $composableBuilder(
    column: $table.bookDifficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scoreBefore => $composableBuilder(
    column: $table.scoreBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scoreAfter => $composableBuilder(
    column: $table.scoreAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get predictedAccuracy => $composableBuilder(
    column: $table.predictedAccuracy,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<double> get readingSeconds => $composableBuilder(
    column: $table.readingSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordsTotal => $composableBuilder(
    column: $table.wordsTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordsCorrect => $composableBuilder(
    column: $table.wordsCorrect,
    builder: (column) => column,
  );

  GeneratedColumn<int> get questionsTotal => $composableBuilder(
    column: $table.questionsTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get questionsCorrect => $composableBuilder(
    column: $table.questionsCorrect,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hesitations => $composableBuilder(
    column: $table.hesitations,
    builder: (column) => column,
  );

  GeneratedColumn<int> get miscues =>
      $composableBuilder(column: $table.miscues, builder: (column) => column);

  GeneratedColumn<int> get skips =>
      $composableBuilder(column: $table.skips, builder: (column) => column);

  GeneratedColumn<int> get unsureWords => $composableBuilder(
    column: $table.unsureWords,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hintsGiven => $composableBuilder(
    column: $table.hintsGiven,
    builder: (column) => column,
  );

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<double> get wcpm =>
      $composableBuilder(column: $table.wcpm, builder: (column) => column);

  GeneratedColumn<double> get comprehension => $composableBuilder(
    column: $table.comprehension,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PhilIriLevel, String> get philiriLevel =>
      $composableBuilder(
        column: $table.philiriLevel,
        builder: (column) => column,
      );

  GeneratedColumn<double> get bookDifficulty => $composableBuilder(
    column: $table.bookDifficulty,
    builder: (column) => column,
  );

  GeneratedColumn<double> get scoreBefore => $composableBuilder(
    column: $table.scoreBefore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get scoreAfter => $composableBuilder(
    column: $table.scoreAfter,
    builder: (column) => column,
  );

  GeneratedColumn<double> get predictedAccuracy => $composableBuilder(
    column: $table.predictedAccuracy,
    builder: (column) => column,
  );

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> wordEventsRefs<T extends Object>(
    Expression<T> Function($$WordEventsTableAnnotationComposer a) f,
  ) {
    final $$WordEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordEvents,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.wordEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          ReadingSession,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (ReadingSession, $$SessionsTableReferences),
          ReadingSession,
          PrefetchHooks Function({bool learnerId, bool wordEventsRefs})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> learnerId = const Value.absent(),
                Value<String> storyId = const Value.absent(),
                Value<SessionType> type = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<double> readingSeconds = const Value.absent(),
                Value<int> wordsTotal = const Value.absent(),
                Value<int> wordsCorrect = const Value.absent(),
                Value<int> questionsTotal = const Value.absent(),
                Value<int> questionsCorrect = const Value.absent(),
                Value<int> hesitations = const Value.absent(),
                Value<int> miscues = const Value.absent(),
                Value<int> skips = const Value.absent(),
                Value<int> unsureWords = const Value.absent(),
                Value<int> hintsGiven = const Value.absent(),
                Value<double> accuracy = const Value.absent(),
                Value<double> wcpm = const Value.absent(),
                Value<double> comprehension = const Value.absent(),
                Value<PhilIriLevel> philiriLevel = const Value.absent(),
                Value<double> bookDifficulty = const Value.absent(),
                Value<double> scoreBefore = const Value.absent(),
                Value<double> scoreAfter = const Value.absent(),
                Value<double?> predictedAccuracy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                learnerId: learnerId,
                storyId: storyId,
                type: type,
                startedAt: startedAt,
                readingSeconds: readingSeconds,
                wordsTotal: wordsTotal,
                wordsCorrect: wordsCorrect,
                questionsTotal: questionsTotal,
                questionsCorrect: questionsCorrect,
                hesitations: hesitations,
                miscues: miscues,
                skips: skips,
                unsureWords: unsureWords,
                hintsGiven: hintsGiven,
                accuracy: accuracy,
                wcpm: wcpm,
                comprehension: comprehension,
                philiriLevel: philiriLevel,
                bookDifficulty: bookDifficulty,
                scoreBefore: scoreBefore,
                scoreAfter: scoreAfter,
                predictedAccuracy: predictedAccuracy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String learnerId,
                required String storyId,
                required SessionType type,
                required DateTime startedAt,
                required double readingSeconds,
                required int wordsTotal,
                required int wordsCorrect,
                required int questionsTotal,
                required int questionsCorrect,
                required int hesitations,
                required int miscues,
                required int skips,
                required int unsureWords,
                required int hintsGiven,
                required double accuracy,
                required double wcpm,
                required double comprehension,
                required PhilIriLevel philiriLevel,
                required double bookDifficulty,
                required double scoreBefore,
                required double scoreAfter,
                Value<double?> predictedAccuracy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                learnerId: learnerId,
                storyId: storyId,
                type: type,
                startedAt: startedAt,
                readingSeconds: readingSeconds,
                wordsTotal: wordsTotal,
                wordsCorrect: wordsCorrect,
                questionsTotal: questionsTotal,
                questionsCorrect: questionsCorrect,
                hesitations: hesitations,
                miscues: miscues,
                skips: skips,
                unsureWords: unsureWords,
                hintsGiven: hintsGiven,
                accuracy: accuracy,
                wcpm: wcpm,
                comprehension: comprehension,
                philiriLevel: philiriLevel,
                bookDifficulty: bookDifficulty,
                scoreBefore: scoreBefore,
                scoreAfter: scoreAfter,
                predictedAccuracy: predictedAccuracy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, ReadingSession>(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnerId = false, wordEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (wordEventsRefs) db.wordEvents],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learnerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.learnerId,
                        referencedTable: $$SessionsTableReferences
                            ._learnerIdTable(db),
                        referencedColumn: $$SessionsTableReferences
                            ._learnerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (wordEventsRefs)
                    await $_getPrefetchedData<
                      ReadingSession,
                      $SessionsTable,
                      WordEvent
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._wordEventsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SessionsTableReferences(
                        db,
                        table,
                        p0,
                      ).wordEventsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      ReadingSession,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (ReadingSession, $$SessionsTableReferences),
      ReadingSession,
      PrefetchHooks Function({bool learnerId, bool wordEventsRefs})
    >;
typedef $$WordEventsTableCreateCompanionBuilder = WordEventsCompanion Function({
  Value<int> id,
  required String sessionId,
  required int position,
  required String word,
  required String primaryPattern,
  required WordResult result,
  required int responseMs,
  required int hintLevel,
});
typedef $$WordEventsTableUpdateCompanionBuilder = WordEventsCompanion Function({
  Value<int> id,
  Value<String> sessionId,
  Value<int> position,
  Value<String> word,
  Value<String> primaryPattern,
  Value<WordResult> result,
  Value<int> responseMs,
  Value<int> hintLevel,
});

final class $$WordEventsTableReferences
    extends BaseReferences<_$AppDatabase, $WordEventsTable, WordEvent> {
  $$WordEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('word_events__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WordEventsTableFilterComposer
    extends Composer<_$AppDatabase, $WordEventsTable> {
  $$WordEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryPattern => $composableBuilder(
    column: $table.primaryPattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WordResult, WordResult, String> get result =>
      $composableBuilder(
        column: $table.result,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get responseMs => $composableBuilder(
    column: $table.responseMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintLevel => $composableBuilder(
    column: $table.hintLevel,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordEventsTable> {
  $$WordEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryPattern => $composableBuilder(
    column: $table.primaryPattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseMs => $composableBuilder(
    column: $table.responseMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintLevel => $composableBuilder(
    column: $table.hintLevel,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordEventsTable> {
  $$WordEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get primaryPattern => $composableBuilder(
    column: $table.primaryPattern,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<WordResult, String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<int> get responseMs => $composableBuilder(
    column: $table.responseMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hintLevel =>
      $composableBuilder(column: $table.hintLevel, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordEventsTable,
          WordEvent,
          $$WordEventsTableFilterComposer,
          $$WordEventsTableOrderingComposer,
          $$WordEventsTableAnnotationComposer,
          $$WordEventsTableCreateCompanionBuilder,
          $$WordEventsTableUpdateCompanionBuilder,
          (WordEvent, $$WordEventsTableReferences),
          WordEvent,
          PrefetchHooks Function({bool sessionId})
        > {
  $$WordEventsTableTableManager(_$AppDatabase db, $WordEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> primaryPattern = const Value.absent(),
                Value<WordResult> result = const Value.absent(),
                Value<int> responseMs = const Value.absent(),
                Value<int> hintLevel = const Value.absent(),
              }) => WordEventsCompanion(
                id: id,
                sessionId: sessionId,
                position: position,
                word: word,
                primaryPattern: primaryPattern,
                result: result,
                responseMs: responseMs,
                hintLevel: hintLevel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required int position,
                required String word,
                required String primaryPattern,
                required WordResult result,
                required int responseMs,
                required int hintLevel,
              }) => WordEventsCompanion.insert(
                id: id,
                sessionId: sessionId,
                position: position,
                word: word,
                primaryPattern: primaryPattern,
                result: result,
                responseMs: responseMs,
                hintLevel: hintLevel,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WordEventsTable, WordEvent>(table),
                  $$WordEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$WordEventsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$WordEventsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WordEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordEventsTable,
      WordEvent,
      $$WordEventsTableFilterComposer,
      $$WordEventsTableOrderingComposer,
      $$WordEventsTableAnnotationComposer,
      $$WordEventsTableCreateCompanionBuilder,
      $$WordEventsTableUpdateCompanionBuilder,
      (WordEvent, $$WordEventsTableReferences),
      WordEvent,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$MasteryEntriesTableCreateCompanionBuilder =
    MasteryEntriesCompanion Function({
      required String learnerId,
      required String patternCode,
      required double mastery,
      required int observations,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MasteryEntriesTableUpdateCompanionBuilder =
    MasteryEntriesCompanion Function({
      Value<String> learnerId,
      Value<String> patternCode,
      Value<double> mastery,
      Value<int> observations,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$MasteryEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $MasteryEntriesTable, MasteryEntry> {
  $$MasteryEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearnersTable _learnerIdTable(_$AppDatabase db) =>
      db.learners.createAlias('mastery__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<String>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MasteryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MasteryEntriesTable> {
  $$MasteryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get patternCode => $composableBuilder(
    column: $table.patternCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mastery => $composableBuilder(
    column: $table.mastery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get observations => $composableBuilder(
    column: $table.observations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MasteryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MasteryEntriesTable> {
  $$MasteryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get patternCode => $composableBuilder(
    column: $table.patternCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mastery => $composableBuilder(
    column: $table.mastery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get observations => $composableBuilder(
    column: $table.observations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MasteryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MasteryEntriesTable> {
  $$MasteryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get patternCode => $composableBuilder(
    column: $table.patternCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get mastery =>
      $composableBuilder(column: $table.mastery, builder: (column) => column);

  GeneratedColumn<int> get observations => $composableBuilder(
    column: $table.observations,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MasteryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MasteryEntriesTable,
          MasteryEntry,
          $$MasteryEntriesTableFilterComposer,
          $$MasteryEntriesTableOrderingComposer,
          $$MasteryEntriesTableAnnotationComposer,
          $$MasteryEntriesTableCreateCompanionBuilder,
          $$MasteryEntriesTableUpdateCompanionBuilder,
          (MasteryEntry, $$MasteryEntriesTableReferences),
          MasteryEntry,
          PrefetchHooks Function({bool learnerId})
        > {
  $$MasteryEntriesTableTableManager(
    _$AppDatabase db,
    $MasteryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MasteryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MasteryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MasteryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> learnerId = const Value.absent(),
                Value<String> patternCode = const Value.absent(),
                Value<double> mastery = const Value.absent(),
                Value<int> observations = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MasteryEntriesCompanion(
                learnerId: learnerId,
                patternCode: patternCode,
                mastery: mastery,
                observations: observations,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String learnerId,
                required String patternCode,
                required double mastery,
                required int observations,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MasteryEntriesCompanion.insert(
                learnerId: learnerId,
                patternCode: patternCode,
                mastery: mastery,
                observations: observations,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MasteryEntriesTable, MasteryEntry>(table),
                  $$MasteryEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learnerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.learnerId,
                        referencedTable: $$MasteryEntriesTableReferences
                            ._learnerIdTable(db),
                        referencedColumn: $$MasteryEntriesTableReferences
                            ._learnerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MasteryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MasteryEntriesTable,
      MasteryEntry,
      $$MasteryEntriesTableFilterComposer,
      $$MasteryEntriesTableOrderingComposer,
      $$MasteryEntriesTableAnnotationComposer,
      $$MasteryEntriesTableCreateCompanionBuilder,
      $$MasteryEntriesTableUpdateCompanionBuilder,
      (MasteryEntry, $$MasteryEntriesTableReferences),
      MasteryEntry,
      PrefetchHooks Function({bool learnerId})
    >;
typedef $$TrickyWordEntriesTableCreateCompanionBuilder =
    TrickyWordEntriesCompanion Function({
      required String learnerId,
      required String word,
      required String patternCode,
      required DateTime addedAt,
      Value<int> cleanReads,
      Value<int> rowid,
    });
typedef $$TrickyWordEntriesTableUpdateCompanionBuilder =
    TrickyWordEntriesCompanion Function({
      Value<String> learnerId,
      Value<String> word,
      Value<String> patternCode,
      Value<DateTime> addedAt,
      Value<int> cleanReads,
      Value<int> rowid,
    });

final class $$TrickyWordEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TrickyWordEntriesTable,
          TrickyWordEntry
        > {
  $$TrickyWordEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearnersTable _learnerIdTable(_$AppDatabase db) =>
      db.learners.createAlias('tricky_words__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<String>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrickyWordEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TrickyWordEntriesTable> {
  $$TrickyWordEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patternCode => $composableBuilder(
    column: $table.patternCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cleanReads => $composableBuilder(
    column: $table.cleanReads,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrickyWordEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TrickyWordEntriesTable> {
  $$TrickyWordEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patternCode => $composableBuilder(
    column: $table.patternCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cleanReads => $composableBuilder(
    column: $table.cleanReads,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrickyWordEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrickyWordEntriesTable> {
  $$TrickyWordEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get patternCode => $composableBuilder(
    column: $table.patternCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get cleanReads => $composableBuilder(
    column: $table.cleanReads,
    builder: (column) => column,
  );

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrickyWordEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrickyWordEntriesTable,
          TrickyWordEntry,
          $$TrickyWordEntriesTableFilterComposer,
          $$TrickyWordEntriesTableOrderingComposer,
          $$TrickyWordEntriesTableAnnotationComposer,
          $$TrickyWordEntriesTableCreateCompanionBuilder,
          $$TrickyWordEntriesTableUpdateCompanionBuilder,
          (TrickyWordEntry, $$TrickyWordEntriesTableReferences),
          TrickyWordEntry,
          PrefetchHooks Function({bool learnerId})
        > {
  $$TrickyWordEntriesTableTableManager(
    _$AppDatabase db,
    $TrickyWordEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrickyWordEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrickyWordEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrickyWordEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> learnerId = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> patternCode = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> cleanReads = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrickyWordEntriesCompanion(
                learnerId: learnerId,
                word: word,
                patternCode: patternCode,
                addedAt: addedAt,
                cleanReads: cleanReads,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String learnerId,
                required String word,
                required String patternCode,
                required DateTime addedAt,
                Value<int> cleanReads = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrickyWordEntriesCompanion.insert(
                learnerId: learnerId,
                word: word,
                patternCode: patternCode,
                addedAt: addedAt,
                cleanReads: cleanReads,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrickyWordEntriesTable, TrickyWordEntry>(table),
                  $$TrickyWordEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learnerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.learnerId,
                        referencedTable: $$TrickyWordEntriesTableReferences
                            ._learnerIdTable(db),
                        referencedColumn: $$TrickyWordEntriesTableReferences
                            ._learnerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrickyWordEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrickyWordEntriesTable,
      TrickyWordEntry,
      $$TrickyWordEntriesTableFilterComposer,
      $$TrickyWordEntriesTableOrderingComposer,
      $$TrickyWordEntriesTableAnnotationComposer,
      $$TrickyWordEntriesTableCreateCompanionBuilder,
      $$TrickyWordEntriesTableUpdateCompanionBuilder,
      (TrickyWordEntry, $$TrickyWordEntriesTableReferences),
      TrickyWordEntry,
      PrefetchHooks Function({bool learnerId})
    >;
typedef $$HintStatEntriesTableCreateCompanionBuilder =
    HintStatEntriesCompanion Function({
      required String learnerId,
      required int hintLevel,
      required int uses,
      required int successes,
      Value<int> rowid,
    });
typedef $$HintStatEntriesTableUpdateCompanionBuilder =
    HintStatEntriesCompanion Function({
      Value<String> learnerId,
      Value<int> hintLevel,
      Value<int> uses,
      Value<int> successes,
      Value<int> rowid,
    });

final class $$HintStatEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $HintStatEntriesTable, HintStatEntry> {
  $$HintStatEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearnersTable _learnerIdTable(_$AppDatabase db) =>
      db.learners.createAlias('hint_stats__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<String>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HintStatEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $HintStatEntriesTable> {
  $$HintStatEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get hintLevel => $composableBuilder(
    column: $table.hintLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uses => $composableBuilder(
    column: $table.uses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get successes => $composableBuilder(
    column: $table.successes,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HintStatEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HintStatEntriesTable> {
  $$HintStatEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get hintLevel => $composableBuilder(
    column: $table.hintLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uses => $composableBuilder(
    column: $table.uses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get successes => $composableBuilder(
    column: $table.successes,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HintStatEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HintStatEntriesTable> {
  $$HintStatEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get hintLevel =>
      $composableBuilder(column: $table.hintLevel, builder: (column) => column);

  GeneratedColumn<int> get uses =>
      $composableBuilder(column: $table.uses, builder: (column) => column);

  GeneratedColumn<int> get successes =>
      $composableBuilder(column: $table.successes, builder: (column) => column);

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HintStatEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HintStatEntriesTable,
          HintStatEntry,
          $$HintStatEntriesTableFilterComposer,
          $$HintStatEntriesTableOrderingComposer,
          $$HintStatEntriesTableAnnotationComposer,
          $$HintStatEntriesTableCreateCompanionBuilder,
          $$HintStatEntriesTableUpdateCompanionBuilder,
          (HintStatEntry, $$HintStatEntriesTableReferences),
          HintStatEntry,
          PrefetchHooks Function({bool learnerId})
        > {
  $$HintStatEntriesTableTableManager(
    _$AppDatabase db,
    $HintStatEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HintStatEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HintStatEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HintStatEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> learnerId = const Value.absent(),
                Value<int> hintLevel = const Value.absent(),
                Value<int> uses = const Value.absent(),
                Value<int> successes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HintStatEntriesCompanion(
                learnerId: learnerId,
                hintLevel: hintLevel,
                uses: uses,
                successes: successes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String learnerId,
                required int hintLevel,
                required int uses,
                required int successes,
                Value<int> rowid = const Value.absent(),
              }) => HintStatEntriesCompanion.insert(
                learnerId: learnerId,
                hintLevel: hintLevel,
                uses: uses,
                successes: successes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HintStatEntriesTable, HintStatEntry>(table),
                  $$HintStatEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learnerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.learnerId,
                        referencedTable: $$HintStatEntriesTableReferences
                            ._learnerIdTable(db),
                        referencedColumn: $$HintStatEntriesTableReferences
                            ._learnerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HintStatEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HintStatEntriesTable,
      HintStatEntry,
      $$HintStatEntriesTableFilterComposer,
      $$HintStatEntriesTableOrderingComposer,
      $$HintStatEntriesTableAnnotationComposer,
      $$HintStatEntriesTableCreateCompanionBuilder,
      $$HintStatEntriesTableUpdateCompanionBuilder,
      (HintStatEntry, $$HintStatEntriesTableReferences),
      HintStatEntry,
      PrefetchHooks Function({bool learnerId})
    >;
typedef $$FlagsTableCreateCompanionBuilder = FlagsCompanion Function({
  Value<int> id,
  required String learnerId,
  required String reason,
  required DateTime createdAt,
  Value<bool> seen,
});
typedef $$FlagsTableUpdateCompanionBuilder = FlagsCompanion Function({
  Value<int> id,
  Value<String> learnerId,
  Value<String> reason,
  Value<DateTime> createdAt,
  Value<bool> seen,
});

final class $$FlagsTableReferences
    extends BaseReferences<_$AppDatabase, $FlagsTable, TeacherFlag> {
  $$FlagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LearnersTable _learnerIdTable(_$AppDatabase db) =>
      db.learners.createAlias('flags__learner_id__learners__id');

  $$LearnersTableProcessedTableManager get learnerId {
    final $_column = $_itemColumn<String>('learner_id')!;

    final manager = $$LearnersTableTableManager(
      $_db,
      $_db.learners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_learnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FlagsTableFilterComposer extends Composer<_$AppDatabase, $FlagsTable> {
  $$FlagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnFilters(column),
  );

  $$LearnersTableFilterComposer get learnerId {
    final $$LearnersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableFilterComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlagsTableOrderingComposer
    extends Composer<_$AppDatabase, $FlagsTable> {
  $$FlagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearnersTableOrderingComposer get learnerId {
    final $$LearnersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableOrderingComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlagsTable> {
  $$FlagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get seen =>
      $composableBuilder(column: $table.seen, builder: (column) => column);

  $$LearnersTableAnnotationComposer get learnerId {
    final $$LearnersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.learnerId,
      referencedTable: $db.learners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnersTableAnnotationComposer(
            $db: $db,
            $table: $db.learners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlagsTable,
          TeacherFlag,
          $$FlagsTableFilterComposer,
          $$FlagsTableOrderingComposer,
          $$FlagsTableAnnotationComposer,
          $$FlagsTableCreateCompanionBuilder,
          $$FlagsTableUpdateCompanionBuilder,
          (TeacherFlag, $$FlagsTableReferences),
          TeacherFlag,
          PrefetchHooks Function({bool learnerId})
        > {
  $$FlagsTableTableManager(_$AppDatabase db, $FlagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> learnerId = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> seen = const Value.absent(),
              }) => FlagsCompanion(
                id: id,
                learnerId: learnerId,
                reason: reason,
                createdAt: createdAt,
                seen: seen,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String learnerId,
                required String reason,
                required DateTime createdAt,
                Value<bool> seen = const Value.absent(),
              }) => FlagsCompanion.insert(
                id: id,
                learnerId: learnerId,
                reason: reason,
                createdAt: createdAt,
                seen: seen,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FlagsTable, TeacherFlag>(table),
                  $$FlagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({learnerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (learnerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.learnerId,
                        referencedTable: $$FlagsTableReferences._learnerIdTable(
                          db,
                        ),
                        referencedColumn: $$FlagsTableReferences
                            ._learnerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FlagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlagsTable,
      TeacherFlag,
      $$FlagsTableFilterComposer,
      $$FlagsTableOrderingComposer,
      $$FlagsTableAnnotationComposer,
      $$FlagsTableCreateCompanionBuilder,
      $$FlagsTableUpdateCompanionBuilder,
      (TeacherFlag, $$FlagsTableReferences),
      TeacherFlag,
      PrefetchHooks Function({bool learnerId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LearnersTableTableManager get learners =>
      $$LearnersTableTableManager(_db, _db.learners);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$WordEventsTableTableManager get wordEvents =>
      $$WordEventsTableTableManager(_db, _db.wordEvents);
  $$MasteryEntriesTableTableManager get masteryEntries =>
      $$MasteryEntriesTableTableManager(_db, _db.masteryEntries);
  $$TrickyWordEntriesTableTableManager get trickyWordEntries =>
      $$TrickyWordEntriesTableTableManager(_db, _db.trickyWordEntries);
  $$HintStatEntriesTableTableManager get hintStatEntries =>
      $$HintStatEntriesTableTableManager(_db, _db.hintStatEntries);
  $$FlagsTableTableManager get flags =>
      $$FlagsTableTableManager(_db, _db.flags);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
