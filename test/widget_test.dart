// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:x_physics/app.dart';
import 'package:x_physics/features/progress/application/app_state.dart';

void main() {
  testWidgets('X-Physics renders login screen', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter('build/test_hive');
    await Hive.openBox<Map>('offline_lessons');
    await Hive.openBox<Map>('pending_progress');

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState()..bootstrap(),
        child: const XPhysicsApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Đăng nhập X-Physics'), findsOneWidget);
  });
}
