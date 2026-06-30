import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService(
      {required FirebaseFirestore firestore,
      required FirebaseAuth firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  Stream<User?> get authStateChange => _firebaseAuth.authStateChanges();
}
