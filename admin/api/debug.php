<?php
// ============================================
// TUNNEL DEBUG FILE — test.devsarun.io/api/debug.php
// DELETE THIS FILE AFTER FIXING!
// ============================================

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header("Content-Type: text/html; charset=UTF-8");
?>
<!DOCTYPE html>
<html>
<head>
<title>Tunnl API Debug</title>
<style>
  body { font-family: monospace; background: #0d1117; color: #c9d1d9; padding: 20px; }
  h2   { color: #58a6ff; border-bottom: 1px solid #30363d; padding-bottom: 8px; }
  .ok  { color: #3fb950; }
  .err { color: #f85149; }
  .warn{ color: #d29922; }
  .box { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 16px; margin: 12px 0; }
  pre  { margin: 0; white-space: pre-wrap; word-break: break-all; background:#0d1117; padding:10px; border-radius:6px; }
  table{ width:100%; border-collapse:collapse; }
  td,th{ padding:6px 10px; border:1px solid #30363d; font-size:13px; }
  th   { background:#161b22; color:#58a6ff; }
</style>
</head>
<body>

<h2>🔍 Tunnl API Debug Panel</h2>
<p style="color:#8b949e">Run once to find the 500 error. <b style="color:#f85149">Delete after fixing!</b></p>

<?php

// ── TEST 1: config.php load ────────────────────────────
echo '<h2>1. config.php Load Test</h2><div class="box">';
$configPath = __DIR__ . '/config.php';
if (!file_exists($configPath)) {
    echo '<span class="err">❌ config.php NOT FOUND at: ' . $configPath . '</span>';
} else {
    echo '<span class="ok">✅ config.php exists at: ' . $configPath . '</span><br><br>';
    ob_start();
    try {
        require_once $configPath;
        $output = ob_get_clean();
        echo '<span class="ok">✅ config.php loaded successfully</span>';
        if ($output) {
            echo '<br><span class="warn">⚠️ config.php has stray output (BREAKS JSON responses):</span><br>';
            echo '<pre>' . htmlspecialchars($output) . '</pre>';
        }
    } catch (Throwable $e) {
        ob_get_clean();
        echo '<span class="err">❌ config.php ERROR: ' . htmlspecialchars($e->getMessage()) . '</span>';
        echo '<br>File: ' . $e->getFile() . ' | Line: ' . $e->getLine();
    }
}
echo '</div>';

// ── TEST 2: DB Connection ──────────────────────────────
echo '<h2>2. Database Connection</h2><div class="box">';
if (isset($pdo)) {
    try {
        $pdo->query("SELECT 1");
        echo '<span class="ok">✅ Database connected successfully</span>';
    } catch (Exception $e) {
        echo '<span class="err">❌ DB query failed: ' . htmlspecialchars($e->getMessage()) . '</span>';
    }
} else {
    echo '<span class="err">❌ $pdo not defined — DB connection failed inside config.php</span>';
}
echo '</div>';

// ── TEST 3: Required Tables ────────────────────────────
echo '<h2>3. Required Tables</h2><div class="box">';
$requiredTables = ['users', 'otp_store', 'app_settings'];
if (isset($pdo)) {
    foreach ($requiredTables as $table) {
        try {
            $count = $pdo->query("SELECT COUNT(*) FROM `$table`")->fetchColumn();
            echo '<span class="ok">✅ ' . $table . '</span> — ' . $count . ' rows<br>';
        } catch (Exception $e) {
            echo '<span class="err">❌ ' . $table . ' — MISSING: ' . htmlspecialchars($e->getMessage()) . '</span><br>';
        }
    }
} else {
    echo '<span class="warn">⚠️ Skipped — DB not connected</span>';
}
echo '</div>';

// ── TEST 4: otp_store structure ───────────────────────
echo '<h2>4. otp_store Table Structure</h2><div class="box">';
if (isset($pdo)) {
    try {
        $cols = $pdo->query("DESCRIBE otp_store")->fetchAll(PDO::FETCH_ASSOC);
        echo '<table><tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>';
        foreach ($cols as $c) {
            echo "<tr><td>{$c['Field']}</td><td>{$c['Type']}</td><td>{$c['Null']}</td><td>{$c['Key']}</td><td>{$c['Default']}</td></tr>";
        }
        echo '</table>';
        $fields = array_column($cols, 'Field');
        foreach (['phone','otp','expires_at'] as $n) {
            if (!in_array($n, $fields))
                echo '<br><span class="err">❌ Missing column: ' . $n . '</span>';
        }
    } catch (Exception $e) {
        echo '<span class="err">❌ otp_store MISSING — create it now:</span>';
        echo '<pre style="color:#79c0ff">
CREATE TABLE IF NOT EXISTS `otp_store` (
  `id`         INT AUTO_INCREMENT PRIMARY KEY,
  `phone`      VARCHAR(15) NOT NULL UNIQUE,
  `otp`        VARCHAR(6)  NOT NULL,
  `expires_at` DATETIME    NOT NULL,
  `created_at` TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;</pre>';
    }
} else {
    echo '<span class="warn">⚠️ Skipped</span>';
}
echo '</div>';

// ── TEST 5: Helper functions ──────────────────────────
echo '<h2>5. Helper Functions (ok, fail, generateJWT)</h2><div class="box">';
foreach (['ok', 'fail', 'generateJWT', 'checkApiKey'] as $fn) {
    if (function_exists($fn))
        echo '<span class="ok">✅ ' . $fn . '()</span><br>';
    else
        echo '<span class="err">❌ ' . $fn . '() — NOT DEFINED in config.php</span><br>';
}
echo '</div>';

// ── TEST 6: Constants ─────────────────────────────────
echo '<h2>6. Constants</h2><div class="box">';
foreach (['OTP_DEBUG', 'SITE_URL', 'JWT_SECRET'] as $c) {
    if (defined($c)) {
        $val = constant($c);
        if (in_array($c, ['JWT_SECRET'])) $val = substr($val,0,4).'****';
        echo '<span class="ok">✅ ' . $c . '</span> = ' . htmlspecialchars((string)$val) . '<br>';
    } else {
        echo '<span class="warn">⚠️ ' . $c . ' — not defined</span><br>';
    }
}
echo '</div>';

// ── TEST 7: SMS Settings in DB ────────────────────────
echo '<h2>7. SMS Settings in app_settings table</h2><div class="box">';
if (isset($pdo)) {
    try {
        $rows = $pdo->query("
            SELECT setting_key, setting_value FROM app_settings
            WHERE setting_key IN ('sms_provider','sms_api_key','sms_sender_id','otp_expiry_minutes','otp_message')
        ")->fetchAll(PDO::FETCH_KEY_PAIR);
        foreach (['sms_provider','sms_api_key','sms_sender_id','otp_expiry_minutes','otp_message'] as $k) {
            $val = $rows[$k] ?? null;
            if ($val) {
                $display = ($k === 'sms_api_key') ? substr($val,0,6).'...'.substr($val,-4) : htmlspecialchars($val);
                echo '<span class="ok">✅ ' . $k . '</span>: ' . $display . '<br>';
            } else {
                echo '<span class="warn">⚠️ ' . $k . ' — not saved in DB yet</span><br>';
            }
        }
    } catch (Exception $e) {
        echo '<span class="err">❌ ' . htmlspecialchars($e->getMessage()) . '</span>';
    }
} else {
    echo '<span class="warn">⚠️ Skipped</span>';
}
echo '</div>';

// ── TEST 8: Simulate OTP insert ───────────────────────
echo '<h2>8. OTP Insert Simulation</h2><div class="box">';
if (isset($pdo)) {
    try {
        $testPhone = '9000000001';
        $expires   = date('Y-m-d H:i:s', strtotime('+10 minutes'));
        $pdo->prepare("
            INSERT INTO otp_store (phone, otp, expires_at)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE otp=?, expires_at=?
        ")->execute([$testPhone, '123456', $expires, '123456', $expires]);
        echo '<span class="ok">✅ OTP insert — OK</span><br>';
        $pdo->prepare("DELETE FROM otp_store WHERE phone=?")->execute([$testPhone]);
        echo '<span class="ok">✅ Cleanup — OK</span><br>';
        echo '<br><b style="color:#3fb950">Core DB logic works fine!</b>';
    } catch (Throwable $e) {
        echo '<span class="err">❌ FAILED: ' . htmlspecialchars($e->getMessage()) . '</span>';
        echo '<br>Line: ' . $e->getLine();
    }
} else {
    echo '<span class="warn">⚠️ Skipped</span>';
}
echo '</div>';

?>

<div class="box" style="border-color:#f85149;margin-top:24px">
  <b style="color:#f85149">⚠️ DELETE THIS FILE AFTER DEBUGGING</b><br>
  <span style="color:#8b949e">This file exposes your server configuration. Remove it immediately after use.</span>
</div>

</body>
</html>