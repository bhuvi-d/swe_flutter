import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  FirebaseAuth? _auth;
  bool _useMock = false;
  
  String? _verificationId;
  int? _resendToken;

  AuthService() {
    _init();
  }

  void _init() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
      } else {
        _useMock = true;
        debugPrint('AuthService: Firebase not initialized, using Mock mode');
      }
    } catch (e) {
      _useMock = true;
    }
  }

  /// Stream of user state changes
  Stream<User?> get userChanges {
    if (_useMock || _auth == null) {
      return const Stream.empty();
    }
    return _auth!.userChanges();
  }

  /// Current user
  User? get currentUser {
    if (_useMock || _auth == null) return null;
    return _auth!.currentUser;
  }

  /// Send OTP to phone number
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    // Ensure number is in international format if not already
    String formattedNumber = phoneNumber;
    if (!phoneNumber.startsWith('+')) {
      formattedNumber = '+91$phoneNumber'; // Defaulting to India as per project context
    }

    if (_useMock || _auth == null) {
      debugPrint('AuthService: Sending Mock OTP to $formattedNumber');
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      onCodeSent('mock_verification_id', 123);
      return;
    }

    try {
      await _auth!.verifyPhoneNumber(
        phoneNumber: formattedNumber,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: (String vid, int? token) {
          _verificationId = vid;
          _resendToken = token;
          onCodeSent(vid, token);
        },
        codeAutoRetrievalTimeout: (String vid) {
          _verificationId = vid;
        },
      );
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      rethrow;
    }
  }

  /// Verify OTP and sign in
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    if (_useMock || _auth == null) {
      debugPrint('AuthService: Verifying Mock OTP $smsCode');
      await Future.delayed(const Duration(seconds: 1));
      if (smsCode == '123456') {
        return; // Success
      } else {
        throw FirebaseAuthException(code: 'invalid-verification-code', message: 'Invalid Mock OTP');
      }
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth!.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (_useMock || _auth == null) return;
    await _auth!.signOut();
  }
}

final authService = AuthService();
