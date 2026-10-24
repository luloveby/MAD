import 'package:cloud_firestore/cloud_firestore.dart';

/// Request data stored in the existing Firestore requests collection.
class BorrowRequest {
  const BorrowRequest({
    required this.id,
    required this.uid,
    required this.equipmentId,
    required this.equipmentName,
    required this.status,
    required this.purpose,
    this.borrowAt,
    this.returnAt,
    this.returnedAt,
    this.createdAt,
    this.approvedAt,
    this.pickedUpAt,
    this.conditionPhotoUrl,
    this.returnConditionPhotoUrl,
    this.approvalReadAt,
    this.archived = false,
    this.readNotificationKeys = const [],
  });

  final String id, uid, equipmentId, equipmentName, status, purpose;
  final DateTime? borrowAt, returnAt, returnedAt;
  final DateTime? createdAt, approvedAt, pickedUpAt;
  final String? conditionPhotoUrl;
  final String? returnConditionPhotoUrl;
  final DateTime? approvalReadAt;
  bool get hasUnreadApproval =>
      !archived && status == 'Approved' && approvalReadAt == null;
  final bool archived;
  final List<String> readNotificationKeys;

  factory BorrowRequest.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime? date(String key) => (data[key] as Timestamp?)?.toDate();
    return BorrowRequest(
      id: id,
      uid: data['uid'] as String,
      equipmentId: data['equipmentId'] as String,
      equipmentName: data['equipmentName'] as String? ?? 'Equipment',
      status: data['status'] as String,
      purpose: data['purpose'] as String? ?? '',
      borrowAt: date('borrowAt'),
      returnAt: date('returnAt'),
      returnedAt: date('returnedAt'),
      createdAt: date('createdAt'),
      approvedAt: date('approvedAt'),
      pickedUpAt: date('pickedUpAt'),
      conditionPhotoUrl: data['conditionPhotoUrl'] as String?,
      returnConditionPhotoUrl: data['returnConditionPhotoUrl'] as String?,
      approvalReadAt: date('approvalReadAt'),
      archived: data['archived'] == true,
      readNotificationKeys: (data['readNotificationKeys'] as List? ?? [])
          .whereType<String>()
          .toList(),
    );
  }
}
