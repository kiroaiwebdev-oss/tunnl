<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// ✅ Apna DB password yahan daalo
$pdo = new PDO("mysql:host=localhost;dbname=u758083880_test;charset=utf8mb4", 
    "u758083880_tes", 
    "4gyF12IY&l",  // ← sirf yeh badlo
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$msg = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $newPass = trim($_POST['new_password'] ?? '');
    if ($newPass) {
        $hash = password_hash($newPass, PASSWORD_BCRYPT);
        $pdo->prepare("UPDATE admins SET password_hash=? WHERE username='admin'")
            ->execute([$hash]);
        $msg = "✅ Done! Hash saved: <code style='font-size:11px;word-break:break-all'>$hash</code><br><br><strong style='color:#f87171'>Ab yeh file DELETE karo!</strong>";
    }
}
?>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  body{background:#0f0f0f;color:#fff;font-family:Arial,sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}
  .b{background:#1a1a2e;border:1px solid #333;border-radius:14px;padding:28px;width:380px}
  h3{color:#00E5FF;margin-bottom:16px}
  input{width:100%;padding:10px;background:#111;border:1px solid #444;border-radius:8px;color:#fff;font-size:14px;box-sizing:border-box;margin-bottom:12px;outline:none}
  button{width:100%;padding:11px;background:#00E5FF;border:none;border-radius:8px;font-weight:700;color:#000;font-size:15px;cursor:pointer}
  .msg{padding:12px;background:rgba(16,185,129,.15);border:1px solid rgba(16,185,129,.4);border-radius:8px;color:#6EE7B7;margin-bottom:14px;font-size:13px}
</style>
</head>
<body>
<div class="b">
  <h3>🔐 Password Update</h3>

  <?php if ($msg): ?>
  <div class="msg"><?= $msg ?></div>
  <?php endif; ?>

  <form method="POST">
    <input type="password" name="new_password" 
      placeholder="Naya password likho" required>
    <button type="submit">Update Password</button>
  </form>
</div>
</body>
</html>