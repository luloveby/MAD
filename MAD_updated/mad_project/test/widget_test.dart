// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mad_project/main.dart';

void main() {
  testWidgets('Login scrolls above the keyboard without overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(const MyApp());
    final fields = find.byType(TextFormField);
    await tester.tap(fields.first);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(fields.last);
    await tester.tap(fields.last, warnIfMissed: true);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(fields.last).dy, lessThanOrEqualTo(340));
    final login = find.widgetWithText(ElevatedButton, 'Log in');
    await tester.ensureVisible(login);
    await tester.tap(login);
    await tester.pumpAndSettle();
    expect(find.text('Please enter a valid email address'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final signup = find.widgetWithText(OutlinedButton, 'Sign up');
    await tester.ensureVisible(signup);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(signup).dy, lessThanOrEqualTo(340));
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login validates before contacting Firebase', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Log in'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
    await tester.pump();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
