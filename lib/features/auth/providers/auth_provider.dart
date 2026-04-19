import 'package:flutter/foundation.dart';

import '../../../core/config/api_config.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/auth_guard.dart';
import '../../../core/security/security.dart';
import '../../../core/storage/secure_storage.dart';

// =============================================================================
// MBOA HEALTH — Auth Provider
// Manages login, registration, and session restoration.
// OWASP A02: passwords are pre-hashed client-side before transmission.
// OWASP A07: brute-force protection via RateLimiter in the UI layer.
// =============================================================================

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = false;
  String? _error;

  AppUser? get user      => _user;
  bool     get isLoading => _loading;
  String?  get error     => _error;
  bool     get isLoggedIn => _user != null && AuthGuard.isAuthenticated;

  // ── Session restoration ────────────────────────────────────────────────────

  /// Called at app start — restores session from secure storage if the token
  /// is still valid by calling GET /api/auth/me.php.
  Future<bool> tryRestoreSession() async {
    String? token;
    try {
      token = await SecureStorage.getToken();
    } catch (_) {
      return false; // Web Crypto unavailable (HTTP) — no stored session
    }
    if (token == null) return false;

    // Temporarily put the token in AuthGuard memory so ApiClient can use it
    final role = await SecureStorage.getSavedRole().catchError((_) => null) ?? 'patient';
    AuthGuard.login(token: token, role: role);

    final result = await ApiClient.instance.get(ApiConfig.me);
    if (result is ApiSuccess<Map<String, dynamic>>) {
      _user = AppUser.fromJson(result.data);
      notifyListeners();
      return true;
    }

    // Token invalid / expired — clean up
    try {
      await SecureStorage.clearAll();
    } catch (_) {}
    AuthGuard.logout();
    return false;
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<String?> login({
    required String email,
    required String passwordHash, // SHA-256(salt:password) from the UI layer
  }) async {
    _setLoading(true);

    final result = await ApiClient.instance.post(
      ApiConfig.login,
      {'email': email, 'passwordHash': passwordHash},
      auth: false,
    );

    if (result is ApiSuccess<Map<String, dynamic>>) {
      await _persistSession(result.data);
      _setLoading(false);
      return null; // success
    }
    final err = (result as ApiFailure<Map<String, dynamic>>).message;
    _setError(err);
    return err;
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String passwordHash,
    required String salt,
    String role = 'patient',
  }) async {
    _setLoading(true);

    final result = await ApiClient.instance.post(
      ApiConfig.register,
      {
        'name':         name,
        'email':        email,
        'phone':        phone,
        'passwordHash': passwordHash,
        'salt':         salt,
        'role':         role,
      },
      auth: false,
    );

    if (result is ApiSuccess<Map<String, dynamic>>) {
      await _persistSession(result.data);
      _setLoading(false);
      return null; // success
    }
    final err = (result as ApiFailure<Map<String, dynamic>>).message;
    _setError(err);
    return err;
  }

  // ── Get Salt (needed before login) ────────────────────────────────────────

  /// Fetches the stored salt for [email].
  /// Returns the salt string or null if the request failed.
  Future<String?> fetchSalt(String email) async {
    final result = await ApiClient.instance.post(
      ApiConfig.getSalt,
      {'email': email},
      auth: false,
    );
    if (result is ApiSuccess<Map<String, dynamic>>) {
      return result.data['salt'] as String?;
    }
    return null;
  }

  // ── Forgot Password ──────────────────────────────────────────────────────

  /// Requests a 6-digit OTP to be sent to [email].
  /// Returns null on success, or an error message.
  Future<String?> forgotPassword(String email) async {
    final result = await ApiClient.instance.post(
      ApiConfig.forgotPassword,
      {'email': email},
      auth: false,
    );
    if (result is ApiSuccess<Map<String, dynamic>>) return null;
    return (result as ApiFailure<Map<String, dynamic>>).message;
  }

  // ── Reset Password ────────────────────────────────────────────────────────

  /// Verifies the OTP and updates the user's password.
  /// Returns null on success, or an error message.
  Future<String?> resetPassword({
    required String email,
    required String token,
    required String newPasswordHash,
    required String newSalt,
  }) async {
    final result = await ApiClient.instance.post(
      ApiConfig.resetPassword,
      {
        'email':           email,
        'token':           token,
        'newPasswordHash': newPasswordHash,
        'newSalt':         newSalt,
      },
      auth: false,
    );
    if (result is ApiSuccess<Map<String, dynamic>>) return null;
    return (result as ApiFailure<Map<String, dynamic>>).message;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _user = null;
    AuthGuard.logout();          // clear in-memory session
    try {
      await SecureStorage.clearAll(); // clear encrypted storage
    } catch (_) {}
    notifyListeners();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<void> _persistSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;
    _user = AppUser.fromJson(userJson);

    AuthGuard.login(token: token, role: _user!.role);
    // On web served over HTTP the Web Crypto API is unavailable, so
    // flutter_secure_storage throws. Catch it so the in-memory session
    // (AuthGuard) still works; the token just won't survive a page refresh.
    try {
      await SecureStorage.saveToken(token);
      await SecureStorage.saveSession(
        email: _user!.email,
        role:  _user!.role,
      );
    } catch (_) {
      // Storage unavailable (e.g. HTTP context) — session is memory-only.
    }
    notifyListeners();
  }

  void _setLoading(bool val) {
    _loading = val;
    _error   = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _loading = false;
    _error   = msg;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
