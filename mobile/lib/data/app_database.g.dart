// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DailyEntriesTable extends DailyEntries
    with TableInfo<$DailyEntriesTable, DailyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emotionMeta = const VerificationMeta(
    'emotion',
  );
  @override
  late final GeneratedColumn<String> emotion = GeneratedColumn<String>(
    'emotion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _followupQuestionMeta = const VerificationMeta(
    'followupQuestion',
  );
  @override
  late final GeneratedColumn<String> followupQuestion = GeneratedColumn<String>(
    'followup_question',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _followupAnswerMeta = const VerificationMeta(
    'followupAnswer',
  );
  @override
  late final GeneratedColumn<String> followupAnswer = GeneratedColumn<String>(
    'followup_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _followupEchoMeta = const VerificationMeta(
    'followupEcho',
  );
  @override
  late final GeneratedColumn<String> followupEcho = GeneratedColumn<String>(
    'followup_echo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _followupNextFocusMeta = const VerificationMeta(
    'followupNextFocus',
  );
  @override
  late final GeneratedColumn<String> followupNextFocus =
      GeneratedColumn<String>(
        'followup_next_focus',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _followupNoteMeta = const VerificationMeta(
    'followupNote',
  );
  @override
  late final GeneratedColumn<String> followupNote = GeneratedColumn<String>(
    'followup_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _followupDepthMeta = const VerificationMeta(
    'followupDepth',
  );
  @override
  late final GeneratedColumn<int> followupDepth = GeneratedColumn<int>(
    'followup_depth',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
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
    id,
    day,
    body,
    emotion,
    followupQuestion,
    followupAnswer,
    followupEcho,
    followupNextFocus,
    followupNote,
    followupDepth,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('emotion')) {
      context.handle(
        _emotionMeta,
        emotion.isAcceptableOrUnknown(data['emotion']!, _emotionMeta),
      );
    }
    if (data.containsKey('followup_question')) {
      context.handle(
        _followupQuestionMeta,
        followupQuestion.isAcceptableOrUnknown(
          data['followup_question']!,
          _followupQuestionMeta,
        ),
      );
    }
    if (data.containsKey('followup_answer')) {
      context.handle(
        _followupAnswerMeta,
        followupAnswer.isAcceptableOrUnknown(
          data['followup_answer']!,
          _followupAnswerMeta,
        ),
      );
    }
    if (data.containsKey('followup_echo')) {
      context.handle(
        _followupEchoMeta,
        followupEcho.isAcceptableOrUnknown(
          data['followup_echo']!,
          _followupEchoMeta,
        ),
      );
    }
    if (data.containsKey('followup_next_focus')) {
      context.handle(
        _followupNextFocusMeta,
        followupNextFocus.isAcceptableOrUnknown(
          data['followup_next_focus']!,
          _followupNextFocusMeta,
        ),
      );
    }
    if (data.containsKey('followup_note')) {
      context.handle(
        _followupNoteMeta,
        followupNote.isAcceptableOrUnknown(
          data['followup_note']!,
          _followupNoteMeta,
        ),
      );
    }
    if (data.containsKey('followup_depth')) {
      context.handle(
        _followupDepthMeta,
        followupDepth.isAcceptableOrUnknown(
          data['followup_depth']!,
          _followupDepthMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      emotion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emotion'],
      )!,
      followupQuestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}followup_question'],
      )!,
      followupAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}followup_answer'],
      )!,
      followupEcho: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}followup_echo'],
      )!,
      followupNextFocus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}followup_next_focus'],
      )!,
      followupNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}followup_note'],
      )!,
      followupDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}followup_depth'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DailyEntriesTable createAlias(String alias) {
    return $DailyEntriesTable(attachedDatabase, alias);
  }
}

class DailyEntry extends DataClass implements Insertable<DailyEntry> {
  final int id;
  final String day;
  final String body;
  final String emotion;
  final String followupQuestion;
  final String followupAnswer;
  final String followupEcho;
  final String followupNextFocus;
  final String followupNote;
  final int followupDepth;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DailyEntry({
    required this.id,
    required this.day,
    required this.body,
    required this.emotion,
    required this.followupQuestion,
    required this.followupAnswer,
    required this.followupEcho,
    required this.followupNextFocus,
    required this.followupNote,
    required this.followupDepth,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day'] = Variable<String>(day);
    map['body'] = Variable<String>(body);
    map['emotion'] = Variable<String>(emotion);
    map['followup_question'] = Variable<String>(followupQuestion);
    map['followup_answer'] = Variable<String>(followupAnswer);
    map['followup_echo'] = Variable<String>(followupEcho);
    map['followup_next_focus'] = Variable<String>(followupNextFocus);
    map['followup_note'] = Variable<String>(followupNote);
    map['followup_depth'] = Variable<int>(followupDepth);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyEntriesCompanion toCompanion(bool nullToAbsent) {
    return DailyEntriesCompanion(
      id: Value(id),
      day: Value(day),
      body: Value(body),
      emotion: Value(emotion),
      followupQuestion: Value(followupQuestion),
      followupAnswer: Value(followupAnswer),
      followupEcho: Value(followupEcho),
      followupNextFocus: Value(followupNextFocus),
      followupNote: Value(followupNote),
      followupDepth: Value(followupDepth),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyEntry(
      id: serializer.fromJson<int>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      body: serializer.fromJson<String>(json['body']),
      emotion: serializer.fromJson<String>(json['emotion']),
      followupQuestion: serializer.fromJson<String>(json['followupQuestion']),
      followupAnswer: serializer.fromJson<String>(json['followupAnswer']),
      followupEcho: serializer.fromJson<String>(json['followupEcho']),
      followupNextFocus: serializer.fromJson<String>(json['followupNextFocus']),
      followupNote: serializer.fromJson<String>(json['followupNote']),
      followupDepth: serializer.fromJson<int>(json['followupDepth']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'day': serializer.toJson<String>(day),
      'body': serializer.toJson<String>(body),
      'emotion': serializer.toJson<String>(emotion),
      'followupQuestion': serializer.toJson<String>(followupQuestion),
      'followupAnswer': serializer.toJson<String>(followupAnswer),
      'followupEcho': serializer.toJson<String>(followupEcho),
      'followupNextFocus': serializer.toJson<String>(followupNextFocus),
      'followupNote': serializer.toJson<String>(followupNote),
      'followupDepth': serializer.toJson<int>(followupDepth),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyEntry copyWith({
    int? id,
    String? day,
    String? body,
    String? emotion,
    String? followupQuestion,
    String? followupAnswer,
    String? followupEcho,
    String? followupNextFocus,
    String? followupNote,
    int? followupDepth,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DailyEntry(
    id: id ?? this.id,
    day: day ?? this.day,
    body: body ?? this.body,
    emotion: emotion ?? this.emotion,
    followupQuestion: followupQuestion ?? this.followupQuestion,
    followupAnswer: followupAnswer ?? this.followupAnswer,
    followupEcho: followupEcho ?? this.followupEcho,
    followupNextFocus: followupNextFocus ?? this.followupNextFocus,
    followupNote: followupNote ?? this.followupNote,
    followupDepth: followupDepth ?? this.followupDepth,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DailyEntry copyWithCompanion(DailyEntriesCompanion data) {
    return DailyEntry(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      body: data.body.present ? data.body.value : this.body,
      emotion: data.emotion.present ? data.emotion.value : this.emotion,
      followupQuestion: data.followupQuestion.present
          ? data.followupQuestion.value
          : this.followupQuestion,
      followupAnswer: data.followupAnswer.present
          ? data.followupAnswer.value
          : this.followupAnswer,
      followupEcho: data.followupEcho.present
          ? data.followupEcho.value
          : this.followupEcho,
      followupNextFocus: data.followupNextFocus.present
          ? data.followupNextFocus.value
          : this.followupNextFocus,
      followupNote: data.followupNote.present
          ? data.followupNote.value
          : this.followupNote,
      followupDepth: data.followupDepth.present
          ? data.followupDepth.value
          : this.followupDepth,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyEntry(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('body: $body, ')
          ..write('emotion: $emotion, ')
          ..write('followupQuestion: $followupQuestion, ')
          ..write('followupAnswer: $followupAnswer, ')
          ..write('followupEcho: $followupEcho, ')
          ..write('followupNextFocus: $followupNextFocus, ')
          ..write('followupNote: $followupNote, ')
          ..write('followupDepth: $followupDepth, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    day,
    body,
    emotion,
    followupQuestion,
    followupAnswer,
    followupEcho,
    followupNextFocus,
    followupNote,
    followupDepth,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyEntry &&
          other.id == this.id &&
          other.day == this.day &&
          other.body == this.body &&
          other.emotion == this.emotion &&
          other.followupQuestion == this.followupQuestion &&
          other.followupAnswer == this.followupAnswer &&
          other.followupEcho == this.followupEcho &&
          other.followupNextFocus == this.followupNextFocus &&
          other.followupNote == this.followupNote &&
          other.followupDepth == this.followupDepth &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DailyEntriesCompanion extends UpdateCompanion<DailyEntry> {
  final Value<int> id;
  final Value<String> day;
  final Value<String> body;
  final Value<String> emotion;
  final Value<String> followupQuestion;
  final Value<String> followupAnswer;
  final Value<String> followupEcho;
  final Value<String> followupNextFocus;
  final Value<String> followupNote;
  final Value<int> followupDepth;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DailyEntriesCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.body = const Value.absent(),
    this.emotion = const Value.absent(),
    this.followupQuestion = const Value.absent(),
    this.followupAnswer = const Value.absent(),
    this.followupEcho = const Value.absent(),
    this.followupNextFocus = const Value.absent(),
    this.followupNote = const Value.absent(),
    this.followupDepth = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DailyEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String day,
    this.body = const Value.absent(),
    this.emotion = const Value.absent(),
    this.followupQuestion = const Value.absent(),
    this.followupAnswer = const Value.absent(),
    this.followupEcho = const Value.absent(),
    this.followupNextFocus = const Value.absent(),
    this.followupNote = const Value.absent(),
    this.followupDepth = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : day = Value(day),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DailyEntry> custom({
    Expression<int>? id,
    Expression<String>? day,
    Expression<String>? body,
    Expression<String>? emotion,
    Expression<String>? followupQuestion,
    Expression<String>? followupAnswer,
    Expression<String>? followupEcho,
    Expression<String>? followupNextFocus,
    Expression<String>? followupNote,
    Expression<int>? followupDepth,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (body != null) 'body': body,
      if (emotion != null) 'emotion': emotion,
      if (followupQuestion != null) 'followup_question': followupQuestion,
      if (followupAnswer != null) 'followup_answer': followupAnswer,
      if (followupEcho != null) 'followup_echo': followupEcho,
      if (followupNextFocus != null) 'followup_next_focus': followupNextFocus,
      if (followupNote != null) 'followup_note': followupNote,
      if (followupDepth != null) 'followup_depth': followupDepth,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DailyEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? day,
    Value<String>? body,
    Value<String>? emotion,
    Value<String>? followupQuestion,
    Value<String>? followupAnswer,
    Value<String>? followupEcho,
    Value<String>? followupNextFocus,
    Value<String>? followupNote,
    Value<int>? followupDepth,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DailyEntriesCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      body: body ?? this.body,
      emotion: emotion ?? this.emotion,
      followupQuestion: followupQuestion ?? this.followupQuestion,
      followupAnswer: followupAnswer ?? this.followupAnswer,
      followupEcho: followupEcho ?? this.followupEcho,
      followupNextFocus: followupNextFocus ?? this.followupNextFocus,
      followupNote: followupNote ?? this.followupNote,
      followupDepth: followupDepth ?? this.followupDepth,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (emotion.present) {
      map['emotion'] = Variable<String>(emotion.value);
    }
    if (followupQuestion.present) {
      map['followup_question'] = Variable<String>(followupQuestion.value);
    }
    if (followupAnswer.present) {
      map['followup_answer'] = Variable<String>(followupAnswer.value);
    }
    if (followupEcho.present) {
      map['followup_echo'] = Variable<String>(followupEcho.value);
    }
    if (followupNextFocus.present) {
      map['followup_next_focus'] = Variable<String>(followupNextFocus.value);
    }
    if (followupNote.present) {
      map['followup_note'] = Variable<String>(followupNote.value);
    }
    if (followupDepth.present) {
      map['followup_depth'] = Variable<int>(followupDepth.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyEntriesCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('body: $body, ')
          ..write('emotion: $emotion, ')
          ..write('followupQuestion: $followupQuestion, ')
          ..write('followupAnswer: $followupAnswer, ')
          ..write('followupEcho: $followupEcho, ')
          ..write('followupNextFocus: $followupNextFocus, ')
          ..write('followupNote: $followupNote, ')
          ..write('followupDepth: $followupDepth, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WeeklyEntriesTable extends WeeklyEntries
    with TableInfo<$WeeklyEntriesTable, WeeklyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _weekStartMeta = const VerificationMeta(
    'weekStart',
  );
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
    'week_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _candidateTopicsJsonMeta =
      const VerificationMeta('candidateTopicsJson');
  @override
  late final GeneratedColumn<String> candidateTopicsJson =
      GeneratedColumn<String>(
        'candidate_topics_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _selectedTopicMeta = const VerificationMeta(
    'selectedTopic',
  );
  @override
  late final GeneratedColumn<String> selectedTopic = GeneratedColumn<String>(
    'selected_topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _followupEmotionMeta = const VerificationMeta(
    'followupEmotion',
  );
  @override
  late final GeneratedColumn<String> followupEmotion = GeneratedColumn<String>(
    'followup_emotion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _followupQuestionMeta = const VerificationMeta(
    'followupQuestion',
  );
  @override
  late final GeneratedColumn<String> followupQuestion = GeneratedColumn<String>(
    'followup_question',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _followupAnswerMeta = const VerificationMeta(
    'followupAnswer',
  );
  @override
  late final GeneratedColumn<String> followupAnswer = GeneratedColumn<String>(
    'followup_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _echoMeta = const VerificationMeta('echo');
  @override
  late final GeneratedColumn<String> echo = GeneratedColumn<String>(
    'echo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nextFocusMeta = const VerificationMeta(
    'nextFocus',
  );
  @override
  late final GeneratedColumn<String> nextFocus = GeneratedColumn<String>(
    'next_focus',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
    id,
    weekStart,
    status,
    candidateTopicsJson,
    selectedTopic,
    followupEmotion,
    followupQuestion,
    followupAnswer,
    echo,
    nextFocus,
    note,
    closedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeeklyEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('week_start')) {
      context.handle(
        _weekStartMeta,
        weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta),
      );
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('candidate_topics_json')) {
      context.handle(
        _candidateTopicsJsonMeta,
        candidateTopicsJson.isAcceptableOrUnknown(
          data['candidate_topics_json']!,
          _candidateTopicsJsonMeta,
        ),
      );
    }
    if (data.containsKey('selected_topic')) {
      context.handle(
        _selectedTopicMeta,
        selectedTopic.isAcceptableOrUnknown(
          data['selected_topic']!,
          _selectedTopicMeta,
        ),
      );
    }
    if (data.containsKey('followup_emotion')) {
      context.handle(
        _followupEmotionMeta,
        followupEmotion.isAcceptableOrUnknown(
          data['followup_emotion']!,
          _followupEmotionMeta,
        ),
      );
    }
    if (data.containsKey('followup_question')) {
      context.handle(
        _followupQuestionMeta,
        followupQuestion.isAcceptableOrUnknown(
          data['followup_question']!,
          _followupQuestionMeta,
        ),
      );
    }
    if (data.containsKey('followup_answer')) {
      context.handle(
        _followupAnswerMeta,
        followupAnswer.isAcceptableOrUnknown(
          data['followup_answer']!,
          _followupAnswerMeta,
        ),
      );
    }
    if (data.containsKey('echo')) {
      context.handle(
        _echoMeta,
        echo.isAcceptableOrUnknown(data['echo']!, _echoMeta),
      );
    }
    if (data.containsKey('next_focus')) {
      context.handle(
        _nextFocusMeta,
        nextFocus.isAcceptableOrUnknown(data['next_focus']!, _nextFocusMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeeklyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      weekStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}week_start'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      candidateTopicsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}candidate_topics_json'],
      )!,
      selectedTopic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_topic'],
      )!,
      followupEmotion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}followup_emotion'],
      )!,
      followupQuestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}followup_question'],
      )!,
      followupAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}followup_answer'],
      )!,
      echo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}echo'],
      )!,
      nextFocus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_focus'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WeeklyEntriesTable createAlias(String alias) {
    return $WeeklyEntriesTable(attachedDatabase, alias);
  }
}

class WeeklyEntry extends DataClass implements Insertable<WeeklyEntry> {
  final int id;
  final String weekStart;
  final String status;
  final String candidateTopicsJson;
  final String selectedTopic;
  final String followupEmotion;
  final String followupQuestion;
  final String followupAnswer;
  final String echo;
  final String nextFocus;
  final String note;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WeeklyEntry({
    required this.id,
    required this.weekStart,
    required this.status,
    required this.candidateTopicsJson,
    required this.selectedTopic,
    required this.followupEmotion,
    required this.followupQuestion,
    required this.followupAnswer,
    required this.echo,
    required this.nextFocus,
    required this.note,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['week_start'] = Variable<String>(weekStart);
    map['status'] = Variable<String>(status);
    map['candidate_topics_json'] = Variable<String>(candidateTopicsJson);
    map['selected_topic'] = Variable<String>(selectedTopic);
    map['followup_emotion'] = Variable<String>(followupEmotion);
    map['followup_question'] = Variable<String>(followupQuestion);
    map['followup_answer'] = Variable<String>(followupAnswer);
    map['echo'] = Variable<String>(echo);
    map['next_focus'] = Variable<String>(nextFocus);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WeeklyEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeeklyEntriesCompanion(
      id: Value(id),
      weekStart: Value(weekStart),
      status: Value(status),
      candidateTopicsJson: Value(candidateTopicsJson),
      selectedTopic: Value(selectedTopic),
      followupEmotion: Value(followupEmotion),
      followupQuestion: Value(followupQuestion),
      followupAnswer: Value(followupAnswer),
      echo: Value(echo),
      nextFocus: Value(nextFocus),
      note: Value(note),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WeeklyEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyEntry(
      id: serializer.fromJson<int>(json['id']),
      weekStart: serializer.fromJson<String>(json['weekStart']),
      status: serializer.fromJson<String>(json['status']),
      candidateTopicsJson: serializer.fromJson<String>(
        json['candidateTopicsJson'],
      ),
      selectedTopic: serializer.fromJson<String>(json['selectedTopic']),
      followupEmotion: serializer.fromJson<String>(json['followupEmotion']),
      followupQuestion: serializer.fromJson<String>(json['followupQuestion']),
      followupAnswer: serializer.fromJson<String>(json['followupAnswer']),
      echo: serializer.fromJson<String>(json['echo']),
      nextFocus: serializer.fromJson<String>(json['nextFocus']),
      note: serializer.fromJson<String>(json['note']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weekStart': serializer.toJson<String>(weekStart),
      'status': serializer.toJson<String>(status),
      'candidateTopicsJson': serializer.toJson<String>(candidateTopicsJson),
      'selectedTopic': serializer.toJson<String>(selectedTopic),
      'followupEmotion': serializer.toJson<String>(followupEmotion),
      'followupQuestion': serializer.toJson<String>(followupQuestion),
      'followupAnswer': serializer.toJson<String>(followupAnswer),
      'echo': serializer.toJson<String>(echo),
      'nextFocus': serializer.toJson<String>(nextFocus),
      'note': serializer.toJson<String>(note),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WeeklyEntry copyWith({
    int? id,
    String? weekStart,
    String? status,
    String? candidateTopicsJson,
    String? selectedTopic,
    String? followupEmotion,
    String? followupQuestion,
    String? followupAnswer,
    String? echo,
    String? nextFocus,
    String? note,
    Value<DateTime?> closedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WeeklyEntry(
    id: id ?? this.id,
    weekStart: weekStart ?? this.weekStart,
    status: status ?? this.status,
    candidateTopicsJson: candidateTopicsJson ?? this.candidateTopicsJson,
    selectedTopic: selectedTopic ?? this.selectedTopic,
    followupEmotion: followupEmotion ?? this.followupEmotion,
    followupQuestion: followupQuestion ?? this.followupQuestion,
    followupAnswer: followupAnswer ?? this.followupAnswer,
    echo: echo ?? this.echo,
    nextFocus: nextFocus ?? this.nextFocus,
    note: note ?? this.note,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WeeklyEntry copyWithCompanion(WeeklyEntriesCompanion data) {
    return WeeklyEntry(
      id: data.id.present ? data.id.value : this.id,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      status: data.status.present ? data.status.value : this.status,
      candidateTopicsJson: data.candidateTopicsJson.present
          ? data.candidateTopicsJson.value
          : this.candidateTopicsJson,
      selectedTopic: data.selectedTopic.present
          ? data.selectedTopic.value
          : this.selectedTopic,
      followupEmotion: data.followupEmotion.present
          ? data.followupEmotion.value
          : this.followupEmotion,
      followupQuestion: data.followupQuestion.present
          ? data.followupQuestion.value
          : this.followupQuestion,
      followupAnswer: data.followupAnswer.present
          ? data.followupAnswer.value
          : this.followupAnswer,
      echo: data.echo.present ? data.echo.value : this.echo,
      nextFocus: data.nextFocus.present ? data.nextFocus.value : this.nextFocus,
      note: data.note.present ? data.note.value : this.note,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyEntry(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('status: $status, ')
          ..write('candidateTopicsJson: $candidateTopicsJson, ')
          ..write('selectedTopic: $selectedTopic, ')
          ..write('followupEmotion: $followupEmotion, ')
          ..write('followupQuestion: $followupQuestion, ')
          ..write('followupAnswer: $followupAnswer, ')
          ..write('echo: $echo, ')
          ..write('nextFocus: $nextFocus, ')
          ..write('note: $note, ')
          ..write('closedAt: $closedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    weekStart,
    status,
    candidateTopicsJson,
    selectedTopic,
    followupEmotion,
    followupQuestion,
    followupAnswer,
    echo,
    nextFocus,
    note,
    closedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyEntry &&
          other.id == this.id &&
          other.weekStart == this.weekStart &&
          other.status == this.status &&
          other.candidateTopicsJson == this.candidateTopicsJson &&
          other.selectedTopic == this.selectedTopic &&
          other.followupEmotion == this.followupEmotion &&
          other.followupQuestion == this.followupQuestion &&
          other.followupAnswer == this.followupAnswer &&
          other.echo == this.echo &&
          other.nextFocus == this.nextFocus &&
          other.note == this.note &&
          other.closedAt == this.closedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WeeklyEntriesCompanion extends UpdateCompanion<WeeklyEntry> {
  final Value<int> id;
  final Value<String> weekStart;
  final Value<String> status;
  final Value<String> candidateTopicsJson;
  final Value<String> selectedTopic;
  final Value<String> followupEmotion;
  final Value<String> followupQuestion;
  final Value<String> followupAnswer;
  final Value<String> echo;
  final Value<String> nextFocus;
  final Value<String> note;
  final Value<DateTime?> closedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const WeeklyEntriesCompanion({
    this.id = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.status = const Value.absent(),
    this.candidateTopicsJson = const Value.absent(),
    this.selectedTopic = const Value.absent(),
    this.followupEmotion = const Value.absent(),
    this.followupQuestion = const Value.absent(),
    this.followupAnswer = const Value.absent(),
    this.echo = const Value.absent(),
    this.nextFocus = const Value.absent(),
    this.note = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WeeklyEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String weekStart,
    this.status = const Value.absent(),
    this.candidateTopicsJson = const Value.absent(),
    this.selectedTopic = const Value.absent(),
    this.followupEmotion = const Value.absent(),
    this.followupQuestion = const Value.absent(),
    this.followupAnswer = const Value.absent(),
    this.echo = const Value.absent(),
    this.nextFocus = const Value.absent(),
    this.note = const Value.absent(),
    this.closedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : weekStart = Value(weekStart),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WeeklyEntry> custom({
    Expression<int>? id,
    Expression<String>? weekStart,
    Expression<String>? status,
    Expression<String>? candidateTopicsJson,
    Expression<String>? selectedTopic,
    Expression<String>? followupEmotion,
    Expression<String>? followupQuestion,
    Expression<String>? followupAnswer,
    Expression<String>? echo,
    Expression<String>? nextFocus,
    Expression<String>? note,
    Expression<DateTime>? closedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weekStart != null) 'week_start': weekStart,
      if (status != null) 'status': status,
      if (candidateTopicsJson != null)
        'candidate_topics_json': candidateTopicsJson,
      if (selectedTopic != null) 'selected_topic': selectedTopic,
      if (followupEmotion != null) 'followup_emotion': followupEmotion,
      if (followupQuestion != null) 'followup_question': followupQuestion,
      if (followupAnswer != null) 'followup_answer': followupAnswer,
      if (echo != null) 'echo': echo,
      if (nextFocus != null) 'next_focus': nextFocus,
      if (note != null) 'note': note,
      if (closedAt != null) 'closed_at': closedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WeeklyEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? weekStart,
    Value<String>? status,
    Value<String>? candidateTopicsJson,
    Value<String>? selectedTopic,
    Value<String>? followupEmotion,
    Value<String>? followupQuestion,
    Value<String>? followupAnswer,
    Value<String>? echo,
    Value<String>? nextFocus,
    Value<String>? note,
    Value<DateTime?>? closedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return WeeklyEntriesCompanion(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      status: status ?? this.status,
      candidateTopicsJson: candidateTopicsJson ?? this.candidateTopicsJson,
      selectedTopic: selectedTopic ?? this.selectedTopic,
      followupEmotion: followupEmotion ?? this.followupEmotion,
      followupQuestion: followupQuestion ?? this.followupQuestion,
      followupAnswer: followupAnswer ?? this.followupAnswer,
      echo: echo ?? this.echo,
      nextFocus: nextFocus ?? this.nextFocus,
      note: note ?? this.note,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (candidateTopicsJson.present) {
      map['candidate_topics_json'] = Variable<String>(
        candidateTopicsJson.value,
      );
    }
    if (selectedTopic.present) {
      map['selected_topic'] = Variable<String>(selectedTopic.value);
    }
    if (followupEmotion.present) {
      map['followup_emotion'] = Variable<String>(followupEmotion.value);
    }
    if (followupQuestion.present) {
      map['followup_question'] = Variable<String>(followupQuestion.value);
    }
    if (followupAnswer.present) {
      map['followup_answer'] = Variable<String>(followupAnswer.value);
    }
    if (echo.present) {
      map['echo'] = Variable<String>(echo.value);
    }
    if (nextFocus.present) {
      map['next_focus'] = Variable<String>(nextFocus.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyEntriesCompanion(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('status: $status, ')
          ..write('candidateTopicsJson: $candidateTopicsJson, ')
          ..write('selectedTopic: $selectedTopic, ')
          ..write('followupEmotion: $followupEmotion, ')
          ..write('followupQuestion: $followupQuestion, ')
          ..write('followupAnswer: $followupAnswer, ')
          ..write('echo: $echo, ')
          ..write('nextFocus: $nextFocus, ')
          ..write('note: $note, ')
          ..write('closedAt: $closedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DailyEntriesTable dailyEntries = $DailyEntriesTable(this);
  late final $WeeklyEntriesTable weeklyEntries = $WeeklyEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dailyEntries,
    weeklyEntries,
  ];
}

typedef $$DailyEntriesTableCreateCompanionBuilder =
    DailyEntriesCompanion Function({
      Value<int> id,
      required String day,
      Value<String> body,
      Value<String> emotion,
      Value<String> followupQuestion,
      Value<String> followupAnswer,
      Value<String> followupEcho,
      Value<String> followupNextFocus,
      Value<String> followupNote,
      Value<int> followupDepth,
      Value<String> status,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$DailyEntriesTableUpdateCompanionBuilder =
    DailyEntriesCompanion Function({
      Value<int> id,
      Value<String> day,
      Value<String> body,
      Value<String> emotion,
      Value<String> followupQuestion,
      Value<String> followupAnswer,
      Value<String> followupEcho,
      Value<String> followupNextFocus,
      Value<String> followupNote,
      Value<int> followupDepth,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$DailyEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyEntriesTable> {
  $$DailyEntriesTableFilterComposer({
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

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emotion => $composableBuilder(
    column: $table.emotion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followupQuestion => $composableBuilder(
    column: $table.followupQuestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followupAnswer => $composableBuilder(
    column: $table.followupAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followupEcho => $composableBuilder(
    column: $table.followupEcho,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followupNextFocus => $composableBuilder(
    column: $table.followupNextFocus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followupNote => $composableBuilder(
    column: $table.followupNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get followupDepth => $composableBuilder(
    column: $table.followupDepth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyEntriesTable> {
  $$DailyEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emotion => $composableBuilder(
    column: $table.emotion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followupQuestion => $composableBuilder(
    column: $table.followupQuestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followupAnswer => $composableBuilder(
    column: $table.followupAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followupEcho => $composableBuilder(
    column: $table.followupEcho,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followupNextFocus => $composableBuilder(
    column: $table.followupNextFocus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followupNote => $composableBuilder(
    column: $table.followupNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get followupDepth => $composableBuilder(
    column: $table.followupDepth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyEntriesTable> {
  $$DailyEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get emotion =>
      $composableBuilder(column: $table.emotion, builder: (column) => column);

  GeneratedColumn<String> get followupQuestion => $composableBuilder(
    column: $table.followupQuestion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get followupAnswer => $composableBuilder(
    column: $table.followupAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get followupEcho => $composableBuilder(
    column: $table.followupEcho,
    builder: (column) => column,
  );

  GeneratedColumn<String> get followupNextFocus => $composableBuilder(
    column: $table.followupNextFocus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get followupNote => $composableBuilder(
    column: $table.followupNote,
    builder: (column) => column,
  );

  GeneratedColumn<int> get followupDepth => $composableBuilder(
    column: $table.followupDepth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DailyEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyEntriesTable,
          DailyEntry,
          $$DailyEntriesTableFilterComposer,
          $$DailyEntriesTableOrderingComposer,
          $$DailyEntriesTableAnnotationComposer,
          $$DailyEntriesTableCreateCompanionBuilder,
          $$DailyEntriesTableUpdateCompanionBuilder,
          (
            DailyEntry,
            BaseReferences<_$AppDatabase, $DailyEntriesTable, DailyEntry>,
          ),
          DailyEntry,
          PrefetchHooks Function()
        > {
  $$DailyEntriesTableTableManager(_$AppDatabase db, $DailyEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> emotion = const Value.absent(),
                Value<String> followupQuestion = const Value.absent(),
                Value<String> followupAnswer = const Value.absent(),
                Value<String> followupEcho = const Value.absent(),
                Value<String> followupNextFocus = const Value.absent(),
                Value<String> followupNote = const Value.absent(),
                Value<int> followupDepth = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DailyEntriesCompanion(
                id: id,
                day: day,
                body: body,
                emotion: emotion,
                followupQuestion: followupQuestion,
                followupAnswer: followupAnswer,
                followupEcho: followupEcho,
                followupNextFocus: followupNextFocus,
                followupNote: followupNote,
                followupDepth: followupDepth,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String day,
                Value<String> body = const Value.absent(),
                Value<String> emotion = const Value.absent(),
                Value<String> followupQuestion = const Value.absent(),
                Value<String> followupAnswer = const Value.absent(),
                Value<String> followupEcho = const Value.absent(),
                Value<String> followupNextFocus = const Value.absent(),
                Value<String> followupNote = const Value.absent(),
                Value<int> followupDepth = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => DailyEntriesCompanion.insert(
                id: id,
                day: day,
                body: body,
                emotion: emotion,
                followupQuestion: followupQuestion,
                followupAnswer: followupAnswer,
                followupEcho: followupEcho,
                followupNextFocus: followupNextFocus,
                followupNote: followupNote,
                followupDepth: followupDepth,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyEntriesTable,
      DailyEntry,
      $$DailyEntriesTableFilterComposer,
      $$DailyEntriesTableOrderingComposer,
      $$DailyEntriesTableAnnotationComposer,
      $$DailyEntriesTableCreateCompanionBuilder,
      $$DailyEntriesTableUpdateCompanionBuilder,
      (
        DailyEntry,
        BaseReferences<_$AppDatabase, $DailyEntriesTable, DailyEntry>,
      ),
      DailyEntry,
      PrefetchHooks Function()
    >;
typedef $$WeeklyEntriesTableCreateCompanionBuilder =
    WeeklyEntriesCompanion Function({
      Value<int> id,
      required String weekStart,
      Value<String> status,
      Value<String> candidateTopicsJson,
      Value<String> selectedTopic,
      Value<String> followupEmotion,
      Value<String> followupQuestion,
      Value<String> followupAnswer,
      Value<String> echo,
      Value<String> nextFocus,
      Value<String> note,
      Value<DateTime?> closedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$WeeklyEntriesTableUpdateCompanionBuilder =
    WeeklyEntriesCompanion Function({
      Value<int> id,
      Value<String> weekStart,
      Value<String> status,
      Value<String> candidateTopicsJson,
      Value<String> selectedTopic,
      Value<String> followupEmotion,
      Value<String> followupQuestion,
      Value<String> followupAnswer,
      Value<String> echo,
      Value<String> nextFocus,
      Value<String> note,
      Value<DateTime?> closedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$WeeklyEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WeeklyEntriesTable> {
  $$WeeklyEntriesTableFilterComposer({
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

  ColumnFilters<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get candidateTopicsJson => $composableBuilder(
    column: $table.candidateTopicsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedTopic => $composableBuilder(
    column: $table.selectedTopic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followupEmotion => $composableBuilder(
    column: $table.followupEmotion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followupQuestion => $composableBuilder(
    column: $table.followupQuestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followupAnswer => $composableBuilder(
    column: $table.followupAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get echo => $composableBuilder(
    column: $table.echo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextFocus => $composableBuilder(
    column: $table.nextFocus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeeklyEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeeklyEntriesTable> {
  $$WeeklyEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get candidateTopicsJson => $composableBuilder(
    column: $table.candidateTopicsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedTopic => $composableBuilder(
    column: $table.selectedTopic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followupEmotion => $composableBuilder(
    column: $table.followupEmotion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followupQuestion => $composableBuilder(
    column: $table.followupQuestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followupAnswer => $composableBuilder(
    column: $table.followupAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get echo => $composableBuilder(
    column: $table.echo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextFocus => $composableBuilder(
    column: $table.nextFocus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeeklyEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeeklyEntriesTable> {
  $$WeeklyEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get candidateTopicsJson => $composableBuilder(
    column: $table.candidateTopicsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedTopic => $composableBuilder(
    column: $table.selectedTopic,
    builder: (column) => column,
  );

  GeneratedColumn<String> get followupEmotion => $composableBuilder(
    column: $table.followupEmotion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get followupQuestion => $composableBuilder(
    column: $table.followupQuestion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get followupAnswer => $composableBuilder(
    column: $table.followupAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get echo =>
      $composableBuilder(column: $table.echo, builder: (column) => column);

  GeneratedColumn<String> get nextFocus =>
      $composableBuilder(column: $table.nextFocus, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WeeklyEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeeklyEntriesTable,
          WeeklyEntry,
          $$WeeklyEntriesTableFilterComposer,
          $$WeeklyEntriesTableOrderingComposer,
          $$WeeklyEntriesTableAnnotationComposer,
          $$WeeklyEntriesTableCreateCompanionBuilder,
          $$WeeklyEntriesTableUpdateCompanionBuilder,
          (
            WeeklyEntry,
            BaseReferences<_$AppDatabase, $WeeklyEntriesTable, WeeklyEntry>,
          ),
          WeeklyEntry,
          PrefetchHooks Function()
        > {
  $$WeeklyEntriesTableTableManager(_$AppDatabase db, $WeeklyEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklyEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeklyEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> weekStart = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> candidateTopicsJson = const Value.absent(),
                Value<String> selectedTopic = const Value.absent(),
                Value<String> followupEmotion = const Value.absent(),
                Value<String> followupQuestion = const Value.absent(),
                Value<String> followupAnswer = const Value.absent(),
                Value<String> echo = const Value.absent(),
                Value<String> nextFocus = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WeeklyEntriesCompanion(
                id: id,
                weekStart: weekStart,
                status: status,
                candidateTopicsJson: candidateTopicsJson,
                selectedTopic: selectedTopic,
                followupEmotion: followupEmotion,
                followupQuestion: followupQuestion,
                followupAnswer: followupAnswer,
                echo: echo,
                nextFocus: nextFocus,
                note: note,
                closedAt: closedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String weekStart,
                Value<String> status = const Value.absent(),
                Value<String> candidateTopicsJson = const Value.absent(),
                Value<String> selectedTopic = const Value.absent(),
                Value<String> followupEmotion = const Value.absent(),
                Value<String> followupQuestion = const Value.absent(),
                Value<String> followupAnswer = const Value.absent(),
                Value<String> echo = const Value.absent(),
                Value<String> nextFocus = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => WeeklyEntriesCompanion.insert(
                id: id,
                weekStart: weekStart,
                status: status,
                candidateTopicsJson: candidateTopicsJson,
                selectedTopic: selectedTopic,
                followupEmotion: followupEmotion,
                followupQuestion: followupQuestion,
                followupAnswer: followupAnswer,
                echo: echo,
                nextFocus: nextFocus,
                note: note,
                closedAt: closedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeeklyEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeeklyEntriesTable,
      WeeklyEntry,
      $$WeeklyEntriesTableFilterComposer,
      $$WeeklyEntriesTableOrderingComposer,
      $$WeeklyEntriesTableAnnotationComposer,
      $$WeeklyEntriesTableCreateCompanionBuilder,
      $$WeeklyEntriesTableUpdateCompanionBuilder,
      (
        WeeklyEntry,
        BaseReferences<_$AppDatabase, $WeeklyEntriesTable, WeeklyEntry>,
      ),
      WeeklyEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DailyEntriesTableTableManager get dailyEntries =>
      $$DailyEntriesTableTableManager(_db, _db.dailyEntries);
  $$WeeklyEntriesTableTableManager get weeklyEntries =>
      $$WeeklyEntriesTableTableManager(_db, _db.weeklyEntries);
}
