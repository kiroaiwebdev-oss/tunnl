<?php
require_once __DIR__ . '/config.php';
checkApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('POST only');

$user  = requireAuth($pdo);
$input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

$practiceId = intval($input['practice_id'] ?? 0);
$correct    = intval($input['correct']     ?? 0);
$wrong      = intval($input['wrong']       ?? 0);
$timeTaken  = intval($input['time_taken']  ?? 0);

if (!$practiceId) error('practice_id required');

// Check already submitted
$exists = $pdo->prepare("
    SELECT id FROM user_daily_practice
    WHERE user_id=? AND practice_id=? LIMIT 1
");
$exists->execute([$user['id'], $practiceId]);
if ($exists->fetch()) error('Already submitted');

// Get practice info
$practice = $pdo->prepare("SELECT * FROM daily_practice WHERE id=?");
$practice->execute([$practiceId]);
$practice = $practice->fetch();
if (!$practice) error('Practice not found');

$total    = $correct + $wrong;
$accuracy = $total > 0 ? round(($correct / $total) * 100, 2) : 0;
$xp       = $accuracy >= 80 ? $practice['xp_reward'] : intval($practice['xp_reward'] * ($accuracy/100));

// Save
$pdo->prepare("
    INSERT INTO user_daily_practice
      (user_id, practice_id, score, correct, wrong, accuracy, time_taken, xp_earned, completed_at)
    VALUES (?,?,?,?,?,?,?,?,NOW())
")->execute([$user['id'], $practiceId, $correct, $correct, $wrong, $accuracy, $timeTaken, $xp]);

// Update user XP
$pdo->prepare("UPDATE users SET total_xp = total_xp + ?, last_active=NOW() WHERE id=?")
    ->execute([$xp, $user['id']]);

response([
    'success'    => true,
    'xp_earned'  => $xp,
    'accuracy'   => $accuracy,
    'message'    => 'Practice completed! +' . $xp . ' XP',
]);