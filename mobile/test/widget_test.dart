import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yekee_mobile/main.dart';
import 'package:yekee_mobile/data/app_database.dart';

void main() {
  testWidgets('夜记 opens the local-first shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      MyApp(databaseOverride: database, prefsOverride: prefs),
    );
    await tester.pumpAndSettle();
    expect(find.text('今晚'), findsOneWidget);
    expect(find.text('本周'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('same-day edits overwrite and appear in history', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      MyApp(databaseOverride: database, prefsOverride: prefs),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '第一次记录');
    await tester.tap(find.text('留下这一点'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '第二次记录');
    await tester.tap(find.text('留下这一点'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('历史'));
    await tester.pumpAndSettle();
    expect(find.text('第二次记录'), findsOneWidget);
    expect(find.text('第一次记录'), findsNothing);
  });

  testWidgets('custom weekly topic is used for the weekly question', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      MyApp(databaseOverride: database, prefsOverride: prefs),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('本周'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '自己的主题').first,
      '我想看清是否继续这件事',
    );
    await tester.tap(find.text('问自己一句（本周）'));
    await tester.pumpAndSettle();

    const question = '关于“我想看清是否继续这件事”，你现在最想对自己诚实的一句话是什么？';
    final saved = await database.getWeek(dateKey(sunday(DateTime.now())));
    expect(saved?.followupQuestion, question);
    expect(find.text('先选一件，或写下这周最想看清的事。'), findsNothing);
  });
}
