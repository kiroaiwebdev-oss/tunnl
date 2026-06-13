<?php
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';

$id = (int)($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/coupons/index.php'); exit; }

$stmt = $pdo->prepare("SELECT * FROM coupons WHERE id = ?");
$stmt->execute([$id]);
$c = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$c) { header('Location: ' . ADMIN_URL . '/coupons/index.php'); exit; }

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $code         = strtoupper(trim($_POST['code'] ?? ''));
    $description  = trim($_POST['description'] ?? '');
    $discountType = ($_POST['discount_type'] ?? 'percent') === 'flat' ? 'flat' : 'percent';
    $discountVal  = (float)($_POST['discount_value'] ?? 0);
    $minAmount    = (int)($_POST['min_amount'] ?? 0);
    $maxDiscount  = (int)($_POST['max_discount'] ?? 0);
    $usageLimit   = (int)($_POST['usage_limit'] ?? 0);
    $perUserLimit = (int)($_POST['per_user_limit'] ?? 1);
    $expiresAt    = !empty($_POST['expires_at']) ? $_POST['expires_at'] : null;
    $isActive     = isset($_POST['is_active']) ? 1 : 0;

    if ($code === '') {
        $error = 'Coupon code is required.';
    } elseif ($discountVal <= 0) {
        $error = 'Discount value must be greater than 0.';
    } elseif ($discountType === 'percent' && $discountVal > 100) {
        $error = 'Percent discount cannot exceed 100.';
    } else {
        try {
            $pdo->prepare("
                UPDATE coupons SET
                  code=?, description=?, discount_type=?, discount_value=?,
                  min_amount=?, max_discount=?, usage_limit=?, per_user_limit=?,
                  expires_at=?, is_active=?
                WHERE id=?
            ")->execute([
                $code, $description, $discountType, $discountVal, $minAmount,
                $maxDiscount, $usageLimit, $perUserLimit, $expiresAt, $isActive, $id,
            ]);
            header('Location: ' . ADMIN_URL . '/coupons/index.php?msg=updated');
            exit;
        } catch (PDOException $e) {
            $error = ($e->getCode() === '23000')
                ? 'A coupon with this code already exists.'
                : $e->getMessage();
        }
        // keep edited values on error
        $c = array_merge($c, [
            'code' => $code, 'description' => $description,
            'discount_type' => $discountType, 'discount_value' => $discountVal,
            'min_amount' => $minAmount, 'max_discount' => $maxDiscount,
            'usage_limit' => $usageLimit, 'per_user_limit' => $perUserLimit,
            'expires_at' => $expiresAt, 'is_active' => $isActive,
        ]);
    }
}

$pageTitle = 'Edit Coupon';
require_once dirname(__DIR__) . '/includes/header.php';
?>

<div style="max-width:640px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Edit Coupon</h2>
    <p class="text-muted">#<?= $id ?> — <?= htmlspecialchars($c['code']) ?></p>
  </div>
  <a href="<?= ADMIN_URL ?>/coupons/index.php" class="btn btn-secondary"><i class="fas fa-arrow-left"></i> Back</a>
</div>

<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:20px">
  ⚠️ <?= htmlspecialchars($error) ?>
</div>
<?php endif; ?>

<form method="POST">
<div class="card">
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Coupon Code *</label>
      <input type="text" name="code" class="form-input" required value="<?= htmlspecialchars($c['code']) ?>" style="text-transform:uppercase">
    </div>
    <div class="form-group">
      <label class="form-label">Description</label>
      <input type="text" name="description" class="form-input" value="<?= htmlspecialchars($c['description']) ?>">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Discount Type *</label>
      <select name="discount_type" class="form-select" required>
        <option value="percent" <?= $c['discount_type']==='percent'?'selected':'' ?>>Percentage (%)</option>
        <option value="flat"    <?= $c['discount_type']==='flat'?'selected':'' ?>>Flat (₹ off)</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Discount Value *</label>
      <input type="number" name="discount_value" class="form-input" required min="1" step="0.01" value="<?= htmlspecialchars($c['discount_value']) ?>">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Min Order (₹)</label>
      <input type="number" name="min_amount" class="form-input" min="0" value="<?= (int)$c['min_amount'] ?>">
    </div>
    <div class="form-group">
      <label class="form-label">Max Discount (₹, percent only)</label>
      <input type="number" name="max_discount" class="form-input" min="0" value="<?= (int)$c['max_discount'] ?>">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Total Usage Limit</label>
      <input type="number" name="usage_limit" class="form-input" min="0" value="<?= (int)$c['usage_limit'] ?>">
    </div>
    <div class="form-group">
      <label class="form-label">Per-User Limit</label>
      <input type="number" name="per_user_limit" class="form-input" min="0" value="<?= (int)$c['per_user_limit'] ?>">
    </div>
    <div class="form-group">
      <label class="form-label">Expires On</label>
      <input type="date" name="expires_at" class="form-input" value="<?= !empty($c['expires_at']) ? date('Y-m-d', strtotime($c['expires_at'])) : '' ?>">
    </div>
  </div>

  <label style="display:flex;align-items:center;gap:8px;cursor:pointer;margin-bottom:16px">
    <input type="checkbox" name="is_active" <?= (int)$c['is_active'] === 1 ? 'checked' : '' ?> style="accent-color:var(--cyan);width:16px;height:16px">
    <span style="font-size:13px;color:var(--text2)">Active — usable by app users</span>
  </label>

  <div style="font-size:12px;color:var(--muted);margin-bottom:16px">
    <i class="fas fa-info-circle"></i> Used <?= (int)$c['used_count'] ?> time(s) so far.
  </div>

  <div style="display:flex;gap:12px">
    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Update Coupon</button>
    <a href="<?= ADMIN_URL ?>/coupons/index.php" class="btn btn-secondary">Cancel</a>
  </div>
</div>
</form>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
