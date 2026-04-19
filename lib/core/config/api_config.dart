/// API configuration — single place to change the server URL.
/// Update [baseUrl] to match your deployment environment.
abstract final class ApiConfig {
  /// Base URL for all API calls.
  /// The Flutter app uploads to mboa_api/ in the server's public_html.
  static const String baseUrl =
      'http://169.239.251.102:280/~tomoh.ikfingeh/mboa_api';

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String getSalt   = '$baseUrl/api/auth/get_salt.php';
  static const String login     = '$baseUrl/api/auth/login.php';
  static const String register  = '$baseUrl/api/auth/register.php';
  static const String me             = '$baseUrl/api/auth/me.php';
  static const String forgotPassword = '$baseUrl/api/auth/forgot_password.php';
  static const String resetPassword  = '$baseUrl/api/auth/reset_password.php';

  // ── Health Records ─────────────────────────────────────────────────────────
  static const String healthRecords = '$baseUrl/api/health_records/index.php';

  // ── Reminders ─────────────────────────────────────────────────────────────
  static const String reminders = '$baseUrl/api/reminders/index.php';

  // ── Clinics ────────────────────────────────────────────────────────────────
  static const String clinics = '$baseUrl/api/clinics/index.php';

  // ── Profile ────────────────────────────────────────────────────────────────
  static const String profile       = '$baseUrl/api/profile/index.php';
  static const String uploadAvatar  = '$baseUrl/api/profile/upload_avatar.php';

  // ── Notifications ──────────────────────────────────────────────────────────
  static const String notifications = '$baseUrl/api/notifications/index.php';

  // ── Emergency Contacts ─────────────────────────────────────────────────────
  static const String emergencyContacts =
      '$baseUrl/api/emergency_contacts/index.php';

  /// Request timeout duration.
  static const Duration timeout = Duration(seconds: 20);
}
