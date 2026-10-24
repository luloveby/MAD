import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/borrow_request.dart';
import 'app_scaffold.dart';
import 'request_scope.dart';
import 'transaction_widgets.dart';

String requestDate(DateTime? date) => transactionDate(date);

class RequestContent extends StatefulWidget {
  const RequestContent({super.key, required this.builder});
  final Widget Function(BuildContext, List<BorrowRequest>) builder;
  @override
  State<RequestContent> createState() => _RequestContentState();
}

class _RequestContentState extends State<RequestContent> {
  Stream<List<BorrowRequest>>? _stream;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    try {
      _stream = RequestScope.watchOf(context);
    } catch (error, stack) {
      _stream = Stream<List<BorrowRequest>>.error(error, stack);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<BorrowRequest>>(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        final error = snapshot.error;
        final message =
            error is FirebaseException && error.code == 'permission-denied'
            ? 'Request access is blocked by Firebase permissions. Please contact the app administrator.'
            : 'Unable to load requests. Check your connection or try again later.';
        return AppScaffold(
          showBack: true,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(message),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const AppScaffold(
          showBack: true,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return widget.builder(context, snapshot.data!);
    },
  );
}

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.selected = false,
  });
  final BorrowRequest request;
  final VoidCallback onTap;
  final bool selected;

  bool get _isOverdue =>
      request.status == 'Borrowed' &&
      request.returnAt != null &&
      request.returnAt!.isBefore(DateTime.now());

  Color get _statusColor => switch (request.status) {
    'Pending' => const Color(0xFFFFB300),
    'Approved' => const Color(0xFFFF692B),
    'Borrowed' => const Color(0xFF00B84A),
    _ => const Color(0xFF777777),
  };

  Widget _scheduleRow(String label, DateTime? date) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            transactionDate(date),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    color: _isOverdue
        ? const Color(0xFFFFE5E5)
        : selected
        ? const Color(0xFFFFE8D9)
        : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: _isOverdue ? const Color(0xFFD32F2F) : const Color(0xFF777777),
        width: _isOverdue ? 2 : 1.5,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    selected ? Icons.check_circle : Icons.devices,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    request.equipmentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: ShapeDecoration(
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: _isOverdue
                            ? const Color(0xFFD32F2F)
                            : _statusColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Text(
                    _isOverdue ? 'OVERDUE' : request.status,
                    style: TextStyle(
                      fontSize: 11,
                      color: _isOverdue
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF555555),
                      fontWeight: _isOverdue
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _scheduleRow('Borrowing', request.borrowAt),
            _scheduleRow(
              request.status == 'Returned'
                  ? 'Returned'
                  : _isOverdue
                  ? 'Overdue since'
                  : 'Return deadline',
              request.status == 'Returned'
                  ? request.returnedAt
                  : request.returnAt,
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(fontSize: 12, color: Color(0xFF555555)),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: Color(0xFF555555)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class RequestLayout extends StatelessWidget {
  const RequestLayout({
    super.key,
    required this.title,
    required this.children,
    this.titleSpacing = 16,
  });
  final String title;
  final List<Widget> children;
  final double titleSpacing;
  @override
  Widget build(BuildContext context) => AppScaffold(
    showBack: true,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: titleSpacing),
          ...children,
        ],
      ),
    ),
  );
}
