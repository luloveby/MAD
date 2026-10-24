import 'dart:async';

import 'package:flutter/material.dart';

import '../models/request_notification.dart';
import '../services/request_service.dart';
import '../widgets/request_widgets.dart';
import '../widgets/transaction_widgets.dart';
import 'pickup_confirmation_page.dart';
import 'approval_notification_page.dart';
import 'request_details_page.dart';
import 'return_reminder_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.markRead});
  final Future<void> Function(String requestId, String notificationKey)?
  markRead;
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final Timer _timer;
  final _opened = <String>{};

  Future<void> _recordOpen(RequestNotification update) async {
    try {
      await (widget.markRead ?? RequestService().markNotificationRead)(
        update.requestId,
        update.title,
      );
      if (mounted)
        setState(() => _opened.add('${update.requestId}/${update.title}'));
    } catch (_) {
      // Keep the unread border if persistence failed; opening again retries it.
    }
  }

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

  void open(RequestNotification update) {
    if (!update.isRead) unawaited(_recordOpen(update));
    final Widget page = switch (update.destination) {
      RequestNotificationDestination.approval => ApprovalNotificationPage(
        requestId: update.requestId,
      ),
      RequestNotificationDestination.pickup => PickupConfirmationPage(
        requestId: update.requestId,
      ),
      RequestNotificationDestination.reminder => ReturnReminderPage(
        requestId: update.requestId,
      ),
      RequestNotificationDestination.details => RequestDetailsPage(
        requestId: update.requestId,
      ),
    };
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final updates = RequestNotification.fromRequests(
        requests,
        DateTime.now(),
      );
      return TransactionLayout(
        title: 'Notifications',
        subtitle: 'Borrowing updates, newest first',
        children: [
          if (updates.isEmpty)
            const TransactionPanel(
              child: Text(
                'No borrowing updates yet. Updates will appear here as your requests progress.',
              ),
            ),
          for (final update in updates)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: BorderSide(
                    color:
                        !update.isRead &&
                            !_opened.contains(
                              '${update.requestId}/${update.title}',
                            )
                        ? const Color(0xFFFF692B)
                        : const Color(0xFF888888),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => open(update),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update.date == null
                              ? 'Request update'
                              : transactionDate(update.date),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF666666),
                          ),
                        ),
                        Text(
                          update.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          update.message,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
