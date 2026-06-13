<?php
// BASE_PATH = jahan ye constants.php file hai uska parent = project root
define('BASE_PATH', dirname(__DIR__));
// e.g. /home/u123/public_html  ya  /home/u123/public_html/TODAY_DELIVER_PROJECT

// AUTO-DETECT BASE URL
$scriptDir  = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME']));
$adminDir   = str_replace('\\', '/', str_replace(
    str_replace('\\', '/', $_SERVER['DOCUMENT_ROOT']), '', BASE_PATH
));
$scheme     = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';

define('ADMIN_URL', rtrim($scheme . '://' . $_SERVER['HTTP_HOST'] . $adminDir, '/'));
// e.g. https://test.devsarun.io  ya  https://test.devsarun.io/TODAY_DELIVER_PROJECT

// App constants
define('APP_ENV',             'production');
// ⚠️ API_KEY MUST stay empty unless the Flutter app is also updated to send the
// matching `X-API-Key` header on every request. A non-empty value here makes
// checkApiKey() reject EVERY app call with 401 Unauthorized — which silently
// breaks all content (sets/questions/shorts/PYQ/daily) AND logs the user out on
// every launch (the 401 message contains "login", so the splash wipes session).
define('API_KEY',             '');
define('FCM_SERVER_KEY',      'your_fcm_key_here');
define('RAZORPAY_KEY_ID',     'your_rzp_key_id');
define('RAZORPAY_KEY_SECRET', 'your_rzp_secret');
define('FAST2SMS_KEY',        'your_fast2sms_key');