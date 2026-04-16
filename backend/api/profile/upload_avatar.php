<?php
// POST /api/profile/upload_avatar.php
// Accepts:  multipart/form-data  field name: "avatar"
// Returns:  {"success":true,"data":{"avatar_url":"http://..."}}
// Requires: Authorization: Bearer <token>
require_once __DIR__ . '/../../helpers.php';
require_once __DIR__ . '/../../db.php';

$auth   = require_auth();
$userId = (int) $auth['user_id'];

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error(405, 'Method not allowed.');
}

if (!isset($_FILES['avatar']) || $_FILES['avatar']['error'] === UPLOAD_ERR_NO_FILE) {
    json_error(422, 'No file provided. Use multipart field name: avatar');
}

$file     = $_FILES['avatar'];
$maxBytes = 2 * 1024 * 1024; // 2 MB

// Map PHP upload error codes to human-readable messages
$uploadErrors = [
    UPLOAD_ERR_INI_SIZE   => 'File exceeds the server upload limit.',
    UPLOAD_ERR_FORM_SIZE  => 'File exceeds the allowed form size.',
    UPLOAD_ERR_PARTIAL    => 'Upload was incomplete. Please try again.',
    UPLOAD_ERR_NO_TMP_DIR => 'Server temp directory is missing.',
    UPLOAD_ERR_CANT_WRITE => 'Server cannot write the file.',
    UPLOAD_ERR_EXTENSION  => 'Upload blocked by server extension.',
];

if ($file['error'] !== UPLOAD_ERR_OK) {
    json_error(422, $uploadErrors[$file['error']] ?? 'Upload failed. Please try again.');
}

if ($file['size'] > $maxBytes) {
    json_error(422, 'Image is too large. Maximum allowed size is 2 MB.');
}

// ── Validate real MIME type from file contents (OWASP A03 — never trust client headers) ──
$finfo    = new finfo(FILEINFO_MIME_TYPE);
$mimeType = $finfo->file($file['tmp_name']);
$allowed  = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

if (!in_array($mimeType, $allowed, true)) {
    json_error(415, 'Invalid file type. Allowed: JPEG, PNG, GIF, WebP.');
}

// ── Destination directory ─────────────────────────────────────────────────────
$uploadDir = __DIR__ . '/../../uploads/avatars/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

// Remove any old avatars for this user to avoid accumulating orphan files
foreach (glob($uploadDir . 'avatar_' . $userId . '_*') ?: [] as $oldFile) {
    @unlink($oldFile);
}

// ── Safe unique filename: avatar_{userId}_{random16hex}.{ext} ─────────────────
$ext = match ($mimeType) {
    'image/jpeg' => 'jpg',
    'image/png'  => 'png',
    'image/gif'  => 'gif',
    'image/webp' => 'webp',
    default       => 'jpg',
};
$filename = 'avatar_' . $userId . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
$dest     = $uploadDir . $filename;

if (!move_uploaded_file($file['tmp_name'], $dest)) {
    json_error(500, 'Could not save the image. Please try again.');
}

// ── Persist URL in database and return it ────────────────────────────────────
$avatarUrl = APP_URL . '/uploads/avatars/' . $filename;

db()->prepare('UPDATE users SET avatar_url = ? WHERE id = ?')
   ->execute([$avatarUrl, $userId]);

json_ok(['avatar_url' => $avatarUrl]);
