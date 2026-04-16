<?php
// =============================================================================
// MBOA HEALTH — Database Configuration Template
// INSTRUCTIONS:
//   1. Copy this file to config.php  (cp config.example.php config.php)
//   2. SSH into the server and change your system password
//   3. Open phpMyAdmin at http://169.239.251.102:280/phpmyadmin
//   4. Change your MySQL password (it expires on first use)
//   5. Create a database named 'mboa_health' (or your chosen name)
//   6. Import backend/schema.sql into that database
//   7. Fill in DB_USER, DB_PASS, and DB_NAME below with your actual values
//   8. Change JWT_SECRET to a long random string (min 32 characters)
//   9. config.php is in .gitignore — never commit the real file
// =============================================================================

// ── Database ──────────────────────────────────────────────────────────────────
define('DB_HOST', 'localhost');
define('DB_PORT', 3306);
define('DB_NAME', 'mboa_health');        // Your database name
define('DB_USER', 'your_mysql_username');
define('DB_PASS', 'YOUR_MYSQL_PASSWORD_HERE');  // ← Change after first login

// ── JWT ───────────────────────────────────────────────────────────────────────
// CHANGE THIS to a random 64-character string — keep it secret.
define('JWT_SECRET', 'replace_with_64_random_chars');
define('JWT_EXPIRY',  8 * 3600); // 8 hours in seconds

// ── App ───────────────────────────────────────────────────────────────────────
define('APP_ENV', 'development');   // 'production' in live deployment
define('APP_URL', 'http://your-server/mboa_api');

// ── CORS — allowed origins ────────────────────────────────────────────────────
// In production, replace '*' with your specific app domain/origin.
define('CORS_ORIGIN', '*');
