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

// Questions per set is admin-controlled via the set's `total_questions`
// column (defaults to 10). With shuffle on, this also gives a random subset
// from a larger pool (e.g. Tunnlity's 200-question bank → 10 random each time).
$limit = intval($set['total_questions'] ?? 0);
if ($limit <= 0) $limit = 10;

$questions = $pdo->prepare("
    SELECT id, question_text, option_a, option_b, option_c, option_d,
           correct_option, explanation, difficulty, time_limit,
           question_text_hi, option_a_hi, option_b_hi, option_c_hi, option_d_hi, explanation_hi
    FROM questions
    WHERE set_id = ? AND is_active = 1
    ORDER BY " . (!empty($_GET['shuffle']) ? 'RAND()' : 'order_num ASC') . "
    LIMIT $limit
");
$questions->execute([$setId]);
$questions = $questions->fetchAll();
// Auto-translate any questions missing Hindi (via Groq) and cache into the DB,
// so the in-quiz language toggle shows real Hindi for ANY set.
require_once __DIR__ . '/_translate_lib.php';
tunnl_fill_hindi($pdo, $questions);

response([
    'success'   => true,
    'set'       => [
        'id'             => intval($set['id']),
        'title'          => $set['title'],
        'set_number'     => intval($set['set_number']),
        'category'       => $set['category'],
        'level'          => $set['level'],
        'total_questions'=> count($questions),
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
        'question_hi'    => $q['question_text_hi'] ?? '',
        'options_hi'     => [
            'a' => $q['option_a_hi'] ?? '',
            'b' => $q['option_b_hi'] ?? '',
            'c' => $q['option_c_hi'] ?? '',
            'd' => $q['option_d_hi'] ?? '',
        ],
        'explanation_hi' => $q['explanation_hi'] ?? '',
        'difficulty'     => $q['difficulty'],
        'time_limit'     => intval($q['time_limit'] ?? 30),
    ], $questions),
]);