import 'package:flutter/material.dart';

import '../services/request_service.dart';
import '../widgets/request_widgets.dart';
import '../widgets/transaction_widgets.dart';
import '../widgets/confirm_pickup_button.dart';
import 'pickup_confirmation_page.dart';
import 'request_details_page.dart';

class ApprovalNotificationPage extends StatefulWidget {
  const ApprovalNotificationPage({
    super.key,
    required this.requestId,
    this.markRead,
  });
  final String requestId;
  final Future<void> Function(String)? markRead;
  @override
  State<ApprovalNotificationPage> createState() =>
      _ApprovalNotificationPageState();
}

class _ApprovalNotificationPageState extends State<ApprovalNotificationPage> {
  bool _attempted = false;
  bool _readFailed = false;

  Future<void> _markRead() async {
    try {
      await (widget.markRead ?? RequestService().markApprovalRead)(
        widget.requestId,
      );
      if (mounted && _readFailed) setState(() => _readFailed = false);
    } catch (_) {
      if (mounted) setState(() => _readFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final matches = requests.where((r) => r.id == widget.requestId);
      if (matches.isEmpty) {
        return const TransactionLayout(
          title: 'Approval notification',
          subtitle: 'In-app update',
          children: [Text('Request not found.')],
        );
      }
      final request = matches.first;
      final approved =
          request.status == 'Approved' || request.approvedAt != null;
      if (approved && request.approvalReadAt == null && !_attempted) {
        _attempted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _markRead();
        });
      }
      return TransactionLayout(
        title: 'Approval notification',
        subtitle: 'In-app update',
        children: [
          TransactionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (approved) ...[
                      const Icon(Icons.check_circle_outline, size: 18),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        approved ? 'REQUEST APPROVED' : 'REQUEST UPDATE',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  approved
                      ? 'Your request for ${request.equipmentName} has been approved!'
                      : 'Current request status: ${request.status}',
                ),
                const SizedBox(height: 16),
                Text(
                  '${transactionDate(request.borrowAt)} pickup',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Request #${request.id}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          TransactionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Step',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  request.status == 'Approved'
                      ? 'Confirm when you receive the equipment.'
                      : 'View your request for the latest transaction details.',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (_readFailed)
            TextButton(
              onPressed: _markRead,
              child: const Text('Unable to mark as read. Tap to retry.'),
            ),
          if (request.status == 'Approved')
            ConfirmPickupButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PickupConfirmationPage(requestId: request.id),
                ),
              ),
            )
          else
            TransactionButton(
              label: 'View Request',
              onPressed: () => Navigator.push(
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
