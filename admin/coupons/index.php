<?php
// Coupons list + toggle. Actions are handled BEFORE header.php so redirects
// and the JSON toggle work (no "headers already sent").
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';

// Toggle active (AJAX)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['toggle_id'])) {
    header('Content-Type: application/json');
    try {
        $id  = (int)$_POST['toggle_id'];
        $val = (int)($_POST['val'] ?? 0);
        $pdo->prepare("UPDATE coupons SET is_active=? WHERE id=?")->execute([$val, $id]);
        echo json_encode(['success' => true]); exit;
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]); exit;
    }
}

$coupons = $pdo->query("SELECT * FROM coupons ORDER BY created_at DESC")->fetchAll(PDO::FETCH_ASSOC);

$pageTitle = 'Coupons';
require_once dirname(__DIR__) . '/includes/header.php';
?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700;color:var(--text)">
      Discount Coupons
    </h2>
    <p class="text-muted"><?= count($coupons) ?> coupons total</p>
  </div>
  <a href="<?= ADMIN_URL ?>/coupons/add.php" class="btn btn-primary">
    <i class="fas fa-plus"></i> Add Coupon
  </a>
</div>

<?php if (isset($_GET['msg'])): ?>
<div style="background:rgba(16,185,129,0.12);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;
  padding:12px 16px;border-radius:10px;margin-bottom:20px;font-size:13px;">
  ✅ <?= $_GET['msg'] === 'added' ? 'Coupon created!' : ($_GET['msg'] === 'updated' ? 'Coupon updated!' : 'Coupon deleted!') ?>
</div>
<?php endif; ?>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Code</th>
          <th>Discount</th>
          <th>Min Order</th>
          <th>Usage</th>
          <th>Expires</th>
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($coupons)): ?>
        <tr><td colspan="7" style="text-align:center;padding:40px;color:var(--muted)">
          <i class="fas fa-ticket-alt" style="font-size:32px;display:block;margin-bottom:10px;opacity:0.3"></i>
          No coupons yet. <a href="<?= ADMIN_URL ?>/coupons/add.php" style="color:var(--cyan)">Create one!</a>
        </td></tr>
        <?php else: ?>
        <?php foreach ($coupons as $c): ?>
        <tr>
          <td>
            <span style="font-family:'Space Grotesk',sans-serif;font-weight:700;color:var(--cyan);letter-spacing:1px">
              <?= htmlspecialchars($c['code']) ?>
            </span>
            <?php if (!empty($c['description'])): ?>
            <div style="font-size:11px;color:var(--muted)"><?= htmlspecialchars($c['description']) ?></div>
            <?php endif; ?>
          </td>
          <td>
            <span class="badge badge-purple">
              <?= $c['discount_type'] === 'percent'
                    ? rtrim(rtrim(number_format((float)$c['discount_value'], 2), '0'), '.') . '% OFF'
                    : '₹' . (int)$c['discount_value'] . ' OFF' ?>
            </span>
            <?php if ($c['discount_type'] === 'percent' && (int)$c['max_discount'] > 0): ?>
            <div style="font-size:10px;color:var(--muted)">max ₹<?= (int)$c['max_discount'] ?></div>
            <?php endif; ?>
          </td>
          <td style="color:var(--text2);font-size:13px"><?= (int)$c['min_amount'] > 0 ? '₹' . (int)$c['min_amount'] : '—' ?></td>
          <td style="color:var(--text2);font-size:13px">
            <?= (int)$c['used_count'] ?><?= (int)$c['usage_limit'] > 0 ? ' / ' . (int)$c['usage_limit'] : '' ?>
          </td>
          <td style="color:var(--text2);font-size:13px">
            <?= !empty($c['expires_at']) ? date('d M Y', strtotime($c['expires_at'])) : 'Never' ?>
          </td>
          <td>
            <?php if ($c['is_active']): ?>
              <a href="javascript:void(0)" onclick="toggleCoupon(<?= $c['id'] ?>,0)" class="badge badge-success" style="text-decoration:none;cursor:pointer">● Active</a>
            <?php else: ?>
              <a href="javascript:void(0)" onclick="toggleCoupon(<?= $c['id'] ?>,1)" class="badge badge-error" style="text-decoration:none;cursor:pointer">● Inactive</a>
            <?php endif; ?>
          </td>
          <td>
            <div style="display:flex;gap:6px">
              <a href="<?= ADMIN_URL ?>/coupons/edit.php?id=<?= $c['id'] ?>" class="btn btn-secondary btn-sm">
                <i class="fas fa-edit"></i>
              </a>
              <button onclick="deleteCoupon(<?= $c['id'] ?>)" class="btn btn-danger btn-sm">
                <i class="fas fa-trash"></i>
              </button>
            </div>
          </td>
        </tr>
        <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<script>
function toggleCoupon(id, val) {
  fetch('index.php', {
    method: 'POST',
    headers: {'Content-Type':'application/x-www-form-urlencoded'},
    body: 'toggle_id=' + id + '&val=' + val
  }).then(r => r.json()).then(d => { if (d.success) location.reload(); else alert(d.message || 'Failed'); });
}
function deleteCoupon(id) {
  if (!confirm('Delete this coupon permanently?')) return;
  fetch('delete.php', {
    method: 'POST',
    headers: {'Content-Type':'application/x-www-form-urlencoded'},
    body: 'id=' + id
  }).then(r => r.json()).then(d => { if (d.success) location.reload(); else alert(d.message || 'Failed'); });
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
