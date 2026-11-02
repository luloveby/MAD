import 'package:flutter/material.dart';

import '../widgets/request_widgets.dart';
import '../widgets/transaction_widgets.dart';
import 'archive_page.dart';
import 'request_details_page.dart';

class BorrowingHistoryPage extends StatelessWidget {
  const BorrowingHistoryPage({super.key});
  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final history = requests
          .where(
            (r) =>
                const {'Approved', 'Borrowed', 'Returned'}.contains(r.status) &&
                !r.archived,
          )
          .toList();
      return TransactionLayout(
        title: 'Borrowing History',
        subtitle: 'Your approved, active, and completed borrowings',
        action: IconButton(
          tooltip: 'Archive',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const ArchivePage()),
          ),
          icon: const Icon(Icons.archive_outlined),
        ),
        children: [
          if (history.isEmpty)
            const Text('No approved or completed borrowings yet.'),
          for (final request in history)
            TransactionCard(
              request: request,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => RequestDetailsPage(requestId: request.id),
                ),
              ),
            ),
        ],
      );
    },
  );
}
