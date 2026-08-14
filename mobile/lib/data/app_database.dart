import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_database.g.dart';

class DailyEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get day => text().unique()();

  TextColumn get body => text().withDefault(const Constant(''))();

  TextColumn get emotion => text().withDefault(const Constant(''))();

  TextColumn get followupQuestion => text().withDefault(const Constant(''))();

  TextColumn get followupAnswer => text().withDefault(const Constant(''))();

  TextColumn get followupEcho => text().withDefault(const Constant(''))();

  TextColumn get followupNextFocus => text().withDefault(const Constant(''))();

  TextColumn get followupNote => text().withDefault(const Constant(''))();

  IntColumn get followupDepth => integer().withDefault(const Constant(0))();

  TextColumn get status => text().withDefault(const Constant('draft'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}

class WeeklyEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get weekStart => text().unique()();

  TextColumn get status => text().withDefault(const Constant('draft'))();

  TextColumn get candidateTopicsJson =>
      text().withDefault(const Constant('[]'))();

  TextColumn get selectedTopic => text().withDefault(const Constant(''))();

  TextColumn get followupEmotion => text().withDefault(const Constant(''))();

  TextColumn get followupQuestion => text().withDefault(const Constant(''))();

  TextColumn get followupAnswer => text().withDefault(const Constant(''))();

  TextColumn get echo => text().withDefault(const Constant(''))();

  TextColumn get nextFocus => text().withDefault(const Constant(''))();

  TextColumn get note => text().withDefault(const Constant(''))();

  DateTimeColumn get closedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}

class DailyRecord {
  const DailyRecord({
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

  bool get hasTrace => body.trim().isNotEmpty || emotion.trim().isNotEmpty;

  bool get hasFollowup => followupQuestion.trim().isNotEmpty;
}

class WeekRecord {
  const WeekRecord({
    required this.weekStart,
    required this.status,
    required this.candidateTopics,
    required this.selectedTopic,
    required this.followupEmotion,
    required this.followupQuestion,
    required this.followupAnswer,
    required this.echo,
    required this.nextFocus,
    required this.note,
    required this.closedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String weekStart;
  final String status;
  final List<String> candidateTopics;
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

  bool get isClosed => status == 'closed';

  bool get hasQuestion => followupQuestion.trim().isNotEmpty;
}

@DriftDatabase(tables: [DailyEntries, WeeklyEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) async => m.createAll());

  Future<DailyRecord?> getDaily(String day) async {
    final row = await (select(
      dailyEntries,
    )..where((entry) => entry.day.equals(day))).getSingleOrNull();
    return row == null ? null : _dailyFromRow(row);
  }

  Future<List<DailyRecord>> listDaily() async {
    final rows = await (select(
      dailyEntries,
    )..orderBy([(entry) => OrderingTerm.desc(entry.day)])).get();
    return rows.map(_dailyFromRow).toList();
  }

  Future<void> saveDaily({
    required String day,
    required String body,
    required String emotion,
    String followupQuestion = '',
    String followupAnswer = '',
    String followupEcho = '',
    String followupNextFocus = '',
    String followupNote = '',
    int followupDepth = 0,
    String status = 'draft',
  }) async {
    final existing = await (select(
      dailyEntries,
    )..where((entry) => entry.day.equals(day))).getSingleOrNull();
    final now = DateTime.now();
    final values = DailyEntriesCompanion.insert(
      day: day,
      body: Value(body),
      emotion: Value(emotion),
      followupQuestion: Value(followupQuestion),
      followupAnswer: Value(followupAnswer),
      followupEcho: Value(followupEcho),
      followupNextFocus: Value(followupNextFocus),
      followupNote: Value(followupNote),
      followupDepth: Value(followupDepth),
      status: Value(status),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await into(dailyEntries).insert(
      values,
      onConflict: DoUpdate(
        (_) => values,
        target: [dailyEntries.day],
      ),
    );
  }

  Future<WeekRecord?> getWeek(String weekStart) async {
    final row = await (select(
      weeklyEntries,
    )..where((entry) => entry.weekStart.equals(weekStart))).getSingleOrNull();
    return row == null ? null : _weekFromRow(row);
  }

  Future<List<WeekRecord>> listWeeks() async {
    final rows = await (select(
      weeklyEntries,
    )..orderBy([(entry) => OrderingTerm.desc(entry.weekStart)])).get();
    return rows.map(_weekFromRow).toList();
  }

  Future<void> saveWeek({
    required String weekStart,
    String status = 'draft',
    List<String> candidateTopics = const [],
    String selectedTopic = '',
    String followupEmotion = '',
    String followupQuestion = '',
    String followupAnswer = '',
    String echo = '',
    String nextFocus = '',
    String note = '',
    DateTime? closedAt,
  }) async {
    final existing = await (select(
      weeklyEntries,
    )..where((entry) => entry.weekStart.equals(weekStart))).getSingleOrNull();
    final now = DateTime.now();
    final values = WeeklyEntriesCompanion.insert(
      weekStart: weekStart,
      status: Value(status),
      candidateTopicsJson: Value(jsonEncode(candidateTopics)),
      selectedTopic: Value(selectedTopic),
      followupEmotion: Value(followupEmotion),
      followupQuestion: Value(followupQuestion),
      followupAnswer: Value(followupAnswer),
      echo: Value(echo),
      nextFocus: Value(nextFocus),
      note: Value(note),
      closedAt: Value(closedAt),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await into(weeklyEntries).insert(
      values,
      onConflict: DoUpdate(
        (_) => values,
        target: [weeklyEntries.weekStart],
      ),
    );
  }

  Future<void> migrateLegacyIfNeeded(SharedPreferences prefs) async {
    const migrationKey = 'nightji_drift_migration_v1';
    if (prefs.getBool(migrationKey) == true) return;

    final legacyNights = _readLegacyNights(prefs);
    final legacyWeeks = _readLegacyWeeks(prefs);
    await transaction(() async {
      for (final entry in legacyNights.entries) {
        final value = entry.value.trim();
        if (value.isEmpty) continue;
        await saveDaily(day: entry.key, body: value, emotion: '');
      }
      for (final entry in legacyWeeks.entries) {
        final value = entry.value;
        await saveWeek(
          weekStart: entry.key,
          status: value['closed'] == true ? 'closed' : 'draft',
          selectedTopic: value['topic'] as String? ?? '',
          followupQuestion: value['question'] as String? ?? '',
          followupAnswer: value['answer'] as String? ?? '',
          nextFocus: value['nextFocus'] as String? ?? '',
          closedAt: value['closed'] == true ? DateTime.now() : null,
        );
      }
    });
    await prefs.setBool(migrationKey, true);
  }

  DailyRecord _dailyFromRow(DailyEntry row) => DailyRecord(
    day: row.day,
    body: row.body,
    emotion: row.emotion,
    followupQuestion: row.followupQuestion,
    followupAnswer: row.followupAnswer,
    followupEcho: row.followupEcho,
    followupNextFocus: row.followupNextFocus,
    followupNote: row.followupNote,
    followupDepth: row.followupDepth,
    status: row.status,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  WeekRecord _weekFromRow(WeeklyEntry row) => WeekRecord(
    weekStart: row.weekStart,
    status: row.status,
    candidateTopics: _decodeTopics(row.candidateTopicsJson),
    selectedTopic: row.selectedTopic,
    followupEmotion: row.followupEmotion,
    followupQuestion: row.followupQuestion,
    followupAnswer: row.followupAnswer,
    echo: row.echo,
    nextFocus: row.nextFocus,
    note: row.note,
    closedAt: row.closedAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'nightji.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

List<String> _decodeTopics(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .take(3)
          .toList();
    }
  } catch (_) {}
  return const [];
}

Map<String, String> _readLegacyNights(SharedPreferences prefs) {
  try {
    final decoded = jsonDecode(prefs.getString('nights') ?? '{}');
    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
  } catch (_) {}
  return {};
}

Map<String, Map<String, dynamic>> _readLegacyWeeks(SharedPreferences prefs) {
  try {
    final decoded = jsonDecode(prefs.getString('weeks') ?? '{}');
    if (decoded is Map) {
      return decoded.map((key, value) {
        final map = value is Map
            ? Map<String, dynamic>.from(value)
            : <String, dynamic>{};
        return MapEntry(key.toString(), map);
      });
    }
  } catch (_) {}
  return {};
}
