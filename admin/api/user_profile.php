<?php
require_once __DIR__ . '/config.php';
checkApiKey();

$method = $_SERVER['REQUEST_METHOD'];

/**
 * Helper — returns true if column exists. Used so the API never crashes
 * if the migration hasn't been run yet.
 */
function colExists(PDO $pdo, string $table, string $col): bool {
    static $cache = [];
    $key = "$table.$col";
    if (isset($cache[$key])) return $cache[$key];
    try {
        $stmt = $pdo->prepare(
            "SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = ? AND COLUMN_NAME = ?"
        );
        $stmt->execute([$table, $col]);
        return $cache[$key] = ((int)$stmt->fetchColumn() > 0);
    } catch (Throwable $e) {
        return $cache[$key] = false;
    }
}

// ══════════════════════════════════════════════════════
// GET — Fetch profile + stats + recent tests
// ══════════════════════════════════════════════════════
if ($method === 'GET') {
    $user = requireAuth($pdo);

    $stats = $pdo->prepare("
        SELECT
          COUNT(*)                          AS total_tests,
          COALESCE(SUM(total_questions), 0) AS total_questions,
          COALESCE(SUM(correct), 0)         AS total_correct,
          COALESCE(SUM(wrong),   0)         AS total_wrong,
          COALESCE(AVG(accuracy), 0)        AS avg_accuracy,
          COALESCE(MAX(score),    0)        AS best_score
        FROM user_test_history
        WHERE user_id = ?
    ");
    $stats->execute([$user['id']]);
    $statsRow = $stats->fetch() ?: [];

    $recent = $pdo->prepare("
        SELECT category, score, total_questions, accuracy,
               time_taken, xp_earned, completed_at
        FROM user_test_history
        WHERE user_id = ?
        ORDER BY completed_at DESC LIMIT 50
    ");
    $recent->execute([$user['id']]);
    $recentRows = $recent->fetchAll();

    response([
        'success' => true,
        'data'    => [
            'user' => [
                'id'             => intval($user['id']),
                'name'           => $user['name']           ?? '',
                'phone'          => $user['phone']          ?? '',
                'standard'       => $user['standard']       ?? '',
                'profile_image'  => $user['profile_image']  ?? '',
                'is_premium'     => !empty($user['is_premium']),
                'premium_expiry' => $user['premium_expiry'] ?? null,
                'total_xp'       => intval($user['total_xp']       ?? 0),
                'current_streak' => intval($user['current_streak'] ?? 0),
                'max_streak'     => intval($user['max_streak']     ?? 0),
                'rank_position'  => intval($user['rank_position']  ?? 0),
                'last_active'    => $user['last_active']    ?? null,
                'created_at'     => $user['created_at']     ?? null,
            ],
            'stats' => [
                'total_tests'     => intval($statsRow['total_tests']     ?? 0),
                'total_questions' => intval($statsRow['total_questions'] ?? 0),
                'total_correct'   => intval($statsRow['total_correct']   ?? 0),
                'total_wrong'     => intval($statsRow['total_wrong']     ?? 0),
                'avg_accuracy'    => round((float)($statsRow['avg_accuracy'] ?? 0), 1),
                'best_score'      => intval($statsRow['best_score']      ?? 0),
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

// ══════════════════════════════════════════════════════
// POST — Update profile (name / standard / fcm / image)
// Accepts JSON body OR multipart for image upload.
// ══════════════════════════════════════════════════════
if ($method === 'POST') {
    $user = requireAuth($pdo);

    // Read JSON or form-data
    $rawJson = file_get_contents('php://input');
    $input   = [];
    if (!empty($rawJson)) {
        $decoded = json_decode($rawJson, true);
        if (is_array($decoded)) $input = $decoded;
    }
    if (empty($input)) $input = $_POST;

    $updates = [];
    $params  = [];

    // ── Name
    if (isset($input['name'])) {
        $name = trim((string)$input['name']);
        if ($name === '') {
            response(['success' => false, 'message' => 'Name cannot be empty']);
            exit();
        }
        $updates[] = 'name = ?';
        $params[]  = $name;
    }

    // ── Standard (only if column exists, otherwise silently ignore)
    if (isset($input['standard']) && colExists($pdo, 'users', 'standard')) {
        $updates[] = 'standard = ?';
        $params[]  = trim((string)$input['standard']);
    }

    // ── FCM token
    if (!empty($input['fcm_token']) && colExists($pdo, 'users', 'fcm_token')) {
        $updates[] = 'fcm_token = ?';
        $params[]  = trim((string)$input['fcm_token']);
    }

    // ── Profile image upload (multipart)
    if (!empty($_FILES['profile_image']['tmp_name']) && colExists($pdo, 'users', 'profile_image')) {
        $file = $_FILES['profile_image'];
        if ($file['error'] === UPLOAD_ERR_OK) {
            $allowed = ['jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'png' => 'image/png', 'webp' => 'image/webp'];
            $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
            if (!isset($allowed[$ext])) {
                response(['success' => false, 'message' => 'Only JPG/PNG/WEBP allowed']);
                exit();
            }
            if ($file['size'] > 4 * 1024 * 1024) {
                response(['success' => false, 'message' => 'Image must be ≤ 4 MB']);
                exit();
            }

            // Resolve uploads dir robustly (parent must exist)
            $uploadsParent = dirname(__DIR__) . '/uploads';
            if (!is_dir($uploadsParent)) {
                @mkdir($uploadsParent, 0755, true);
            }
            $userDir = $uploadsParent . '/profiles';
            if (!is_dir($userDir)) {
                @mkdir($userDir, 0755, true);
            }

            // Sanity checks the image picker fix actually wrote a file
            if (!is_dir($userDir) || !is_writable($userDir)) {
                response([
                    'success' => false,
                    'message' => 'Server cannot write uploads. Please CHMOD admin/uploads/profiles to 755.',
                ], 500);
                exit();
            }

            $fname = 'u' . $user['id'] . '_' . time() . '.' . $ext;
            $dest  = $userDir . '/' . $fname;
            if (!@move_uploaded_file($file['tmp_name'], $dest)) {
                response(['success' => false, 'message' => 'Failed to save image'], 500);
                exit();
            }

            $publicUrl = rtrim(ADMIN_URL, '/') . '/uploads/profiles/' . $fname;
            $updates[] = 'profile_image = ?';
            $params[]  = $publicUrl;
        }
    } elseif (isset($input['profile_image']) && colExists($pdo, 'users', 'profile_image')) {
        $updates[] = 'profile_image = ?';
        $params[]  = trim((string)$input['profile_image']);
    }

    if (empty($updates)) {
        response(['success' => false, 'message' => 'Nothing to update']);
        exit();
    }

    $params[] = $user['id'];
    try {
        $pdo->prepare(
            "UPDATE users SET " . implode(', ', $updates) . " WHERE id = ?"
        )->execute($params);
    } catch (Throwable $e) {
        response(['success' => false, 'message' => 'Update failed: ' . $e->getMessage()], 500);
        exit();
    }

    // Updated user wapis bhejo
    $stmt = $pdo->prepare("SELECT id, name, standard, profile_image FROM users WHERE id = ?");
    try {
        $stmt->execute([$user['id']]);
        $updated = $stmt->fetch() ?: [];
    } catch (Throwable $e) {
        // standard or profile_image column missing — fall back
        $stmt2 = $pdo->prepare("SELECT id, name FROM users WHERE id = ?");
        $stmt2->execute([$user['id']]);
        $updated = $stmt2->fetch() ?: [];
    }

    response([
        'success' => true,
        'message' => 'Profile updated successfully',
        'data'    => [
            'name'          => $updated['name']          ?? '',
            'standard'      => $updated['standard']      ?? '',
            'profile_image' => $updated['profile_image'] ?? '',
        ],
    ]);
    exit();
}

http_response_code(405);
response(['success' => false, 'message' => 'Method not allowed']);
