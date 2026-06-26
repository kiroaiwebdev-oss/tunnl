<?php
// Shared helper for the Tricks editor: if the admin uploaded an image file,
// store it under admin/uploads/tricks/ and return its public URL. Otherwise
// returns the URL the admin typed (or the existing one). Sets $error on failure.

function tunnl_trick_image_url(string $current, ?string &$error): string
{
    $imageUrl = trim($current);

    if (!empty($_FILES['image_file']['name'])
        && is_uploaded_file($_FILES['image_file']['tmp_name'] ?? '')) {

        $f = $_FILES['image_file'];
        if (($f['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
            $error = 'Image upload failed (code ' . (int)$f['error'] . ').';
            return $imageUrl;
        }
        $ext = strtolower(pathinfo($f['name'], PATHINFO_EXTENSION));
        $allowed = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
        if (!in_array($ext, $allowed, true)) {
            $error = 'Image must be jpg, jpeg, png, webp or gif.';
            return $imageUrl;
        }
        if ($f['size'] > 8 * 1024 * 1024) {
            $error = 'Image file too large (max 8MB).';
            return $imageUrl;
        }
        $dir = dirname(__DIR__) . '/uploads/tricks/';
        if (!is_dir($dir)) @mkdir($dir, 0775, true);
        $fn = 'trick_' . time() . '_' . mt_rand(1000, 9999) . '.' . $ext;
        if (@move_uploaded_file($f['tmp_name'], $dir . $fn)) {
            $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
            $host   = $_SERVER['HTTP_HOST'] ?? '';
            $imageUrl = $scheme . '://' . $host . '/uploads/tricks/' . $fn;
        } else {
            $error = 'Could not save the uploaded image file.';
        }
    }

    return $imageUrl;
}
