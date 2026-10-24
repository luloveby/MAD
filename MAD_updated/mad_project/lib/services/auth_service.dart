import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  String _studentId(String value) {
    final id = value.trim();
    if (id.isEmpty || id.contains('/') || id == '.' || id == '..') {
      throw ArgumentError('Enter a valid student number without slashes.');
    }
    return id;
  }

  Future<DocumentReference<Map<String, dynamic>>> _profileRef(User user) async {
    final profiles = await _db
        .collection('users')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (profiles.docs.isNotEmpty) return profiles.docs.first.reference;
    // Keep accounts registered with the previous UID document names readable.
    return _db.collection('users').doc(user.uid);
  }

  Future<void> register({
    required String fullName,
    required String studentNumber,
    required String email,
    required String password,
    required String address,
    required String contactNumber,
    required String program,
  }) async {
    final id = _studentId(studentNumber);
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    final profile = _db.collection('users').doc(id);
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(profile);
      if (existing.exists) {
        throw StateError('This student number is already registered.');
      }
      transaction.set(profile, {
        'uid': user.uid,
        'fullName': fullName.trim(),
        'studentNumber': id,
        'email': user.email,
        'address': address.trim(),
        'contactNumber': contactNumber.trim(),
        'program': program,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    await user.sendEmailVerification();
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream() async* {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No student is logged in.');
    }

    await for (final profiles
        in _db
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .snapshots()) {
      if (profiles.docs.isNotEmpty) {
        yield profiles.docs.first;
      } else {
        yield await _db.collection('users').doc(user.uid).get();
      }
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String studentNumber,
    required String address,
    required String contactNumber,
    required String program,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No student is logged in.');
    }

    final id = _studentId(studentNumber);
    final previous = await _profileRef(user);
    final target = _db.collection('users').doc(id);
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(previous);
      if (!existing.exists) throw StateError('Student profile not found.');
      if (previous.path != target.path) {
        final other = await transaction.get(target);
        if (other.exists) {
          throw StateError('This student number is already registered.');
        }
      }
      transaction.set(target, {
        ...existing.data()!,
        'uid': user.uid,
        'fullName': fullName.trim(),
        'studentNumber': id,
        'address': address.trim(),
        'contactNumber': contactNumber.trim(),
        'program': program,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (previous.path != target.path) transaction.delete(previous);
    });
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
