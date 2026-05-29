<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$user     = getAuthUser($pdo);
$category = $_GET['category'] ?? 'mcq';
$page     = max(1, intval($_GET['page'] ?? 1));
$perPage  = intval($_GET['per_page'] ?? 20);
$offset   = ($page - 1) * $perPage;

$validCats = ['mcq','simplification','previous_year'];
if (!in_array($category, $validCats)) error('Invalid category');

$where  = ['s.category = ?', 's.is_active = 1'];
$params = [$category];

// exam_id filter for PY
if (!empty($_GET['exam_id'])) {
    $where[]  = 's.exam_id = ?';
    $params[] = intval($_GET['exam_id']);
}

$whereSQL = implode(' AND ', $where);

$total = $pdo->prepare("SELECT COUNT(*) FROM sets s WHERE $whereSQL");
$total->execute($params);
$total = $total->fetchColumn();

// Add pagination params
$params[] = $perPage;
$params[] = $offset;

$sets = $pdo->prepare("
    SELECT s.*,
      (SELECT COUNT(*) FROM questions q WHERE q.set_id = s.id) as question_count
    FROM sets s
    WHERE $whereSQL
    ORDER BY s.set_number ASC
    LIMIT ? OFFSET ?
");
$sets->execute($params);
$sets = $sets->fetchAll();

// Mark locked for free users
$isPremium = $user ? (bool)$user['is_premium'] : false;

$result = array_map(fn($s) => [
    'id'              => intval($s['id']),
    'set_number'      => intval($s['set_number']),
    'title'           => $s['title'],
    'exam_name'       => $s['exam_name'],
    'category'        => $s['category'],
    'level'           => $s['level'],
    'total_questions' => intval($s['total_questions']),
    'question_count'  => intval($s['question_count']),
    'is_locked'       => (bool)$s['is_locked'],
    'is_premium'      => (bool)$s['is_premium'],
    'can_access'      => !$s['is_premium'] || $isPremium,
], $sets);

response([
    'success'  => true,
    'category' => $category,
    'total'    => intval($total),
    'page'     => $page,
    'per_page' => $perPage,
    'sets'     => $result,
]);