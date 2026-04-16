// =============================================================================
// MBOA HEALTH — Rate Limiter
// OWASP A07 – Identification and Authentication Failures
//
// Prevents brute-force and credential-stuffing attacks by locking an
// identifier (email / device key) after [maxAttempts] failed attempts
// within a rolling [windowDuration].
// =============================================================================

/// In-memory rate limiter.
///
/// Usage (in your login controller / screen):
/// ```dart
/// final _limiter = RateLimiter();
///
/// void onLoginFailed(String email) {
///   final remaining = _limiter.recordFailure(email);
///   if (_limiter.isLockedOut(email)) {
///     // Show lockout message
///   } else {
///     // Show "X attempts remaining" warning
///   }
/// }
///
/// void onLoginSuccess(String email) {
///   _limiter.recordSuccess(email);
/// }
/// ```
class RateLimiter {
  RateLimiter({
    this.maxAttempts = 5,
    this.windowDuration = const Duration(minutes: 15),
    this.lockoutDuration = const Duration(minutes: 30),
  });

  /// Maximum consecutive failures before lockout.
  final int maxAttempts;

  /// Sliding window within which [maxAttempts] counts.
  final Duration windowDuration;

  /// How long the account stays locked after exceeding [maxAttempts].
  final Duration lockoutDuration;

  final Map<String, _AttemptRecord> _records = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns `true` when [identifier] is currently locked out.
  bool isLockedOut(String identifier) {
    final record = _records[identifier];
    if (record == null) return false;
    if (record.lockedUntil != null &&
        DateTime.now().isBefore(record.lockedUntil!)) {
      return true;
    }
    // Auto-clear an expired lockout.
    if (record.lockedUntil != null) _records.remove(identifier);
    return false;
  }

  /// How long until the lockout for [identifier] expires.
  /// Returns [Duration.zero] when not locked out.
  Duration remainingLockout(String identifier) {
    final record = _records[identifier];
    if (record?.lockedUntil == null) return Duration.zero;
    final diff = record!.lockedUntil!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Records one failed attempt for [identifier].
  /// Returns the number of remaining attempts before lockout.
  int recordFailure(String identifier) {
    final now = DateTime.now();
    final existing = _records[identifier];

    if (existing == null ||
        now.difference(existing.firstAttempt) > windowDuration) {
      // Start a fresh window.
      _records[identifier] =
          _AttemptRecord(firstAttempt: now, count: 1);
      return maxAttempts - 1;
    }

    existing.count++;
    if (existing.count >= maxAttempts) {
      existing.lockedUntil = now.add(lockoutDuration);
    }
    return (maxAttempts - existing.count).clamp(0, maxAttempts);
  }

  /// Resets the failure record for [identifier] after a successful login.
  void recordSuccess(String identifier) => _records.remove(identifier);

  /// Number of failed attempts recorded for [identifier] in the current window.
  int attemptsUsed(String identifier) =>
      _records[identifier]?.count ?? 0;

  /// Completely clears all stored records (useful for testing / sign-out).
  void clearAll() => _records.clear();
}

// ── Private data class ─────────────────────────────────────────────────────

class _AttemptRecord {
  _AttemptRecord({
    required this.firstAttempt,
    this.count = 0,
  });

  final DateTime firstAttempt;
  int count;
  DateTime? lockedUntil; // set directly after reaching maxAttempts
}
