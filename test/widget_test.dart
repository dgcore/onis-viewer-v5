// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:onis_viewer/main.dart';

void main() {
  testWidgets('ONIS Viewer smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OnisViewerApp());

    // Verify that our app title is displayed.
    expect(find.text('ONIS Viewer - Test FFI'), findsOneWidget);

    // Verify that the app doesn't crash
    await tester.pumpAndSettle();
  });
}
