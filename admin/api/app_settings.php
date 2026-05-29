<?php
require_once 'config.php';
// Public endpoint

$rows = $pdo->query("SELECT setting_key, setting_value FROM app_settings")->fetchAll();
$settings = [];
foreach ($rows as $r) $settings[$r['setting_key']] = $r['setting_value'];

ok($settings);
?>
