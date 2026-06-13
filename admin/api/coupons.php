<?php
// Public-ish endpoint: validate a coupon code and preview the discount.
// Auth optional — if a Bearer token is sent we also enforce per-user limits.
//
// POST { code, plan? }  →  { success, valid, code, discount_type,
//                            discount_value, base_price, discount, final_price, message }

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/_coupon_lib.php';
checkApiKey();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') error('POST only', 405);

$user  = getAuthUser($pdo); // may be null
$input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

$code = (string)($input['code'] ?? '');
$plan = (string)($input['plan'] ?? 'lifetime');

// Resolve base price from settings (same logic as create_order.php)
$settings = $pdo->query("SELECT setting_key, setting_value FROM app_settings")
                ->fetchAll(PDO::FETCH_KEY_PAIR);
$basePrice = intval($settings['premium_price'] ?? 50);
if ($plan === 'yearly') {
    $basePrice = intval($settings['premium_yearly_price'] ?? 499);
}
if ($basePrice < 1) $basePrice = 50;

$res = tunnl_validate_coupon($pdo, $code, $basePrice, $user['id'] ?? null);

if (!$res['valid']) {
    response([
        'success'     => true,
        'valid'       => false,
        'base_price'  => $basePrice,
        'message'     => $res['message'],
    ]);
}

$c = $res['coupon'];
response([
    'success'        => true,
    'valid'          => true,
    'code'           => $c['code'],
    'discount_type'  => $c['discount_type'],
    'discount_value' => (float)$c['discount_value'],
    'base_price'     => $basePrice,
    'discount'       => $res['discount'],
    'final_price'    => $res['final'],
    'message'        => 'Coupon applied! You save ₹' . $res['discount'] . '.',
]);
