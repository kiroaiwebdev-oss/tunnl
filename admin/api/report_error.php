<?php
// Public endpoint: lets an app user submit a "technical error" report.
// Stored in tech_reports for the admin panel to review.
//
// POST JSON: { message, app_version? }  (Bearer token optional but captured)
// Returns { success, message }

require_once __DIR__ . '/config.php';
checkApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error('Method not allowed', 405);
}

$user  = getAuthUser($pdo);
$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) $input = $_POST;

$message    = trim($input['message']     ?? '');
$appVersion = trim($input['app_version'] ?? '');

if ($message === '') {
    error('Please describe the technical error.');
}

try {
    $stmt = $pdo->prepare("
        INSERT INTO tech_reports (user_id, name, phone, message, app_version)
        VALUES (?, ?, ?, ?, ?)
    ");
    $stmt->execute([
        $user['id']   ?? null,
        $user['name'] ?? '',
        $user['phone'] ?? '',
        mb_substr($message, 0, 2000),
        mb_substr($appVersion, 0, 30),
    ]);
} catch (Exception $e) {
    error('Could not submit report. Please try again.', 500);
}

response(['success' => true, 'message' => 'Report submitted. Thank you!']);
