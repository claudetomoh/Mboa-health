<?php
// =============================================================================
// POST /api/auth/login.php
// Body: { email, passwordHash }
// The client pre-hashes the password with the salt obtained from get_salt.php.
// =============================================================================
require_once __DIR__ . '/../../helpers.php';
require_once __DIR__ . '/../../db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error(405, 'Method not allowed.');

$body         = request_body();
$email        = validate_email(str_input($body, 'email'));
$passwordHash = str_input($body, 'passwordHash');

if (!$email || strlen($passwordHash) < 32) {
    // OWASP A07: generic message — never indicate which field is wrong
    json_error(401, 'Invalid email or password.');
}

$pdo = db();

// Fetch user — single query; do NOT split into "check email, then check pass"
$stmt = $pdo->prepare(
    'SELECT id, full_name, email, phone, password_hash, role,
            avatar_url, blood_type, allergies
     FROM users
     WHERE email = ? AND is_active = 1
     LIMIT 1'
);
$stmt->execute([$email]);
$user = $stmt->fetch();

// OWASP A07: always run password_verify even when no user found (prevent timing attacks)
$dummyHash = '$2y$12$ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ.';
$hashToCheck  = $user ? $user['password_hash'] : $dummyHash;
$isValid      = password_verify($passwordHash, $hashToCheck);

if (!$user || !$isValid) {
    json_error(401, 'Invalid email or password.');
}

// ── Issue JWT ─────────────────────────────────────────────────────────────────
$token = jwt_encode([
    'user_id' => (int)$user['id'],
    'email'   => $user['email'],
    'role'    => $user['role'],
    'iat'     => time(),
    'exp'     => time() + JWT_EXPIRY,
]);

json_ok([
    'token' => $token,
    'user'  => [
        'id'         => (int)$user['id'],
        'full_name'  => $user['full_name'],
        'email'      => $user['email'],
        'phone'      => $user['phone'],
        'role'       => $user['role'],
        'avatar_url' => $user['avatar_url'],
        'blood_type' => $user['blood_type'],
        'allergies'  => $user['allergies'],
    ],
]);
