<?php
// =============================================================================
// POST /api/auth/get_salt.php
// Returns the stored salt for an email — required for client-side password
// hashing before login. OWASP A07: generic response prevents user enumeration.
// =============================================================================
require_once __DIR__ . '/../../helpers.php';
require_once __DIR__ . '/../../db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error(405, 'Method not allowed.');

$body  = request_body();
$email = validate_email(str_input($body, 'email'));

if (!$email) json_error(400, 'A valid email is required.');

// OWASP A07: always return a valid-looking response to prevent user enumeration.
// If the email doesn't exist, return a deterministic dummy salt derived from
// the email so the response time is indistinguishable from a real hit.
$stmt = db()->prepare('SELECT salt FROM users WHERE email = ? AND is_active = 1 LIMIT 1');
$stmt->execute([$email]);
$row  = $stmt->fetch();

if ($row) {
    json_ok(['salt' => $row['salt']]);
} else {
    // Deterministic dummy salt (prevents timing-based enumeration)
    $dummySalt = base64_encode(hash_hmac('sha256', $email, JWT_SECRET, true));
    json_ok(['salt' => $dummySalt]);
}
