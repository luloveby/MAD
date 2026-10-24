import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/request_widgets.dart';
import '../widgets/transaction_widgets.dart';
import 'request_details_page.dart';

class ReturnReminderPage extends StatefulWidget {
  const ReturnReminderPage({super.key, required this.requestId});
  final String requestId;
  @override
  State<ReturnReminderPage> createState() => _ReturnReminderPageState();
}

class _ReturnReminderPageState extends State<ReturnReminderPage> {
  late final Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final matches = requests.where((r) => r.id == widget.requestId);
      if (matches.isEmpty) {
        return const TransactionLayout(
          title: 'Return Reminder',
          subtitle: '',
          children: [Text('Request not found.')],
        );
      }
      final request = matches.first;
      final borrowed = request.status == 'Borrowed';
      final overdue =
          borrowed &&
          request.returnAt != null &&
          request.returnAt!.isBefore(DateTime.now());
      return TransactionLayout(
        title: 'Return Reminder',
        subtitle: overdue
            ? 'Overdue deadline'
            : borrowed
            ? 'Upcoming deadline'
            : 'Request update',
        children: [
          TransactionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !borrowed
                      ? 'Current status: ${request.status}'
                      : request.returnAt == null
                      ? 'Return schedule unavailable'
                      : overdue
                      ? 'Return deadline passed'
                      : 'Return deadline approaching',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  !borrowed
                      ? 'View your request for the latest transaction details.'
                      : request.returnAt == null
                      ? 'Contact the equipment office to confirm when to return your ${request.equipmentName}.'
                      : 'Reminder: Your ${request.equipmentName} ${overdue ? 'is overdue' : 'is due for return soon'}. Please return it by ${transactionDate(request.returnAt)}.',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          TransactionButton(
            label: 'View Request',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => RequestDetailsPage(requestId: widget.requestId),
              ),
            ),
          ),
        ],
      );
    },
  );
}
