<?php
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';

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
                INSERT INTO coupons
                  (code, description, discount_type, discount_value, min_amount,
                   max_discount, usage_limit, per_user_limit, expires_at, is_active)
                VALUES (?,?,?,?,?,?,?,?,?,?)
            ")->execute([
                $code, $description, $discountType, $discountVal, $minAmount,
                $maxDiscount, $usageLimit, $perUserLimit, $expiresAt, $isActive,
            ]);
            header('Location: ' . ADMIN_URL . '/coupons/index.php?msg=added');
            exit;
        } catch (PDOException $e) {
            $error = ($e->getCode() === '23000')
                ? 'A coupon with this code already exists.'
                : $e->getMessage();
        }
    }
}

$pageTitle = 'Add Coupon';
require_once dirname(__DIR__) . '/includes/header.php';
?>

<div style="max-width:640px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Add Coupon</h2>
    <p class="text-muted">Create a discount code for the premium upgrade</p>
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
      <input type="text" name="code" class="form-input" required placeholder="e.g. WELCOME50"
             value="<?= htmlspecialchars($_POST['code'] ?? '') ?>"
             style="text-transform:uppercase">
    </div>
    <div class="form-group">
      <label class="form-label">Description</label>
      <input type="text" name="description" class="form-input" placeholder="Launch offer"
             value="<?= htmlspecialchars($_POST['description'] ?? '') ?>">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Discount Type *</label>
      <select name="discount_type" class="form-select" required>
        <option value="percent">Percentage (%)</option>
        <option value="flat">Flat (₹ off)</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Discount Value *</label>
      <input type="number" name="discount_value" class="form-input" required min="1" step="0.01"
             placeholder="50" value="<?= htmlspecialchars($_POST['discount_value'] ?? '') ?>">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Min Order (₹)</label>
      <input type="number" name="min_amount" class="form-input" min="0" value="0">
    </div>
    <div class="form-group">
      <label class="form-label">Max Discount (₹, percent only)</label>
      <input type="number" name="max_discount" class="form-input" min="0" value="0">
      <p style="font-size:11px;color:var(--muted);margin-top:4px">0 = no cap</p>
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Total Usage Limit</label>
      <input type="number" name="usage_limit" class="form-input" min="0" value="0">
      <p style="font-size:11px;color:var(--muted);margin-top:4px">0 = unlimited</p>
    </div>
    <div class="form-group">
      <label class="form-label">Per-User Limit</label>
      <input type="number" name="per_user_limit" class="form-input" min="0" value="1">
      <p style="font-size:11px;color:var(--muted);margin-top:4px">0 = unlimited per user</p>
    </div>
    <div class="form-group">
      <label class="form-label">Expires On</label>
      <input type="date" name="expires_at" class="form-input">
    </div>
  </div>

  <label style="display:flex;align-items:center;gap:8px;cursor:pointer;margin-bottom:16px">
    <input type="checkbox" name="is_active" checked style="accent-color:var(--cyan);width:16px;height:16px">
    <span style="font-size:13px;color:var(--text2)">Active — usable by app users</span>
  </label>

  <div style="display:flex;gap:12px">
    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Create Coupon</button>
    <a href="<?= ADMIN_URL ?>/coupons/index.php" class="btn btn-secondary">Cancel</a>
  </div>
</div>
</form>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
