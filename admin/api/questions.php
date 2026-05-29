<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$user  = requireAuth($pdo);
$setId = intval($_GET['set_id'] ?? 0);

if (!$setId) error('set_id required');

// Get set info
$set = $pdo->prepare("SELECT * FROM sets WHERE id=? AND is_active=1 LIMIT 1");
$set->execute([$setId]);
$set = $set->fetch();

if (!$set) error('Set not found', 404);

// Check premium access
if ($set['is_premium'] && !$user['is_premium']) {
    error('Premium required to access this set', 403);
}

// Get questions (shuffle)
$questions = $pdo->prepare("
    SELECT id, question_text, option_a, option_b, option_c, option_d,
           correct_option, explanation, difficulty, time_limit
    FROM questions
    WHERE set_id = ? AND is_active = 1
    ORDER BY " . (!empty($_GET['shuffle']) ? 'RAND()' : 'order_num ASC') . "
");
$questions->execute([$setId]);
$questions = $questions->fetchAll();

response([
    'success'   => true,
    'set'       => [
        'id'             => intval($set['id']),
        'title'          => $set['title'],
        'set_number'     => intval($set['set_number']),
        'category'       => $set['category'],
        'level'          => $set['level'],
        'total_questions'=> intval($set['total_questions']),
    ],
    'questions' => array_map(fn($q) => [
        'id'             => intval($q['id']),
        'question'       => $q['question_text'],
        'options'        => [
            'a' => $q['option_a'],
            'b' => $q['option_b'],
            'c' => $q['option_c'],
            'd' => $q['option_d'],
        ],
        'correct'        => $q['correct_option'],
        'explanation'    => $q['explanation'],
        'difficulty'     => $q['difficulty'],
        'time_limit'     => intval($q['time_limit'] ?? 30),
    ], $questions),
]);