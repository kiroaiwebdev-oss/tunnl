<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$method = $_SERVER['REQUEST_METHOD'];
$user   = requireAuth($pdo);

// GET — Active challenge
if ($method === 'GET') {
    $challenge = $pdo->query("
        SELECT * FROM weekly_challenges
        WHERE status='active'
        ORDER BY COALESCE(start_date, created_at) DESC, id DESC
        LIMIT 1
    ")->fetch();

    if (!$challenge) {
        response(['success'=>true,'challenge'=>null,'message'=>'No active challenge']);
    }

    // Check if user already participated
    $entry = $pdo->prepare("
        SELECT * FROM challenge_entries
        WHERE challenge_id=? AND user_id=? LIMIT 1
    ");
    $entry->execute([$challenge['id'], $user['id']]);
    $entry = $entry->fetch();

    // Questions (only if not attempted yet)
    $questions = [];
    if (!$entry) {
        $qs = $pdo->prepare("
            SELECT q.id, q.question_text, q.option_a, q.option_b,
                   q.option_c, q.option_d, q.difficulty
            FROM challenge_questions cq
            JOIN questions q ON cq.question_id = q.id
            WHERE cq.challenge_id = ?
            ORDER BY cq.order_num ASC
        ");
        $qs->execute([$challenge['id']]);
        $questions = $qs->fetchAll();
    }

    // Leaderboard top 10
    $top = $pdo->prepare("
        SELECT e.score, e.accuracy, e.time_taken, u.name,
          RANK() OVER (ORDER BY e.score DESC, e.time_taken ASC) as rank
        FROM challenge_entries e
        JOIN users u ON e.user_id = u.id
        WHERE e.challenge_id = ?
        ORDER BY e.score DESC, e.time_taken ASC
        LIMIT 10
    ");
    $top->execute([$challenge['id']]);
    $top = $top->fetchAll();

    response([
        'success'     => true,
        'challenge'   => [
            'id'             => intval($challenge['id']),
            'title'          => $challenge['title'],
            'description'    => $challenge['description'],
            'start_date'     => $challenge['start_date'],
            'end_date'       => $challenge['end_date'],
            'prize_amount'   => floatval($challenge['prize_amount']),
            'total_questions'=> intval($challenge['total_questions']),
            'time_limit'     => intval($challenge['time_limit']),
            'is_attempted'   => (bool)$entry,
            'my_entry'       => $entry ? [
                'score'     => intval($entry['score']),
                'accuracy'  => round($entry['accuracy'],1),
                'time_taken'=> intval($entry['time_taken']),
                'is_winner' => (bool)$entry['is_winner'],
                'prize_won' => floatval($entry['prize_won']),
            ] : null,
        ],
        'questions'   => array_map(fn($q) => [
            'id'       => intval($q['id']),
            'question' => $q['question_text'],
            'options'  => ['a'=>$q['option_a'],'b'=>$q['option_b'],'c'=>$q['option_c'],'d'=>$q['option_d']],
            'difficulty'=> $q['difficulty'],
        ], $questions),
        'leaderboard' => array_map(fn($r) => [
            'rank'      => intval($r['rank']),
            'name'      => $r['name'] ?: 'Anonymous',
            'score'     => intval($r['score']),
            'accuracy'  => round($r['accuracy'],1),
            'time_taken'=> intval($r['time_taken']),
        ], $top),
    ]);
}

// POST — Submit challenge attempt
if ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

    $challengeId = intval($input['challenge_id'] ?? 0);
    $correct     = intval($input['correct']      ?? 0);
    $wrong       = intval($input['wrong']        ?? 0);
    $timeTaken   = intval($input['time_taken']   ?? 0);

    if (!$challengeId) error('challenge_id required');

    // Check already submitted
    $exists = $pdo->prepare("
        SELECT id FROM challenge_entries
        WHERE challenge_id=? AND user_id=? LIMIT 1
    ");
    $exists->execute([$challengeId, $user['id']]);
    if ($exists->fetch()) error('Already submitted for this challenge');

    $total    = $correct + $wrong;
    $accuracy = $total > 0 ? round(($correct/$total)*100, 2) : 0;

    $pdo->prepare("
        INSERT INTO challenge_entries
          (challenge_id, user_id, score, correct, wrong, accuracy, time_taken, submitted_at)
        VALUES (?,?,?,?,?,?,?,NOW())
    ")->execute([$challengeId, $user['id'], $correct, $correct, $wrong, $accuracy, $timeTaken]);

    // XP for participation
    $xp = 30 + ($correct * 5);
    $pdo->prepare("UPDATE users SET total_xp=total_xp+?, last_active=NOW() WHERE id=?")
        ->execute([$xp, $user['id']]);

    response([
        'success'   => true,
        'message'   => 'Challenge submitted!',
        'result'    => [
            'score'    => $correct,
            'total'    => $total,
            'accuracy' => $accuracy,
            'xp_earned'=> $xp,
        ],
    ]);
}