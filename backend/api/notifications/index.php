<?php
// =============================================================================
// Notifications
// GET  /api/notifications/index.php               → list for user (newest first)
// POST /api/notifications/index.php?action=mark_read&id=X  → mark one read
// POST /api/notifications/index.php?action=mark_all_read   → mark all read
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
        'SELECT id, type, title, body, is_read, created_at
         FROM notifications
         WHERE user_id = ?
         ORDER BY created_at DESC
         LIMIT 50'
    );
    $stmt->execute([$userId]);
    $rows = $stmt->fetchAll();

    $unread = 0;
    foreach ($rows as &$r) {
        $r['id']      = (int)$r['id'];
        $r['is_read'] = (bool)$r['is_read'];
        if (!$r['is_read']) $unread++;
    }

    json_ok(['notifications' => $rows, 'unread_count' => $unread]);
}

// ─── POST ─────────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $action = isset($_GET['action']) ? $_GET['action'] : '';

    if ($action === 'mark_all_read') {
        $pdo->prepare('UPDATE notifications SET is_read = 1 WHERE user_id = ?')
            ->execute([$userId]);
        json_ok(['message' => 'All notifications marked as read.']);
    }

    if ($action === 'mark_read') {
        $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
        if (!$id) json_error(400, 'Notification ID required.');
        $stmt = $pdo->prepare(
            'UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?'
        );
        $stmt->execute([$id, $userId]);
        if ($stmt->rowCount() === 0) json_error(404, 'Notification not found.');
        json_ok(['message' => 'Notification marked as read.']);
    }

    json_error(400, 'Unknown action. Use mark_read or mark_all_read.');
}

json_error(405, 'Method not allowed.');
