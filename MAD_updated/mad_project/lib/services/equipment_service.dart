import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/equipment_item.dart';

class EquipmentService {
  EquipmentService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<EquipmentItem>> watchEquipment() => _firestore
      .collection('equipment')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final items = snapshot.docs
            .map((doc) => EquipmentItem.fromFirestore(doc.id, doc.data()))
            .toList();
        items.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        return items;
      });
}
