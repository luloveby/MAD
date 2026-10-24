import 'package:flutter/material.dart';

import '../widgets/request_widgets.dart';
import '../widgets/transaction_widgets.dart';
import '../widgets/confirm_pickup_button.dart';
import '../widgets/app_navigation_bar.dart';
import 'borrowing_history_page.dart';
import 'pickup_confirmation_page.dart';
import 'return_confirmation_page.dart';
import 'return_reminder_page.dart';

class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({super.key, required this.requestId});
  final String requestId;
  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final matches = requests.where((r) => r.id == requestId);
      if (matches.isEmpty) {
        return const TransactionLayout(
          title: 'Request details',
          subtitle: '',
          children: [Text('Request not found.')],
        );
      }
      final request = matches.first;
      final statusColor = switch (request.status) {
        'Pending' => const Color(0xFFB77900),
        'Approved' => const Color(0xFFE85D20),
        'Borrowed' => const Color(0xFF008C3D),
        'Returned' => const Color(0xFF666666),
        _ => const Color(0xFF666666),
      };
      return TransactionLayout(
        title: 'Request details',
        subtitle: '${request.equipmentName} • Request ${request.id}',
        children: [
          TransactionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'TRANSACTION DETAILS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: ShapeDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        shape: StadiumBorder(
                          side: BorderSide(color: statusColor),
                        ),
                      ),
                      child: Text(
                        'Status: ${request.status}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TransactionField(
                  label: 'Equipment',
                  value: request.equipmentName,
                ),
                const SizedBox(height: 6),
                TransactionField(
                  label: 'Borrow',
                  value: transactionDate(request.borrowAt),
                ),
                const SizedBox(height: 6),
                TransactionField(
                  label: 'Return',
                  value: transactionDate(request.returnAt),
                ),
                const SizedBox(height: 6),
                TransactionField(
                  label: 'Purpose',
                  value: request.purpose.isEmpty
                      ? 'Not provided'
                      : request.purpose,
                ),
                if (request.returnedAt != null) ...[
                  const SizedBox(height: 6),
                  TransactionField(
                    label: 'Returned',
                    value: transactionDate(request.returnedAt),
                  ),
                ],
              ],
            ),
          ),
          if (request.status == 'Approved')
            ConfirmPickupButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PickupConfirmationPage(requestId: requestId),
                ),
              ),
            ),
          if (request.status == 'Borrowed') ...[
            TransactionPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ITEM CONDITION UPON BORROWING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 10),
                  if (request.conditionPhotoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        Uri.parse(request.conditionPhotoUrl!).data!.contentAsBytes(),
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 64),
                      ),
                    )
                  else
                    const Text('No condition photo was saved.', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            TransactionPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup confirmed',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.returnAt == null
                        ? 'Return schedule has not been set. Contact the equipment office.'
                        : 'Please return this equipment by ${transactionDate(request.returnAt)}.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF692B),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReturnReminderPage(requestId: requestId),
                ),
              ),
              child: const Text('Return reminder'),
            ),
            ConfirmPickupButton(
              label: 'Confirm returned',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReturnConfirmationPage(requestId: requestId),
                ),
              ),
            ),
          ],
          if (request.status == 'Returned' &&
              request.returnConditionPhotoUrl != null)
            TransactionPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ITEM CONDITION UPON RETURN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      Uri.parse(request.returnConditionPhotoUrl!)
                          .data!
                          .contentAsBytes(),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image, size: 64),
                    ),
                  ),
                ],
              ),
            ),
          if (request.status == 'Returned')
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const BorrowingHistoryPage(),
                ),
              ),
              child: const Text('Borrowing History'),
            ),
          TransactionButton(
            label: 'Back to Home',
            onPressed: () => AppNavigation.openHome(context),
          ),
        ],
      );
    },
  );
}
