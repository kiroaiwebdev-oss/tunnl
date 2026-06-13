<?php
// Shared coupon helpers used by coupons.php (validate) and create_order.php.
// No output here — pure functions.

/**
 * Validate a coupon for a given base price (rupees) + user.
 *
 * Returns:
 *   ['valid' => true,  'coupon' => row, 'discount' => int, 'final' => int]
 *   ['valid' => false, 'message' => '...']
 */
function tunnl_validate_coupon(PDO $pdo, string $code, int $basePrice, ?int $userId): array
{
    $code = strtoupper(trim($code));
    if ($code === '') {
        return ['valid' => false, 'message' => 'Enter a coupon code.'];
    }

    $stmt = $pdo->prepare("SELECT * FROM coupons WHERE code = ? LIMIT 1");
    $stmt->execute([$code]);
    $c = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$c) {
        return ['valid' => false, 'message' => 'Invalid coupon code.'];
    }
    if ((int)$c['is_active'] !== 1) {
        return ['valid' => false, 'message' => 'This coupon is no longer active.'];
    }
    if (!empty($c['expires_at']) && strtotime($c['expires_at'] . ' 23:59:59') < time()) {
        return ['valid' => false, 'message' => 'This coupon has expired.'];
    }
    if ((int)$c['min_amount'] > 0 && $basePrice < (int)$c['min_amount']) {
        return ['valid' => false, 'message' => 'Minimum order of ₹' . (int)$c['min_amount'] . ' required.'];
    }
    if ((int)$c['usage_limit'] > 0 && (int)$c['used_count'] >= (int)$c['usage_limit']) {
        return ['valid' => false, 'message' => 'This coupon has reached its usage limit.'];
    }

    // Per-user limit (count only successful redemptions)
    if ($userId && (int)$c['per_user_limit'] > 0) {
        $u = $pdo->prepare("SELECT COUNT(*) FROM coupon_redemptions WHERE coupon_id=? AND user_id=? AND status='success'");
        $u->execute([(int)$c['id'], $userId]);
        if ((int)$u->fetchColumn() >= (int)$c['per_user_limit']) {
            return ['valid' => false, 'message' => 'You have already used this coupon.'];
        }
    }

    // Compute discount
    $discount = 0;
    if ($c['discount_type'] === 'percent') {
        $discount = (int)floor($basePrice * ((float)$c['discount_value'] / 100));
        if ((int)$c['max_discount'] > 0 && $discount > (int)$c['max_discount']) {
            $discount = (int)$c['max_discount'];
        }
    } else { // flat
        $discount = (int)$c['discount_value'];
    }

    if ($discount < 0) $discount = 0;
    if ($discount > $basePrice) $discount = $basePrice;

    $final = $basePrice - $discount;
    // Razorpay requires amount >= ₹1. If a coupon would make it free, clamp to 1.
    if ($final < 1) $final = 1;

    return [
        'valid'    => true,
        'coupon'   => $c,
        'discount' => $discount,
        'final'    => $final,
    ];
}
