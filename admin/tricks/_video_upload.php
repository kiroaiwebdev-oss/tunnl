<?php
// Shared helper for the Tricks editor: if the admin uploaded a local video
// file, store it under admin/uploads/videos/ and return its public URL.
// Otherwise returns the URL the admin typed. Sets $error on failure.

function tunnl_trick_video_url(string $current, ?string &$error): string
{
    $videoUrl = trim($current);

    if (!empty($_FILES['video_file']['name'])
        && is_uploaded_file($_FILES['video_file']['tmp_name'] ?? '')) {

        $f = $_FILES['video_file'];
        if (($f['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
            $error = 'Video upload failed (code ' . (int)$f['error'] . ').';
            return $videoUrl;
        }
        $ext = strtolower(pathinfo($f['name'], PATHINFO_EXTENSION));
        $allowed = ['mp4', 'mov', 'webm', 'm4v'];
        if (!in_array($ext, $allowed, true)) {
            $error = 'Video must be mp4, mov, webm or m4v.';
            return $videoUrl;
        }
        if ($f['size'] > 60 * 1024 * 1024) {
            $error = 'Video file too large (max 60MB).';
            return $videoUrl;
        }
        $dir = dirname(__DIR__) . '/uploads/videos/';
        if (!is_dir($dir)) @mkdir($dir, 0775, true);
        $fn = 'trick_' . time() . '_' . mt_rand(1000, 9999) . '.' . $ext;
        if (@move_uploaded_file($f['tmp_name'], $dir . $fn)) {
            $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
            $host   = $_SERVER['HTTP_HOST'] ?? '';
            $videoUrl = $scheme . '://' . $host . '/uploads/videos/' . $fn;
        } else {
            $error = 'Could not save the uploaded video file.';
        }
    }

    return $videoUrl;
}
