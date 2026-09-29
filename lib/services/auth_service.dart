import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Error with a Firebase-style code, e.g. "wrong-password", "email-already-in-use".
class AuthException implements Exception {
  final String code;
  final String message;
  AuthException(this.code, [this.message = '']);

  @override
  String toString() => message.isEmpty ? code : message;
}

/// Port of AuthViewModel.swift.
///
/// Uses Firebase Authentication when Firebase is configured for Android.
/// Otherwise falls back to accounts stored on the device ("offline mode"),
/// so the app is fully usable without any Firebase setup.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool firebaseEnabled = false;
  late SharedPreferences _prefs;
  String? _localEmail;

  static const _accountsKey = 'local_accounts';
  static const _sessionKey = 'local_session';

  Future<void> init({required bool firebase}) async {
    firebaseEnabled = firebase;
    _prefs = await SharedPreferences.getInstance();
    if (firebaseEnabled) {
      FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
    } else {
      _localEmail = _prefs.getString(_sessionKey);
    }
  }

  User? get _fbUser => firebaseEnabled ? FirebaseAuth.instance.currentUser : null;

  bool get isSignedIn => firebaseEnabled ? _fbUser != null : _localEmail != null;

  String? get email => firebaseEnabled ? _fbUser?.email : _localEmail;

  /// Firebase uid (null in offline mode).
  String? get uid => _fbUser?.uid;

  String? get displayName {
    if (firebaseEnabled) return _fbUser?.displayName;
    final acc = _accounts()[_localEmail];
    return acc?['name'] as String?;
  }

  String? get joinedDate {
    if (firebaseEnabled) {
      return null; // handled by AppData from creation time
    }
    final acc = _accounts()[_localEmail];
    return acc?['joined'] as String?;
  }

  DateTime? get firebaseCreationTime => _fbUser?.metadata.creationTime;

  // ---------------------------------------------------------------- actions

  Future<void> signIn(String email, String password) async {
    email = email.trim();
    if (firebaseEnabled) {
      await _wrap(() => FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password));
    } else {
      final key = email.toLowerCase();
      if (!_isValidEmail(email)) throw AuthException('invalid-email');
      final acc = _accounts()[key];
      if (acc == null || acc['hash'] != _hash(key, password)) {
        throw AuthException('invalid-credential');
      }
      _localEmail = key;
      await _prefs.setString(_sessionKey, key);
    }
    notifyListeners();
  }

  Future<void> signUp(String fullName, String email, String password, String joined) async {
    email = email.trim();
    if (firebaseEnabled) {
      await _wrap(() async {
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        await cred.user?.updateDisplayName(fullName);
        await cred.user?.reload();
      });
    } else {
      final key = email.toLowerCase();
      if (!_isValidEmail(email)) throw AuthException('invalid-email');
      if (password.length < 6) throw AuthException('weak-password');
      final accounts = _accounts();
      if (accounts.containsKey(key)) throw AuthException('email-already-in-use');
      accounts[key] = {'hash': _hash(key, password), 'name': fullName, 'joined': joined};
      await _saveAccounts(accounts);
      _localEmail = key;
      await _prefs.setString(_sessionKey, key);
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    if (firebaseEnabled) {
      await FirebaseAuth.instance.signOut();
    } else {
      _localEmail = null;
      await _prefs.remove(_sessionKey);
    }
    notifyListeners();
  }

  /// Checks the current password (Firebase re-authentication).
  Future<void> reauthenticate(String password) async {
    if (firebaseEnabled) {
      final user = _fbUser;
      if (user == null || user.email == null) throw AuthException('no-current-user');
      await _wrap(() => user.reauthenticateWithCredential(
            EmailAuthProvider.credential(email: user.email!, password: password),
          ));
    } else {
      final key = _localEmail;
      if (key == null) throw AuthException('no-current-user');
      final acc = _accounts()[key];
      if (acc == null || acc['hash'] != _hash(key, password)) {
        throw AuthException('wrong-password');
      }
    }
  }

  Future<void> changePassword(String current, String newPassword) async {
    await reauthenticate(current);
    if (firebaseEnabled) {
      await _wrap(() => _fbUser!.updatePassword(newPassword));
    } else {
      final key = _localEmail!;
      final accounts = _accounts();
      accounts[key]!['hash'] = _hash(key, newPassword);
      await _saveAccounts(accounts);
    }
  }

  /// Verifies the password, runs [beforeDelete] (e.g. wipe cloud data while
  /// still signed in), then deletes the account.
  Future<void> deleteAccount(String password, {Future<void> Function()? beforeDelete}) async {
    await reauthenticate(password);
    if (beforeDelete != null) await beforeDelete();
    if (firebaseEnabled) {
      await _wrap(() => _fbUser!.delete());
    } else {
      final accounts = _accounts()..remove(_localEmail);
      await _saveAccounts(accounts);
      _localEmail = null;
      await _prefs.remove(_sessionKey);
    }
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    if (firebaseEnabled) {
      try {
        await _fbUser?.updateDisplayName(name);
      } catch (e) {
        debugPrint('updateDisplayName failed: $e');
      }
    } else if (_localEmail != null) {
      final accounts = _accounts();
      accounts[_localEmail!]?['name'] = name;
      await _saveAccounts(accounts);
    }
  }

  /// Sends a password-reset email (Firebase only).
  Future<void> sendPasswordReset(String email) async {
    if (!firebaseEnabled) throw AuthException('offline-mode');
    await _wrap(() => FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim()));
  }

  /// Email remembered on the login screen ("Remember me").
  String? get rememberedEmail => _prefs.getString('remembered_email');

  Future<void> setRememberedEmail(String? email) async {
    if (email == null || email.isEmpty) {
      await _prefs.remove('remembered_email');
    } else {
      await _prefs.setString('remembered_email', email.trim());
    }
  }

  /// Friendly message for any auth error code.
  static String messageFor(AuthException e) {
    final lower = e.message.toLowerCase();
    if (lower.contains('malformed') || lower.contains('expired')) {
      return 'Your credentials are invalid or have expired. Please try again.';
    }
    switch (e.code) {
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in instead.';
      case 'weak-password':
        return 'That password is too weak. Please choose a stronger one.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'requires-recent-login':
        return 'For your security, please log out and log in again, then retry.';
      case 'no-current-user':
        return 'You are not signed in. Please log in again.';
      case 'offline-mode':
        return 'Password reset by email needs Firebase. In offline mode, create a new account instead.';
      case 'internal-error':
        return 'Something went wrong on our side. Please try again later.';
      default:
        return e.message.isEmpty ? 'Something went wrong (${e.code}).' : e.message;
    }
  }

  // ---------------------------------------------------------------- helpers

  Future<T> _wrap<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? e.code);
    }
  }

  Map<String, Map<String, dynamic>> _accounts() {
    final raw = _prefs.getString(_accountsKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
  }

  Future<void> _saveAccounts(Map<String, Map<String, dynamic>> a) =>
      _prefs.setString(_accountsKey, jsonEncode(a));

  String _hash(String email, String password) =>
      sha256.convert(utf8.encode('drivenow:$email:$password')).toString();

  static bool _isValidEmail(String email) =>
      RegExp(r'^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$').hasMatch(email);

  static bool isValidEmail(String email) => _isValidEmail(email.trim());

  /// 8+ chars, uppercase, lowercase, number (UserProfileManager.isValidPassword)
  static bool isStrongPassword(String p) =>
      p.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(p) &&
      RegExp(r'[a-z]').hasMatch(p) &&
      RegExp(r'[0-9]').hasMatch(p);
}
