<?php
// =============================================================================
// Emergency Passport — public read-only view (CC-05A)
// GET /api/passport/view.php?token=<64-char-hex-token>
//
// No authentication. Lookup by token only — never by user id. Per
// DECISIONS.md ADR-001, this file is intentionally separate from the
// authenticated lifecycle endpoint (backend/api/passport/index.php, CC-04)
// and must never become a shared router with it.
//
// Response is a fixed whitelist only: full_name, date_of_birth, blood_type,
// allergies, emergency_contact_name, emergency_contact_phone, last_updated.
// date_of_birth has no source anywhere in the current schema and is always
// returned as null until that gap is resolved in a future, explicitly
// approved task (see CC-05A deliverables — schema expansion was deferred).
// =============================================================================
require_once __DIR__ . '/../../helpers.php';
require_once __DIR__ . '/../../db.php';

// OWASP A02/A05 — this response carries live medical data and must never be
// cached by a browser, proxy, or CDN.
header('Cache-Control: no-store');
header('Pragma: no-cache');

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_error(405, 'Method not allowed.');
}

$token = isset($_GET['token']) ? (string)$_GET['token'] : '';

// Token shape must exactly match generate_secure_token()'s output format
// (32 random bytes, hex-encoded = 64 lowercase hex characters). Anything
// else — missing, wrong length, non-hex — is rejected before it ever
// reaches a query.
if (!preg_match('/^[0-9a-f]{64}$/', $token)) {
    json_error(400, 'Invalid passport token.');
}

$pdo = db();

/**
 * Looks up a passport strictly by token. Returns null if no such token
 * exists, or if the owning account has been deactivated — both cases are
 * reported identically to the caller (404) so neither is distinguishable
 * from the other. Never selects any id column.
 */
function find_passport_for_token(PDO $pdo, string $token): ?array {
    $stmt = $pdo->prepare(
        'SELECT p.is_active AS passport_active, p.user_id,
                u.full_name, u.blood_type, u.allergies, u.updated_at
         FROM emergency_passports p
         JOIN users u ON u.id = p.user_id AND u.is_active = 1
         WHERE p.token = ?'
    );
    $stmt->execute([$token]);
    $row = $stmt->fetch();
    return $row ?: null;
}

/**
 * Returns the primary emergency contact for $userId (falling back to the
 * first contact alphabetically if none is flagged primary), or null if
 * there are none. Never selects the contact's id.
 */
function find_primary_contact(PDO $pdo, int $userId): ?array {
    $stmt = $pdo->prepare(
        'SELECT full_name, phone FROM emergency_contacts
         WHERE user_id = ? ORDER BY is_primary DESC, full_name ASC LIMIT 1'
    );
    $stmt->execute([$userId]);
    $row = $stmt->fetch();
    return $row ?: null;
}

// $userId below is used only as an internal join key for the contact
// lookup — it is never placed into the response payload.
$passport = find_passport_for_token($pdo, $token);
if (!$passport) {
    json_error(404, 'Passport not found.');
}
if (!$passport['passport_active']) {
    json_error(410, 'This passport has been disabled.');
}

$contact = find_primary_contact($pdo, (int)$passport['user_id']);

// Fixed whitelist only — never add a field here without updating the
// approved specification first.
json_ok([
    'full_name'               => $passport['full_name'],
    'date_of_birth'           => null, // no source in schema — see DECISIONS.md
    'blood_type'              => $passport['blood_type'],
    'allergies'               => $passport['allergies'],
    'emergency_contact_name'  => $contact['full_name'] ?? null,
    'emergency_contact_phone' => $contact['phone'] ?? null,
    'last_updated'            => $passport['updated_at'],
]);
