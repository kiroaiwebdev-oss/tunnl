<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$category = $_GET['category'] ?? '';
$page     = max(1, intval($_GET['page'] ?? 1));
$perPage  = intval($_GET['per_page'] ?? 15);
$offset   = ($page - 1) * $perPage;

$where  = ['is_active = 1'];
$params = [];
if ($category) { $where[] = 'category = ?'; $params[] = $category; }

$whereSQL = implode(' AND ', $where);

$total = $pdo->prepare("SELECT COUNT(*) FROM shorts WHERE $whereSQL");
$total->execute($params);
$total = $total->fetchColumn();

$params[] = $perPage;
$params[] = $offset;

$shorts = $pdo->prepare("
    SELECT * FROM shorts WHERE $whereSQL
    ORDER BY created_at DESC LIMIT ? OFFSET ?
");
$shorts->execute($params);
$shorts = $shorts->fetchAll();

// Extract YouTube video ID helper
function ytId($url): ?string {
    preg_match('/(?:v=|\/shorts\/|youtu\.be\/)([a-zA-Z0-9_-]{11})/', $url, $m);
    return $m[1] ?? null;
}

response([
    'success'  => true,
    'total'    => intval($total),
    'page'     => $page,
    'per_page' => $perPage,
    'shorts'   => array_map(fn($s) => [
        'id'          => intval($s['id']),
        'title'       => $s['title'],
        'youtube_url' => $s['youtube_url'],
        'video_id'    => ytId($s['youtube_url']),
        'thumbnail'   => ytId($s['youtube_url'])
                         ? 'https://img.youtube.com/vi/'.ytId($s['youtube_url']).'/mqdefault.jpg'
                         : null,
        'category'    => $s['category'],
        'duration'    => intval($s['duration']),
        'created_at'  => $s['created_at'],
    ], $shorts),
]);