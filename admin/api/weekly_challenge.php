<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$method = $_SERVER['REQUEST_METHOD'];
$user   = requireAuth($pdo);

// ── 7-day challenge config ──────────────────────────
// A challenge runs 7 days. Each day has 10 questions, mapped from the assigned
// questions' order_num (1-10 = day 1, 11-20 = day 2, ... 61-70 = day 7).
// Final ranking aggregates all days: total correct (accuracy) then total time.
const WC_DAYS    = 7;
const WC_PER_DAY = 10;

/**
 * Returns [currentDay, sevenDayMode, totalAssigned].
 * Legacy challenges (<=10 questions assigned) stay single-day so old data works.
 */
function wc_day_info(PDO $pdo, array $challenge): array {
    $total = (int)$pdo->query(
        "SELECT COUNT(*) FROM challenge_questions WHERE challenge_id = " . (int)$challenge['id']
    )->fetchColumn();

    $sevenDay = $total > WC_PER_DAY;
    if (!$sevenDay) return [1, false, $total];

    $startStr = !empty($challenge['start_date']) ? $challenge['start_date'] : ($challenge['created_at'] ?? date('Y-m-d'));
    $start    = strtotime(date('Y-m-d', strtotime($startStr)));
    $today    = strtotime(date('Y-m-d'));
    $day      = (int)floor(($today - $start) / 86400) + 1;
    if ($day < 1) $day = 1;
    if ($day > WC_DAYS) $day = WC_DAYS;
    return [$day, true, $total];
}

// ══════════════════════════════════════════════════════
// GET — Active challenge (today's questions + aggregate leaderboard)
// ══════════════════════════════════════════════════════
if ($method === 'GET') {
    // Latest challenge that has admin-declared winners → dashboard announcement.
    $winnerAnnounce = null;
    $wc = $pdo->query("
        SELECT w.id, w.title, w.prize_amount
        FROM weekly_challenges w
        WHERE EXISTS (SELECT 1 FROM challenge_entries e
                      WHERE e.challenge_id = w.id AND e.is_winner = 1)
        ORDER BY COALESCE(w.end_date, w.created_at) DESC, w.id DESC
        LIMIT 1
    ")->fetch();
    if ($wc) {
        $ws = $pdo->prepare("
            SELECT u.name, MAX(e.prize_won) AS prize_won
            FROM challenge_entries e
            JOIN users u ON e.user_id = u.id
            WHERE e.challenge_id = ? AND e.is_winner = 1
            GROUP BY e.user_id, u.name
            ORDER BY prize_won DESC, u.name ASC
            LIMIT 5
        ");
        $ws->execute([$wc['id']]);
        $winners = array_map(fn($r) => [
            'name'  => $r['name'] ?: 'Anonymous',
            'prize' => floatval($r['prize_won'] ?? 0),
        ], $ws->fetchAll());
        if ($winners) {
            $winnerAnnounce = [
                'challenge_id'    => intval($wc['id']),
                'challenge_title' => $wc['title'],
                'winners'         => $winners,
            ];
        }
    }

    $challenge = $pdo->query("
        SELECT * FROM weekly_challenges
        WHERE status='active'
        ORDER BY COALESCE(start_date, created_at) DESC, id DESC
        LIMIT 1
    ")->fetch();

    if (!$challenge) {
        response(['success'=>true,'challenge'=>null,'winner_announcement'=>$winnerAnnounce,'message'=>'No active challenge']);
    }

    [$day, $sevenDay, $totalAssigned] = wc_day_info($pdo, $challenge);

    // Has the user attempted TODAY's day?
    $entryStmt = $pdo->prepare("
        SELECT * FROM challenge_entries
        WHERE challenge_id=? AND user_id=? AND day_number=? LIMIT 1
    ");
    $entryStmt->execute([$challenge['id'], $user['id'], $day]);
    $entry = $entryStmt->fetch();

    // Today's questions (only if not attempted yet today)
    $questions = [];
    if (!$entry) {
        if ($sevenDay) {
            $startOrd = ($day - 1) * WC_PER_DAY + 1;
            $endOrd   = $day * WC_PER_DAY;
            $qs = $pdo->prepare("
                SELECT q.id, q.question_text, q.option_a, q.option_b,
                       q.option_c, q.option_d, q.difficulty,
                       q.correct_option, q.explanation, q.time_limit,
                       q.question_text_hi, q.option_a_hi, q.option_b_hi,
                       q.option_c_hi, q.option_d_hi, q.explanation_hi
                FROM challenge_questions cq
                JOIN questions q ON cq.question_id = q.id
                WHERE cq.challenge_id = ? AND cq.order_num BETWEEN ? AND ?
                ORDER BY cq.order_num ASC
            ");
            $qs->execute([$challenge['id'], $startOrd, $endOrd]);
        } else {
            $qs = $pdo->prepare("
                SELECT q.id, q.question_text, q.option_a, q.option_b,
                       q.option_c, q.option_d, q.difficulty,
                       q.correct_option, q.explanation, q.time_limit,
                       q.question_text_hi, q.option_a_hi, q.option_b_hi,
                       q.option_c_hi, q.option_d_hi, q.explanation_hi
                FROM challenge_questions cq
                JOIN questions q ON cq.question_id = q.id
                WHERE cq.challenge_id = ?
                ORDER BY cq.order_num ASC
            ");
            $qs->execute([$challenge['id']]);
        }
        $questions = $qs->fetchAll();
        // Auto-translate missing Hindi (Groq) + cache, so the weekly challenge
        // questions show real Hindi when the user toggles language.
        require_once __DIR__ . '/_translate_lib.php';
        tunnl_fill_hindi($pdo, $questions);
    }

    // Aggregate leaderboard (sum across all days) — accuracy then time.
    $top = $pdo->prepare("
        SELECT u.name,
               SUM(e.correct)        AS score,
               SUM(e.time_taken)     AS time_taken,
               ROUND(AVG(e.accuracy),1) AS accuracy,
               RANK() OVER (ORDER BY SUM(e.correct) DESC, SUM(e.time_taken) ASC) AS rank
        FROM challenge_entries e
        JOIN users u ON e.user_id = u.id
        WHERE e.challenge_id = ?
        GROUP BY e.user_id, u.name
        ORDER BY SUM(e.correct) DESC, SUM(e.time_taken) ASC
        LIMIT 10
    ");
    $top->execute([$challenge['id']]);
    $top = $top->fetchAll();

    // My aggregate so far
    $mine = $pdo->prepare("
        SELECT SUM(correct) AS total_correct, SUM(time_taken) AS total_time,
               ROUND(AVG(accuracy),1) AS accuracy, COUNT(*) AS days_played
        FROM challenge_entries WHERE challenge_id=? AND user_id=?
    ");
    $mine->execute([$challenge['id'], $user['id']]);
    $mine = $mine->fetch() ?: [];

    response([
        'success'     => true,
        'winner_announcement' => $winnerAnnounce,
        'challenge'   => [
            'id'             => intval($challenge['id']),
            'title'          => $challenge['title'],
            'description'    => $challenge['description'] ?? '',
            'start_date'     => $challenge['start_date'] ?? null,
            'end_date'       => $challenge['end_date'] ?? null,
            'prize_amount'   => floatval($challenge['prize_amount'] ?? 0),
            'total_questions'=> $sevenDay ? (WC_DAYS * WC_PER_DAY) : intval($challenge['total_questions'] ?? 0),
            'time_limit'     => intval($challenge['time_limit'] ?? 10),
            'current_day'    => $day,
            'total_days'     => $sevenDay ? WC_DAYS : 1,
            'per_day'        => WC_PER_DAY,
            'is_attempted'   => (bool)$entry,          // attempted TODAY
            'my_total_correct' => intval($mine['total_correct'] ?? 0),
            'my_total_time'    => intval($mine['total_time'] ?? 0),
            'my_days_played'   => intval($mine['days_played'] ?? 0),
            'my_entry'       => $entry ? [
                'score'     => intval($entry['correct'] ?? $entry['score'] ?? 0),
                'accuracy'  => round(($entry['accuracy'] ?? 0), 1),
                'time_taken'=> intval($entry['time_taken'] ?? 0),
                'is_winner' => (bool)($entry['is_winner'] ?? 0),
            ] : null,
        ],
        'questions'   => array_map(fn($q) => [
            'id'        => intval($q['id']),
            'question'  => $q['question_text'],
            'options'   => ['a'=>$q['option_a'],'b'=>$q['option_b'],'c'=>$q['option_c'],'d'=>$q['option_d']],
            'correct'   => strtolower((string)($q['correct_option'] ?? 'a')),
            'explanation'=> $q['explanation'] ?? '',
            'time_limit'=> intval($q['time_limit'] ?? 30),
            'question_hi'=> $q['question_text_hi'] ?? '',
            'options_hi'=> [
                'a'=>$q['option_a_hi'] ?? '', 'b'=>$q['option_b_hi'] ?? '',
                'c'=>$q['option_c_hi'] ?? '', 'd'=>$q['option_d_hi'] ?? '',
            ],
            'explanation_hi'=> $q['explanation_hi'] ?? '',
            'difficulty'=> $q['difficulty'],
        ], $questions),
        'leaderboard' => array_map(fn($r) => [
            'rank'      => intval($r['rank']),
            'name'      => $r['name'] ?: 'Anonymous',
            'score'     => intval($r['score']),
            'accuracy'  => round($r['accuracy'], 1),
            'time_taken'=> intval($r['time_taken']),
        ], $top),
    ]);
}

// ══════════════════════════════════════════════════════
// POST — Submit a day's attempt
// ══════════════════════════════════════════════════════
if ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

    $challengeId = intval($input['challenge_id'] ?? 0);
    $correct     = intval($input['correct']      ?? 0);
    $wrong       = intval($input['wrong']        ?? 0);
    $timeTaken   = intval($input['time_taken']   ?? 0);

    if (!$challengeId) error('challenge_id required');

    $ch = $pdo->prepare("SELECT * FROM weekly_challenges WHERE id=? LIMIT 1");
    $ch->execute([$challengeId]);
    $ch = $ch->fetch();
    if (!$ch) error('Challenge not found', 404);

    [$day] = wc_day_info($pdo, $ch);

    // One attempt per day
    $exists = $pdo->prepare("
        SELECT id FROM challenge_entries
        WHERE challenge_id=? AND user_id=? AND day_number=? LIMIT 1
    ");
    $exists->execute([$challengeId, $user['id'], $day]);
    if ($exists->fetch()) error("You've already submitted today's challenge. Come back tomorrow!");

    $total    = $correct + $wrong;
    $accuracy = $total > 0 ? round(($correct/$total)*100, 2) : 0;

    $pdo->prepare("
        INSERT INTO challenge_entries
          (challenge_id, user_id, day_number, score, correct, wrong, accuracy, time_taken, submitted_at)
        VALUES (?,?,?,?,?,?,?,?,NOW())
    ")->execute([$challengeId, $user['id'], $day, $correct, $correct, $wrong, $accuracy, $timeTaken]);

    // XP for participation
    $xp = 30 + ($correct * 5);
    $pdo->prepare("UPDATE users SET total_xp=total_xp+?, last_active=NOW() WHERE id=?")
        ->execute([$xp, $user['id']]);

    response([
        'success'   => true,
        'message'   => "Day $day submitted!",
        'result'    => [
            'score'    => $correct,
            'total'    => $total,
            'accuracy' => $accuracy,
            'day'      => $day,
            'xp_earned'=> $xp,
        ],
    ]);
}
