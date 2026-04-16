// =============================================================================
// MBOA HEALTH — Auth Guard
// OWASP A01 – Broken Access Control
//
// Centralises session state and provides a single authoritative check
// before any authenticated route is accessed.  No route should be
// navigated to without calling [AuthGuard.isAuthenticated] first.
// =============================================================================

/// Manages an in-memory session after a successful login.
///
/// In a real backend integration replace [login] / [logout] with
/// secure token storage (flutter_secure_storage) and verify JWTs
/// server-side on every request.
class AuthGuard {
  AuthGuard._(); // singleton-like; state is static for simplicity.

  static bool _isLoggedIn = false;
  static String? _sessionToken;
  static DateTime? _sessionExpiry;
  static String? _userRole; // 'patient' | 'doctor' | 'admin'

  /// Default session duration (OWASP recommends short-lived tokens).
  static const Duration _sessionDuration = Duration(hours: 8);

  // ── State queries ──────────────────────────────────────────────────────────

  /// `true` when a non-expired session exists.
  static bool get isAuthenticated {
    if (!_isLoggedIn) return false;
    if (_sessionExpiry != null &&
        DateTime.now().isAfter(_sessionExpiry!)) {
      // Session expired — force log-out transparently (A01 / A07).
      logout();
      return false;
    }
    return true;
  }

  /// The authenticated user's role (null when not logged in).
  static String? get currentRole => _userRole;

  /// The raw session token (use for Authorization headers).
  static String? get sessionToken => _sessionToken;

  // ── Role-based access control (RBAC) ──────────────────────────────────────

  /// Returns `true` when the current user has [requiredRole].
  /// OWASP A01: every sensitive action should call this guard.
  static bool hasRole(String requiredRole) {
    if (!isAuthenticated) return false;
    return _userRole == requiredRole;
  }

  /// Returns `true` when the current user has any of [roles].
  static bool hasAnyRole(List<String> roles) {
    if (!isAuthenticated) return false;
    return roles.contains(_userRole);
  }

  // ── Session lifecycle ──────────────────────────────────────────────────────

  /// Call after a successful authentication response from the server.
  ///
  /// [token]    – opaque session token (JWT / UUID) from the back-end.
  /// [role]     – user's role string ('patient', 'doctor', etc.).
  static void login({required String token, String role = 'patient'}) {
    _isLoggedIn = true;
    _sessionToken = token;
    _userRole = role;
    _sessionExpiry = DateTime.now().add(_sessionDuration);
  }

  /// Invalidates the current session.
  /// OWASP A07: must clear ALL session data — not just a flag.
  static void logout() {
    _isLoggedIn = false;
    _sessionToken = null;
    _userRole = null;
    _sessionExpiry = null;
  }

  /// Extends the session by another [_sessionDuration] on user activity.
  /// OWASP A07: idle-timeout re-authentication policy.
  static void refreshSession() {
    if (_isLoggedIn) {
      _sessionExpiry = DateTime.now().add(_sessionDuration);
    }
  }

  /// How long until the current session expires.
  static Duration get timeUntilExpiry {
    if (_sessionExpiry == null) return Duration.zero;
    final diff = _sessionExpiry!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}
