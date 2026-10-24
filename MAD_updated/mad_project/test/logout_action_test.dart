import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_project/widgets/logout_action.dart';

Widget logoutApp(Future<void> Function() signOut) => MaterialApp(
  home: const Scaffold(body: Text('Login screen')),
  initialRoute: '/student',
  routes: {
    '/student': (_) => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => confirmLogout(context, signOut: signOut),
          child: const Text('Start logout'),
        ),
      ),
    ),
  },
);

void main() {
  testWidgets('Cancellation does not sign out', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      logoutApp(() async {
        calls++;
      }),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Start logout'), findsOneWidget);
  });

  testWidgets('Confirmed logout clears student routes', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      logoutApp(() async {
        calls++;
      }),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out').last);
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Login screen'), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('Failed logout keeps the page and shows an error', (
    tester,
  ) async {
    await tester.pumpWidget(
      logoutApp(() async {
        throw StateError('offline');
      }),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out').last);
    await tester.pumpAndSettle();
    expect(find.text('Start logout'), findsOneWidget);
    expect(find.text('Unable to log out. Please try again.'), findsOneWidget);
  });
}
