<?php
// Tunnlity (speed test) leaderboard — best score per user, from
// user_test_history rows with category='tunnlity'.
//
// Returns { success, leaderboard: [...], my_rank, my_best }

require_once __DIR__ . '/config.php';
checkApiKey();

$user  = getAuthUser($pdo);
$limit = min(50, intval($_GET['limit'] ?? 30));

try {
    $rows = $pdo->query("
        SELECT u.id, u.name, u.phone, u.profile_image,
               MAX(h.score)    AS best_score,
               MAX(h.accuracy) AS best_accuracy,
               COUNT(*)        AS attempts
        FROM user_test_history h
        JOIN users u ON u.id = h.user_id
        WHERE h.category = 'tunnlity'
        GROUP BY u.id, u.name, u.phone, u.profile_image
        ORDER BY best_score DESC, best_accuracy DESC, attempts ASC
        LIMIT $limit
    ")->fetchAll();
} catch (Throwable $e) {
    response(['success' => true, 'leaderboard' => [], 'my_rank' => null, 'my_best' => null]);
}

$medals = ['🥇', '🥈', '🥉'];
$out     = [];
$myRank  = null;
$myBest  = null;
$i       = 0;

foreach ($rows as $r) {
    $isMe = $user && intval($r['id']) === intval($user['id']);
    if ($isMe) {
        $myRank = $i + 1;
        $myBest = intval($r['best_score']);
    }
    $out[] = [
        'rank'          => $i + 1,
        'medal'         => $medals[$i] ?? null,
        'user_id'       => intval($r['id']),
        'name'          => $r['name'] ?: 'Anonymous',
        'phone_masked'  => substr((string)$r['phone'], 0, 4) . '******',
        'best_score'    => intval($r['best_score']),
        'best_accuracy' => round((float)$r['best_accuracy'], 1),
        'attempts'      => intval($r['attempts']),
        'profile_image' => $r['profile_image'] ?? null,
        'is_me'         => $isMe,
    ];
    $i++;
}

response([
    'success'     => true,
    'leaderboard' => $out,
    'my_rank'     => $myRank,
    'my_best'     => $myBest,
]);
