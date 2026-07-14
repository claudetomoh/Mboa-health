<?php
// =============================================================================
// Emergency Passport — authenticated lifecycle (backend foundation only)
// GET  /api/passport/index.php                     → current passport status
// POST /api/passport/index.php?action=create        → create a new passport (409 if one already exists)
// POST /api/passport/index.php?action=enable         → reactivate a disabled passport, new token
// POST /api/passport/index.php?action=regenerate     → issue a new token, same passport
// POST /api/passport/index.php?action=disable         → disable the current passport
//
// No public read endpoint exists here. Per DECISIONS.md ADR-001, the public
// passport-view endpoint (looked up by token only, never by user_id) belongs
// in its own separate file, added in a later task — never a shared router
// with these authenticated actions.
// =============================================================================
require_once __DIR__ . '/../../helpers.php';
require_once __DIR__ . '/../../db.php';

$auth   = require_auth();
$userId = (int)$auth['user_id'];
$method = $_SERVER['REQUEST_METHOD'];
$pdo    = db();

/**
 * Returns the caller's passport row, or null if none exists.
 * Never selects the internal `id` column — nothing here should leak a
 * database row id, user id, or profile id back to the client.
 */
function find_passport(PDO $pdo, int $userId): ?array {
    $stmt = $pdo->prepare(
        'SELECT token, is_active, created_at, updated_at, disabled_at
         FROM emergency_passports WHERE user_id = ?'
    );
    $stmt->execute([$userId]);
    $row = $stmt->fetch();
    return $row ?: null;
}

function passport_payload(array $row): array {
    return [
        'exists'      => true,
        'token'       => $row['token'],
        'is_active'   => (bool)$row['is_active'],
        'created_at'  => $row['created_at'],
        'updated_at'  => $row['updated_at'],
        'disabled_at' => $row['disabled_at'],
    ];
}

/**
 * True when a 23000 integrity-constraint violation was specifically a
 * UNIQUE(token) collision, identified by the failing index name
 * (`idx_token`) in the driver error message — not a UNIQUE(user_id) clash.
 */
function is_token_collision(PDOException $e): bool {
    if ($e->getCode() !== '23000') return false;
    $message = $e->errorInfo[2] ?? $e->getMessage();
    return str_contains($message, 'idx_token');
}

/**
 * Writes a fresh secure token via $write($token), retrying ONLY when the
 * failure is a UNIQUE(token) collision (astronomically unlikely, but a new
 * token fixes it). Any other integrity-constraint violation — in particular
 * UNIQUE(user_id) — is not retried, since a new token cannot fix it; it is
 * rethrown for the caller to translate into the correct error.
 */
function write_with_fresh_token(callable $write): void {
    for ($attempt = 0; $attempt < 5; $attempt++) {
        $token = generate_secure_token();
        try {
            $write($token);
            return;
        } catch (PDOException $e) {
            if ($attempt < 4 && is_token_collision($e)) continue;
            throw $e;
        }
    }
}

// ─── GET — current status ──────────────────────────────────────────────────
if ($method === 'GET') {
    $row = find_passport($pdo, $userId);
    if (!$row) json_ok(['exists' => false]);
    json_ok(passport_payload($row));
}

// ─── POST — lifecycle actions ───────────────────────────────────────────────
if ($method === 'POST') {
    $action = $_GET['action'] ?? '';

    // ── create: makes a brand-new passport only. If one already exists
    //    (active or disabled), this is a 409 — use `enable` to reactivate.
    if ($action === 'create') {
        $existing = find_passport($pdo, $userId);
        if ($existing) {
            json_error(409, 'A passport already exists for this account.');
        }

        try {
            write_with_fresh_token(function (string $token) use ($pdo, $userId): void {
                $stmt = $pdo->prepare(
                    'INSERT INTO emergency_passports (user_id, token, is_active)
                     VALUES (?, ?, 1)'
                );
                $stmt->execute([$userId, $token]);
            });
        } catch (PDOException $e) {
            // Not a token collision (those are retried) — this is a
            // UNIQUE(user_id) race: another request created one first.
            if ($e->getCode() === '23000' && !is_token_collision($e)) {
                json_error(409, 'A passport already exists for this account.');
            }
            throw $e;
        }

        json_ok(passport_payload(find_passport($pdo, $userId)), 201);
    }

    // ── enable: reactivates a disabled passport with a brand-new token.
    //    The previous token is never reused (it may already be exposed).
    if ($action === 'enable') {
        $existing = find_passport($pdo, $userId);
        if (!$existing) {
            json_error(404, 'No passport exists for this account. Create one first.');
        }
        if ($existing['is_active']) {
            json_error(409, 'Passport is already active.');
        }

        write_with_fresh_token(function (string $token) use ($pdo, $userId): void {
            $stmt = $pdo->prepare(
                'UPDATE emergency_passports
                 SET token = ?, is_active = 1, disabled_at = NULL
                 WHERE user_id = ?'
            );
            $stmt->execute([$token, $userId]);
        });

        json_ok(passport_payload(find_passport($pdo, $userId)));
    }

    // ── regenerate: issues a new token for an existing, active passport.
    if ($action === 'regenerate') {
        $existing = find_passport($pdo, $userId);
        if (!$existing) {
            json_error(404, 'No passport exists for this account. Create one first.');
        }
        if (!$existing['is_active']) {
            json_error(409, 'Passport is disabled and cannot be regenerated. Create a new one instead.');
        }

        write_with_fresh_token(function (string $token) use ($pdo, $userId): void {
            $stmt = $pdo->prepare(
                'UPDATE emergency_passports SET token = ? WHERE user_id = ?'
            );
            $stmt->execute([$token, $userId]);
        });

        json_ok(passport_payload(find_passport($pdo, $userId)));
    }

    // ── disable: deactivates the current passport. Idempotent.
    if ($action === 'disable') {
        $existing = find_passport($pdo, $userId);
        if (!$existing) {
            json_error(404, 'No passport exists for this account.');
        }
        if (!$existing['is_active']) {
            json_ok(passport_payload($existing)); // already disabled — no-op
        }

        $stmt = $pdo->prepare(
            'UPDATE emergency_passports
             SET is_active = 0, disabled_at = NOW()
             WHERE user_id = ?'
        );
        $stmt->execute([$userId]);

        json_ok(passport_payload(find_passport($pdo, $userId)));
    }

    json_error(400, 'Unknown action. Use create, enable, regenerate, or disable.');
}

json_error(405, 'Method not allowed.');
