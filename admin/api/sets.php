<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$user     = getAuthUser($pdo);
$category = $_GET['category'] ?? 'mcq';
$page     = max(1, intval($_GET['page'] ?? 1));
$perPage  = max(1, intval($_GET['per_page'] ?? 50));
$offset   = ($page - 1) * $perPage;

$validCats = ['mcq','simplification','previous_year','tunnlity','tricks'];
if (!in_array($category, $validCats, true)) error('Invalid category');

$where  = ['s.category = ?'];
$params = [$category];

$where[] = '(s.is_active IS NULL OR s.is_active = 1)';

if (!empty($_GET['exam_id'])) {
    $where[]  = '(s.exam_id = ? OR s.exam_name = (SELECT exam_name FROM py_exams WHERE id = ?))';
    $params[] = intval($_GET['exam_id']);
    $params[] = intval($_GET['exam_id']);
}

// Filter mcq sets by exam_name (used by the 5000 MCQ exam-wise screen).
if (!empty($_GET['exam_name'])) {
    $where[]  = 's.exam_name = ?';
    $params[] = trim($_GET['exam_name']);
}

// Only sets NOT tied to any exam (the "500 Free Practice MCQs" pool).
if (!empty($_GET['ungrouped'])) {
    $where[] = "(s.exam_name IS NULL OR s.exam_name = '')";
}

$whereSQL = implode(' AND ', $where);

$totalStmt = $pdo->prepare("SELECT COUNT(*) FROM sets s WHERE $whereSQL");
$totalStmt->execute($params);
$total = $totalStmt->fetchColumn();

$paramsList = $params;
$paramsList[] = $perPage;
$paramsList[] = $offset;

$sets = $pdo->prepare("
    SELECT s.*,
      (SELECT COUNT(*) FROM questions q WHERE q.set_id = s.id) AS question_count
    FROM sets s
    WHERE $whereSQL
    ORDER BY s.set_number ASC
    LIMIT ? OFFSET ?
");
$sets->execute($paramsList);
$sets = $sets->fetchAll();

$isPremium = $user ? !empty($user['is_premium']) : false;

$result = array_map(function ($s) use ($isPremium) {
    // First 2 sets of practice categories are ALWAYS free (preview). The
    // "Tunnlity" speed-test sets are fully free (guest feature).
    $freePreview = $s['category'] === 'tunnlity'
                   || (in_array($s['category'], ['mcq', 'simplification'], true)
                       && intval($s['set_number']) <= 2);
    $premium = !empty($s['is_premium']) && !$freePreview;

    // How many questions this set will actually serve in the quiz:
    //  - never more than the questions actually added to the set
    //  - capped by the admin-configured `total_questions` when set
    //  - if no questions added yet, show the planned count (admin limit / 10)
    $avail      = intval($s['question_count']);
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
        'subtitle'        => $s['subtitle']  ?? '',
        'exam_name'       => $s['exam_name'] ?? '',
        'category'        => $s['category'],
        'level'           => $s['level']     ?? 'beginner',
        // Real number of questions served (matches the quiz exactly).
        'total_questions' => $served,
        'question_count'  => intval($s['question_count']),
        'is_locked'       => !empty($s['is_locked']),
        'is_premium'      => $premium,
        'can_access'      => !$premium || $isPremium,
    ];
}, $sets);

response([
    'success'  => true,
    'category' => $category,
    'total'    => intval($total),
    'page'     => $page,
    'per_page' => $perPage,
    'sets'     => $result,
]);
