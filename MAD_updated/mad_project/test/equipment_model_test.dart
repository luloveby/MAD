import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:mad_project/models/equipment_item.dart';

void main() {
  final records = (jsonDecode(
    File('scripts/equipment_seed.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();
  test('Seed records are unique, readable and do not invent stock counts', () {
    expect(records.map((r) => r['id']).toSet().length, records.length);
    for (final record in records) {
      final item = EquipmentItem.fromFirestore(record['id'] as String, record);
      expect(item.status, 'Check availability');
      expect(item.availableQuantity, isNull);
      expect(File(item.imagePath).existsSync(), isTrue);
      expect(item.eligiblePrograms, contains('BLISS'));
    }
  });
  test('Only verified, valid stock counts show availability', () {
    final record = {
      ...records.first,
      'inventoryVerified': true,
      'totalQuantity': 2,
      'availableQuantity': 1,
    };
    expect(EquipmentItem.fromFirestore('test', record).status, 'Available');
    record['availableQuantity'] = 0;
    expect(EquipmentItem.fromFirestore('test', record).status, 'Unavailable');
    record['availableQuantity'] = 3;
    expect(
      EquipmentItem.fromFirestore('test', record).status,
      'Check availability',
    );
  });
}
