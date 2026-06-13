<?php
// Verifies Razorpay payment signature, marks user as premium, logs txn.
// Reads razorpay_key_secret from app_settings (with constant fallback) so
// admin can rotate it from the UI without redeploying code.

require_once __DIR__ . '/config.php';
checkApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('POST only');

$user  = requireAuth($pdo);
$input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

$orderId   = trim($input['razorpay_order_id']   ?? '');
$paymentId = trim($input['razorpay_payment_id'] ?? '');
$signature = trim($input['razorpay_signature']  ?? '');
$plan      = $input['plan'] ?? 'lifetime';

if (!$orderId || !$paymentId || !$signature) {
    error('Payment details missing');
}

// ── Read key_secret from settings (admin UI configurable) ──
$settings = $pdo->query(
    "SELECT setting_key, setting_value FROM app_settings"
)->fetchAll(PDO::FETCH_KEY_PAIR);

$keySecret = trim((string)($settings['razorpay_key_secret'] ?? ''));
if (!$keySecret && defined('RAZORPAY_KEY_SECRET')) {
    $keySecret = trim((string)RAZORPAY_KEY_SECRET);
}
if (!$keySecret || str_starts_with($keySecret, 'your_')) {
    error('Payment gateway not configured', 503);
}

// ── Verify Razorpay signature ───────────────────────
$generatedSig = hash_hmac('sha256', $orderId . '|' . $paymentId, $keySecret);

if (!hash_equals($generatedSig, $signature)) {
    try {
        $pdo->prepare("
            INSERT INTO transactions
              (user_id, razorpay_order_id, razorpay_payment_id,
               amount, type, status, note, created_at)
            VALUES (?,?,?,0,'razorpay','failed','Signature mismatch',NOW())
        ")->execute([$user['id'], $orderId, $paymentId]);
    } catch (Exception $_) {}
    error('Payment verification failed', 402);
}

// ── Resolve amount based on plan ────────────────────
$planAmounts = [
    'monthly'  => intval($settings['premium_price']          ?? 50),
    'yearly'   => intval($settings['premium_yearly_price']   ?? 499),
    'lifetime' => intval($settings['premium_lifetime_price'] ?? intval($settings['premium_price'] ?? 50)),
];
$amount = $planAmounts[$plan] ?? 50;

// ── Set expiry ──────────────────────────────────────
$expiry = null;
if ($plan === 'monthly') {
    $expiry = date('Y-m-d', strtotime('+1 month'));
} elseif ($plan === 'yearly') {
    $expiry = date('Y-m-d', strtotime('+1 year'));
}
// lifetime → expiry stays null

// ── Update user ─────────────────────────────────────
$pdo->prepare("UPDATE users SET is_premium=1, premium_expiry=? WHERE id=?")
    ->execute([$expiry, $user['id']]);

// ── Log transaction ─────────────────────────────────
try {
    $pdo->prepare("
        INSERT INTO transactions
          (user_id, razorpay_order_id, razorpay_payment_id,
           amount, type, plan, status, note, created_at)
        VALUES (?,?,?,?,'razorpay',?,'success','Payment verified',NOW())
        ON DUPLICATE KEY UPDATE
          razorpay_payment_id = VALUES(razorpay_payment_id),
          status              = 'success',
          note                = 'Payment verified',
          amount              = VALUES(amount),
          plan                = VALUES(plan)
    ")->execute([$user['id'], $orderId, $paymentId, $amount, $plan]);
} catch (Exception $_) {
    // Fallback insert without ON DUPLICATE clause for old schemas
    try {
        $pdo->prepare("
            INSERT INTO transactions
              (user_id, razorpay_order_id, razorpay_payment_id,
               amount, type, plan, status, note, created_at)
            VALUES (?,?,?,?,'razorpay',?,'success','Payment verified',NOW())
        ")->execute([$user['id'], $orderId, $paymentId, $amount, $plan]);
    } catch (Exception $_) {}
}

response([
    'success' => true,
    'message' => 'Payment verified! Premium activated 🎉',
    'premium' => [
        'plan'      => $plan,
        'amount'    => $amount,
        'expiry'    => $expiry ?? 'Lifetime',
        'activated' => true,
    ],
]);
