<?php
require_once __DIR__ . '/config.php';
checkApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('POST only');

$input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
$phone = trim($input['phone'] ?? '');
$otp   = trim($input['otp']   ?? '');
$name  = trim($input['name']  ?? '');
$fcmToken = trim($input['fcm_token'] ?? '');

if (!$phone || !$otp) error('Phone and OTP required');

// Verify OTP
$log = $pdo->prepare("
    SELECT * FROM otp_logs
    WHERE phone = ? AND otp = ? AND expires_at > NOW() AND is_used = 0
    ORDER BY created_at DESC LIMIT 1
");
$log->execute([$phone, $otp]);
$log = $log->fetch();

if (!$log) error('Invalid or expired OTP');

// Mark OTP used
$pdo->prepare("UPDATE otp_logs SET is_used=1 WHERE id=?")
    ->execute([$log['id']]);

// Find or create user
$user = $pdo->prepare("SELECT * FROM users WHERE phone=? LIMIT 1");
$user->execute([$phone]);
$user = $user->fetch();

$isNew = false;
if (!$user) {
    // New user
    $isNew = true;
    $pdo->prepare("
        INSERT INTO users (phone, name, created_at, last_active)
        VALUES (?,?,NOW(),NOW())
    ")->execute([$phone, $name ?: null]);
    $userId = $pdo->lastInsertId();
    $user   = $pdo->prepare("SELECT * FROM users WHERE id=?");
    $user->execute([$userId]);
    $user   = $user->fetch();
}

// Generate auth token
$token     = bin2hex(random_bytes(32));
$expiresAt = date('Y-m-d H:i:s', time() + (30 * 86400)); // 30 days

$pdo->prepare("
    UPDATE users SET
      auth_token=?, token_expires_at=?,
      last_active=NOW()
      " . ($name && !$user['name'] ? ", name=?" : "") . "
      " . ($fcmToken ? ", fcm_token=?" : "") . "
    WHERE id=?
")->execute(array_filter([
    $token,
    $expiresAt,
    ($name && !$user['name']) ? $name   : null,
    $fcmToken                 ? $fcmToken : null,
    $user['id'],
], fn($v) => $v !== null));

response([
    'success'    => true,
    'is_new_user'=> $isNew,
    'token'      => $token,
    'user'       => [
        'id'              => $user['id'],
        'name'            => $user['name'],
        'phone'           => $user['phone'],
        'is_premium'      => (bool)$user['is_premium'],
        'premium_expiry'  => $user['premium_expiry'],
        'total_xp'        => intval($user['total_xp']),
        'current_streak'  => intval($user['current_streak']),
        'rank_position'   => intval($user['rank_position']),
        'profile_image'   => $user['profile_image'],
    ],
]);