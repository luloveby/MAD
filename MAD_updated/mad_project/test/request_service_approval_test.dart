import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_project/models/equipment_item.dart';
import 'package:mad_project/services/request_service.dart';
import 'package:mad_project/utils/philippine_time.dart';

// Exercise the service transaction without production credentials or writes.
// ignore_for_file: subtype_of_sealed_class
class Student extends Fake implements User {
  @override
  String get uid => 'student';
}

class StudentAuth extends Fake implements FirebaseAuth {
  @override
  User get currentUser => Student();
}

class Ref extends Fake implements DocumentReference<Map<String, dynamic>> {
  Ref(this.path);
  @override
  final String path;
  @override
  String get id => path.split('/').last;
}

class Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  Collection(this.name);
  final String name;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      Ref('$name/${path ?? 'BIT-0001'}');
}

class Snapshot<T extends Object?> extends Fake implements DocumentSnapshot<T> {
  Snapshot(this.value);
  final T? value;
  @override
  T? data() => value;
}

class MemoryTransaction extends Fake implements Transaction {
  MemoryTransaction(this.records, {this.rejectCounter = false});
  final bool rejectCounter;
  final Map<String, Map<String, dynamic>> records;
  final Map<String, Map<String, dynamic>> writes = {};
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> ref,
  ) async {
    if (rejectCounter && ref.path == 'counters/requests') {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    }
    return Snapshot<T>(records[ref.path] as T?);
  }
  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    writes[ref.path] = Map<String, dynamic>.from(data as Map);
    return this;
  }

  @override
  Transaction update(DocumentReference ref, Map<Object, Object?> data) {
    writes[ref.path] = {
      ...?records[ref.path],
      ...data.map((key, value) => MapEntry(key as String, value)),
    };
    return this;
  }
}

class MemoryFirestore extends Fake implements FirebaseFirestore {
  final records = <String, Map<String, dynamic>>{
    'equipment/laptop': {
      'name': 'Laptop',
      'isActive': true,
      'inventoryVerified': true,
      'availableQuantity': 1,
    },
  };
  bool failCommit = false;
  bool rejectCounter = false;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      Collection(path);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final transaction = MemoryTransaction(records, rejectCounter: rejectCounter);
    final result = await transactionHandler(transaction);
    if (failCommit) throw StateError('offline');
    records.addAll(transaction.writes);
    return result;
  }
}

void main() {
  final item = EquipmentItem(
    id: 'laptop',
    name: 'Laptop',
    category: 'Computer',
    status: 'Available',
    imagePath: '',
    description: '',
  );
  late MemoryFirestore db;
  late RequestService service;
  setUp(() {
    db = MemoryFirestore();
    service = RequestService(firestore: db, auth: StudentAuth());
  });
  Future<String> submit() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return service.submitRequest(
      item: item,
      borrowAt: PhilippineTime.fromWallClock(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        10,
      ),
      returnAt: PhilippineTime.fromWallClock(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        16,
      ),
      purpose: 'Presentation',
    );
  }

  test('Valid submission persists Approved and server approval time', () async {
    expect(await submit(), 'BIT-0001');
    final saved = db.records['requests/BIT-0001']!;
    expect(saved['status'], 'Approved');
    expect(saved['uid'], 'student');
    expect(saved['approvedAt'], FieldValue.serverTimestamp());
    expect(saved['createdAt'], FieldValue.serverTimestamp());
    expect(saved.containsKey('approvalReadAt'), isFalse);
  });
  test('Request numbers increment and continue past four digits', () async {
    expect(await submit(), 'BIT-0001');
    expect(await submit(), 'BIT-0002');
    expect(db.records['counters/requests']!['lastNumber'], 2);
    db.records['counters/requests'] = {
      'lastNumber': 9999,
      'lastRequestId': 'BIT-9999',
    };
    expect(await submit(), 'BIT-10000');
  });
  test('Older Firebase rules fall back to a real Pending request', () async {
    db.rejectCounter = true;
    final id = await submit();
    final saved = db.records['requests/$id']!;
    expect(saved['status'], 'Pending');
    expect(saved.containsKey('approvedAt'), isFalse);
    expect(db.records.containsKey('counters/requests'), isFalse);
    expect(service.lastSubmissionStatus, 'Pending');
  });
  test('Unavailable equipment is not auto-approved', () async {
    db.records['equipment/laptop']!['availableQuantity'] = 0;
    await expectLater(submit(), throwsStateError);
    expect(db.records.containsKey('requests/BIT-0001'), isFalse);
    expect(db.records.containsKey('counters/requests'), isFalse);
  });
  test('Failed commit does not report approval', () async {
    db.failCommit = true;
    await expectLater(submit(), throwsStateError);
    expect(db.records.containsKey('requests/BIT-0001'), isFalse);
  });
  test('Read update records only the current owner approval', () async {
    await submit();
    await service.markApprovalRead('BIT-0001');
    expect(
      db.records['requests/BIT-0001']!['approvalReadAt'],
      FieldValue.serverTimestamp(),
    );
    expect(db.records['requests/BIT-0001']!['status'], 'Approved');
    db.records['requests/BIT-0001']!['uid'] = 'someone-else';
    await expectLater(service.markApprovalRead('BIT-0001'), throwsStateError);
  });
}
