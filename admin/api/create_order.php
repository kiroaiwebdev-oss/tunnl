<?php
// Creates a Razorpay order for premium upgrade.
// Reads razorpay_key_id + razorpay_key_secret from app_settings (or falls
// back to constants in admin/config/constants.php).
//
// Auth: Bearer JWT required.

require_once __DIR__ . '/config.php';
checkApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('POST only', 405);

$user  = requireAuth($pdo);
$input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

$plan = isset($input['plan']) ? (string)$input['plan'] : 'lifetime';
$plan = in_array($plan, ['monthly', 'yearly', 'lifetime'], true) ? $plan : 'lifetime';

// ── Read settings (key_id, key_secret, prices) ──────
$settings = $pdo->query(
    "SELECT setting_key, setting_value FROM app_settings"
)->fetchAll(PDO::FETCH_KEY_PAIR);

// Hard-disabled by admin? Treat empty as enabled (default-on behaviour).
$enabledRaw = strtolower(trim((string)($settings['razorpay_enabled'] ?? '1')));
if (in_array($enabledRaw, ['0','false','no','off','disabled'], true)) {
    error('Online payments are temporarily disabled. Please contact support.', 503);
}

$keyId = trim($settings['razorpay_key_id'] ?? '');
$keySecret = trim($settings['razorpay_key_secret'] ?? '');

// Fallback to constants if admin hasn't set them via UI
if (!$keyId && defined('RAZORPAY_KEY_ID')) {
    $keyId = trim(RAZORPAY_KEY_ID);
}
if (!$keySecret && defined('RAZORPAY_KEY_SECRET')) {
    $keySecret = trim(RAZORPAY_KEY_SECRET);
}

if (!$keyId || !$keySecret ||
    str_starts_with($keyId, 'your_') ||
    str_starts_with($keySecret, 'your_')) {
    error('Payment gateway not configured. Please contact support.', 503);
}

// ── Resolve amount ──────────────────────────────────
// The app displays `premium_price` and only sells a one-time unlock, so the
// charged amount MUST match `premium_price` to avoid display/charge mismatch.
$basePrice = intval($settings['premium_price'] ?? 50);
$priceMap = [
    'monthly'  => $basePrice,
    'yearly'   => intval($settings['premium_yearly_price'] ?? 499),
    'lifetime' => $basePrice,
];
$amountRupees = $priceMap[$plan] ?? $basePrice;
if ($amountRupees < 1) error('Invalid amount configuration', 500);

$amountPaise = $amountRupees * 100;

// ── Hit Razorpay API to create the order ────────────
$receipt = 'tunnl_' . $user['id'] . '_' . time();
$payload = [
    'amount'   => $amountPaise,
    'currency' => 'INR',
    'receipt'  => $receipt,
    'notes'    => [
        'user_id' => (string)$user['id'],
        'phone'   => (string)($user['phone'] ?? ''),
        'plan'    => $plan,
    ],
];

$ch = curl_init('https://api.razorpay.com/v1/orders');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_USERPWD        => "$keyId:$keySecret",
    CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
    CURLOPT_POST           => true,
    CURLOPT_POSTFIELDS     => json_encode($payload),
    CURLOPT_TIMEOUT        => 20,
    CURLOPT_CONNECTTIMEOUT => 10,
]);
$rzpResp = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlErr  = curl_error($ch);
curl_close($ch);

if ($curlErr) error('Network error: ' . $curlErr, 502);
if (!$rzpResp) error('Empty response from gateway', 502);

$rzpData = json_decode($rzpResp, true);
if ($httpCode >= 400 || empty($rzpData['id'])) {
    $msg = $rzpData['error']['description'] ?? 'Failed to create order';
    error($msg, 502);
}

// ── Log a pending transaction ───────────────────────
try {
    $pdo->prepare("
        INSERT INTO transactions
          (user_id, razorpay_order_id, amount, type, plan, status, note, created_at)
        VALUES (?, ?, ?, 'razorpay', ?, 'pending', 'Order created', NOW())
    ")->execute([$user['id'], $rzpData['id'], $amountRupees, $plan]);
} catch (Exception $_) {
    // Non-fatal — table may not have all columns. Continue.
}

// ── Respond ─────────────────────────────────────────
response([
    'success'   => true,
    'message'   => 'Order created',
    'order_id'  => $rzpData['id'],
    'key_id'    => $keyId,
    'amount'    => $amountPaise,
    'currency'  => 'INR',
    'plan'      => $plan,
    'rupees'    => $amountRupees,
    'name'      => $user['name'] ?? '',
    'phone'     => $user['phone'] ?? '',
]);
