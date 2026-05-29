<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$user  = getAuthUser($pdo);
$examId= intval($_GET['exam_id'] ?? 0);

// List all exams grouped
if (!$examId) {
    $exams = $pdo->query("
        SELECT e.*,
          (SELECT COUNT(*) FROM sets s WHERE s.exam_id=e.id) as set_count,
          (SELECT COUNT(*) FROM questions q
             JOIN sets s ON q.set_id=s.id WHERE s.exam_id=e.id) as q_count
        FROM py_exams e
        WHERE e.is_active=1
        ORDER BY e.exam_name ASC, e.exam_year DESC
    ")->fetchAll();

    // Group by exam name
    $grouped = [];
    foreach ($exams as $e) {
        $grouped[$e['exam_name']][] = [
            'id'             => intval($e['id']),
            'exam_name'      => $e['exam_name'],
            'exam_year'      => intval($e['exam_year']),
            'exam_date'      => $e['exam_date'],
            'difficulty'     => $e['difficulty'],
            'is_premium'     => (bool)$e['is_premium'],
            'can_access'     => !$e['is_premium'] || ($user && $user['is_premium']),
            'set_count'      => intval($e['set_count']),
            'total_questions'=> intval($e['q_count']),
        ];
    }

    response(['success'=>true,'exams'=>$grouped]);
}

// Exam detail + sets
$exam = $pdo->prepare("SELECT * FROM py_exams WHERE id=? AND is_active=1 LIMIT 1");
$exam->execute([$examId]);
$exam = $exam->fetch();
if (!$exam) error('Exam not found', 404);

// Premium check
if ($exam['is_premium'] && (!$user || !$user['is_premium'])) {
    error('Premium required', 403);
}

$sets = $pdo->prepare("
    SELECT s.*,
      (SELECT COUNT(*) FROM questions q WHERE q.set_id=s.id) as q_count
    FROM sets s WHERE s.exam_id=? AND s.is_active=1
    ORDER BY s.set_number ASC
");
$sets->execute([$examId]);
$sets = $sets->fetchAll();

response([
    'success' => true,
    'exam'    => [
        'id'        => intval($exam['id']),
        'exam_name' => $exam['exam_name'],
        'exam_year' => intval($exam['exam_year']),
        'exam_date' => $exam['exam_date'],
        'difficulty'=> $exam['difficulty'],
        'is_premium'=> (bool)$exam['is_premium'],
    ],
    'sets'    => array_map(fn($s) => [
        'id'             => intval($s['id']),
        'set_number'     => intval($s['set_number']),
        'title'          => $s['title'],
        'level'          => $s['level'],
        'total_questions'=> intval($s['total_questions']),
        'question_count' => intval($s['q_count']),
    ], $sets),
]);