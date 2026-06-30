import 'package:devotion/core/type_defs.dart';
import 'package:devotion/features/auth/data/models/user_models.dart';
import 'package:devotion/features/auth/Repository/auth_repository.dart';
import 'package:devotion/features/auth/presentation/screen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/material.dart';

final userProvider = StateProvider<UserModel?>((ref) => null);

final authControllerProvider = NotifierProvider<AuthController, bool>(
  AuthController.new,
);

final authStateChangeProvider = StreamProvider((ref) {
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.authStateChange;
});

final getUserDataProvider = StreamProvider.family((ref, String uid) {
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.getUserData(uid);
});

class AuthController extends Notifier<bool> {
  late final AuthRepository _authRepository;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, DateTime> _lastEmailSent = {};

  @override
  bool build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return false;
  }

  Stream<User?> get authStateChange => _authRepository.authStateChange;

  // ✅ _handleAuthResult no longer navigates — caller (LoginScreen) owns navigation
  Future<bool> _handleAuthResult(
      ScaffoldMessengerState messenger, FutureEither<UserModel> result) async {
    state = true;
    final outcome = await result;
    state = false;

    return outcome.fold(
      (l) {
        _showSnackBarFromMessenger(messenger, l.message);
        return false; // ✅ Returns false on failure
      },
      (userModel) {
        ref.read(userProvider.notifier).update((state) => userModel);
        return true; // ✅ Returns true on success, let caller navigate
      },
    );
  }

  Future<bool> signInWithGoogle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    return _handleAuthResult(messenger, _authRepository.signInWithGoogle());
  }

  Future<bool> signInWithEmailAndPassword(
      ScaffoldMessengerState messenger, String email, String password) async {
    return _handleAuthResult(
        messenger, _authRepository.signInWithEmailAndPassword(email, password));
  }

  Stream<UserModel> getUserData(String uid) {
    return _authRepository.getUserData(uid);
  }

  Future<void> resetPassword(BuildContext context, String email) async {
    if (email.isEmpty) {
      _showSnackBar(context, 'Please enter an email address.');
      return;
    }
    try {
      state = true;
      await _auth.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        _showSnackBar(context, 'Password reset link sent to your email.',
            isError: false);
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        final error = _mapFirebaseError(e.code);
        _showSnackBar(context, error);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, e.toString());
      }
    } finally {
      state = false;
    }
  }

  Future<void> resendVerificationEmail(BuildContext context) async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        final lastSent = _lastEmailSent[user.email];
        final now = DateTime.now();
        if (lastSent != null && now.difference(lastSent).inSeconds < 60) {
          throw 'Please wait ${60 - now.difference(lastSent).inSeconds} seconds before requesting another email.';
        }

        await user.sendEmailVerification();
        _lastEmailSent[user.email!] = now;

        if (context.mounted) {
          _showSnackBar(context, 'Verification email resent successfully.',
              isError: false);
        }
      } else {
        throw 'User not found or already verified.';
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, e.toString());
      }
    }
  }

  void _showSnackBarFromMessenger(
      ScaffoldMessengerState messenger, String message,
      {bool isError = true}) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = true}) {
    _showSnackBarFromMessenger(ScaffoldMessenger.of(context), message,
        isError: isError);
  }

  Future<void> signOut(BuildContext context) async {
    await _authRepository.signOutUser();
    ref.read(userProvider.notifier).update((state) => null);
    if (context.mounted) {
      // ✅ Use pushAndRemoveUntil to clear the entire back stack on sign out
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found with that email address.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}
