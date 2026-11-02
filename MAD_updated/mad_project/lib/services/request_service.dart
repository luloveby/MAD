import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/borrow_request.dart';
import '../models/equipment_item.dart';
import '../utils/philippine_time.dart';

import 'package:flutter/foundation.dart';

class RequestSubmissionException implements Exception {
  const RequestSubmissionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RequestService {
  RequestService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  String lastSubmissionStatus = 'Approved';

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please log in to view requests.');
    return user.uid;
  }

  Stream<List<BorrowRequest>> watchRequests() {
    return _db
        .collection('requests')
        .where('uid', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => BorrowRequest.fromFirestore(doc.id, doc.data()))
              .toList();
          requests.sort(
            (a, b) => (b.borrowAt ?? DateTime(1970)).compareTo(
              a.borrowAt ?? DateTime(1970),
            ),
          );
          return requests;
        });
  }

  Future<String> submitRequest({
    required EquipmentItem item,
    required DateTime borrowAt,
    required DateTime returnAt,
    required String purpose,
  }) async {
    final uid = _uid;
    bool withinHours(DateTime date) {
      final local = PhilippineTime.wallClock(date);
      final minutes = local.hour * 60 + local.minute;
      return minutes >= 480 && minutes <= 1020;
    }

    if (item.id.isEmpty ||
        purpose.trim().isEmpty ||
        purpose.trim().length > 2000 ||
        !borrowAt.isAfter(DateTime.now()) ||
        !returnAt.isAfter(borrowAt) ||
        !withinHours(borrowAt) ||
        !withinHours(returnAt)) {
      throw StateError('Please check the equipment, purpose, and schedule.');
    }
    final equipment = _db.collection('equipment').doc(item.id);
    final counter = _db.collection('counters').doc('requests');
    var submissionStep = 'reading equipment';
    try {
      final id = await _db.runTransaction<String>((transaction) async {
        submissionStep = 'reading equipment';
        final snapshot = await transaction.get(equipment);
        submissionStep = 'reading counters/requests';
        final counterSnapshot = await transaction.get(counter);
        final data = snapshot.data();
        if (data == null ||
            data['isActive'] != true ||
            data['inventoryVerified'] != true ||
            data['availableQuantity'] is! int ||
            (data['availableQuantity'] as int) <= 0) {
          throw StateError('This equipment is no longer available.');
        }
        final lastNumber = counterSnapshot.data()?['lastNumber'] ?? 0;
        if (lastNumber is! int || lastNumber < 0) {
          throw StateError('Request numbering is unavailable.');
        }
        final nextNumber = lastNumber + 1;
        final id = 'BIT-${nextNumber.toString().padLeft(4, '0')}';
        final ref = _db.collection('requests').doc(id);
        submissionStep = 'saving $id and its numbering counter';
        transaction.set(counter, {
          'lastNumber': nextNumber,
          'lastRequestId': id,
        });
        transaction.set(ref, {
          'uid': uid,
          'equipmentId': item.id,
          'equipmentName': data['name'],
          'status': 'Approved',
          'purpose': purpose.trim(),
          'borrowAt': Timestamp.fromDate(borrowAt),
          'returnAt': Timestamp.fromDate(returnAt),
          'createdAt': FieldValue.serverTimestamp(),
          'approvedAt': FieldValue.serverTimestamp(),
          'archived': false,
        });
        return id;
      });
      lastSubmissionStatus = 'Approved';
      return id;
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      debugPrint(
        'Request submission denied while $submissionStep: ${error.message}',
      );
      // Older deployed rules accept Pending requests, without counter access.
      final ref = _db.collection('requests').doc();
      try {
        await _db.runTransaction((transaction) async {
          final snapshot = await transaction.get(equipment);
          final data = snapshot.data();
          if (data == null ||
              data['isActive'] != true ||
              data['inventoryVerified'] != true ||
              data['availableQuantity'] is! int ||
              (data['availableQuantity'] as int) <= 0) {
            throw StateError('This equipment is no longer available.');
          }
          transaction.set(ref, {
            'uid': uid,
            'equipmentId': item.id,
            'equipmentName': data['name'],
            'status': 'Pending',
            'purpose': purpose.trim(),
            'borrowAt': Timestamp.fromDate(borrowAt),
            'returnAt': Timestamp.fromDate(returnAt),
            'createdAt': FieldValue.serverTimestamp(),
            'archived': false,
          });
        });
      } on FirebaseException catch (fallbackError) {
        if (fallbackError.code != 'permission-denied') rethrow;
        throw RequestSubmissionException(
          'Firebase denied $submissionStep. The Pending fallback was also denied. '
          'Check the signed-in account and the existing request counter.',
        );
      }
      lastSubmissionStatus = 'Pending';
      return ref.id;
    }
  }

  Future<void> confirmPickup(String id, {String? conditionPhotoUrl}) async {
    final uid = _uid;
    final ref = _db.collection('requests').doc(id);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null || data['uid'] != uid) {
        throw StateError('Request not found.');
      }
      if (data['status'] == 'Borrowed') return;
      if (data['status'] != 'Approved') {
        throw StateError('Only approved requests can be picked up.');
      }
      final equipmentRef = _db
          .collection('equipment')
          .doc(data['equipmentId'] as String);
      final equipmentSnapshot = await transaction.get(equipmentRef);
      final equipment = equipmentSnapshot.data();
      final available = equipment?['availableQuantity'];
      final total = equipment?['totalQuantity'];
      if (equipment == null ||
          equipment['inventoryVerified'] != true ||
          available is! int ||
          total is! int ||
          available <= 0 ||
          available > total) {
        throw StateError('This equipment is currently unavailable.');
      }
      transaction.update(equipmentRef, {
        'availableQuantity': available - 1,
        'lastAvailabilityRequestId': id,
        'lastAvailabilityAction': 'borrow',
      });
      transaction.update(ref, {
        'status': 'Borrowed',
        'pickedUpAt': FieldValue.serverTimestamp(),
        'inventoryUpdated': true,
        if (conditionPhotoUrl != null) 'conditionPhotoUrl': conditionPhotoUrl,
      });
    });
  }

  Future<void> confirmReturn(
    String id, {
    required String returnConditionPhotoUrl,
  }) async {
    final uid = _uid;
    final ref = _db.collection('requests').doc(id);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null || data['uid'] != uid) {
        throw StateError('Request not found.');
      }
      if (data['status'] == 'Returned') return;
      if (data['status'] != 'Borrowed') {
        throw StateError('Only borrowed requests can be returned.');
      }
      final inventoryWasUpdated = data['inventoryUpdated'] == true;
      DocumentReference<Map<String, dynamic>>? equipmentRef;
      if (inventoryWasUpdated) {
        equipmentRef = _db
            .collection('equipment')
            .doc(data['equipmentId'] as String);
        final equipmentSnapshot = await transaction.get(equipmentRef);
        final equipment = equipmentSnapshot.data();
        final available = equipment?['availableQuantity'];
        final total = equipment?['totalQuantity'];
        if (equipment == null ||
            equipment['inventoryVerified'] != true ||
            available is! int ||
            total is! int ||
            available < 0 ||
            available >= total) {
          throw StateError('Equipment availability could not be restored.');
        }
        transaction.update(equipmentRef, {
          'availableQuantity': available + 1,
          'lastAvailabilityRequestId': id,
          'lastAvailabilityAction': 'return',
        });
      }
      transaction.update(ref, {
        'status': 'Returned',
        'returnedAt': FieldValue.serverTimestamp(),
        'returnConditionPhotoUrl': returnConditionPhotoUrl,
      });
    });
  }

  Future<void> markApprovalRead(String id) async {
    final uid = _uid;
    final ref = _db.collection('requests').doc(id);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null || data['uid'] != uid) {
        throw StateError('Request not found.');
      }
      if (data['approvalReadAt'] != null) return;
      if (data['status'] != 'Approved' && data['approvedAt'] == null) return;
      transaction.update(ref, {'approvalReadAt': FieldValue.serverTimestamp()});
    });
  }

  Future<void> markNotificationRead(String id, String key) async {
    final uid = _uid;
    final ref = _db.collection('requests').doc(id);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null || data['uid'] != uid)
        throw StateError('Request not found.');
      final keys = (data['readNotificationKeys'] as List? ?? [])
          .whereType<String>()
          .toSet();
      if (!keys.add(key)) return;
      transaction.update(ref, {'readNotificationKeys': keys.toList()});
    });
  }

  Future<void> archiveRequests(Set<String> ids) async {
    if (ids.isEmpty) return;
    if (ids.length > 400) {
      throw StateError('Select up to 400 requests at a time.');
    }
    final uid = _uid;
    await _db.runTransaction((transaction) async {
      final refs = ids.map((id) => _db.collection('requests').doc(id)).toList();
      for (final ref in refs) {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        if (data == null ||
            data['uid'] != uid ||
            data['status'] != 'Returned') {
          throw StateError('Only your returned requests can be archived.');
        }
      }
      for (final ref in refs) {
        transaction.update(ref, {
          'archived': true,
          'archivedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
