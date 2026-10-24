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
      final returned = requests
          .where((r) => r.status == 'Returned' && !r.archived)
          .toList();
      return TransactionLayout(
        title: 'Borrowing History',
        subtitle: 'Your completed transactions',
        action: IconButton(
          tooltip: 'Archive',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const ArchivePage()),
          ),
          icon: const Icon(Icons.archive_outlined),
        ),
        children: [
          if (returned.isEmpty) const Text('No completed transactions.'),
          for (final request in returned)
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
