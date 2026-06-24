<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$user  = requireAuth($pdo);
$today = date('Y-m-d');

// Today's practice
$practice = $pdo->prepare("
    SELECT * FROM daily_practice
    WHERE practice_date = ? AND is_active = 1 LIMIT 1
");
$practice->execute([$today]);
$practice = $practice->fetch();

if (!$practice) {
    response(['success'=>true,'practice'=>null,'message'=>'No practice scheduled today']);
}

// Check already completed
$completed = $pdo->prepare("
    SELECT * FROM user_daily_practice
    WHERE user_id = ? AND practice_id = ? LIMIT 1
");
$completed->execute([$user['id'], $practice['id']]);
$completed = $completed->fetch();

// Get questions
$questions = $pdo->prepare("
    SELECT q.id, q.question_text, q.option_a, q.option_b,
           q.option_c, q.option_d, q.correct_option,
           q.explanation, q.difficulty,
           q.question_text_hi, q.option_a_hi, q.option_b_hi,
           q.option_c_hi, q.option_d_hi, q.explanation_hi
    FROM daily_practice_questions dpq
    JOIN questions q ON dpq.question_id = q.id
    WHERE dpq.practice_id = ?
    ORDER BY dpq.order_num ASC
");
$questions->execute([$practice['id']]);
$questions = $questions->fetchAll();

// Auto-translate missing Hindi (via Groq) + cache into the DB.
require_once __DIR__ . '/_translate_lib.php';
tunnl_fill_hindi($pdo, $questions);

response([
    'success'   => true,
    'practice'  => [
        'id'             => intval($practice['id']),
        'title'          => $practice['title'],
        'category'       => $practice['category'],
        'total_questions'=> intval($practice['total_questions']),
        'time_limit'     => intval($practice['time_limit']),
        'xp_reward'      => intval($practice['xp_reward']),
        'is_completed'   => (bool)$completed,
        'completed_at'   => $completed ? $completed['completed_at'] : null,
        'score'          => $completed ? intval($completed['score']) : null,
    ],
    'questions' => array_map(fn($q) => [
        'id'         => intval($q['id']),
        'question'   => $q['question_text'],
        'options'    => [
            'a' => $q['option_a'],
            'b' => $q['option_b'],
            'c' => $q['option_c'],
            'd' => $q['option_d'],
        ],
        'correct'    => $completed ? $q['correct_option'] : null, // reveal only after completion
        'explanation'=> $completed ? $q['explanation']    : null,
        'question_hi'=> $q['question_text_hi'] ?? '',
        'options_hi' => [
            'a' => $q['option_a_hi'] ?? '',
            'b' => $q['option_b_hi'] ?? '',
            'c' => $q['option_c_hi'] ?? '',
            'd' => $q['option_d_hi'] ?? '',
        ],
        'explanation_hi'=> $completed ? ($q['explanation_hi'] ?? '') : null,
        'difficulty' => $q['difficulty'],
    ], $questions),
]);