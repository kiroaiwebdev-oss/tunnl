<?php
$pageTitle = 'Premium';
require_once dirname(__DIR__) . '/includes/header.php';

$page    = max(1, intval($_GET['page'] ?? 1));
$perPage = 20;
$offset  = ($page - 1) * $perPage;

$total      = $pdo->query("SELECT COUNT(*) FROM users WHERE is_premium=1")->fetchColumn();
$totalPages = ceil($total / $perPage);

$premiumUsers = $pdo->prepare("
    SELECT u.*,
      (SELECT SUM(amount) FROM transactions WHERE user_id=u.id AND status='success') as total_paid
    FROM users u
    WHERE u.is_premium = 1
    ORDER BY u.created_at DESC
    LIMIT ? OFFSET ?
");
$premiumUsers->execute([$perPage, $offset]);
$premiumUsers = $premiumUsers->fetchAll();

// Revenue Stats
$totalRevenue  = $pdo->query("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE status='success'")->fetchColumn();
$todayRevenue  = $pdo->query("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE status='success' AND DATE(created_at)=CURDATE()")->fetchColumn();
$monthRevenue  = $pdo->query("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE status='success' AND MONTH(created_at)=MONTH(NOW()) AND YEAR(created_at)=YEAR(NOW())")->fetchColumn();
$totalPremium  = $total;
?>

<!-- Revenue Stats -->
<div class="stats-grid" style="grid-template-columns:repeat(4,1fr);margin-bottom:24px">
  <div class="stat-card" style="--accent-color:var(--success);--accent-bg:rgba(16,185,129,0.1)">
    <div class="stat-icon"><i class="fas fa-rupee-sign"></i></div>
    <div class="stat-value">₹<?= number_format($totalRevenue) ?></div>
    <div class="stat-label">Total Revenue</div>
  </div>
  <div class="stat-card" style="--accent-color:var(--cyan);--accent-bg:rgba(0,229,255,0.1)">
    <div class="stat-icon"><i class="fas fa-calendar-day"></i></div>
    <div class="stat-value">₹<?= number_format($todayRevenue) ?></div>
    <div class="stat-label">Today</div>
  </div>
  <div class="stat-card" style="--accent-color:var(--purple);--accent-bg:rgba(139,92,246,0.1)">
    <div class="stat-icon"><i class="fas fa-calendar-alt"></i></div>
    <div class="stat-value">₹<?= number_format($monthRevenue) ?></div>
    <div class="stat-label">This Month</div>
  </div>
  <div class="stat-card" style="--accent-color:var(--warning);--accent-bg:rgba(245,158,11,0.1)">
    <div class="stat-icon"><i class="fas fa-crown"></i></div>
    <div class="stat-value"><?= number_format($totalPremium) ?></div>
    <div class="stat-label">Premium Users</div>
  </div>
</div>

<!-- Header -->
<div class="flex-between mb-20">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Premium Users</h2>
    <p class="text-muted"><?= number_format($total) ?> premium subscribers</p>
  </div>
  <div style="display:flex;gap:8px">
    <a href="<?= ADMIN_URL ?>/premium/manual_add.php" class="btn btn-secondary">
      <i class="fas fa-user-plus"></i> Manual Add
    </a>
    <a href="<?= ADMIN_URL ?>/premium/transactions.php" class="btn btn-primary">
      <i class="fas fa-receipt"></i> Transactions
    </a>
  </div>
</div>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>User</th>
          <th>Phone</th>
          <th>Expiry</th>
          <th>Total Paid</th>
          <th>XP</th>
          <th>Joined</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($premiumUsers)): ?>
        <tr><td colspan="7" style="text-align:center;padding:40px;color:var(--muted)">
          <i class="fas fa-crown" style="font-size:32px;display:block;margin-bottom:10px;opacity:0.3"></i>
          No premium users yet
        </td></tr>
        <?php else: ?>
        <?php foreach ($premiumUsers as $u): ?>
        <tr>
          <td>
            <div style="display:flex;align-items:center;gap:10px">
              <div style="width:34px;height:34px;border-radius:10px;
                background:linear-gradient(135deg,rgba(245,158,11,0.3),rgba(245,158,11,0.1));
                border:1px solid rgba(245,158,11,0.3);
                display:flex;align-items:center;justify-content:center;
                font-weight:700;color:#F59E0B;flex-shrink:0">
                <?= strtoupper(substr($u['name']?:'U',0,1)) ?>
              </div>
              <div>
                <div style="font-weight:600;color:var(--text);font-size:13px">
                  <?= htmlspecialchars($u['name'] ?: 'No Name') ?>
                </div>
                <span class="badge badge-warning" style="font-size:9px">
                  <i class="fas fa-crown"></i> Premium
                </span>
              </div>
            </div>
          </td>
          <td style="color:var(--text2)"><?= htmlspecialchars($u['phone']) ?></td>
          <td>
            <?php if ($u['premium_expiry']): ?>
            <span style="color:<?= strtotime($u['premium_expiry'])>time()?'var(--success)':'var(--error)' ?>;font-size:13px">
              <?= date('d M Y', strtotime($u['premium_expiry'])) ?>
            </span>
            <?php else: ?>
            <span class="badge badge-success">♾️ Lifetime</span>
            <?php endif; ?>
          </td>
          <td style="font-weight:700;color:var(--success)">
            ₹<?= number_format($u['total_paid'] ?? 0) ?>
          </td>
          <td style="color:var(--cyan);font-weight:600">⚡ <?= number_format($u['total_xp']) ?></td>
          <td style="color:var(--muted);font-size:12px">
            <?= date('d M Y', strtotime($u['created_at'])) ?>
          </td>
          <td>
            <div style="display:flex;gap:6px">
              <a href="<?= ADMIN_URL ?>/users/view.php?id=<?= $u['id'] ?>"
                 class="btn btn-secondary btn-sm">
                <i class="fas fa-eye"></i>
              </a>
              <a href="<?= ADMIN_URL ?>/users/edit.php?id=<?= $u['id'] ?>"
                 class="btn btn-secondary btn-sm">
                <i class="fas fa-edit"></i>
              </a>
            </div>
          </td>
        </tr>
        <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>

  <!-- Pagination -->
  <?php if ($totalPages > 1): ?>
  <div style="display:flex;align-items:center;justify-content:space-between;padding:16px 0 0;flex-wrap:wrap;gap:12px">
    <div style="font-size:13px;color:var(--muted)">
      Showing <?= $offset+1 ?>–<?= min($offset+$perPage,$total) ?> of <?= number_format($total) ?>
    </div>
    <div style="display:flex;gap:6px">
      <?php if ($page>1): ?>
      <a href="?page=<?=$page-1?>" class="btn btn-secondary btn-sm">
        <i class="fas fa-chevron-left"></i>
      </a>
      <?php endif; ?>
      <?php for ($p=max(1,$page-2); $p<=min($totalPages,$page+2); $p++): ?>
      <a href="?page=<?=$p?>" class="btn <?=$p==$page?'btn-primary':'btn-secondary'?> btn-sm">
        <?=$p?>
      </a>
      <?php endfor; ?>
      <?php if ($page<$totalPages): ?>
      <a href="?page=<?=$page+1?>" class="btn btn-secondary btn-sm">
        <i class="fas fa-chevron-right"></i>
      </a>
      <?php endif; ?>
    </div>
  </div>
  <?php endif; ?>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>