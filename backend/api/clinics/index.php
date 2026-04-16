<?php
// =============================================================================
// Clinics — Read-only (seed data managed by admin)
// GET /api/clinics/index.php              → list / search
// GET /api/clinics/index.php?id=X         → clinic details
// Query params: ?q=search&city=Yaoundé&type=hospital
// =============================================================================
require_once __DIR__ . '/../../helpers.php';
require_once __DIR__ . '/../../db.php';

// Auth optional for reading clinics (makes UX easier before login)
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? apache_request_headers()['Authorization'] ?? '';
if (str_starts_with($authHeader, 'Bearer ')) {
    $payload = jwt_decode(substr($authHeader, 7));
    // Silently ignore invalid token for this endpoint
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') json_error(405, 'Method not allowed.');

$pdo = db();
$id  = isset($_GET['id']) ? (int)$_GET['id'] : 0;

// ─── Single clinic ────────────────────────────────────────────────────────────
if ($id > 0) {
    $stmt = $pdo->prepare(
        'SELECT id, name, address, city, country, latitude, longitude,
                phone, email, website, type, rating, is_24h, hours, services
         FROM clinics WHERE id = ? AND is_active = 1'
    );
    $stmt->execute([$id]);
    $clinic = $stmt->fetch();
    if (!$clinic) json_error(404, 'Clinic not found.');
    $clinic['id']     = (int)$clinic['id'];
    $clinic['is_24h'] = (bool)$clinic['is_24h'];
    $clinic['rating'] = $clinic['rating'] ? (float)$clinic['rating'] : null;
    $clinic['services'] = $clinic['services']
        ? array_map('trim', explode(',', $clinic['services']))
        : [];
    json_ok($clinic);
}

// ─── List / search ────────────────────────────────────────────────────────────
$where  = ['is_active = 1'];
$params = [];

$q    = isset($_GET['q'])    ? trim($_GET['q'])    : '';
$city = isset($_GET['city']) ? trim($_GET['city']) : '';
$type = isset($_GET['type']) ? trim($_GET['type']) : '';

if ($q !== '') {
    $where[]  = '(name LIKE ? OR address LIKE ? OR services LIKE ?)';
    $like     = '%' . $q . '%';
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}
if ($city !== '') {
    $where[]  = 'city = ?';
    $params[] = $city;
}
$validTypes = ['hospital','clinic','pharmacy','laboratory','specialist','dental','eye_care','other'];
if ($type !== '' && in_array($type, $validTypes, true)) {
    $where[]  = 'type = ?';
    $params[] = $type;
}

$sql = 'SELECT id, name, address, city, type, rating, is_24h, hours, phone, latitude, longitude
        FROM clinics
        WHERE ' . implode(' AND ', $where) . '
        ORDER BY rating DESC, name ASC
        LIMIT 50';

$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$clinics = $stmt->fetchAll();

foreach ($clinics as &$c) {
    $c['id']     = (int)$c['id'];
    $c['is_24h'] = (bool)$c['is_24h'];
    $c['rating'] = $c['rating'] ? (float)$c['rating'] : null;
}

json_ok(['clinics' => $clinics]);
