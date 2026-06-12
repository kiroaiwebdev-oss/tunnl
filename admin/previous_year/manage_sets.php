<?php
// Previous Year — Exam → Sets → Questions (master-detail). Sets link by exam_id.
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';

$examId = intval($_GET['exam_id'] ?? 0);
if (!$examId) { header('Location: ' . ADMIN_URL . '/previous_year/index.php'); exit; }

$exam = $pdo->prepare("SELECT * FROM py_exams WHERE id = ?");
$exam->execute([$examId]);
$exam = $exam->fetch();
if (!$exam) { header('Location: ' . ADMIN_URL . '/previous_year/index.php'); exit; }

$subtitle = trim(($exam['exam_full_name'] ?? '') . (!empty($exam['exam_year']) ? ' ' . $exam['exam_year'] : ''));
if ($subtitle === '') $subtitle = 'Previous Year Paper';

$cfg = [
    'category'    => 'previous_year',
    'examId'      => $examId,
    'exam'        => $exam,
    'title'       => $exam['exam_name'],
    'subtitle'    => $subtitle,
    'backUrl'     => ADMIN_URL . '/previous_year/index.php',
    'selfBase'    => ADMIN_URL . '/previous_year/manage_sets.php?exam_id=' . $examId,
    'accent'      => 'var(--warning)',
    'icon'        => 'fa-archive',
    'matchSql'    => "s.category = ? AND s.exam_id = ?",
    'matchParams' => ['previous_year', $examId],
    'addSet'      => function (PDO $pdo, array $post, array $exam) {
        $pdo->prepare("
            INSERT INTO sets (exam_id, category, exam_name, set_number, title, level, total_questions, is_premium)
            VALUES (?, 'previous_year', ?, ?, ?, ?, 10, ?)
        ")->execute([
            (int)$exam['id'],
            $exam['exam_name'],
            intval($post['set_number']),
            trim($post['set_title'] ?? ''),
            $post['level'] ?? 'intermediate',
            !empty($exam['is_premium']) ? 1 : 0,
        ]);
    },
];

require dirname(__DIR__) . '/includes/exam_sets_manager.php';
