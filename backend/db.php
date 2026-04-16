<?php
// =============================================================================
// MBOA HEALTH — PDO Database Connection
// =============================================================================
require_once __DIR__ . '/config.php';

/**
 * Returns a singleton PDO connection.
 * All queries MUST use prepared statements (OWASP A03 — SQL Injection).
 */
function db(): PDO {
    static $pdo = null;
    if ($pdo !== null) return $pdo;

    $dsn = sprintf(
        'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
        DB_HOST, DB_PORT, DB_NAME
    );
    $options = [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,  // OWASP A03: native prepared stmts
        PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES 'utf8mb4'",
    ];

    try {
        $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
    } catch (PDOException $e) {
        // Never expose DB error details to the client (OWASP A05)
        error_log('[MboaHealth DB] Connection failed: ' . $e->getMessage());
        json_error(503, 'Database unavailable. Please try again later.');
    }
    return $pdo;
}
