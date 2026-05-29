<?php
$pageTitle = 'Give Premium Manually';
require_once dirname(__DIR__) . '/includes/header.php';

$success = $error = '';
$foundUser = null;

// Search user
if (isset($_GET['search'])) {
    $q = trim($_GET['search']);
    $foundUser = $pdo->prepare("SELECT * FROM users WHERE phone = ? OR id = ? LIMIT 1");
    $foundUser->execute([$q, intval($q)]);
    $foundUser = $foundUser->fetch();
    if (!$foundUser) $error = 'No user found with this phone or ID.';
}

// Give premium
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $userId  = intval($_POST['user_id']);
        $expiry  = !empty($_POST['expiry']) ? $_POST['expiry'] : null;
        $note    = trim($_POST['note'] ?? 'Manual by admin');
        $amount  = floatval($_POST['amount'] ?? 0);

        // Update user
        $pdo->prepare("UPDATE users SET is_premium=1, premium_expiry=? WHERE id=?")
            ->execute([$expiry, $userId]);

        // Log transaction
        if ($amount > 0) {
            $pdo->prepare("
                INSERT INTO transactions
                  (user_id, amount, type, status, note, created_at)
                VALUES (?,?,'manual','success',?,NOW())
            ")->execute([$userId, $amount, $note]);
        }

        $success = 'Premium access granted successfully!';

        // Refresh user
        $foundUser = $pdo->prepare("SELECT * FROM users WHERE id=?");
        $foundUser->execute([$userId]);
        $foundUser = $foundUser->fetch();
    } catch (Exception $e) { $error = $e->getMessage(); }
}
?>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;
  padding:14px 18px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle fa-lg"></i>
  <strong><?= $success ?></strong>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;
  padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-exclamation-circle"></i> <?= $error ?>
</div>
<?php endif; ?>

<div style="max-width:600px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">
      Give Premium Manually
    </h2>
    <p class="text-muted">Grant premium access without payment</p>
  </div>
  <a href="<?= ADMIN_URL ?>/premium/index.php" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back
  </a>
</div>

<!-- Search User -->
<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-search" style="color:var(--cyan)"></i> Find User
    </div>
  </div>
  <form method="GET" style="display:flex;gap:10px">
    <input type="text" name="search" class="form-input"
      placeholder="Enter phone number or User ID..."
      value="<?= htmlspecialchars($_GET['search'] ?? '') ?>"
      style="flex:1">
    <button class="btn btn-primary"><i class="fas fa-search"></i> Find</button>
  </form>
</div>

<!-- Grant Form -->
<?php if ($foundUser): ?>
<div class="card mb-16" style="border-color:rgba(245,158,11,0.3)">
  <div style="display:flex;align-items:center;gap:14px;padding:4px 0 16px;
    border-bottom:1px solid var(--border);margin-bottom:16px">
    <div style="width:48px;height:48px;border-radius:14px;
      background:linear-gradient(135deg,rgba(0,229,255,0.2),rgba(0,229,255,0.05));
      border:2px solid rgba(0,229,255,0.3);
      display:flex;align-items:center;justify-content:center;
      font-family:'Space Grotesk',sans-serif;font-weight:700;font-size:20px;color:var(--cyan)">
      <?= strtoupper(substr($foundUser['name']?:'U',0,1)) ?>
    </div>
    <div>
      <div style="font-weight:700;color:var(--text);font-size:16px">
        <?= htmlspecialchars($foundUser['name'] ?: 'No Name') ?>
      </div>
      <div style="font-size:13px;color:var(--muted)">
        📱 <?= $foundUser['phone'] ?> &middot; ID: #<?= $foundUser['id'] ?>
      </div>
      <div style="margin-top:4px">
        <?php if ($foundUser['is_premium']): ?>
        <span class="badge badge-warning"><i class="fas fa-crown"></i> Already Premium</span>
        <?php else: ?>
        <span class="badge badge-cyan">Free User</span>
        <?php endif; ?>
      </div>
    </div>
  </div>

  <form method="POST">
    <input type="hidden" name="user_id" value="<?= $foundUser['id'] ?>">

    <div class="form-group">
      <label class="form-label">Premium Expiry (blank = Lifetime)</label>
      <input type="date" name="expiry" class="form-input"
        value="<?= $foundUser['premium_expiry'] ?? '' ?>">
    </div>

    <div class="form-row">
      <div class="form-group">
        <label class="form-label">Amount Received (₹)</label>
        <div style="display:flex;align-items:center;gap:8px">
          <span style="color:var(--warning);font-weight:700;font-size:18px">₹</span>
          <input type="number" name="amount" class="form-input"
            placeholder="0 = Free grant" min="0" step="1">
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">Note</label>
        <input type="text" name="note" class="form-input"
          value="Manual grant by admin" placeholder="Reason...">
      </div>
    </div>

    <button type="submit" class="btn btn-primary" style="width:100%"
      onclick="return confirm('Grant premium to <?= htmlspecialchars($foundUser['name']) ?>?')">
      <i class="fas fa-crown"></i> Grant Premium Access
    </button>
  </form>
</div>
<?php endif; ?>

</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>