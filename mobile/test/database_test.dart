import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yekee_mobile/data/app_database.dart';

void main() {
  test('stores a complete daily and weekly result locally', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.saveDaily(
      day: '2026-08-12',
      body: '今天反复想到要不要继续。',
      emotion: '犹豫',
      followupQuestion: '我真正想保留的是什么？',
      followupAnswer: '我想保留做事时的自由。',
      followupEcho: '你在意的不只是继续或停止，而是自由。',
      followupNextFocus: '留意哪些安排让你感到更自由。',
      followupNote: '先放在这里。',
      followupDepth: 1,
      status: 'closed',
    );
    await database.saveWeek(
      weekStart: '2026-08-09',
      status: 'closed',
      candidateTopics: ['继续还是停止？', '自由感从哪里来？'],
      selectedTopic: '自由感从哪里来？',
      followupEmotion: '说不清',
      followupQuestion: '这周最想对自己诚实的一句话是什么？',
      followupAnswer: '我想少一点证明。',
      echo: '你想少一点证明，多一点真实。',
      nextFocus: '留意不证明的时候发生什么。',
      note: '没有截止时间。',
      closedAt: DateTime(2026, 8, 12),
    );

    final daily = await database.getDaily('2026-08-12');
    final week = await database.getWeek('2026-08-09');
    expect(daily?.emotion, '犹豫');
    expect(daily?.followupAnswer, '我想保留做事时的自由。');
    expect(week?.candidateTopics, ['继续还是停止？', '自由感从哪里来？']);
    expect(week?.echo, '你想少一点证明，多一点真实。');
  });

  test('replaces the same day and keeps it in history', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.saveDaily(
      day: '2026-08-12',
      body: '第一次记录',
      emotion: '犹豫',
    );
    await database.saveDaily(
      day: '2026-08-12',
      body: '第二次记录',
      emotion: '期待',
    );

    final saved = await database.getDaily('2026-08-12');
    final history = await database.listDaily();
    expect(saved?.body, '第二次记录');
    expect(saved?.emotion, '期待');
    expect(history, hasLength(1));
    expect(history.single.body, '第二次记录');
  });

  test('replaces the same week and keeps the latest result in history', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.saveWeek(
      weekStart: '2026-08-09',
      selectedTopic: '第一次主题',
      followupQuestion: '第一次问题？',
    );
    await database.saveWeek(
      weekStart: '2026-08-09',
      selectedTopic: '第二次主题',
      followupQuestion: '第二次问题？',
    );

    final saved = await database.getWeek('2026-08-09');
    final history = await database.listWeeks();
    expect(saved?.selectedTopic, '第二次主题');
    expect(saved?.followupQuestion, '第二次问题？');
    expect(history, hasLength(1));
    expect(history.single.selectedTopic, '第二次主题');
  });

  test('serializes concurrent writes for one day and one week', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await Future.wait([
      database.saveDaily(day: '2026-08-12', body: '并发 A', emotion: ''),
      database.saveDaily(day: '2026-08-12', body: '并发 B', emotion: ''),
    ]);
    await Future.wait([
      database.saveWeek(weekStart: '2026-08-09', selectedTopic: '并发周 A'),
      database.saveWeek(weekStart: '2026-08-09', selectedTopic: '并发周 B'),
    ]);

    expect((await database.listDaily()), hasLength(1));
    expect((await database.listWeeks()), hasLength(1));
  });

  test('migrates legacy data only once when old data exists', () async {
    SharedPreferences.setMockInitialValues({
      'nights': jsonEncode({'2026-08-11': '旧版的一条记录'}),
      'weeks': jsonEncode({
        '2026-08-09': {
          'topic': '旧版主题',
          'question': '旧版问题？',
          'answer': '旧版回答。',
          'closed': true,
        },
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.migrateLegacyIfNeeded(prefs);
    await database.migrateLegacyIfNeeded(prefs);

    expect((await database.listDaily()).length, 1);
    expect((await database.listWeeks()).length, 1);
    expect((await database.getDaily('2026-08-11'))?.body, '旧版的一条记录');
    expect((await database.getWeek('2026-08-09'))?.isClosed, isTrue);
    expect(prefs.getBool('nightji_drift_migration_v1'), isTrue);
  });
}
