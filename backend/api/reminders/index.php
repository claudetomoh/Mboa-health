<?php
// =============================================================================
// Reminders — CRUD
// GET    /api/reminders/index.php        → list all for user
// GET    /api/reminders/index.php?id=X   → get one
// POST   /api/reminders/index.php        → create
// PUT    /api/reminders/index.php?id=X   → update (including toggle active)
// DELETE /api/reminders/index.php?id=X   → delete
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
            'SELECT id, medication_name, dosage, frequency, reminder_time,
                    days_of_week, is_active, start_date, end_date, notes, created_at
             FROM reminders WHERE id = ? AND user_id = ?'
        );
        $stmt->execute([$id, $userId]);
        $row = $stmt->fetch();
        if (!$row) json_error(404, 'Reminder not found.');
        $row['id']        = (int)$row['id'];
        $row['is_active'] = (bool)$row['is_active'];
        json_ok($row);
    }

    $stmt = $pdo->prepare(
        'SELECT id, medication_name, dosage, frequency, reminder_time,
                days_of_week, is_active, start_date, end_date, notes, created_at
         FROM reminders
         WHERE user_id = ?
         ORDER BY is_active DESC, reminder_time ASC'
    );
    $stmt->execute([$userId]);
    $rows = $stmt->fetchAll();
    foreach ($rows as &$r) {
        $r['id']        = (int)$r['id'];
        $r['is_active'] = (bool)$r['is_active'];
    }
    json_ok(['reminders' => $rows]);
}

// ─── POST ─────────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $body = request_body();

    $medName   = str_input($body, 'medication_name');
    $dosage    = str_input($body, 'dosage');
    $frequency = str_input($body, 'frequency', 'daily');
    $time      = str_input($body, 'reminder_time');
    $days      = str_input($body, 'days_of_week');
    $startDate = str_input($body, 'start_date');
    $endDate   = str_input($body, 'end_date');
    $notes     = str_input($body, 'notes');

    if (!$medName) json_error(422, 'Medication name is required.');
    if (!$time)    json_error(422, 'Reminder time is required.');

    $validFreqs = ['daily','twice_daily','thrice_daily','weekly','as_needed'];
    if (!in_array($frequency, $validFreqs, true)) $frequency = 'daily';

    $stmt = $pdo->prepare(
        'INSERT INTO reminders
            (user_id, medication_name, dosage, frequency, reminder_time,
             days_of_week, start_date, end_date, notes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
    );
    $stmt->execute([
        $userId,
        $medName,
        $dosage    ?: null,
        $frequency, $time,
        $days      ?: null,
        $startDate ?: null,
        $endDate   ?: null,
        $notes     ?: null,
    ]);
    $newId = (int)$pdo->lastInsertId();

    // Auto-notification
    $pdo->prepare(
        'INSERT INTO notifications (user_id, type, title, body) VALUES (?, ?, ?, ?)'
    )->execute([
        $userId, 'reminder',
        "Reminder set: $medName",
        "You'll be reminded to take $medName at $time.",
    ]);

    json_ok(['id' => $newId, 'message' => 'Reminder created successfully.'], 201);
}

// ─── PUT ─────────────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    if (!$id) json_error(400, 'Reminder ID is required (use ?id=X).');

    $check = $pdo->prepare('SELECT id FROM reminders WHERE id = ? AND user_id = ?');
    $check->execute([$id, $userId]);
    if (!$check->fetch()) json_error(404, 'Reminder not found.');

    $body   = request_body();
    $fields = [];
    $params = [];

    $allowed = ['medication_name','dosage','frequency','reminder_time',
                'days_of_week','is_active','start_date','end_date','notes'];
    foreach ($allowed as $f) {
        if (!array_key_exists($f, $body)) continue;
        if ($f === 'is_active') {
            $fields[] = "$f = ?";
            $params[] = $body[$f] ? 1 : 0;
        } elseif ($f === 'frequency') {
            $val = str_input($body, $f, 'daily');
            $validFreqs = ['daily','twice_daily','thrice_daily','weekly','as_needed'];
            if (!in_array($val, $validFreqs, true)) $val = 'daily';
            $fields[] = "$f = ?";
            $params[] = $val;
        } else {
            $val = str_input($body, $f);
            $fields[] = "$f = ?";
            $params[] = $val ?: null;
        }
    }

    if (empty($fields)) json_error(422, 'No valid fields provided for update.');

    $params[] = $id;
    $params[] = $userId;
    $pdo->prepare('UPDATE reminders SET ' . implode(', ', $fields) .
                  ' WHERE id = ? AND user_id = ?')
        ->execute($params);

    json_ok(['message' => 'Reminder updated successfully.']);
}

// ─── DELETE ───────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    if (!$id) json_error(400, 'Reminder ID is required (use ?id=X).');

    $stmt = $pdo->prepare('DELETE FROM reminders WHERE id = ? AND user_id = ?');
    $stmt->execute([$id, $userId]);
    if ($stmt->rowCount() === 0) json_error(404, 'Reminder not found.');
    json_ok(['message' => 'Reminder deleted successfully.']);
}

json_error(405, 'Method not allowed.');
