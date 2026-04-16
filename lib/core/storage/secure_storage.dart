import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// =============================================================================
// MBOA HEALTH — Secure Storage
// Stores the JWT token in encrypted device storage.
// OWASP A02: never use SharedPreferences for tokens — it is unencrypted.
// =============================================================================

abstract final class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyToken     = 'mboa_jwt_token';
  static const String _keyUserEmail = 'mboa_user_email';
  static const String _keyUserRole  = 'mboa_user_role';

  // ── Token ──────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  static Future<String?> getToken() =>
      _storage.read(key: _keyToken);

  static Future<void> deleteToken() =>
      _storage.delete(key: _keyToken);

  // ── Session metadata ───────────────────────────────────────────────────────

  static Future<void> saveSession({
    required String email,
    required String role,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUserEmail, value: email),
      _storage.write(key: _keyUserRole, value: role),
    ]);
  }

  static Future<String?> getSavedEmail() =>
      _storage.read(key: _keyUserEmail);

  static Future<String?> getSavedRole() =>
      _storage.read(key: _keyUserRole);

  // ── Clear all (logout) ─────────────────────────────────────────────────────

  /// Wipes all stored credentials. Call on logout. OWASP A07.
  static Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _keyToken),
      _storage.delete(key: _keyUserEmail),
      _storage.delete(key: _keyUserRole),
    ]);
  }
}
