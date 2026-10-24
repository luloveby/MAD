import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_project/models/equipment_item.dart';
import 'package:mad_project/pages/borrow_request_page.dart';
import 'package:mad_project/pages/request_submitted_page.dart';

void main() {
  final item = EquipmentItem(
    id: 'e1',
    name: 'Laptop',
    category: 'Computer',
    status: 'Available',
    imagePath: '',
    description: 'Laptop',
  );

  for (final succeeds in [true, false]) {
    testWidgets(
      'submission ${succeeds ? 'waits for persistence' : 'failure keeps form'}',
      (tester) async {
        final result = Completer<String>();
        var calls = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: BorrowRequestPage(
              item: item,
              submitRequest:
                  ({
                    required item,
                    required borrowAt,
                    required returnAt,
                    required purpose,
                  }) {
                    calls++;
                    expect(item.id, 'e1');
                    expect(purpose, 'Coursework');
                    expect(returnAt.isAfter(borrowAt), isTrue);
                    return result.future;
                  },
            ),
          ),
        );
        await tester.enterText(find.byType(TextFormField), 'Coursework');
        await tester.ensureVisible(find.text('Submit Request'));
        await tester.tap(find.text('Submit Request'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(find.byType(RequestSubmittedPage), findsNothing);
        expect(find.text('Submitting…'), findsOneWidget);
        if (succeeds) {
          result.complete('saved-request');
        } else {
          result.completeError(StateError('offline'));
        }
        await tester.pumpAndSettle();
        expect(
          find.byType(RequestSubmittedPage),
          succeeds ? findsOneWidget : findsNothing,
        );
        if (succeeds) {
          expect(
            find.text('Request #saved-request was automatically approved.'),
            findsOneWidget,
          );
        } else {
          expect(
            find.textContaining('Unable to submit request.'),
            findsOneWidget,
          );
          expect(find.text('Coursework'), findsOneWidget);
        }
      },
    );
  }
}
