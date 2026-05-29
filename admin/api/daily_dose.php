<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$today = date('Y-m-d');

$dose = $pdo->prepare("
    SELECT * FROM daily_doses
    WHERE dose_date = ? AND is_active = 1
    LIMIT 1
");
$dose->execute([$today]);
$dose = $dose->fetch();

if (!$dose) {
    // Fallback to latest dose
    $dose = $pdo->query("
        SELECT * FROM daily_doses WHERE is_active=1
        ORDER BY dose_date DESC LIMIT 1
    ")->fetch();
}

if (!$dose) {
    response(['success'=>true, 'dose'=>null, 'message'=>'No dose today']);
}

response([
    'success' => true,
    'dose'    => [
        'id'          => intval($dose['id']),
        'title'       => $dose['title'],
        'content'     => $dose['content'],
        'type'        => $dose['type'],
        'example'     => $dose['example'],
        'tip'         => $dose['tip'],
        'dose_date'   => $dose['dose_date'],
        'has_video'   => (bool)$dose['has_video'],
        'video_url'   => $dose['video_url'],
    ],
]);