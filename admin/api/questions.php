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
// With pool=1 we return the FULL active question bank (no cap) so the app can
// pick a type-diverse subset itself (used by Test Your Tunnlity).
$pool  = !empty($_GET['pool']);
$limit = intval($set['total_questions'] ?? 0);
if ($limit <= 0) $limit = 10;
if ($pool) $limit = 1000000;

$cols = "id, question_text, option_a, option_b, option_c, option_d,
         correct_option, explanation, difficulty, time_limit,
         question_text_hi, option_a_hi, option_b_hi, option_c_hi, option_d_hi, explanation_hi,
         exam_name, exam_year";

if (!empty($_GET['shuffle'])) {
    // ── Type-diverse random pick ──────────────────────────────────────────
    // Pull every active question's id + type (category), then round-robin
    // across types so the 10 shown are each a DIFFERENT type as far as
    // possible. Only once all types are used does a type repeat (with a
    // different question); actual question repeats happen only if the whole
    // pool is smaller than the requested count.
    $cand = $pdo->prepare(
        "SELECT id, COALESCE(NULLIF(TRIM(category), ''), 'general') AS cat
         FROM questions WHERE set_id = ? AND is_active = 1 ORDER BY RAND()"
    );
    $cand->execute([$setId]);
    $rows = $cand->fetchAll();

    $byCat = [];
    foreach ($rows as $r) { $byCat[$r['cat']][] = (int)$r['id']; }
    $cats = array_keys($byCat);
    shuffle($cats);

    $totalAvail = count($rows);
    // Serve at most the admin-configured count, but NEVER more than the number
    // of questions actually added to the set. Questions are never duplicated to
    // pad a set up to `total_questions` — a 10-question set serves 10 questions.
    $target     = min($limit, $totalAvail);
    $picked     = [];

    while (count($picked) < $target) {
        $progress = false;
        foreach ($cats as $c) {
            if (!empty($byCat[$c])) {
                $picked[]  = array_shift($byCat[$c]);
                $progress  = true;
                if (count($picked) >= $target) break;
            }
        }
        if (!$progress) break; // every type exhausted
    }

    if (empty($picked)) {
        $questions = [];
    } else {
        $place = implode(',', array_fill(0, count($picked), '?'));
        $full  = $pdo->prepare("SELECT $cols FROM questions WHERE id IN ($place)");
        $full->execute($picked);
        $map = [];
        foreach ($full->fetchAll() as $row) { $map[(int)$row['id']] = $row; }
        // Rebuild in the diverse picked order (repeats reuse the same row).
        $questions = [];
        foreach ($picked as $pid) {
            if (isset($map[$pid])) $questions[] = $map[$pid];
        }
    }
} else {
    $stmt = $pdo->prepare(
        "SELECT $cols FROM questions
         WHERE set_id = ? AND is_active = 1
         ORDER BY order_num ASC LIMIT $limit"
    );
    $stmt->execute([$setId]);
    $questions = $stmt->fetchAll();
}
// Auto-translate any questions missing Hindi (via Groq) and cache into the DB,
// so the in-quiz language toggle shows real Hindi for ANY set. Skipped for
// pool requests (large banks, e.g. Tunnlity) to keep the response fast.
if (!$pool) {
    require_once __DIR__ . '/_translate_lib.php';
    tunnl_fill_hindi($pdo, $questions);
}

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
        'exam_name'      => $q['exam_name'] ?? '',
        'exam_year'      => $q['exam_year'] ?? '',
        'difficulty'     => $q['difficulty'],
        'time_limit'     => intval($q['time_limit'] ?? 30),
    ], $questions),
]);