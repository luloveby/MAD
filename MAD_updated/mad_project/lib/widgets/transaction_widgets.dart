import 'package:flutter/material.dart';

import '../models/borrow_request.dart';
import '../utils/philippine_time.dart';
import 'app_scaffold.dart';

String transactionDate(DateTime? date) {
  if (date == null) return 'Not scheduled';
  date = PhilippineTime.wallClock(date);
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  return '${months[date.month - 1]} ${date.day}, ${date.year} - '
      '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'AM' : 'PM'}';
}

class TransactionLayout extends StatelessWidget {
  const TransactionLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.action,
  });
  final String title, subtitle;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) => AppScaffold(
    showBack: true,
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ?action,
                ],
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    ),
  );
}

class TransactionPanel extends StatelessWidget {
  const TransactionPanel({
    super.key,
    required this.child,
    this.color = Colors.grey,
  });
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(6),
    ),
    child: child,
  );
}

class TransactionButton extends StatelessWidget {
  const TransactionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3D3D3D),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    ),
  );
}

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.request,
    required this.onTap,
    this.selected = false,
  });
  final BorrowRequest request;
  final VoidCallback onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: selected ? const Color(0xFFFFF0E7) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF777777), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.devices,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.equipmentName,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: ShapeDecoration(
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: request.status == 'Borrowed'
                              ? const Color(0xFF00C853)
                              : Colors.grey,
                        ),
                      ),
                    ),
                    child: Text(
                      request.status,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TransactionField(
                label: 'Borrowing',
                value: transactionDate(request.borrowAt),
              ),
              TransactionField(
                label: 'Returned',
                value: request.returnedAt == null
                    ? 'Awaiting return record'
                    : transactionDate(request.returnedAt),
              ),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('Details ›', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class TransactionField extends StatelessWidget {
  const TransactionField({super.key, required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
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
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );
}
