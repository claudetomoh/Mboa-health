<?php
// =============================================================================
// Health Records — CRUD
// GET    /api/health_records/index.php        → list all for user
// GET    /api/health_records/index.php?id=X   → get one
// POST   /api/health_records/index.php        → create
// PUT    /api/health_records/index.php?id=X   → update
// DELETE /api/health_records/index.php?id=X   → delete (soft)
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
    if ($id > 0) {
        $stmt = $pdo->prepare(
            'SELECT id, type, title, doctor, facility, date, file_url, notes, created_at
             FROM health_records
             WHERE id = ? AND user_id = ? AND is_active = 1'
        );
        $stmt->execute([$id, $userId]);
        $row = $stmt->fetch();
        if (!$row) json_error(404, 'Record not found.');
        $row['id'] = (int)$row['id'];
        json_ok($row);
    }

    // List all
    $stmt = $pdo->prepare(
        'SELECT id, type, title, doctor, facility, date, file_url, notes, created_at
         FROM health_records
         WHERE user_id = ? AND is_active = 1
         ORDER BY date DESC, created_at DESC'
    );
    $stmt->execute([$userId]);
    $rows = $stmt->fetchAll();
    foreach ($rows as &$r) $r['id'] = (int)$r['id'];
    json_ok(['records' => $rows]);
}

// ─── POST ─────────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $body = request_body();

    $type     = str_input($body, 'type', 'other');
    $title    = str_input($body, 'title');
    $doctor   = str_input($body, 'doctor');
    $facility = str_input($body, 'facility');
    $date     = str_input($body, 'date');
    $fileUrl  = str_input($body, 'file_url');
    $notes    = str_input($body, 'notes');

    $validTypes = ['prescription','lab_result','x_ray','vaccination','consultation','surgery','other'];
    if (!in_array($type, $validTypes, true)) $type = 'other';
    if (!$title) json_error(422, 'Record title is required.');
    if (!$date || !DateTime::createFromFormat('Y-m-d', $date)) {
        json_error(422, 'A valid date (YYYY-MM-DD) is required.');
    }
    if ($fileUrl && !filter_var($fileUrl, FILTER_VALIDATE_URL)) {
        json_error(422, 'file_url must be a valid URL.');
    }

    $stmt = $pdo->prepare(
        'INSERT INTO health_records (user_id, type, title, doctor, facility, date, file_url, notes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
    );
    $stmt->execute([
        $userId, $type,
        $title,
        $doctor   ?: null,
        $facility ?: null,
        $date,
        $fileUrl  ?: null,
        $notes    ?: null,
    ]);
    $newId = (int)$pdo->lastInsertId();
    json_ok(['id' => $newId, 'message' => 'Record created successfully.'], 201);
}

// ─── PUT ─────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    if (!$id) json_error(400, 'Record ID is required (use ?id=X).');

    // Verify ownership
    $check = $pdo->prepare('SELECT id FROM health_records WHERE id = ? AND user_id = ? AND is_active = 1');
    $check->execute([$id, $userId]);
    if (!$check->fetch()) json_error(404, 'Record not found.');

    $body   = request_body();
    $fields = [];
    $params = [];

    foreach (['type','title','doctor','facility','date','file_url','notes'] as $f) {
        if (array_key_exists($f, $body)) {
            $val = str_input($body, $f);
            if ($f === 'type') {
                $valid = ['prescription','lab_result','x_ray','vaccination','consultation','surgery','other'];
                if (!in_array($val, $valid, true)) continue;
            }
            if (in_array($f, ['title','doctor','facility','notes'], true)) {
                $val = $val ?: null;
            }
            if ($f === 'file_url' && $val && !filter_var($val, FILTER_VALIDATE_URL)) {
                json_error(422, 'file_url must be a valid URL.');
            }
            $fields[] = "$f = ?";
            $params[] = $val ?: null;
        }
    }

    if (empty($fields)) json_error(422, 'No valid fields provided for update.');

    $params[] = $id;
    $params[] = $userId;
    $pdo->prepare('UPDATE health_records SET ' . implode(', ', $fields) .
                  ' WHERE id = ? AND user_id = ?')
        ->execute($params);

    json_ok(['message' => 'Record updated successfully.']);
}

// ─── DELETE ───────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    if (!$id) json_error(400, 'Record ID is required (use ?id=X).');

    $stmt = $pdo->prepare(
        'UPDATE health_records SET is_active = 0 WHERE id = ? AND user_id = ?'
    );
    $stmt->execute([$id, $userId]);
    if ($stmt->rowCount() === 0) json_error(404, 'Record not found.');
    json_ok(['message' => 'Record deleted successfully.']);
}

json_error(405, 'Method not allowed.');
