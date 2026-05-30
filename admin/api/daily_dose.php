<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$today = date('Y-m-d');

// Try today's dose first
$stmt = $pdo->prepare("
    SELECT * FROM daily_dose
    WHERE dose_date = ? AND is_active = 1
    LIMIT 1
");
$stmt->execute([$today]);
$dose = $stmt->fetch();

// Fallback to latest
if (!$dose) {
    $dose = $pdo->query("
        SELECT * FROM daily_dose WHERE is_active = 1
        ORDER BY dose_date DESC LIMIT 1
    ")->fetch();
}

if (!$dose) {
    response(['success' => true, 'dose' => null, 'message' => 'No dose available']);
}

response([
    'success' => true,
    'dose'    => [
        'id'        => intval($dose['id']),
        'title'     => $dose['title']     ?? '',
        'content'   => $dose['content']   ?? '',
        'type'      => $dose['type']      ?? '',
        'example'   => $dose['example']   ?? '',
        'tip'       => $dose['tip']       ?? '',
        'category'  => $dose['category']  ?? '',
        'image_url' => $dose['image_url'] ?? '',
        'dose_date' => $dose['dose_date'],
        'has_video' => !empty($dose['has_video']) ? 1 : 0,
        'video_url' => $dose['video_url'] ?? '',
    ],
]);
