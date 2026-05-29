<?php
require_once 'config.php';

$body  = json_decode(file_get_contents('php://input'), true);
$phone = trim($body['phone'] ?? '');
$otp   = trim($body['otp']   ?? '');
$step  = trim($body['step']  ?? 'send');

if (!preg_match('/^[6-9]\d{9}$/', $phone)) fail('Invalid phone number');

// ── Helper: Send SMS ──────────────────────────────────
function sendOtpSms($pdo, $phone, $otp_code) {
    $settings = $pdo->query("
        SELECT setting_key, setting_value FROM app_settings
        WHERE setting_key IN ('sms_provider','sms_api_key','sms_sender_id','otp_message','otp_expiry_minutes')
    ")->fetchAll(PDO::FETCH_KEY_PAIR);

    $provider = $settings['sms_provider'] ?? 'fast2sms';
    $apiKey   = $settings['sms_api_key']  ?? '';
    $senderId = $settings['sms_sender_id'] ?? '';
    $msgTpl   = $settings['otp_message']  ?? 'Your TUNNEL OTP is {otp}. Valid for 10 minutes. Do not share.';
    $message  = str_replace('{otp}', $otp_code, $msgTpl);

    if (empty($apiKey)) {
        // Log karo agar key missing hai
        file_put_contents(__DIR__ . '/sms_log.txt',
            date('Y-m-d H:i:s') . " | SKIPPED — sms_api_key empty\n", FILE_APPEND);
        return;
    }

    // Sirf 10 digits — 91 prefix remove karo
    $cleanPhone = preg_replace('/[^0-9]/', '', $phone);
    if (strlen($cleanPhone) === 12 && str_starts_with($cleanPhone, '91')) {
        $cleanPhone = substr($cleanPhone, 2);
    }

    $result    = '';
    $curlError = '';

    if ($provider === 'fast2sms') {
        // ✅ Fast2SMS official docs: JSON body + content-type header
        $fields = json_encode([
            'variables_values' => $otp_code,
            'route'            => 'otp',
            'numbers'          => $cleanPhone,
        ]);

        $ch = curl_init('https://www.fast2sms.com/dev/bulkV2');
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_SSL_VERIFYHOST => 0,
            CURLOPT_SSL_VERIFYPEER => 0,
            CURLOPT_TIMEOUT        => 15,
            CURLOPT_HTTP_VERSION   => CURL_HTTP_VERSION_1_1,
            CURLOPT_POSTFIELDS     => $fields,
            CURLOPT_HTTPHEADER     => [
                "authorization: $apiKey",
                "accept: */*",
                "cache-control: no-cache",
                "content-type: application/json",  // ← ye missing tha
            ],
        ]);
        $result    = curl_exec($ch);
        $curlError = curl_error($ch);
        curl_close($ch);

    } elseif ($provider === 'msg91') {
        $url = "https://api.msg91.com/api/v5/otp"
             . "?template_id={$senderId}"
             . "&mobile=91{$cleanPhone}"
             . "&authkey={$apiKey}"
             . "&otp={$otp_code}";
        $ch  = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 15,
            CURLOPT_HTTPHEADER     => ['content-type: application/json'],
        ]);
        $result    = curl_exec($ch);
        $curlError = curl_error($ch);
        curl_close($ch);

    } elseif ($provider === 'twilio') {
        $parts = explode(':', $apiKey);
        $sid   = $parts[0] ?? '';
        $token = $parts[1] ?? '';
        $url   = "https://api.twilio.com/2010-04-01/Accounts/{$sid}/Messages.json";
        $ch    = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_USERPWD        => "$sid:$token",
            CURLOPT_TIMEOUT        => 15,
            CURLOPT_POSTFIELDS     => http_build_query([
                'From' => $senderId ?: '+1234567890',
                'To'   => '+91' . $cleanPhone,
                'Body' => $message,
            ]),
        ]);
        $result    = curl_exec($ch);
        $curlError = curl_error($ch);
        curl_close($ch);

    } elseif ($provider === 'textlocal') {
        $ch = curl_init('https://api.textlocal.in/send/');
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 15,
            CURLOPT_POSTFIELDS     => http_build_query([
                'apikey'  => $apiKey,
                'numbers' => '91' . $cleanPhone,
                'message' => $message,
                'sender'  => $senderId ?: 'TUNNEL',
            ]),
        ]);
        $result    = curl_exec($ch);
        $curlError = curl_error($ch);
        curl_close($ch);
    }

    // ── Log response (debugging ke liye — baad me hata dena) ──
    file_put_contents(__DIR__ . '/sms_log.txt',
        date('Y-m-d H:i:s') . " | Provider: $provider | Phone: $cleanPhone | OTP: $otp_code\n" .
        "Response: $result\n" .
        "cURL Error: " . ($curlError ?: 'none') . "\n" .
        "---\n",
        FILE_APPEND
    );
}

// ── Step 1: Send OTP ─────────────────────────────────
if ($step === 'send') {
    $expiryRow = $pdo->query("SELECT setting_value FROM app_settings WHERE setting_key='otp_expiry_minutes'")->fetch();
    $expiryMin = (int)($expiryRow['setting_value'] ?? 10);
    $expires   = date('Y-m-d H:i:s', strtotime("+{$expiryMin} minutes"));
    $otp_code  = (defined('OTP_DEBUG') && OTP_DEBUG) ? '123456' : str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

    $pdo->prepare("
        INSERT INTO otp_store (phone, otp, expires_at)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE otp=?, expires_at=?
    ")->execute([$phone, $otp_code, $expires, $otp_code, $expires]);

    sendOtpSms($pdo, $phone, $otp_code);

    $response = ['phone' => $phone];
    if (defined('OTP_DEBUG') && OTP_DEBUG) $response['debug_otp'] = $otp_code;
    ok($response, 'OTP sent');
}

// ── Step 2: Verify OTP ───────────────────────────────
if ($step === 'verify') {
    if (empty($otp)) fail('OTP required');

    $row = $pdo->prepare("SELECT * FROM otp_store WHERE phone=?");
    $row->execute([$phone]);
    $stored = $row->fetch();

    if (!$stored)                                  fail('OTP not requested');
    if ($stored['otp'] !== $otp)                   fail('Wrong OTP');
    if (strtotime($stored['expires_at']) < time()) fail('OTP expired');

    $pdo->prepare("DELETE FROM otp_store WHERE phone=?")->execute([$phone]);

    $u = $pdo->prepare("SELECT * FROM users WHERE phone=?");
    $u->execute([$phone]);
    $user = $u->fetch();

    if (!$user) {
        $pdo->prepare("INSERT INTO users (phone, created_at) VALUES (?, NOW())")->execute([$phone]);
        $u->execute([$phone]);
        $user = $u->fetch();
    }

    $pdo->prepare("UPDATE users SET last_active=NOW() WHERE id=?")->execute([$user['id']]);

    $token = generateJWT([
        'user_id'    => $user['id'],
        'phone'      => $user['phone'],
        'is_premium' => $user['is_premium'],
        'exp'        => time() + (30 * 24 * 60 * 60),
    ]);

    ok([
        'token' => $token,
        'user'  => [
            'id'         => $user['id'],
            'name'       => $user['name']    ?? '',
            'phone'      => $user['phone'],
            'is_premium' => (bool)$user['is_premium'],
            'total_xp'   => (int)($user['total_xp'] ?? 0),
        ],
    ], 'Login successful');
}

fail('Invalid step');