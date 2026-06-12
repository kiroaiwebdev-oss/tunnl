<?php
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Invalid request']); exit;
}
$id = intval($_POST['id'] ?? 0);
if (!$id) { echo json_encode(['success' => false, 'message' => 'Invalid ID']); exit; }

try {
    $pdo->beginTransaction();
    // Remove the set's questions first, then the set itself.
    $pdo->prepare("DELETE FROM questions WHERE set_id = ?")->execute([$id]);
    $pdo->prepare("DELETE FROM sets WHERE id = ?")->execute([$id]);
    $pdo->commit();
    echo json_encode(['success' => true]);
} catch (Throwable $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
