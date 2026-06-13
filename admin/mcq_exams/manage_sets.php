<?php
// 5000 MCQ — Exam → Sets → Questions (master-detail). Sets link by exam_name.
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';

$examId = intval($_GET['exam_id'] ?? 0);
if (!$examId) { header('Location: ' . ADMIN_URL . '/mcq_exams/index.php'); exit; }

$exam = $pdo->prepare("SELECT * FROM mcq_exams WHERE id = ?");
$exam->execute([$examId]);
$exam = $exam->fetch();
if (!$exam) { header('Location: ' . ADMIN_URL . '/mcq_exams/index.php'); exit; }

$cfg = [
    'category'    => 'mcq',
    'examId'      => $examId,
    'exam'        => $exam,
    'title'       => $exam['exam_name'],
    'subtitle'    => $exam['exam_full_name'] ?: '5000 Speed MCQs',
    'backUrl'     => ADMIN_URL . '/mcq_exams/index.php',
    'selfBase'    => ADMIN_URL . '/mcq_exams/manage_sets.php?exam_id=' . $examId,
    'accent'      => 'var(--cyan)',
    'icon'        => 'fa-bolt',
    'matchSql'    => "s.category = ? AND s.exam_name = ?",
    'matchParams' => ['mcq', $exam['exam_name']],
    'addSet'      => function (PDO $pdo, array $post, array $exam) {
        $pdo->prepare("
            INSERT INTO sets (category, exam_name, set_number, title, level, total_questions, is_premium)
            VALUES ('mcq', ?, ?, ?, ?, 10, ?)
        ")->execute([
            $exam['exam_name'],
            intval($post['set_number']),
            trim($post['set_title'] ?? ''),
            $post['level'] ?? 'intermediate',
            !empty($exam['is_premium']) ? 1 : 0,
        ]);
    },
];

require dirname(__DIR__) . '/includes/exam_sets_manager.php';
