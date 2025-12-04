import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return credential.user;
  }

  Future<User?> register({
    required String name,
    required String email,
    required String password,
    required String role, // 'student' or 'lecturer'
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final user = credential.user;

    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': role, // 'student' / 'lecturer' / 'admin'
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
    return _db.collection('users').doc(uid).get();
  }
}
