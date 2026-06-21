<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$category = $_GET['category'] ?? '';
$platform = $_GET['platform'] ?? '';
$page     = max(1, intval($_GET['page'] ?? 1));
$perPage  = max(1, intval($_GET['per_page'] ?? 30));
$offset   = ($page - 1) * $perPage;

$where  = ['is_active = 1'];
$params = [];
if ($category) { $where[] = 'category = ?'; $params[] = $category; }
if ($platform) { $where[] = 'platform = ?'; $params[] = strtolower($platform); }

$whereSQL = implode(' AND ', $where);

$totalStmt = $pdo->prepare("SELECT COUNT(*) FROM shorts WHERE $whereSQL");
$totalStmt->execute($params);
$total = $totalStmt->fetchColumn();

$paramsList = $params;
$paramsList[] = $perPage;
$paramsList[] = $offset;

$shorts = $pdo->prepare("
    SELECT * FROM shorts WHERE $whereSQL
    ORDER BY created_at DESC LIMIT ? OFFSET ?
");
$shorts->execute($paramsList);
$shorts = $shorts->fetchAll();

// ── Helpers ────────────────────────────────────────────
// Handle both `youtube_url` (new) and `url` (legacy) columns.
function pickUrl(array $s): string {
    return !empty($s['youtube_url']) ? $s['youtube_url'] : ($s['url'] ?? '');
}

function ytId(string $url): ?string {
    if (!$url) return null;
    if (preg_match('/(?:v=|\/shorts\/|youtu\.be\/|\/embed\/)([a-zA-Z0-9_-]{11})/', $url, $m)) {
        return $m[1];
    }
    return null;
}

// Detect the platform: prefer the stored column, fall back to URL sniffing.
function detectPlatform(array $s, string $url): string {
    $p = strtolower(trim($s['platform'] ?? ''));
    if (in_array($p, ['youtube', 'instagram', 'facebook', 'telegram', 'local'], true)) {
        return $p;
    }
    $u = strtolower($url);
    if (strpos($u, 'instagram') !== false) return 'instagram';
    if (strpos($u, 'facebook') !== false || strpos($u, 'fb.watch') !== false) return 'facebook';
    if (strpos($u, 't.me') !== false || strpos($u, 'telegram') !== false) return 'telegram';
    return 'youtube';
}

response([
    'success'  => true,
    'total'    => intval($total),
    'page'     => $page,
    'per_page' => $perPage,
    'shorts'   => array_map(function ($s) {
        $url      = pickUrl($s);
        $platform = detectPlatform($s, $url);
        $vid      = $platform === 'youtube' ? ytId($url) : null;

        // Thumbnail priority: admin-provided > youtube auto-thumb > none.
        $thumb = !empty($s['thumbnail_url'])
            ? $s['thumbnail_url']
            : ($vid ? 'https://img.youtube.com/vi/' . $vid . '/mqdefault.jpg' : '');

        return [
            'id'           => intval($s['id']),
            'title'        => $s['title'] ?? '',
            'youtube_url'  => $url,
            'url'          => $url,
            'video_id'     => $vid,
            'thumbnail'    => $thumb,
            'category'     => $s['category'] ?? '',
            'platform'     => $platform,
            'duration'     => intval($s['duration'] ?? 0),
            'created_at'   => $s['created_at'] ?? '',
        ];
    }, $shorts),
]);
