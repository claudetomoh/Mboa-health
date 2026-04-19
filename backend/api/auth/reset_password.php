<?php
// =============================================================================
// POST /api/auth/reset_password.php
// Body: { email, token, newPasswordHash, newSalt }
//
// Verifies the 6-digit OTP and replaces the user's password + salt.
// The client generates a new salt and pre-hashes the new password
// identically to registration: SHA-256(salt:password).
//
// OWASP A02: password_hash(bcrypt) on server, SHA-256 pre-hash from client.
// OWASP A07: generic error to prevent enumeration.
// =============================================================================
require_once __DIR__ . '/../../helpers.php';
require_once __DIR__ . '/../../db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error(405, 'Method not allowed.');

$body            = request_body();
$email           = validate_email(str_input($body, 'email'));
$token           = str_input($body, 'token');
$newPasswordHash = str_input($body, 'newPasswordHash');
$newSalt         = str_input($body, 'newSalt');

// Validate inputs
if (!$email || strlen($token) !== 6 || !ctype_digit($token)) {
    json_error(400, 'Invalid or expired reset code.');
}
if (strlen($newPasswordHash) < 32 || strlen($newSalt) < 8) {
    json_error(400, 'Invalid password data.');
}

$pdo = db();

// ── Verify token ──────────────────────────────────────────────────────────────
$stmt = $pdo->prepare(
    'SELECT id FROM password_resets
     WHERE email = ? AND token = ? AND used = 0 AND expires_at > NOW()
     ORDER BY id DESC LIMIT 1'
);
$stmt->execute([$email, $token]);
$reset = $stmt->fetch();

if (!$reset) {
    json_error(400, 'Invalid or expired reset code. Please request a new one.');
}

// ── Update password ───────────────────────────────────────────────────────────
// OWASP A02: bcrypt the pre-hash (cost factor 12)
$bcrypted = password_hash($newPasswordHash, PASSWORD_BCRYPT, ['cost' => 12]);

$pdo->prepare(
    'UPDATE users SET password_hash = ?, salt = ?, updated_at = NOW()
     WHERE email = ? AND is_active = 1'
)->execute([$bcrypted, $newSalt, $email]);

// ── Mark token as used ────────────────────────────────────────────────────────
$pdo->prepare('UPDATE password_resets SET used = 1 WHERE id = ?')
    ->execute([$reset['id']]);

json_ok(['message' => 'Password reset successfully. Please log in with your new password.']);
