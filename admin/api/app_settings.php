<?php
// Public endpoint — returns ONLY safe app settings.
// Secret keys (razorpay_key_secret, sms_api_key, fcm_server_key, etc.) are
// filtered out before reaching the app.

require_once __DIR__ . '/config.php';

// Keys that must NEVER be exposed to the public app
$BLOCKED_KEYS = [
    'razorpay_key_secret',
    'sms_api_key',
    'fcm_server_key',
    'jwt_secret',
    'admin_password',
    'fast2sms_key',
    'groq_api_key',   // server-side only (used by the translation library)
];

// Substring filters — anything containing these will also be blocked
$BLOCKED_SUBSTR = ['_secret', '_password', '_private'];

try {
    $rows = $pdo->query(
        "SELECT setting_key, setting_value FROM app_settings"
    )->fetchAll(PDO::FETCH_ASSOC);

    $settings = [];
    foreach ($rows as $row) {
        $k = $row['setting_key'];
        $kLower = strtolower($k);

        // Skip blocked keys
        if (in_array($kLower, $BLOCKED_KEYS, true)) continue;

        // Skip if contains any blocked substring
        $skip = false;
        foreach ($BLOCKED_SUBSTR as $needle) {
            if (strpos($kLower, $needle) !== false) { $skip = true; break; }
        }
        if ($skip) continue;

        $settings[$k] = $row['setting_value'];
    }

    // Make sure Razorpay key_id (public) is exposed if present
    // (key_id is safe to expose, only key_secret is sensitive)

    ok($settings);
} catch (Exception $e) {
    fail('Failed to load settings: ' . $e->getMessage(), 500);
}
