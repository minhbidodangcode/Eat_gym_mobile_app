// This is a basic Flutter widget test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymer_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: MainScreen()));
    await tester.pump();

    // Verify that our app header text is displayed.
    expect(find.text('Quét Nguyên Liệu'), findsOneWidget);
  });
}
