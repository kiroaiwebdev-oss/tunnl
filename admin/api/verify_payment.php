<?php
require_once __DIR__ . '/config.php';
checkApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('POST only');

$user  = requireAuth($pdo);
$input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

$orderId   = trim($input['razorpay_order_id']   ?? '');
$paymentId = trim($input['razorpay_payment_id'] ?? '');
$signature = trim($input['razorpay_signature']  ?? '');
$plan      = $input['plan'] ?? 'monthly'; // monthly | yearly | lifetime

if (!$orderId || !$paymentId || !$signature) {
    error('Payment details missing');
}

// Verify Razorpay signature
$generatedSig = hash_hmac('sha256', $orderId . '|' . $paymentId, RAZORPAY_KEY_SECRET);

if (!hash_equals($generatedSig, $signature)) {
    // Log failed attempt
    $pdo->prepare("
        INSERT INTO transactions
          (user_id, razorpay_order_id, razorpay_payment_id,
           amount, type, status, note, created_at)
        VALUES (?,?,?,0,'razorpay','failed','Signature mismatch',NOW())
    ")->execute([$user['id'], $orderId, $paymentId]);

    error('Payment verification failed', 402);
}

// Get amount from settings
$settings = $pdo->query("SELECT setting_key, setting_value FROM app_settings")
                ->fetchAll(PDO::FETCH_KEY_PAIR);

$planAmounts = [
    'monthly'  => intval($settings['premium_price']         ?? 299),
    'yearly'   => intval($settings['premium_yearly_price']  ?? 999),
    'lifetime' => intval($settings['premium_lifetime_price']?? 1999),
];
$amount = $planAmounts[$plan] ?? 299;

// Set expiry
$expiry = null;
if ($plan === 'monthly') {
    $expiry = date('Y-m-d', strtotime('+1 month'));
} elseif ($plan === 'yearly') {
    $expiry = date('Y-m-d', strtotime('+1 year'));
}
// lifetime = null (no expiry)

// Update user premium
$pdo->prepare("UPDATE users SET is_premium=1, premium_expiry=? WHERE id=?")
    ->execute([$expiry, $user['id']]);

// Log transaction
$pdo->prepare("
    INSERT INTO transactions
      (user_id, razorpay_order_id, razorpay_payment_id,
       amount, type, plan, status, note, created_at)
    VALUES (?,?,?,?,'razorpay',?,'success','Payment verified',NOW())
")->execute([$user['id'], $orderId, $paymentId, $amount, $plan]);

response([
    'success'        => true,
    'message'        => 'Payment verified! Premium activated 🎉',
    'premium'        => [
        'plan'       => $plan,
        'amount'     => $amount,
        'expiry'     => $expiry ?? 'Lifetime',
        'activated'  => true,
    ],
]);