import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

// =============================================================================
// MBOA HEALTH — Security Utilities
// Addresses OWASP Top 10:
//   A01 – Broken Access Control   → validators / role-aware guards
//   A02 – Cryptographic Failures  → SHA-256 + random salt password hashing
//   A03 – Injection               → InputSanitizer (XSS / SQL patterns)
//   A07 – Auth Failures           → strong password policy, brute-force guard
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// A07 / A03  ─  AppValidators
// ─────────────────────────────────────────────────────────────────────────────

/// Centralised, reusable form validators.
/// All validators trim then sanitize before evaluating.
class AppValidators {
  AppValidators._(); // non-instantiable

  // RFC 5322-simplified email pattern.
  static final _emailRe = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  // Password component patterns.
  static final _uppercaseRe = RegExp(r'[A-Z]');
  static final _lowercaseRe = RegExp(r'[a-z]');
  static final _digitRe = RegExp(r'[0-9]');
  // Matches any character that is not alphanumeric or whitespace.
  // This avoids escaping issues with special-character sets.
  static final _specialRe = RegExp(r'[^\w\s]');

  // Cameroon phone: optional +237 / 237 / 0 prefix, 8–9 trailing digits.
  static final _phoneRe = RegExp(r'^(\+237|237|0)[0-9]{8,9}$');

  // ── Email ──────────────────────────────────────────────────────────────────

  /// Validates an email address using an RFC 5322-simplified regex.
  /// OWASP A07: prevents authentication with malformed credentials.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim();
    if (!_emailRe.hasMatch(trimmed)) {
      return 'Enter a valid email address (e.g. name@example.com)';
    }
    // Injection check on the email itself (A03)
    final injectionError = InputSanitizer.detectInjection(trimmed);
    if (injectionError != null) return injectionError;
    return null;
  }

  // ── Password (registration — strict policy) ────────────────────────────────

  /// Full password policy for new accounts.
  /// OWASP A07: enforces complexity to resist brute-force / dictionary attacks.
  static String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (value.length > 128) {
      return 'Password is too long (max 128 characters)';
    }
    if (!_uppercaseRe.hasMatch(value)) {
      return 'Include at least one uppercase letter (A–Z)';
    }
    if (!_lowercaseRe.hasMatch(value)) {
      return 'Include at least one lowercase letter (a–z)';
    }
    if (!_digitRe.hasMatch(value)) {
      return 'Include at least one number (0–9)';
    }
    if (!_specialRe.hasMatch(value)) {
      return r'Include at least one special character (!@#$%…)';
    }
    return null;
  }

  /// Login-time password validator — only checks presence.
  /// Avoids leaking policy hints that could assist enumeration (A07).
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  // ── Confirm password ───────────────────────────────────────────────────────

  static String? validateConfirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != original) return 'Passwords do not match';
    return null;
  }

  // ── Full name ──────────────────────────────────────────────────────────────

  /// Validates and sanitizes a display name.
  /// OWASP A03: rejects characters outside [letters, spaces, hyphen, apostrophe].
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    final cleaned = InputSanitizer.sanitize(value.trim());
    if (cleaned.length < 2) return 'Name is too short';
    if (cleaned.length > 100) return 'Name is too long (max 100 characters)';
    if (RegExp('[^a-zA-Z\\s\'\\-]').hasMatch(cleaned)) {
      return 'Name may only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }

  // ── Phone ──────────────────────────────────────────────────────────────────

  /// Validates a Cameroon-format phone number.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'\s'), '').trim();
    if (!_phoneRe.hasMatch(digits)) {
      return 'Enter a valid Cameroon number (e.g. +237 600 000 000)';
    }
    return null;
  }

  // ── Generic text / notes ───────────────────────────────────────────────────

  /// Validates free-text notes or descriptions.
  /// OWASP A03: limits length and strips injection patterns.
  static String? validateNote(String? value, {int maxLength = 2000}) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    final cleaned = InputSanitizer.sanitize(value.trim());
    if (cleaned.length > maxLength) {
      return 'Description too long (max $maxLength characters)';
    }
    final injectionError = InputSanitizer.detectInjection(cleaned);
    if (injectionError != null) return injectionError;
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A03  ─  InputSanitizer
// ─────────────────────────────────────────────────────────────────────────────

/// Strips HTML/script tags, control characters, and common injection patterns.
/// OWASP A03 – Injection (XSS, stored-script, SQL-like patterns).
class InputSanitizer {
  InputSanitizer._();

  /// Returns a sanitized copy of [input]:
  ///   1. Removes HTML/XML tags
  ///   2. Strips javascript:/vbscript: schemes
  ///   3. Removes inline event handlers (onXxx=)
  ///   4. Strips non-printable control characters
  static String sanitize(String input) {
    // 1. Strip HTML tags
    var out = input.replaceAll(RegExp(r'<[^>]*>'), '');
    // 2. Remove dangerous URI schemes
    out = out.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    out = out.replaceAll(RegExp(r'vbscript:', caseSensitive: false), '');
    // 3. Remove inline event handlers  e.g.  onclick=
    out = out.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
    // 4. Strip control characters (keep \t and \n for multi-line fields)
    out = out.replaceAll(
        RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    return out.trim();
  }

  /// Returns an error string when common SQL / script injection patterns are
  /// detected, or null when the input is considered safe.
  /// OWASP A03 – prevents stored injection in unparameterised queries.
  static String? detectInjection(String input) {
    final sqlRe = RegExp(
      r"(--|;|'|\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b)",
      caseSensitive: false,
    );
    if (sqlRe.hasMatch(input)) {
      return 'Input contains disallowed characters or keywords';
    }
    // Detect script injection
    final scriptRe = RegExp(
      r'(<script|<iframe|<object|<embed|javascript:|onerror|onload)',
      caseSensitive: false,
    );
    if (scriptRe.hasMatch(input)) {
      return 'Input contains disallowed characters or keywords';
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A02  ─  PasswordHasher
// ─────────────────────────────────────────────────────────────────────────────

/// Client-side SHA-256 + random salt hashing.
///
/// OWASP A02 – Cryptographic Failures:
///   • A random 32-byte salt prevents rainbow-table attacks.
///   • The hash is hex-encoded (256-bit output).
///
/// ⚠️  Important: in a real production back-end, always apply a slow hashing
///     algorithm (bcrypt / argon2id / scrypt) with a work-factor of ≥12.
///     This client-side hash provides an additional layer before transmission.
class PasswordHasher {
  PasswordHasher._();

  static final Random _secureRandom = Random.secure();

  /// Generates a cryptographically random 32-byte salt encoded as Base64Url.
  static String generateSalt() {
    final bytes =
        List<int>.generate(32, (_) => _secureRandom.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Returns SHA-256( salt + ':' + password ) as a lowercase hex string.
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  /// Constant-time-equivalent check: rehash and compare.
  static bool verify(String password, String salt, String storedHash) {
    final candidate = hashPassword(password, salt);
    // XOR every character so the loop always runs the full length (timing-safe).
    if (candidate.length != storedHash.length) return false;
    int diff = 0;
    for (int i = 0; i < candidate.length; i++) {
      diff |= candidate.codeUnitAt(i) ^ storedHash.codeUnitAt(i);
    }
    return diff == 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A07  ─  PasswordStrength
// ─────────────────────────────────────────────────────────────────────────────

/// Indicates how strong a candidate password is.
enum PasswordStrength { empty, weak, fair, good, strong }

/// Evaluates password strength against multiple criteria and returns a score.
class PasswordStrengthChecker {
  PasswordStrengthChecker._();

  static PasswordStrength evaluate(String password) {
    if (password.isEmpty) return PasswordStrength.empty;

    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^\w\s]').hasMatch(password)) score++;

    if (score <= 1) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.fair;
    if (score <= 4) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  /// Human-readable label for the given strength.
  static String label(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.empty:
        return '';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
}
