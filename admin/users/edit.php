<?php
$pageTitle = 'Edit User';
require_once dirname(__DIR__) . '/includes/header.php';

$id = intval($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/users/index.php'); exit; }

// Quick actions from URL
if (isset($_GET['give_premium'])) {
    $pdo->prepare("UPDATE users SET is_premium=1, premium_expiry=NULL WHERE id=?")
        ->execute([$id]);
    header("Location: " . ADMIN_URL . "/users/view.php?id=$id&msg=premium_given");
    exit;
}
if (isset($_GET['revoke_premium'])) {
    $pdo->prepare("UPDATE users SET is_premium=0, premium_expiry=NULL WHERE id=?")
        ->execute([$id]);
    header("Location: " . ADMIN_URL . "/users/view.php?id=$id&msg=premium_revoked");
    exit;
}

$user = $pdo->prepare("SELECT * FROM users WHERE id = ?");
$user->execute([$id]);
$user = $user->fetch();
if (!$user) { header('Location: ' . ADMIN_URL . '/users/index.php'); exit; }

$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $is_premium     = isset($_POST['is_premium']) ? 1 : 0;
        $premium_expiry = !empty($_POST['premium_expiry']) ? $_POST['premium_expiry'] : null;

        $pdo->prepare("
            UPDATE users SET
              name=?, is_premium=?, premium_expiry=?,
              total_xp=?, current_streak=?
            WHERE id=?
        ")->execute([
            trim($_POST['name']),
            $is_premium,
            $premium_expiry,
            intval($_POST['total_xp']),
            intval($_POST['current_streak']),
            $id
        ]);
        $success = 'User updated successfully!';
        $user = $pdo->prepare("SELECT * FROM users WHERE id = ?");
        $user->execute([$id]);
        $user = $user->fetch();
    } catch (Exception $e) { $error = $e->getMessage(); }
}
?>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $success ?>
</div>
<?php endif; ?>

<div style="max-width:600px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">
      Edit User
    </h2>
    <p class="text-muted">Phone: <?= htmlspecialchars($user['phone']) ?></p>
  </div>
  <div style="display:flex;gap:8px">
    <a href="<?= ADMIN_URL ?>/users/view.php?id=<?= $id ?>" class="btn btn-secondary">
      <i class="fas fa-eye"></i> View Profile
    </a>
    <a href="<?= ADMIN_URL ?>/users/index.php" class="btn btn-secondary">
      <i class="fas fa-arrow-left"></i> Back
    </a>
  </div>
</div>

<form method="POST">
<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-user" style="color:var(--cyan)"></i> Basic Info
    </div>
  </div>

  <div class="form-group">
    <label class="form-label">Name</label>
    <input type="text" name="name" class="form-input"
      value="<?= htmlspecialchars($user['name']) ?>"
      placeholder="User's name">
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Total XP</label>
      <input type="number" name="total_xp" class="form-input"
        value="<?= $user['total_xp'] ?>" min="0">
    </div>
    <div class="form-group">
      <label class="form-label">Current Streak (days)</label>
      <input type="number" name="current_streak" class="form-input"
        value="<?= $user['current_streak'] ?>" min="0">
    </div>
  </div>
</div>

<div class="card mb-16" style="border-color:rgba(245,158,11,0.2)">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-crown" style="color:var(--warning)"></i> Premium Control
    </div>
  </div>

  <div style="margin-bottom:16px">
    <label style="display:flex;align-items:center;gap:10px;cursor:pointer">
      <input type="checkbox" name="is_premium" value="1"
        style="accent-color:var(--warning);width:18px;height:18px"
        <?= $user['is_premium'] ? 'checked':'' ?>
        onchange="document.getElementById('expiryRow').style.display=this.checked?'block':'none'">
      <div>
        <div style="font-size:14px;font-weight:600;color:var(--text)">
          Give Premium Access
        </div>
        <div style="font-size:12px;color:var(--muted)">
          User will get full access to all premium content
        </div>
      </div>
    </label>
  </div>

  <div id="expiryRow" style="display:<?= $user['is_premium']?'block':'none' ?>">
    <div class="form-group">
      <label class="form-label">Premium Expiry Date (blank = Lifetime)</label>
      <input type="date" name="premium_expiry" class="form-input"
        value="<?= $user['premium_expiry'] ?? '' ?>">
    </div>
  </div>
</div>

<div style="display:flex;gap:12px">
  <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Save Changes</button>
  <a href="<?= ADMIN_URL ?>/users/index.php" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
</div>
</form>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>