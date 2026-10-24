import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_project/models/borrow_request.dart';
import 'package:mad_project/pages/user_requests_page.dart';
import 'package:mad_project/pages/pickup_confirmation_page.dart';
import 'package:mad_project/widgets/request_scope.dart';
import 'package:mad_project/widgets/app_scaffold.dart';

const approved = BorrowRequest(
  id: 'r1',
  uid: 'u1',
  equipmentId: 'e1',
  equipmentName: 'Laptop',
  status: 'Approved',
  purpose: 'Coursework',
);
const returned = BorrowRequest(
  id: 'r2',
  uid: 'u1',
  equipmentId: 'e2',
  equipmentName: 'Mouse',
  status: 'Returned',
  purpose: 'Coursework',
);

Widget app(Widget page) => RequestScope(
  watch: () => Stream.value([approved, returned]),
  child: MaterialApp(home: page),
);

void main() {
  testWidgets('Home navigation and drawer open My Requests', (tester) async {
    await tester.pumpWidget(app(const AppScaffold(
      navigationIndex: 0,
      body: Text('Home content'),
    )));
    await tester.tap(find.text('My Requests'));
    await tester.pumpAndSettle();
    expect(find.byType(UserRequestsPage), findsOneWidget);
    expect(find.text('Laptop'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.byType(UserRequestsPage), findsOneWidget);
  });

  testWidgets('Filters requests and opens live request details', (
    tester,
  ) async {
    await tester.pumpWidget(app(const UserRequestsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Laptop'), findsOneWidget);
    expect(find.text('Mouse'), findsNothing);
    await tester.tap(find.text('Returned'));
    await tester.pumpAndSettle();
    expect(find.text('Mouse'), findsOneWidget);
    expect(find.text('Laptop'), findsNothing);
    await tester.tap(find.text('Mouse'));
    await tester.pumpAndSettle();
    expect(find.text('Mouse • Request r2'), findsOneWidget);
    expect(find.text('Status: Returned'), findsOneWidget);
  });

  testWidgets('Only acknowledges pickup after successful persistence', (
    tester,
  ) async {
    String? saved;
    await tester.pumpWidget(
      app(
        PickupConfirmationPage(
          requestId: 'r1',
          confirmPickup: (id) async {
            saved = id;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, I received it'));
    await tester.pumpAndSettle();
    expect(saved, 'r1');
    expect(find.text('Thank you for confirming!'), findsOneWidget);
  });

  testWidgets('Failed pickup shows error without success dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        PickupConfirmationPage(
          requestId: 'r1',
          confirmPickup: (_) async {
            throw StateError('offline');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, I received it'));
    await tester.pump();
    expect(find.text('Thank you for confirming!'), findsNothing);
    expect(
      find.text('Unable to confirm pickup. Please try again.'),
      findsOneWidget,
    );
  });
}
