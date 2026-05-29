<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$user     = getAuthUser($pdo);
$category = $_GET['category'] ?? '';
$id       = intval($_GET['id'] ?? 0);

// Single trick
if ($id) {
    $trick = $pdo->prepare("SELECT * FROM tricks WHERE id=? AND is_active=1 LIMIT 1");
    $trick->execute([$id]);
    $trick = $trick->fetch();
    if (!$trick) error('Trick not found', 404);

    response([
        'success' => true,
        'trick'   => formatTrick($trick),
    ]);
}

// List
$where  = ['is_active = 1'];
$params = [];
if ($category) {
    $where[]  = 'category = ?';
    $params[] = strtoupper($category);
}

$tricks = $pdo->prepare("
    SELECT * FROM tricks
    WHERE " . implode(' AND ', $where) . "
    ORDER BY chapter_number ASC
");
$tricks->execute($params);
$tricks = $tricks->fetchAll();

response([
    'success' => true,
    'total'   => count($tricks),
    'tricks'  => array_map('formatTrick', $tricks),
]);

function formatTrick(array $t): array {
    return [
        'id'             => intval($t['id']),
        'chapter_number' => intval($t['chapter_number']),
        'title'          => $t['title'],
        'subtitle'       => $t['subtitle'],
        'category'       => $t['category'],
        'difficulty'     => $t['difficulty'],
        'is_new'         => (bool)$t['is_new'],
        'has_video'      => (bool)$t['has_video'],
        'video_url'      => $t['has_video'] ? $t['video_url'] : null,
        'video_duration' => intval($t['video_duration']),
        'has_article'    => (bool)$t['has_article'],
        'article_content'=> $t['has_article'] ? $t['article_content'] : null,
        'read_duration'  => intval($t['read_duration']),
    ];
}