<?php
// Per-set leaderboard — ranks all users who attempted a given set
// (any category: previous_year, mcq, etc.). Best score per user, ties broken
// by fastest time. Returns top 3 + the caller's own rank + total participants.
//
// GET ?set_id=123   → { success, top:[...], my_rank, my_total_participants }

require_once __DIR__ . '/config.php';
checkApiKey();

$user  = getAuthUser($pdo);
$setId = intval($_GET['set_id'] ?? 0);
if ($setId <= 0) error('set_id required');

try {
    $rows = $pdo->query("
        SELECT u.id, u.name, u.profile_image,
               MAX(h.score)        AS best_score,
               MIN(h.time_taken)   AS best_time,
               MAX(h.accuracy)     AS best_accuracy
        FROM user_test_history h
        JOIN users u ON u.id = h.user_id
        WHERE h.set_id = $setId
        GROUP BY u.id, u.name, u.profile_image
        ORDER BY best_score DESC, best_time ASC
        LIMIT 200
    ")->fetchAll();
} catch (Throwable $e) {
    response(['success' => true, 'top' => [], 'my_rank' => null, 'total' => 0]);
}

$total  = count($rows);
$medals = ['🥇', '🥈', '🥉'];
$top    = [];
$myRank = null;
$i      = 0;

foreach ($rows as $r) {
    $isMe = $user && intval($r['id']) === intval($user['id']);
    if ($isMe) $myRank = $i + 1;
    if ($i < 3) {
        $top[] = [
            'rank'          => $i + 1,
            'medal'         => $medals[$i] ?? null,
            'name'          => $r['name'] ?: 'Anonymous',
            'best_score'    => intval($r['best_score']),
            'best_accuracy' => round((float)$r['best_accuracy'], 1),
            'is_me'         => $isMe,
        ];
    }
    $i++;
}

response([
    'success'  => true,
    'top'      => $top,
    'my_rank'  => $myRank,
    'total'    => $total,
]);
