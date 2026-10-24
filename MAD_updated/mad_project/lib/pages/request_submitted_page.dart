import 'package:flutter/material.dart';

import '../models/equipment_item.dart';
import '../widgets/transaction_widgets.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_navigation_bar.dart';

class RequestSubmittedPage extends StatelessWidget {
  const RequestSubmittedPage({
    super.key,
    required this.item,
    required this.needed,
    required this.returnAt,
    required this.purpose,
    required this.requestId,
    this.status = 'Approved',
  });

  final EquipmentItem item;
  final DateTime needed;
  final DateTime returnAt;
  final String purpose;
  final String requestId;
  final String status;

  @override
  Widget build(BuildContext context) {
    String schedule(DateTime value) => transactionDate(value);
    Widget summaryRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
    return AppScaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Request submitted',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Center(
                child: ClipRect(
                  child: Align(
                    heightFactor: 0.8,
                    child: Image.asset(
                      'assets/images/ok_Badge.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      semanticLabel: 'Request approved',
                    ),
                  ),
                ),
              ),
              Text(
                status == 'Approved'
                    ? 'Your request has been approved!'
                    : 'Your request has been submitted',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                status == 'Approved'
                    ? 'Request #$requestId was automatically approved.'
                    : 'Request #$requestId is pending approval.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REQUEST SUMMARY',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    summaryRow('Equipment', item.name),
                    summaryRow('Borrow', schedule(needed)),
                    summaryRow('Return', schedule(returnAt)),
                    summaryRow('Purpose', purpose),
                    summaryRow('Status', status),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == 'Approved'
                          ? 'Ready for pickup'
                          : 'Awaiting approval',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      status == 'Approved'
                          ? 'Open the notification bell on Home to view your approval and confirm pickup after receiving the equipment.'
                          : 'Track your request in My Requests under Pending. Automatic approval requires updated Firebase rules.',
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => AppNavigation.openHome(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF383838),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
