import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_project/models/borrow_request.dart';
import 'package:mad_project/models/request_notification.dart';
import 'package:mad_project/pages/archive_page.dart';
import 'package:mad_project/pages/borrowing_history_page.dart';
import 'package:mad_project/pages/notifications_page.dart';
import 'package:mad_project/pages/pickup_confirmation_page.dart';
import 'package:mad_project/pages/return_reminder_page.dart';
import 'package:mad_project/pages/request_details_page.dart';
import 'package:mad_project/pages/approval_notification_page.dart';
import 'package:mad_project/widgets/request_scope.dart';

BorrowRequest record(String status, {bool archived = false, DateTime? due}) =>
    BorrowRequest(
      id: 'r1',
      uid: 'student',
      equipmentId: 'e1',
      equipmentName: 'Laptop',
      status: status,
      purpose: 'Class presentation',
      archived: archived,
      borrowAt: DateTime(2026, 10, 17, 10),
      returnAt: due,
      returnedAt: status == 'Returned' ? DateTime(2026, 10, 18, 15) : null,
    );

Widget app(Widget page, List<BorrowRequest> requests) => RequestScope(
  watch: () => Stream.value(requests),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Poppins'),
    home: page,
  ),
);

void main() {
  setUpAll(() async {
    final text = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-Bold.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([text.load(), icons.load()]);
  });
  test('Firestore event timestamps remain optional for existing requests', () {
    final request = BorrowRequest.fromFirestore('r1', {
      'uid': 'student',
      'equipmentId': 'e1',
      'equipmentName': 'Laptop',
      'status': 'Borrowed',
      'pickedUpAt': Timestamp.fromDate(DateTime(2026, 10, 17)),
    });
    expect(request.pickedUpAt, DateTime(2026, 10, 17));
    expect(request.approvedAt, isNull);
    expect(request.archived, isFalse);
  });

  test('Reminders respect actual status, deadline and archive state', () {
    final now = DateTime(2026, 10, 18, 12);
    List<RequestNotification> updates(BorrowRequest r) =>
        RequestNotification.fromRequests([r], now);
    expect(
      updates(record('Borrowed', due: now.add(const Duration(days: 2))))
          .any((n) => n.title == 'Return reminder'),
      isFalse,
    );
    expect(
      updates(record('Borrowed', due: now.add(const Duration(hours: 2))))
          .any((n) => n.title == 'Return reminder'),
      isTrue,
    );
    expect(
      updates(record('Borrowed', due: now.subtract(const Duration(hours: 2))))
          .any((n) => n.title == 'Return overdue'),
      isTrue,
    );
    expect(
      updates(record('Returned', due: now.subtract(const Duration(days: 1))))
          .map((n) => n.title),
      ['Equipment returned'],
    );
    expect(updates(record('Returned', archived: true)), isEmpty);
    expect(updates(record('Approved')).every((n) => n.date == null), isTrue);
  });

  testWidgets(
    'Notification taps open pickup and react to Firestore stream updates',
    (tester) async {
      await tester.pumpWidget(
        app(const NotificationsPage(), [record('Approved')]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Request Approved'), findsOneWidget);
      expect(find.text('Pickup confirmation'), findsNothing);
      await tester.tap(find.text('Request Approved'));
      await tester.pumpAndSettle();
      expect(find.byType(PickupConfirmationPage), findsNothing);
      await tester.tap(find.text('Confirm pickup'));
      await tester.pumpAndSettle();
      expect(find.byType(PickupConfirmationPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final source = StreamController<List<BorrowRequest>>();
      addTearDown(source.close);
      await tester.pumpWidget(
        RequestScope(
          watch: () => source.stream,
          child: const MaterialApp(home: NotificationsPage()),
        ),
      );
      source.add([record('Approved')]);
      await tester.pumpAndSettle();
      source.add([record('Returned')]);
      await tester.pumpAndSettle();
      expect(find.text('Equipment returned'), findsOneWidget);
      expect(find.text('Pickup confirmation'), findsNothing);
    },
  );

  testWidgets('History excludes archived and active transactions', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const BorrowingHistoryPage(), [
        record('Borrowed'),
        record('Returned', archived: true),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('No completed transactions.'), findsOneWidget);
    await tester.tap(find.byTooltip('Archive'));
    await tester.pumpAndSettle();
    expect(find.byType(ArchivePage), findsOneWidget);
    expect(find.text('Archived'), findsOneWidget);
  });

  testWidgets('Archive saves only selected returned request IDs', (
    tester,
  ) async {
    Set<String>? saved;
    await tester.pumpWidget(
      app(
        ArchivePage(
          archiveRequests: (ids) async {
            saved = ids;
          },
        ),
        [record('Returned')],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.byTooltip('Archive selected'));
    await tester.pumpAndSettle();
    expect(saved, {'r1'});
    expect(find.text('Requests archived.'), findsOneWidget);
  });

  testWidgets('Archive failures retain selection for retry', (tester) async {
    await tester.pumpWidget(
      app(
        ArchivePage(
          archiveRequests: (_) async {
            throw StateError('offline');
          },
        ),
        [record('Returned')],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.byTooltip('Archive selected'));
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to archive requests. Please try again.'),
      findsOneWidget,
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('Reminder does not claim a returned request is overdue', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const ReturnReminderPage(requestId: 'r1'), [
        record('Returned', due: DateTime(2020)),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Current status: Returned'), findsOneWidget);
    expect(find.text('Return deadline passed'), findsNothing);
  });

  testWidgets('Narrow history and notifications remain readable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(const BorrowingHistoryPage(), [record('Returned')]),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/history-preview.png'),
    );
    await tester.pumpWidget(
      app(const NotificationsPage(), [record('Approved')]),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/notifications-preview.png'),
    );
    await tester.pumpWidget(app(const ArchivePage(), [record('Returned')]));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/archive-preview.png'),
    );
    await tester.pumpWidget(
      app(const RequestDetailsPage(requestId: 'r1'), [
        record('Borrowed', due: DateTime(2026, 10, 20, 15)),
      ]),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/details-preview.png'),
    );
    await tester.pumpWidget(
      app(const ReturnReminderPage(requestId: 'r1'), [
        record('Borrowed', due: DateTime(2020, 10, 20, 15)),
      ]),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/reminder-preview.png'),
    );
    await tester.pumpWidget(
      app(ApprovalNotificationPage(requestId: 'r1', markRead: (_) async {}), [
        record('Approved'),
      ]),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/approval-preview.png'),
    );
    await tester.pumpWidget(
      app(const PickupConfirmationPage(requestId: 'r1'), [record('Approved')]),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/pickup-preview.png'),
    );
  });
}
