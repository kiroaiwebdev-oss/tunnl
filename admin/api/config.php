<?php
// ── CORS Headers ───────────────────────────────────────
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-API-Key');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200); exit();
}

// ── Includes — __DIR__ based (never breaks on subdomains) ──
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../config/constants.php';

// ── Constants (fallback agar constants.php me nahi hain) ───
if (!defined('OTP_DEBUG'))  define('OTP_DEBUG',  false);
if (!defined('JWT_SECRET')) define('JWT_SECRET', 'tunnel_jwt_secret_change_me');

// ── API Key Check ──────────────────────────────────────
function checkApiKey() {
    // Agar API_KEY constant defined nahi hai to skip
    if (!defined('API_KEY') || !API_KEY) return;

    $key = $_SERVER['HTTP_X_API_KEY']
        ?? $_GET['api_key']
        ?? $_POST['api_key']
        ?? '';

    if ($key !== API_KEY) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized']);
        exit;
    }
}

// ── Auth: token se user fetch karo ────────────────────
function getAuthUser(PDO $pdo) {
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    $token  = trim(str_replace('Bearer', '', $header));
    if (!$token) return null;

    // JWT verify karo
    $payload = verifyJWT($token);
    if (!$payload || !isset($payload['user_id'])) return null;

    $stmt = $pdo->prepare("
        SELECT * FROM users WHERE id = ? AND is_active != 0 LIMIT 1
    ");
    $stmt->execute([$payload['user_id']]);
    return $stmt->fetch() ?: null;
}

function requireAuth(PDO $pdo) {
    $user = getAuthUser($pdo);
    if (!$user) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Login required']);
        exit;
    }
    return $user;
}

// ── JWT ────────────────────────────────────────────────
function generateJWT(array $payload): string {
    $header  = rtrim(base64_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT'])), '=');
    $payload = rtrim(base64_encode(json_encode($payload)), '=');
    $sig     = rtrim(base64_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true)), '=');
    return "$header.$payload.$sig";
}

function verifyJWT(string $token): ?array {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;
    [$header, $payload, $sig] = $parts;

    $expected = rtrim(base64_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true)), '=');
    if (!hash_equals($expected, $sig)) return null;

    // Padding restore karke decode
    $data = json_decode(base64_decode(str_pad($payload, strlen($payload) + (4 - strlen($payload) % 4) % 4, '=')), true);
    if (!$data) return null;
    if (isset($data['exp']) && $data['exp'] < time()) return null;

    return $data;
}

// ── Response Helpers ───────────────────────────────────
function ok($data = [], string $message = 'Success') {
    echo json_encode([
        'success' => true,
        'message' => $message,
        'data'    => $data,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function fail(string $msg, int $code = 400) {
    http_response_code($code);
    echo json_encode([
        'success' => false,
        'message' => $msg,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

// Backward compat — teri purani files response()/error() use karti hain
function response($data, int $code = 200) {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function error(string $msg, int $code = 400) {
    http_response_code($code);
    echo json_encode(['success' => false, 'message' => $msg]);
    exit;
}