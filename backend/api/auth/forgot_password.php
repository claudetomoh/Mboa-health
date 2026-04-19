<?php
// =============================================================================
// POST /api/auth/forgot_password.php
// Body: { email }
//
// Generates a 6-digit OTP, stores it in password_resets (15-min expiry),
// and emails it to the user.
//
// OWASP A07: generic success response regardless of whether email exists
//            (prevents email enumeration).
// =============================================================================
require_once __DIR__ . '/../../helpers.php';
require_once __DIR__ . '/../../db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error(405, 'Method not allowed.');

$body  = request_body();
$email = validate_email(str_input($body, 'email'));

// Always return the same success message regardless of outcome (A07 anti-enum)
$genericOk = ['message' => 'If that email is registered, a reset code has been sent.'];

if (!$email) json_ok($genericOk);

$pdo = db();

// Check if user exists (silently skip if not — do NOT reveal)
$stmt = $pdo->prepare('SELECT id, full_name FROM users WHERE email = ? AND is_active = 1 LIMIT 1');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user) json_ok($genericOk); // email not found, but don't reveal that

// ── Rate-limit: max 3 codes per email per 15 minutes ─────────────────────────
$stmt = $pdo->prepare(
    'SELECT COUNT(*) FROM password_resets
     WHERE email = ? AND created_at > DATE_SUB(NOW(), INTERVAL 15 MINUTE)'
);
$stmt->execute([$email]);
if ((int)$stmt->fetchColumn() >= 3) {
    // Still return generic OK — no enumeration
    json_ok($genericOk);
}

// ── Generate 6-digit code ─────────────────────────────────────────────────────
$code      = str_pad((string)random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
$expiresAt = date('Y-m-d H:i:s', time() + 900); // 15 minutes

// ── Store code ────────────────────────────────────────────────────────────────
// Invalidate all previous unused codes for this email first
$pdo->prepare('UPDATE password_resets SET used = 1 WHERE email = ? AND used = 0')
    ->execute([$email]);

$pdo->prepare(
    'INSERT INTO password_resets (email, token, expires_at) VALUES (?, ?, ?)'
)->execute([$email, $code, $expiresAt]);

// ── Send email ────────────────────────────────────────────────────────────────
$name    = $user['full_name'];
$subject = 'Your Mboa Health password reset code';
$message = "Dear $name,\n\n"
         . "Your password reset code is: $code\n\n"
         . "This code expires in 15 minutes.\n\n"
         . "If you did not request this, please ignore this email.\n\n"
         . "— Mboa Health Team";

$headers = "From: no-reply@mboahealth.cm\r\n"
         . "Reply-To: support@mboahealth.cm\r\n"
         . "X-Mailer: PHP/" . PHP_VERSION;

@mail($email, $subject, $message, $headers);

json_ok($genericOk);
