<?php
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/config.php';

echo json_encode([
    'name'    => 'Mboa Health API',
    'version' => '1.0.0',
    'status'  => 'online',
    'base_url'=> APP_URL,
    'endpoints' => [
        'POST ' . APP_URL . '/api/auth/get_salt.php',
        'POST ' . APP_URL . '/api/auth/register.php',
        'POST ' . APP_URL . '/api/auth/login.php',
        'GET  ' . APP_URL . '/api/auth/me.php',
        'GET|POST|PUT|DELETE ' . APP_URL . '/api/health_records/index.php',
        'GET|POST|PUT|DELETE ' . APP_URL . '/api/reminders/index.php',
        'GET|POST|PUT|DELETE ' . APP_URL . '/api/emergency_contacts/index.php',
        'GET  ' . APP_URL . '/api/clinics/index.php',
        'GET  ' . APP_URL . '/api/notifications/index.php',
        'GET|PUT ' . APP_URL . '/api/profile/index.php',
    ],
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
