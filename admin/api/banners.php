<?php
require_once 'config.php';
// Public endpoint — no auth required

$banners = $pdo->query("
    SELECT id, title, subtitle, image_url, action_value
    FROM carousel_banners
    WHERE is_active = 1
    ORDER BY sort_order ASC
")->fetchAll();

ok($banners);
?>
