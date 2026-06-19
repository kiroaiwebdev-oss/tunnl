<?php
require_once __DIR__ . '/config.php';
checkApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('POST only');

$user  = requireAuth($pdo);
$input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

$setId    = intval($input['set_id']    ?? 0);
$category = $input['category']         ?? 'mcq';
$correct  = intval($input['correct']   ?? 0);
$wrong    = intval($input['wrong']     ?? 0);
$skipped  = intval($input['skipped']   ?? 0);
$timeTaken= intval($input['time_taken']?? 0);
$answers  = $input['answers']          ?? []; // [{question_id, selected, correct}]

$total    = $correct + $wrong + $skipped;
$score    = $correct;
$accuracy = $total > 0 ? round(($correct / $total) * 100, 2) : 0;

// XP Calculation
$baseXp   = $correct * 10;
$bonusXp  = $accuracy >= 90 ? 50 : ($accuracy >= 70 ? 20 : 0);
$speedBonus = $timeTaken > 0 && $timeTaken < 300 ? 10 : 0;
$xpEarned = $baseXp + $bonusXp + $speedBonus;

// Save test history
$pdo->prepare("
    INSERT INTO user_test_history
      (user_id, set_id, category, score, total_questions,
       correct, wrong, skipped, accuracy, time_taken,
       xp_earned, completed_at)
    VALUES (?,?,?,?,?,?,?,?,?,?,?,NOW())
")->execute([
    $user['id'], $setId, $category, $score, $total,
    $correct, $wrong, $skipped, $accuracy, $timeTaken, $xpEarned
]);

// Update user XP & streak
$today     = date('Y-m-d');
$lastActive= substr($user['last_active'] ?? '', 0, 10);
$yesterday = date('Y-m-d', strtotime('-1 day'));

if ($lastActive === $today) {
    $newStreak = $user['current_streak']; // same day
} elseif ($lastActive === $yesterday) {
    $newStreak = $user['current_streak'] + 1; // continue
} else {
    $newStreak = 1; // reset
}

$newMaxStreak = max($user['max_streak'] ?? 0, $newStreak);
$newXp        = $user['total_xp'] + $xpEarned;

$pdo->prepare("
    UPDATE users SET
      total_xp = ?,
      current_streak = ?,
      max_streak = ?,
      last_active = NOW()
    WHERE id = ?
")->execute([$newXp, $newStreak, $newMaxStreak, $user['id']]);

// Update leaderboard rank — safe (no multi-statement query, never 500s)
try {
    $pdo->exec("SET @rank := 0");
    $pdo->exec("UPDATE users SET rank_position = (@rank := @rank + 1) ORDER BY total_xp DESC");
} catch (Throwable $e) {
    // Non-critical: ranks recompute on next submission / leaderboard load.
}

response([
    'success'      => true,
    'result'       => [
        'score'         => $score,
        'total'         => $total,
        'correct'       => $correct,
        'wrong'         => $wrong,
        'skipped'       => $skipped,
        'accuracy'      => $accuracy,
        'time_taken'    => $timeTaken,
        'xp_earned'     => $xpEarned,
        'xp_breakdown'  => [
            'base'      => $baseXp,
            'accuracy'  => $bonusXp,
            'speed'     => $speedBonus,
        ],
    ],
    'user_stats'   => [
        'total_xp'      => $newXp,
        'current_streak'=> $newStreak,
        'max_streak'    => $newMaxStreak,
    ],
    'badges'       => getBadges($accuracy, $newStreak, $xpEarned),
]);

function getBadges($accuracy, $streak, $xp): array {
    $badges = [];
    if ($accuracy >= 100) $badges[] = ['icon'=>'🎯','title'=>'Perfect Score!',  'color'=>'#FFD700'];
    if ($accuracy >= 90)  $badges[] = ['icon'=>'⚡','title'=>'Speed Master!',   'color'=>'#00E5FF'];
    if ($streak >= 7)     $badges[] = ['icon'=>'🔥','title'=>'7-Day Streak!',   'color'=>'#FF6B35'];
    if ($streak >= 30)    $badges[] = ['icon'=>'💎','title'=>'30-Day Legend!',  'color'=>'#8B5CF6'];
    if ($xp >= 200)       $badges[] = ['icon'=>'🚀','title'=>'XP Blaster!',     'color'=>'#10B981'];
    return $badges;
}