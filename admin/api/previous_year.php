<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$user   = getAuthUser($pdo);
$examId = intval($_GET['exam_id'] ?? 0);

// ── List all exams grouped by exam_name ─────────────
if (!$examId) {
    $exams = $pdo->query("
        SELECT
          e.*,
          COALESCE(
            (SELECT COUNT(*) FROM sets s
              WHERE s.category='previous_year'
                AND (s.exam_id = e.id OR s.exam_name = e.exam_name)),
            0
          ) AS set_count,
          COALESCE(
            (SELECT COUNT(*) FROM questions q
               JOIN sets s ON q.set_id = s.id
              WHERE s.category='previous_year'
                AND (s.exam_id = e.id OR s.exam_name = e.exam_name)),
            0
          ) AS q_count
        FROM py_exams e
        WHERE e.is_active = 1
        ORDER BY e.exam_name ASC, COALESCE(e.exam_year, 0) DESC
    ")->fetchAll();

    $grouped = [];
    foreach ($exams as $e) {
        $grouped[$e['exam_name']][] = [
            'id'              => intval($e['id']),
            'exam_name'       => $e['exam_name'],
            'exam_full_name'  => $e['exam_full_name']   ?? '',
            'exam_category'   => $e['exam_category']    ?? '',
            'icon'            => $e['icon']             ?? 'school',
            'icon_url'        => $e['icon_url']         ?? '',
            'exam_year'       => intval($e['exam_year'] ?? 0),
            'exam_date'       => $e['exam_date']        ?? null,
            'difficulty'      => $e['difficulty']       ?? 'Medium',
            'is_premium'      => !empty($e['is_premium']),
            'can_access'      => empty($e['is_premium']) || ($user && !empty($user['is_premium'])),
            'set_count'       => intval($e['set_count']),
            'total_questions' => intval($e['q_count']),
        ];
    }

    response(['success' => true, 'exams' => $grouped]);
}

// ── Single exam + its sets ──────────────────────────
$stmt = $pdo->prepare("SELECT * FROM py_exams WHERE id=? AND is_active=1 LIMIT 1");
$stmt->execute([$examId]);
$exam = $stmt->fetch();
if (!$exam) error('Exam not found', 404);

if (!empty($exam['is_premium']) && (!$user || empty($user['is_premium']))) {
    error('Premium required', 403);
}

$setsStmt = $pdo->prepare("
    SELECT s.*,
      (SELECT COUNT(*) FROM questions q WHERE q.set_id = s.id) AS q_count
    FROM sets s
    WHERE (s.exam_id = ? OR (s.exam_id IS NULL AND s.exam_name = ?))
      AND s.category = 'previous_year'
      AND (s.is_active IS NULL OR s.is_active = 1)
    ORDER BY s.set_number ASC
");
$setsStmt->execute([$examId, $exam['exam_name']]);
$sets = $setsStmt->fetchAll();

response([
    'success' => true,
    'exam'    => [
        'id'         => intval($exam['id']),
        'exam_name'  => $exam['exam_name'],
        'icon'       => $exam['icon']         ?? 'school',
        'icon_url'   => $exam['icon_url']     ?? '',
        'exam_year'  => intval($exam['exam_year'] ?? 0),
        'exam_date'  => $exam['exam_date']    ?? null,
        'difficulty' => $exam['difficulty']   ?? 'Medium',
        'is_premium' => !empty($exam['is_premium']),
    ],
    'sets'    => array_map(function ($s) use ($user) {
        $isPremium = !empty($s['is_premium']);
        $avail      = intval($s['q_count']);
        $adminLimit = intval($s['total_questions'] ?? 0);
        if ($avail > 0) {
            $served = $adminLimit > 0 ? min($adminLimit, $avail) : $avail;
        } else {
            $served = $adminLimit > 0 ? $adminLimit : 10;
        }
        return [
            'id'              => intval($s['id']),
            'set_number'      => intval($s['set_number']),
            'title'           => $s['title']     ?? '',
            'level'           => $s['level']     ?? 'beginner',
            'total_questions' => $served,
            'question_count'  => intval($s['q_count']),
            'is_premium'      => $isPremium,
            'can_access'      => !$isPremium || ($user && !empty($user['is_premium'])),
        ];
    }, $sets),
]);
