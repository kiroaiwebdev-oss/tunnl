<?php
define('DB_HOST', 'localhost');
define('DB_USER', 'u758083880_tes');        // Apna DB username
define('DB_PASS', '4gyF12IY&l');            // Apna DB password
define('DB_NAME', 'u758083880_test'); // Apna DB name

define('ADMIN_VERSION', '1.0.0');
define('APP_NAME', 'Mathematical Void');

try {
    $pdo = new PDO(
        "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]
    );
} catch (PDOException $e) {
    die(json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]));
}

// Self-healing: make sure the coupon + MCQ-exam tables exist so new admin
// pages and payment APIs never 500 on a fresh database. Fully guarded.
require_once __DIR__ . '/ensure_tables.php';