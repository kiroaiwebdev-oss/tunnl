<?php
session_start();

require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';

if (!empty($_SESSION['admin_logged_in'])) {
    header('Location: ' . ADMIN_URL . '/dashboard/index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = trim($_POST['password'] ?? '');

    if (empty($username) || empty($password)) {
        $error = 'Username and password required!';
    } else {
        // ✅ password_hash column use kar rahe hain
        $stmt = $pdo->prepare("SELECT * FROM admins WHERE username = ? LIMIT 1");
        $stmt->execute([$username]);
        $admin = $stmt->fetch();

        if ($admin && password_verify($password, $admin['password_hash'])) {
            session_regenerate_id(true);
            $_SESSION['admin_logged_in'] = true;
            $_SESSION['admin_id']        = $admin['id'];
            $_SESSION['admin_username']  = $admin['username'];
            $_SESSION['admin_role']      = $admin['role'];

            header('Location: ' . ADMIN_URL . '/dashboard/index.php');
            exit;
        } else {
            $error = 'Invalid username or password!';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Admin Login — Mathematical Void</title>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@600;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--bg:#0A0A0F;--card:#12121A;--border:rgba(255,255,255,0.08);--cyan:#00E5FF;--text:#F1F5F9;--muted:#64748B}
body{background:var(--bg);min-height:100vh;display:flex;align-items:center;justify-content:center;font-family:'Inter',sans-serif;color:var(--text)}
body::before{content:'';position:fixed;inset:0;background:radial-gradient(ellipse 80% 50% at 20% 40%,rgba(0,229,255,0.06) 0%,transparent 60%),radial-gradient(ellipse 60% 40% at 80% 70%,rgba(139,92,246,0.05) 0%,transparent 60%);pointer-events:none}
.wrap{width:100%;max-width:420px;padding:20px;position:relative;z-index:1}
.logo{text-align:center;margin-bottom:28px}
.logo-icon{width:64px;height:64px;background:linear-gradient(135deg,rgba(0,229,255,0.2),rgba(0,229,255,0.05));border:2px solid rgba(0,229,255,0.3);border-radius:18px;display:flex;align-items:center;justify-content:center;font-size:28px;margin:0 auto 14px}
.logo-title{font-family:'Space Grotesk',sans-serif;font-size:22px;font-weight:700;background:linear-gradient(135deg,#fff 0%,#00E5FF 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.logo-sub{font-size:13px;color:var(--muted);margin-top:4px}
.card{background:var(--card);border:1px solid var(--border);border-radius:20px;padding:32px}
.fg{margin-bottom:18px}
.fl{display:block;font-size:12px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px}
.iw{position:relative}
.iw .ic{position:absolute;left:14px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:14px;pointer-events:none}
.fi{width:100%;background:rgba(255,255,255,0.04);border:1px solid var(--border);border-radius:12px;padding:12px 40px;color:var(--text);font-size:14px;font-family:'Inter',sans-serif;outline:none;transition:border-color .2s}
.fi:focus{border-color:rgba(0,229,255,.5);background:rgba(0,229,255,.03)}
.tp{position:absolute;right:14px;top:50%;transform:translateY(-50%);background:none;border:none;color:var(--muted);cursor:pointer;font-size:14px;padding:0}
.tp:hover{color:var(--cyan)}
.btn{width:100%;padding:13px;background:linear-gradient(135deg,#00E5FF,#00B8D4);border:none;border-radius:12px;color:#000;font-size:15px;font-weight:700;font-family:'Space Grotesk',sans-serif;cursor:pointer;transition:all .2s;display:flex;align-items:center;justify-content:center;gap:8px;margin-top:8px}
.btn:hover{transform:translateY(-1px);box-shadow:0 8px 24px rgba(0,229,255,.3)}
.err{background:rgba(239,68,68,.1);border:1px solid rgba(239,68,68,.3);color:#FCA5A5;padding:12px 14px;border-radius:10px;font-size:13px;margin-bottom:18px;display:flex;align-items:center;gap:8px}
.foot{text-align:center;font-size:12px;color:var(--muted);margin-top:20px}
</style>
</head>
<body>
<div class="wrap">
  <div class="logo">
    <div class="logo-icon">⚡</div>
    <div class="logo-title">Mathematical Void</div>
    <div class="logo-sub">Admin Panel</div>
  </div>
  <div class="card">
    <?php if ($error): ?>
    <div class="err">
      <i class="fas fa-exclamation-circle"></i>
      <?= htmlspecialchars($error) ?>
    </div>
    <?php endif; ?>
    <form method="POST">
      <div class="fg">
        <label class="fl">Username</label>
        <div class="iw">
          <i class="fas fa-user ic"></i>
          <input type="text" name="username" class="fi"
            placeholder="Enter username"
            value="<?= htmlspecialchars($_POST['username'] ?? '') ?>"
            autofocus required>
        </div>
      </div>
      <div class="fg">
        <label class="fl">Password</label>
        <div class="iw">
          <i class="fas fa-lock ic"></i>
          <input type="password" name="password" id="pi" class="fi"
            placeholder="Enter password" required>
          <button type="button" class="tp" onclick="tp()">
            <i class="fas fa-eye" id="pe"></i>
          </button>
        </div>
      </div>
      <button type="submit" class="btn">
        <i class="fas fa-sign-in-alt"></i> Login
      </button>
    </form>
  </div>
  <div class="foot">Mathematical Void &copy; <?= date('Y') ?> — Admin Only</div>
</div>
<script>
function tp(){
  const i=document.getElementById('pi'),e=document.getElementById('pe');
  i.type=i.type==='password'?'text':'password';
  e.className=i.type==='password'?'fas fa-eye':'fas fa-eye-slash';
}
</script>
</body>
</html>