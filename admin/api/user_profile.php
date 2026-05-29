<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$method = $_SERVER['REQUEST_METHOD'];

// ══════════════════════════════════════
// GET — Fetch Profile
// ══════════════════════════════════════
if ($method === 'GET') {
    $user = requireAuth($pdo);

    $stats = $pdo->prepare("
        SELECT
          COUNT(*) as total_tests,
          COALESCE(SUM(correct), 0) as total_correct,
          COALESCE(AVG(accuracy), 0) as avg_accuracy,
          MAX(score) as best_score
        FROM user_test_history
        WHERE user_id = ?
    ");
    $stats->execute([$user['id']]);
    $statsRow = $stats->fetch();

    $recent = $pdo->prepare("
        SELECT category, score, total_questions, accuracy,
               time_taken, xp_earned, completed_at
        FROM user_test_history
        WHERE user_id = ?
        ORDER BY completed_at DESC LIMIT 5
    ");
    $recent->execute([$user['id']]);
    $recentRows = $recent->fetchAll();

    response([
        'success' => true,
        'data'    => [
            'user' => [
                'id'             => intval($user['id']),
                'name'           => $user['name'] ?? '',
                'phone'          => $user['phone'] ?? '',
                'standard'       => $user['standard'] ?? '',
                'profile_image'  => $user['profile_image'] ?? '',
                'is_premium'     => (bool)$user['is_premium'],
                'premium_expiry' => $user['premium_expiry'],
                'total_xp'       => intval($user['total_xp']),
                'current_streak' => intval($user['current_streak']),
                'max_streak'     => intval($user['max_streak'] ?? 0),
                'rank_position'  => intval($user['rank_position']),
                'last_active'    => $user['last_active'],
                'created_at'     => $user['created_at'],
            ],
            'stats' => [
                'total_tests'   => intval($statsRow['total_tests']),
                'total_correct' => intval($statsRow['total_correct']),
                'avg_accuracy'  => round((float)$statsRow['avg_accuracy'], 1),
                'best_score'    => intval($statsRow['best_score'] ?? 0),
            ],
            'recent_tests' => array_map(fn($r) => [
                'category'        => $r['category'],
                'score'           => intval($r['score']),
                'total_questions' => intval($r['total_questions']),
                'accuracy'        => round((float)$r['accuracy'], 1),
                'time_taken'      => intval($r['time_taken']),
                'xp_earned'       => intval($r['xp_earned']),
                'completed_at'    => $r['completed_at'],
            ], $recentRows),
        ],
    ]);
    exit();
}

// ══════════════════════════════════════
// POST — Update Profile (Setup)
// ══════════════════════════════════════
if ($method === 'POST') {
    $user  = requireAuth($pdo);
    $input = json_decode(file_get_contents('php://input'), true);
    if (empty($input)) $input = $_POST; // fallback

    $updates = [];
    $params  = [];

    // ✅ Name
    if (!empty($input['name'])) {
        $updates[] = 'name = ?';
        $params[]  = trim($input['name']);
    }

    // ✅ Standard (YE PEHLE MISSING THA — MAIN BUG)
    if (isset($input['standard']) && $input['standard'] !== '') {
        $updates[] = 'standard = ?';
        $params[]  = trim($input['standard']);
    }

    // ✅ FCM Token
    if (!empty($input['fcm_token'])) {
        $updates[] = 'fcm_token = ?';
        $params[]  = trim($input['fcm_token']);
    }

    if (empty($updates)) {
        response(['success' => false, 'message' => 'Nothing to update']);
        exit();
    }

    $params[] = $user['id'];
    $pdo->prepare(
        "UPDATE users SET " . implode(', ', $updates) . " WHERE id = ?"
    )->execute($params);

    // ✅ Updated user wapis bhejo
    $stmt = $pdo->prepare("SELECT name, standard FROM users WHERE id = ?");
    $stmt->execute([$user['id']]);
    $updated = $stmt->fetch();

    response([
        'success' => true,
        'message' => 'Profile updated successfully',
        'data'    => [
            'name'     => $updated['name'],
            'standard' => $updated['standard'],
        ],
    ]);
    exit();
}

http_response_code(405);
response(['success' => false, 'message' => 'Method not allowed']);