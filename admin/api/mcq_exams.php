<?php
// Public endpoint: lists the "5000 Speed MCQ" exams (SSC, Railway, …) the
// admin created. Sets are grouped by exam_name. Optional Bearer token used
// for premium access flags.
//
// Returns { success, exams: [ { id, exam_name, exam_full_name, exam_category,
//   icon, difficulty, is_premium, can_access, set_count, total_questions } ] }

require_once __DIR__ . '/config.php';
checkApiKey();

$user = getAuthUser($pdo);

try {
    $exams = $pdo->query("
        SELECT
          e.*,
          COALESCE(
            (SELECT COUNT(*) FROM sets s
              WHERE s.category='mcq' AND s.exam_name = e.exam_name
                AND (s.is_active IS NULL OR s.is_active = 1)),
            0
          ) AS set_count,
          COALESCE(
            (SELECT COUNT(*) FROM questions q
               JOIN sets s ON q.set_id = s.id
              WHERE s.category='mcq' AND s.exam_name = e.exam_name),
            0
          ) AS q_count
        FROM mcq_exams e
        WHERE e.is_active = 1
        ORDER BY e.sort_order ASC, e.exam_name ASC
    ")->fetchAll();
} catch (Exception $e) {
    // Table missing (migration not run yet) → return empty list gracefully.
    response(['success' => true, 'exams' => []]);
}

$isPremium = $user ? !empty($user['is_premium']) : false;

$out = array_map(function ($e) use ($isPremium) {
    $premium = !empty($e['is_premium']);
    return [
        'id'              => intval($e['id']),
        'exam_name'       => $e['exam_name'],
        'exam_full_name'  => $e['exam_full_name'] ?? '',
        'exam_category'   => $e['exam_category']  ?? 'OTHER',
        'icon'            => $e['icon']           ?? 'school',
        'icon_url'        => $e['icon_url']       ?? '',
        'difficulty'      => $e['difficulty']     ?? 'Medium',
        'is_premium'      => $premium,
        'can_access'      => !$premium || $isPremium,
        'set_count'       => intval($e['set_count']),
        'total_questions' => intval($e['q_count']),
    ];
}, $exams);

response(['success' => true, 'exams' => $out]);
