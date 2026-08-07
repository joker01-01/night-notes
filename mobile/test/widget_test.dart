import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yekee_mobile/main.dart';

void main() {
  testWidgets('夜记 opens the local-first shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('今晚'), findsOneWidget);
    expect(find.text('本周'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });
}
