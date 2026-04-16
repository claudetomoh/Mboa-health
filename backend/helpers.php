<?php
// =============================================================================
// MBOA HEALTH — Helpers: JWT, HTTP responses, input validation, auth middleware
// =============================================================================
require_once __DIR__ . '/config.php';

// ─── CORS + JSON Headers ──────────────────────────────────────────────────────
function send_cors_headers(): void {
    header('Access-Control-Allow-Origin: ' . CORS_ORIGIN);
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
    header('Access-Control-Max-Age: 86400');
    header('Content-Type: application/json; charset=utf-8');
    // OWASP A05 — remove server fingerprinting headers
    header_remove('X-Powered-By');
    header_remove('Server');
}

// Handle CORS preflight immediately
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    send_cors_headers();
    http_response_code(204);
    exit;
}

send_cors_headers();

// ─── JSON Response Helpers ────────────────────────────────────────────────────
function json_ok(array $data = [], int $code = 200): never {
    http_response_code($code);
    echo json_encode(['success' => true, 'data' => $data]);
    exit;
}

function json_error(int $code, string $message, array $extra = []): never {
    http_response_code($code);
    echo json_encode(['success' => false, 'message' => $message] + $extra);
    exit;
}

// ─── JWT (pure PHP, no libraries) ────────────────────────────────────────────

function base64url_encode(string $data): string {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64url_decode(string $data): string {
    return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', (4 - strlen($data) % 4) % 4));
}

/**
 * Encodes a JWT using HMAC-SHA256.
 * OWASP A02 — always use a strong algorithm; never use 'none'.
 */
function jwt_encode(array $payload): string {
    $header  = base64url_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $claims  = base64url_encode(json_encode($payload));
    $sig     = base64url_encode(hash_hmac('sha256', "$header.$claims", JWT_SECRET, true));
    return "$header.$claims.$sig";
}

/**
 * Decodes and validates a JWT. Returns the payload array, or null on failure.
 * OWASP A02 — verifies signature with hash_equals (timing-safe).
 */
function jwt_decode(string $token): ?array {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;

    [$header, $claims, $sig] = $parts;

    // Verify algorithm header
    $hdr = json_decode(base64url_decode($header), true);
    if (!isset($hdr['alg']) || $hdr['alg'] !== 'HS256') return null;

    // Verify signature (timing-safe)
    $expectedSig = base64url_encode(hash_hmac('sha256', "$header.$claims", JWT_SECRET, true));
    if (!hash_equals($expectedSig, $sig)) return null;

    $payload = json_decode(base64url_decode($claims), true);
    if (!is_array($payload)) return null;

    // Check expiry
    if (isset($payload['exp']) && $payload['exp'] < time()) return null;

    return $payload;
}

// ─── Auth Middleware ──────────────────────────────────────────────────────────

/**
 * Extracts the JWT from the Authorization header, validates it,
 * and returns the payload. Terminates with 401 on failure.
 * OWASP A01 — every protected endpoint MUST call this.
 */
function require_auth(): array {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION']
                  ?? apache_request_headers()['Authorization']
                  ?? '';

    if (!str_starts_with($authHeader, 'Bearer ')) {
        json_error(401, 'Authentication required. Please log in.');
    }

    $token   = substr($authHeader, 7);
    $payload = jwt_decode($token);

    if ($payload === null) {
        json_error(401, 'Session expired or invalid. Please log in again.');
    }

    return $payload; // ['user_id' => X, 'email' => '...', 'role' => '...', ...]
}

// ─── Input Helpers ────────────────────────────────────────────────────────────

/**
 * Reads and decodes the JSON request body.
 * Returns an empty array if the body is absent or malformed.
 */
function request_body(): array {
    $raw = file_get_contents('php://input');
    if (empty($raw)) return [];
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}

/**
 * Returns a trimmed string from $data[$key], or $default if absent/empty.
 * OWASP A03 — always sanitize input before use in queries.
 */
function str_input(array $data, string $key, string $default = ''): string {
    return isset($data[$key]) ? trim((string)$data[$key]) : $default;
}

/**
 * Returns an integer from $data[$key] after casting, or $default.
 */
function int_input(array $data, string $key, int $default = 0): int {
    return isset($data[$key]) ? (int)$data[$key] : $default;
}

/**
 * Validates an email address.
 * Returns the lowercased email or null if invalid.
 */
function validate_email(string $email): ?string {
    $email = strtolower(trim($email));
    return filter_var($email, FILTER_VALIDATE_EMAIL) ? $email : null;
}
