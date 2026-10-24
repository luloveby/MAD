import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_project/models/borrow_request.dart';
import 'package:mad_project/utils/philippine_time.dart';
import 'package:mad_project/widgets/transaction_widgets.dart';

void main() {
  test('03:06 UTC displays as 11:06 AM in the Philippines', () {
    expect(
      transactionDate(DateTime.utc(2026, 10, 19, 3, 6)),
      'Oct 19, 2026 - 11:06 AM',
    );
  });
  test('An 11 AM picker selection saves as 03:00 UTC and round trips', () {
    final selected = PhilippineTime.fromWallClock(2026, 10, 19, 11);
    expect(selected, DateTime.utc(2026, 10, 19, 3));
    final request = BorrowRequest.fromFirestore('BIT-0001', {
      'uid': 'student',
      'equipmentId': 'laptop',
      'status': 'Approved',
      'borrowAt': Timestamp.fromDate(selected),
    });
    expect(transactionDate(request.borrowAt), 'Oct 19, 2026 - 11:00 AM');
  });
  test('Philippine midnight uses the correct calendar date', () {
    expect(
      transactionDate(DateTime.utc(2026, 10, 18, 16)),
      'Oct 19, 2026 - 12:00 AM',
    );
    expect(
      PhilippineTime.fromWallClock(2026, 10, 19),
      DateTime.utc(2026, 10, 18, 16),
    );
  });
}
