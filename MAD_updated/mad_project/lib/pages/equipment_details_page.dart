import '../widgets/app_scaffold.dart';

import 'package:flutter/material.dart';

import '../models/equipment_item.dart';
import 'borrow_request_page.dart';

class EquipmentDetailsPage extends StatelessWidget {
  const EquipmentDetailsPage({super.key, required this.item});

  final EquipmentItem item;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6525);
    final available = item.status == 'Available';
    return AppScaffold(
      navigationIndex: 1,

      backgroundColor: Colors.white,
      showBack: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Equipment details',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.asset(
                    item.imagePath,
                    fit: BoxFit.contain,
                    cacheWidth: 900,
                    semanticLabel: item.name,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(
                          color: Color(0xFFE0E0E0),
                          child: Icon(Icons.image_not_supported, size: 80),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: available ? orange : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.status,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(item.description),
              const SizedBox(height: 12),
              const Text(
                'Category',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(item.category),
              const SizedBox(height: 12),
              const Text(
                'Eligible programs',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(item.eligiblePrograms),
              const SizedBox(height: 12),
              Text(
                item.inventoryVerified
                    ? 'Available: ${item.availableQuantity} of ${item.totalQuantity}'
                    : 'Stock counts have not been verified yet.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              DecoratedBox(
                decoration: BoxDecoration(
                  color: available ? null : Colors.grey,
                  gradient: available
                      ? const LinearGradient(
                          colors: [Color(0xFFFF5424), Color(0xFFF58B21)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: available
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BorrowRequestPage(item: item),
                              ),
                            );
                          }
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                    ),
                    child: Text(
                      available
                          ? 'Request to Borrow'
                          : item.inventoryVerified
                          ? 'Unable to borrow'
                          : 'Check availability',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
