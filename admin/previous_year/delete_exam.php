<?php
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
header('Content-Type: application/json');
$id = intval($_POST['id'] ?? 0);
if (!$id) { echo json_encode(['success'=>false,'message'=>'Invalid ID']); exit; }
try {
    $pdo->beginTransaction();
    // Delete questions under sets of this exam
    $pdo->prepare("
        DELETE q FROM questions q
        INNER JOIN sets s ON q.set_id = s.id
        WHERE s.exam_id = ?
    ")->execute([$id]);
    $pdo->prepare("DELETE FROM sets WHERE exam_id=?")->execute([$id]);
    $pdo->prepare("DELETE FROM py_exams WHERE id=?")->execute([$id]);
    $pdo->commit();
    echo json_encode(['success'=>true]);
} catch (Exception $e) {
    $pdo->rollBack();
    echo json_encode(['success'=>false,'message'=>$e->getMessage()]);
}