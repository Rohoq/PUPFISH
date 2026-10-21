// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pupfish_mobile/main.dart';

void main() {
  testWidgets('login screen shows the Pupfish sign-in form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('pupfish'), findsOneWidget);
    expect(find.text('Miło Cię widzieć!'), findsOneWidget);
    expect(find.text('Zaloguj się'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
