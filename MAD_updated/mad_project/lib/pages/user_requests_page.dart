import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/request_widgets.dart';
import 'borrowing_history_page.dart';
import 'request_details_page.dart';

class UserRequestsPage extends StatefulWidget {
  const UserRequestsPage({super.key});
  @override
  State<UserRequestsPage> createState() => _UserRequestsPageState();
}

class _UserRequestsPageState extends State<UserRequestsPage> {
  String status = 'Approved';
  late final Timer _overdueTimer;

  @override
  void initState() {
    super.initState();
    _overdueTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _overdueTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final filtered = requests
          .where((r) => r.status == status && !r.archived)
          .toList();
      return RequestLayout(
        title: 'My Requests',
        titleSpacing: 0,
        children: [
          const Text(
            'Active and upcoming borrowings',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final value in [
                'Pending',
                'Approved',
                'Borrowed',
                'Returned',
              ])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: value == 'Returned' ? 0 : 4,
                    ),
                    child: ChoiceChip(
                      chipAnimationStyle: ChipAnimationStyle(
                        selectAnimation: const AnimationStyle(
                          duration: Duration(milliseconds: 30),
                          reverseDuration: Duration(milliseconds: 30),
                        ),
                      ),
                      color: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected)
                            ? const Color(0xFFFF692B)
                            : Colors.white),
                      surfaceTintColor: Colors.transparent,
                      label: SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(value),
                        ),
                      ),
                      selected: status == value,
                      showCheckmark: false,
                      selectedColor: const Color(0xFFFF692B),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: status == value ? Colors.white : Colors.black87,
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Color(0xFFFF692B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (_) => setState(() => status = value),
                    ),
                  ),
                ),
            ],
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF692B),
            ),
            icon: const Icon(Icons.history),
            label: const Text('Borrowing History'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const BorrowingHistoryPage(),
              ),
            ),
          ),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No requests in this category.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final request in filtered)
            RequestCard(
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
