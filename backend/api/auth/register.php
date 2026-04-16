<?php
// =============================================================================
// POST /api/auth/register.php
// Body: { name, email, phone, passwordHash, salt, role? }
// The client sends SHA-256(salt:password) — we bcrypt that hash for storage.
// =============================================================================
require_once __DIR__ . '/../../helpers.php';
require_once __DIR__ . '/../../db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error(405, 'Method not allowed.');

$body = request_body();

// ── Validate inputs ───────────────────────────────────────────────────────────
$name         = str_input($body, 'name');
$email        = validate_email(str_input($body, 'email'));
$phone        = str_input($body, 'phone');
$passwordHash = str_input($body, 'passwordHash');
$salt         = str_input($body, 'salt');
$role         = str_input($body, 'role', 'patient');

if (!$name || strlen($name) < 2 || strlen($name) > 100) {
    json_error(422, 'Full name must be between 2 and 100 characters.');
}
if (!$email) {
    json_error(422, 'A valid email address is required.');
}
if (strlen($passwordHash) < 32) {
    json_error(422, 'Password hash is invalid.');
}
if (empty($salt)) {
    json_error(422, 'Password salt is required.');
}
if (!in_array($role, ['patient', 'doctor', 'admin'], true)) {
    $role = 'patient'; // default to patient if invalid
}
if ($phone && !preg_match('/^\+?[0-9]{7,15}$/', $phone)) {
    json_error(422, 'Phone number is invalid.');
}

// Strip any raw HTML tags from the name (keep apostrophes, quotes etc. as-is)
$name = strip_tags($name);

$pdo = db();

// ── Check for duplicate email (OWASP A07: generic error message) ──────────────
$stmt = $pdo->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
$stmt->execute([$email]);
if ($stmt->fetch()) {
    // OWASP A07: same message whether email exists or not
    json_error(409, 'An account with this email already exists.');
}

// ── Hash the received SHA-256 hash with bcrypt ────────────────────────────────
// Client sends SHA-256(salt:password); we bcrypt that before storing.
// OWASP A02: bcrypt with cost factor 12.
$storedHash = password_hash($passwordHash, PASSWORD_BCRYPT, ['cost' => 12]);
if ($storedHash === false) {
    error_log('[MboaHealth] password_hash failed for registration');
    json_error(500, 'Registration failed. Please try again.');
}

// ── Insert user ───────────────────────────────────────────────────────────────
$stmt = $pdo->prepare(
    'INSERT INTO users (full_name, email, phone, password_hash, salt, role)
     VALUES (?, ?, ?, ?, ?, ?)'
);
$stmt->execute([$name, $email, $phone ?: null, $storedHash, $salt, $role]);
$userId = (int)$pdo->lastInsertId();

// ── Create welcome notification ───────────────────────────────────────────────
$notifStmt = $pdo->prepare(
    'INSERT INTO notifications (user_id, type, title, body)
     VALUES (?, ?, ?, ?)'
);
$notifStmt->execute([
    $userId,
    'info',
    'Welcome to Mboa Health!',
    'Your account has been created successfully. Start by adding your health records or setting medication reminders.',
]);

// ── Issue JWT ─────────────────────────────────────────────────────────────────
$token = jwt_encode([
    'user_id' => $userId,
    'email'   => $email,
    'role'    => $role,
    'iat'     => time(),
    'exp'     => time() + JWT_EXPIRY,
]);

json_ok([
    'token' => $token,
    'user'  => [
        'id'        => $userId,
        'full_name' => $name,
        'email'     => $email,
        'phone'     => $phone ?: null,
        'role'      => $role,
        'avatar_url'=> null,
        'blood_type'=> null,
        'allergies' => null,
    ],
], 201);
