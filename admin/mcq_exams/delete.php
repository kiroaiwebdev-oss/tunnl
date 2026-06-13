<?php
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
header('Content-Type: application/json');
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success'=>false,'message'=>'Invalid request']); exit;
}
$id = intval($_POST['id'] ?? 0);
if (!$id) { echo json_encode(['success'=>false,'message'=>'Invalid ID']); exit; }
try {
    // Only remove the exam grouping; the mcq sets remain (unlinked).
    $pdo->prepare("DELETE FROM mcq_exams WHERE id = ?")->execute([$id]);
    echo json_encode(['success'=>true]);
} catch (Exception $e) {
    echo json_encode(['success'=>false,'message'=>$e->getMessage()]);
}
