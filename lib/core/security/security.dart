// Security module barrel — import everything with one line:
//
// ```dart
// import 'package:mboa_health/core/security/security.dart';
// ```
//
// Covers OWASP Top 10 concerns relevant to a Flutter client:
//   A01 – Broken Access Control   → [AuthGuard]
//   A02 – Cryptographic Failures  → [PasswordHasher]
//   A03 – Injection               → [InputSanitizer]
//   A07 – Auth Failures           → [AppValidators], [RateLimiter],
//                                   [PasswordStrengthChecker]
export 'auth_guard.dart';
export 'rate_limiter.dart';
export 'security_utils.dart';
