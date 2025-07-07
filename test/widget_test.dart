// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:disasterlink/app/app_module.dart';
import 'package:disasterlink/app/app_widget.dart';

void main() {
  testWidgets('Basic app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ModularApp(module: AppModule(), child: const AppWidget()),
    );

    // Verify that the app starts correctly by looking for a common UI element
    // Instead of looking for counters, look for elements that should exist in the app
    await tester.pump();

    // This is a basic test to ensure the app doesn't crash on startup
    expect(find.byType(AppWidget), findsOneWidget);
  });
}
