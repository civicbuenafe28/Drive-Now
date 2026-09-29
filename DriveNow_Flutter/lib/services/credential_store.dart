import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// "Remember me" storage for the login screen.
///
/// The email and password are saved with flutter_secure_storage, which
/// encrypts them with a key kept in the Android Keystore — they are never
/// stored as plain text.
class CredentialStore {
  CredentialStore._();
  static final CredentialStore instance = CredentialStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _kEmail = 'remember_email';
  static const _kPassword = 'remember_password';

  /// Saved (email, password), or null when "Remember me" is off.
  Future<(String, String)?> load() async {
    try {
      final email = await _storage.read(key: _kEmail);
      final password = await _storage.read(key: _kPassword);
      if (email == null || email.isEmpty || password == null) return null;
      return (email, password);
    } catch (e) {
      debugPrint('CredentialStore.load failed: $e');
      return null;
    }
  }

  Future<void> save(String email, String password) async {
    try {
      await _storage.write(key: _kEmail, value: email.trim());
      await _storage.write(key: _kPassword, value: password);
    } catch (e) {
      debugPrint('CredentialStore.save failed: $e');
    }
  }

  /// Updates the stored password (after "Change password") if remembered.
  Future<void> updatePasswordIfSaved(String email, String newPassword) async {
    final saved = await load();
    if (saved != null && saved.$1.toLowerCase() == email.trim().toLowerCase()) {
      await save(saved.$1, newPassword);
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _kEmail);
      await _storage.delete(key: _kPassword);
    } catch (e) {
      debugPrint('CredentialStore.clear failed: $e');
    }
  }
}
