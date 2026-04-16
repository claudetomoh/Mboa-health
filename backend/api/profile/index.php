<?php
// =============================================================================
// Profile — GET / PUT
// GET /api/profile/index.php      → get current user's full profile
// PUT /api/profile/index.php      → update profile fields
// =============================================================================
require_once __DIR__ . '/../../helpers.php';
require_once __DIR__ . '/../../db.php';

$auth   = require_auth();
$userId = (int)$auth['user_id'];
$method = $_SERVER['REQUEST_METHOD'];
$pdo    = db();

// ─── GET ─────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    $stmt = $pdo->prepare(
        'SELECT id, full_name, email, phone, role, avatar_url, blood_type,
                allergies, created_at
         FROM users WHERE id = ? AND is_active = 1'
    );
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    if (!$user) json_error(404, 'User not found.');
    $user['id'] = (int)$user['id'];

    // Fetch stats
    $recCount = $pdo->prepare('SELECT COUNT(*) FROM health_records WHERE user_id = ? AND is_active = 1');
    $recCount->execute([$userId]);
    $remCount = $pdo->prepare('SELECT COUNT(*) FROM reminders WHERE user_id = ? AND is_active = 1');
    $remCount->execute([$userId]);
    $ecCount  = $pdo->prepare('SELECT COUNT(*) FROM emergency_contacts WHERE user_id = ?');
    $ecCount->execute([$userId]);

    $user['stats'] = [
        'health_records'      => (int)$recCount->fetchColumn(),
        'active_reminders'    => (int)$remCount->fetchColumn(),
        'emergency_contacts'  => (int)$ecCount->fetchColumn(),
    ];

    // Fetch emergency contacts
    $ecStmt = $pdo->prepare(
        'SELECT id, full_name, phone, relationship, is_primary
         FROM emergency_contacts WHERE user_id = ? ORDER BY is_primary DESC'
    );
    $ecStmt->execute([$userId]);
    $contacts = $ecStmt->fetchAll();
    foreach ($contacts as &$c) {
        $c['id']         = (int)$c['id'];
        $c['is_primary'] = (bool)$c['is_primary'];
    }
    $user['emergency_contacts'] = $contacts;

    json_ok($user);
}

// ─── PUT ─────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    $body   = request_body();
    $fields = [];
    $params = [];

    $allowed = ['full_name','phone','avatar_url','blood_type','allergies'];
    foreach ($allowed as $f) {
        if (!array_key_exists($f, $body)) continue;
        $val = str_input($body, $f);
        if ($f === 'full_name') {
            if (strlen($val) < 2 || strlen($val) > 100) continue;
        } elseif (in_array($f, ['allergies'], true)) {
            $val = $val ?: null;
        }
        $fields[] = "$f = ?";
        $params[] = $val ?: null;
    }

    if (empty($fields)) json_error(422, 'No valid fields provided for update.');

    $params[] = $userId;
    $pdo->prepare('UPDATE users SET ' . implode(', ', $fields) . ' WHERE id = ?')
        ->execute($params);

    json_ok(['message' => 'Profile updated successfully.']);
}

json_error(405, 'Method not allowed.');
