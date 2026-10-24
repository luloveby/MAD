import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_project/models/borrow_request.dart';
import 'package:mad_project/models/request_notification.dart';
import 'package:mad_project/pages/approval_notification_page.dart';
import 'package:mad_project/pages/pickup_confirmation_page.dart';
import 'package:mad_project/widgets/notification_bell.dart';
import 'package:mad_project/widgets/request_scope.dart';

BorrowRequest approval({DateTime? readAt, String status = 'Approved'}) =>
    BorrowRequest(
      id: 'approved-request',
      uid: 'student',
      equipmentId: 'laptop',
      equipmentName: 'Laptop',
      status: status,
      purpose: 'Presentation',
      approvedAt: DateTime(2026, 10, 18, 10),
      borrowAt: DateTime(2026, 10, 19, 10),
      approvalReadAt: readAt,
    );

Widget app(Widget page, List<BorrowRequest> requests) => RequestScope(
  watch: () => Stream.value(requests),
  child: MaterialApp(home: page),
);

void main() {
  test('Notification borders follow saved read state rather than status', () {
    const request = BorrowRequest(
      id: 'r1',
      uid: 'u1',
      equipmentId: 'e1',
      equipmentName: 'Laptop',
      status: 'Borrowed',
      purpose: '',
      readNotificationKeys: ['Pickup confirmed'],
    );
    final updates = RequestNotification.fromRequests([
      request,
    ], DateTime(2026, 10, 19));
    expect(
      updates.singleWhere((n) => n.title == 'Pickup confirmed').isRead,
      isTrue,
    );
    final unread = RequestNotification.fromRequests([
      approval(),
    ], DateTime(2026, 10, 19));
    expect(
      unread.singleWhere((n) => n.title == 'Request Approved').isRead,
      isFalse,
    );
  });
  test('Approval read state comes from Firestore and routes to the approval notice', () {
    final request = BorrowRequest.fromFirestore('approved-request', {
      'uid': 'student',
      'equipmentId': 'laptop',
      'status': 'Approved',
      'approvedAt': Timestamp.fromDate(DateTime(2026, 10, 18)),
      'approvalReadAt': Timestamp.fromDate(DateTime(2026, 10, 18, 11)),
    });
    expect(request.hasUnreadApproval, isFalse);
    expect(approval().hasUnreadApproval, isTrue);
    expect(approval(status: 'Borrowed').hasUnreadApproval, isFalse);
    final notification = RequestNotification.fromRequests(
      [approval()],
      DateTime(2026, 10, 18),
    ).singleWhere((n) => n.title == 'Request Approved');
    expect(notification.destination, RequestNotificationDestination.approval);
  });

  testWidgets('Bell dot follows unread approvals in the live stream', (
    tester,
  ) async {
    final source = StreamController<List<BorrowRequest>>();
    addTearDown(source.close);
    await tester.pumpWidget(
      RequestScope(
        watch: () => source.stream,
        child: const MaterialApp(home: Scaffold(body: NotificationBell())),
      ),
    );
    source.add([]);
    await tester.pumpAndSettle();
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    source.add([approval()]);
    await tester.pumpAndSettle();
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);
    source.add([approval(readAt: DateTime(2026, 10, 18, 11))]);
    await tester.pumpAndSettle();
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
  });

  testWidgets('White dot stays until every notification is read', (
    tester,
  ) async {
    final source = StreamController<List<BorrowRequest>>();
    addTearDown(source.close);
    await tester.pumpWidget(
      RequestScope(
        watch: () => source.stream,
        child: const MaterialApp(home: Scaffold(body: NotificationBell())),
      ),
    );
    BorrowRequest borrowed(List<String> readKeys) => BorrowRequest(
      id: 'r2',
      uid: 'student',
      equipmentId: 'laptop',
      equipmentName: 'Laptop',
      status: 'Borrowed',
      purpose: '',
      returnAt: DateTime.now().add(const Duration(days: 3)),
      readNotificationKeys: readKeys,
    );
    source.add([
      approval(readAt: DateTime(2026, 10, 18)),
      borrowed(['Pickup confirmed']),
    ]);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Badge>(find.byType(Badge)).backgroundColor,
      Colors.white,
    );
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);
    source.add([
      approval(readAt: DateTime(2026, 10, 18)),
      borrowed(['Pickup confirmed', 'Return schedule']),
    ]);
    await tester.pumpAndSettle();
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
  });

  testWidgets('Unread bell opens the PDF approval notification', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const Scaffold(body: NotificationBell()), [approval()]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifications: unread approval'));
    await tester.pumpAndSettle();
    expect(find.byType(ApprovalNotificationPage), findsOneWidget);
    expect(
      find.text('Your request for Laptop has been approved!'),
      findsOneWidget,
    );
    expect(find.text('Confirm pickup'), findsOneWidget);
  });

  testWidgets('Opening approval marks it read and allows pickup confirmation', (
    tester,
  ) async {
    String? readId;
    await tester.pumpWidget(
      app(
        ApprovalNotificationPage(
          requestId: 'approved-request',
          markRead: (id) async {
            readId = id;
          },
        ),
        [approval()],
      ),
    );
    await tester.pumpAndSettle();
    expect(readId, 'approved-request');
    await tester.tap(find.text('Confirm pickup'));
    await tester.pumpAndSettle();
    expect(find.byType(PickupConfirmationPage), findsOneWidget);
    expect(find.text('Yes, I received it'), findsOneWidget);
  });

  testWidgets('Failed read update can retry without hiding the approval', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      app(
        ApprovalNotificationPage(
          requestId: 'approved-request',
          markRead: (_) async {
            if (++attempts == 1) throw StateError('offline');
          },
        ),
        [approval()],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unable to mark as read. Tap to retry.'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Unable to mark as read. Tap to retry.'), findsNothing);
    expect(
      find.text('Your request for Laptop has been approved!'),
      findsOneWidget,
    );
  });
}
