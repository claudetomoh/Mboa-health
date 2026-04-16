<?php
// =============================================================================
// GET /api/auth/me.php
// Returns the authenticated user's profile. Used by the app on startup
// to validate the stored token and restore session state.
// =============================================================================
require_once __DIR__ . '/../../helpers.php';
require_once __DIR__ . '/../../db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') json_error(405, 'Method not allowed.');

$auth = require_auth(); // terminates with 401 if invalid

$stmt = db()->prepare(
    'SELECT id, full_name, email, phone, role, avatar_url, blood_type, allergies
     FROM users
     WHERE id = ? AND is_active = 1
     LIMIT 1'
);
$stmt->execute([$auth['user_id']]);
$user = $stmt->fetch();

if (!$user) json_error(404, 'User not found.');

json_ok([
    'id'         => (int)$user['id'],
    'full_name'  => $user['full_name'],
    'email'      => $user['email'],
    'phone'      => $user['phone'],
    'role'       => $user['role'],
    'avatar_url' => $user['avatar_url'],
    'blood_type' => $user['blood_type'],
    'allergies'  => $user['allergies'],
]);
