<?php
// AJAX upload endpoint for the Tricks rich block editor.
// Accepts a single `file` (image or video), stores it under the right uploads
// folder and returns JSON: { success, url, kind }.

require_once dirname(__DIR__) . '/config/auth_check.php';

header('Content-Type: application/json');

function out(array $d) { echo json_encode($d); exit; }

if ($_SERVER['REQUEST_METHOD'] !== 'POST' || empty($_FILES['file']['name'])) {
    out(['success' => false, 'message' => 'No file uploaded']);
}

$f = $_FILES['file'];
if (($f['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    out(['success' => false, 'message' => 'Upload failed (code ' . (int)$f['error'] . ')']);
}

$ext = strtolower(pathinfo($f['name'], PATHINFO_EXTENSION));
$images = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
$videos = ['mp4', 'mov', 'webm', 'm4v'];

if (in_array($ext, $images, true)) {
    $kind = 'image';
    $sub  = 'tricks';
    $max  = 8 * 1024 * 1024;
} elseif (in_array($ext, $videos, true)) {
    $kind = 'video';
    $sub  = 'videos';
    $max  = 60 * 1024 * 1024;
} else {
    out(['success' => false, 'message' => 'Allowed: jpg, png, webp, gif, mp4, mov, webm, m4v']);
}

if ($f['size'] > $max) {
    out(['success' => false, 'message' => 'File too large (' . ($kind === 'video' ? '60MB' : '8MB') . ' max)']);
}

$dir = dirname(__DIR__) . '/uploads/' . $sub . '/';
if (!is_dir($dir)) @mkdir($dir, 0775, true);
$fn = 'trick_' . time() . '_' . mt_rand(1000, 9999) . '.' . $ext;

if (!@move_uploaded_file($f['tmp_name'], $dir . $fn)) {
    out(['success' => false, 'message' => 'Could not save the file']);
}

$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host   = $_SERVER['HTTP_HOST'] ?? '';
out([
    'success' => true,
    'kind'    => $kind,
    'url'     => $scheme . '://' . $host . '/uploads/' . $sub . '/' . $fn,
]);
