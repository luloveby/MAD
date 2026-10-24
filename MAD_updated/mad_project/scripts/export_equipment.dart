// One-time seed export: dart run scripts/export_equipment.dart
import 'dart:convert';
import 'dart:io';

import 'package:mad_project/data/equipment_catalog.dart';

void main() {
  const recommended = {
    'BSIT': [
      'Switches',
      'LAN Cable Tester',
      'Crimping Tool',
      'Laptop',
      'LAN Cables',
    ],
    'BSIS': [
      'Laptop',
      'Numeric Keypads',
      'Flash Drives',
      'Presentation Clicker',
    ],
    'BLISS': [
      'Flash Drives',
      'Laptop',
      'Webcams',
      'Presentation Clicker',
      'Speaker',
    ],
  };
  final seed = equipmentCatalog.asMap().entries.map((entry) {
    final item = entry.value;
    if (!File(item.imagePath).existsSync()) {
      throw StateError('Missing ${item.imagePath}');
    }
    return {
      'id': 'EQ-${(entry.key + 1).toString().padLeft(3, '0')}',
      'name': item.name.trim(),
      'category': item.category,
      'description': item.description,
      'imagePath': item.imagePath,
      'eligiblePrograms': ['BSIT', 'BSIS', 'BLISS'],
      'recommendedPrograms': recommended.entries
          .where((e) => e.value.contains(item.category))
          .map((e) => e.key)
          .toList(),
      'status': 'Check availability',
      'catalogStatus': item.status,
      'totalQuantity': null,
      'availableQuantity': null,
      'inventoryVerified': false,
      'isActive': true,
      'source': 'partNiRed catalog',
    };
  }).toList();
  File('scripts/equipment_seed.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(seed));
  stdout.writeln('Prepared ${seed.length} equipment records.');
}
