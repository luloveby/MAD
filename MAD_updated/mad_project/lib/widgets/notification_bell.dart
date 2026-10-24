import 'package:flutter/material.dart';

import 'dart:async';

import '../models/borrow_request.dart';
import '../models/request_notification.dart';
import '../pages/approval_notification_page.dart';
import '../pages/notifications_page.dart';
import 'request_scope.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});
  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  Stream<List<BorrowRequest>>? _stream;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    try {
      _stream = RequestScope.watchOf(context);
    } catch (error, stack) {
      _stream = Stream.error(error, stack);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<BorrowRequest>>(
    stream: _stream,
    builder: (context, snapshot) {
      final hasUnread = RequestNotification.fromRequests(
        snapshot.data ?? <BorrowRequest>[],
        DateTime.now(),
      ).any((notification) => !notification.isRead);
      final unread =
          (snapshot.data ?? <BorrowRequest>[])
              .where((r) => r.hasUnreadApproval)
              .toList()
            ..sort(
              (a, b) => (b.approvedAt ?? b.createdAt ?? DateTime(1970))
                  .compareTo(a.approvedAt ?? a.createdAt ?? DateTime(1970)),
            );
      return IconButton(
        tooltip: unread.isNotEmpty
            ? 'Notifications: unread approval'
            : hasUnread
            ? 'Notifications: unread updates'
            : 'Notifications',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => unread.isEmpty
                ? const NotificationsPage()
                : ApprovalNotificationPage(requestId: unread.first.id),
          ),
        ),
        icon: Badge(
          key: const ValueKey('notification-badge'),
          isLabelVisible: hasUnread,
          backgroundColor: Colors.white,
          smallSize: 9,
          child: const Icon(
            Icons.notifications_none,
            color: Colors.white,
            size: 28,
          ),
        ),
      );
    },
  );
}
