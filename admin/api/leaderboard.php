<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$user   = getAuthUser($pdo);
$type   = $_GET['type']  ?? 'all_time'; // all_time | weekly | monthly
$limit  = min(50, intval($_GET['limit'] ?? 20));

// Build date filter
$dateFilter = '';
if ($type === 'weekly') {
    $dateFilter = "AND DATE(last_active) >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
} elseif ($type === 'monthly') {
    $dateFilter = "AND MONTH(last_active) = MONTH(NOW()) AND YEAR(last_active) = YEAR(NOW())";
}

$leaders = $pdo->query("
    SELECT id, name, phone, total_xp, current_streak, rank_position, profile_image
    FROM users
    WHERE 1=1 $dateFilter
    ORDER BY total_xp DESC, last_active DESC, id ASC
    LIMIT $limit
")->fetchAll();

// Current user rank
$myRank = null;
if ($user) {
    $myRankRow = $pdo->prepare("
        SELECT COUNT(*) + 1 as rank FROM users
        WHERE total_xp > (SELECT total_xp FROM users WHERE id=?)
    ");
    $myRankRow->execute([$user['id']]);
    $myRank = intval($myRankRow->fetchColumn());
}

$medals = ['🥇','🥈','🥉'];

response([
    'success'     => true,
    'type'        => $type,
    'leaderboard' => array_map(fn($i, $u) => [
        'rank'         => $i + 1,
        'medal'        => $medals[$i] ?? null,
        'user_id'      => intval($u['id']),
        'name'         => $u['name'] ?: 'Anonymous',
        'phone_masked' => substr($u['phone'],0,4).'******',
        'total_xp'     => intval($u['total_xp']),
        'streak'       => intval($u['current_streak']),
        'profile_image'=> $u['profile_image'],
        'is_me'        => $user ? $u['id'] === $user['id'] : false,
    ], array_keys($leaders), $leaders),
    'my_rank'     => $myRank,
    'my_xp'       => $user ? intval($user['total_xp']) : null,
]);