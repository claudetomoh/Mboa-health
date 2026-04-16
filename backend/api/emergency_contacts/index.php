<?php
// =============================================================================
// Emergency Contacts — CRUD
// GET    /api/emergency_contacts/index.php        → list for user
// POST   /api/emergency_contacts/index.php        → create
// PUT    /api/emergency_contacts/index.php?id=X   → update
// DELETE /api/emergency_contacts/index.php?id=X   → delete
// =============================================================================
require_once __DIR__ . '/../../helpers.php';
require_once __DIR__ . '/../../db.php';

$auth   = require_auth();
$userId = (int)$auth['user_id'];
$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : 0;
$pdo    = db();

// ─── GET ─────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    $stmt = $pdo->prepare(
        'SELECT id, full_name, phone, relationship, is_primary
         FROM emergency_contacts
         WHERE user_id = ?
         ORDER BY is_primary DESC, full_name ASC'
    );
    $stmt->execute([$userId]);
    $rows = $stmt->fetchAll();
    foreach ($rows as &$r) {
        $r['id']         = (int)$r['id'];
        $r['is_primary'] = (bool)$r['is_primary'];
    }
    json_ok(['contacts' => $rows]);
}

// ─── POST ─────────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $body         = request_body();
    $fullName     = str_input($body, 'full_name');
    $phone        = str_input($body, 'phone');
    $relationship = str_input($body, 'relationship');
    $isPrimary    = isset($body['is_primary']) ? (bool)$body['is_primary'] : false;

    if (!$fullName) json_error(422, 'Contact name is required.');
    if (!$phone)    json_error(422, 'Contact phone number is required.');
    if (!preg_match('/^\+?[0-9]{7,15}$/', $phone)) {
        json_error(422, 'Phone number is invalid.');
}

    // Enforce only one primary contact per user
    if ($isPrimary) {
        $pdo->prepare('UPDATE emergency_contacts SET is_primary = 0 WHERE user_id = ?')
            ->execute([$userId]);
    }

    $stmt = $pdo->prepare(
        'INSERT INTO emergency_contacts (user_id, full_name, phone, relationship, is_primary)
         VALUES (?, ?, ?, ?, ?)'
    );
    $stmt->execute([
        $userId,
        $fullName,
        $phone,
        $relationship ?: null,
        $isPrimary ? 1 : 0,
    ]);
    json_ok(['id' => (int)$pdo->lastInsertId(), 'message' => 'Contact added.'], 201);
}

// ─── PUT ─────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    if (!$id) json_error(400, 'Contact ID required (use ?id=X).');

    $check = $pdo->prepare('SELECT id FROM emergency_contacts WHERE id = ? AND user_id = ?');
    $check->execute([$id, $userId]);
    if (!$check->fetch()) json_error(404, 'Contact not found.');

    $body   = request_body();
    $fields = [];
    $params = [];

    foreach (['full_name','phone','relationship'] as $f) {
        if (!array_key_exists($f, $body)) continue;
        $val = str_input($body, $f);
        if ($f !== 'phone') $val = $val ?: null;
        $fields[] = "$f = ?";
        $params[] = $val;
    }
    if (array_key_exists('is_primary', $body)) {
        $isPrimary = (bool)$body['is_primary'];
        if ($isPrimary) {
            $pdo->prepare('UPDATE emergency_contacts SET is_primary = 0 WHERE user_id = ?')
                ->execute([$userId]);
        }
        $fields[] = 'is_primary = ?';
        $params[] = $isPrimary ? 1 : 0;
    }

    if (empty($fields)) json_error(422, 'No fields to update.');

    $params[] = $id;
    $params[] = $userId;
    $pdo->prepare('UPDATE emergency_contacts SET ' . implode(', ', $fields) .
                  ' WHERE id = ? AND user_id = ?')
        ->execute($params);

    json_ok(['message' => 'Contact updated successfully.']);
}

// ─── DELETE ───────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    if (!$id) json_error(400, 'Contact ID required (use ?id=X).');
    $stmt = $pdo->prepare('DELETE FROM emergency_contacts WHERE id = ? AND user_id = ?');
    $stmt->execute([$id, $userId]);
    if ($stmt->rowCount() === 0) json_error(404, 'Contact not found.');
    json_ok(['message' => 'Contact deleted successfully.']);
}

json_error(405, 'Method not allowed.');
