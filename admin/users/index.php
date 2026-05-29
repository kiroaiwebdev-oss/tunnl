<?php
$pageTitle = 'Users';
require_once dirname(__DIR__) . '/includes/header.php';

$search  = $_GET['search']  ?? '';
$filter  = $_GET['filter']  ?? '';
$page    = max(1, intval($_GET['page'] ?? 1));
$perPage = 20;
$offset  = ($page - 1) * $perPage;

$where  = ['1=1'];
$params = [];

if ($search) {
    $where[]  = '(name LIKE ? OR phone LIKE ?)';
    $params[] = "%$search%";
    $params[] = "%$search%";
}
if ($filter === 'premium')  { $where[] = 'is_premium = 1'; }
if ($filter === 'free')     { $where[] = 'is_premium = 0'; }

$whereSQL = implode(' AND ', $where);

$total      = $pdo->prepare("SELECT COUNT(*) FROM users WHERE $whereSQL");
$total->execute($params);
$total      = $total->fetchColumn();
$totalPages = ceil($total / $perPage);

$params[] = $perPage;
$params[] = $offset;

$users = $pdo->prepare("
    SELECT u.*,
      (SELECT COUNT(*) FROM user_test_history WHERE user_id = u.id) as test_count
    FROM users u
    WHERE $whereSQL
    ORDER BY u.created_at DESC
    LIMIT ? OFFSET ?
");
$users->execute($params);
$users = $users->fetchAll();

// Stats
$totalUsers   = $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
$premiumUsers = $pdo->query("SELECT COUNT(*) FROM users WHERE is_premium=1")->fetchColumn();
$todayUsers   = $pdo->query("SELECT COUNT(*) FROM users WHERE DATE(created_at)=CURDATE()")->fetchColumn();
?>

<!-- Stats -->
<div class="stats-grid" style="grid-template-columns:repeat(3,1fr);margin-bottom:24px">
  <div class="stat-card" style="--accent-color:var(--cyan);--accent-bg:rgba(0,229,255,0.1)">
    <div class="stat-icon"><i class="fas fa-users"></i></div>
    <div class="stat-value"><?= number_format($totalUsers) ?></div>
    <div class="stat-label">Total Users</div>
  </div>
  <div class="stat-card" style="--accent-color:var(--warning);--accent-bg:rgba(245,158,11,0.1)">
    <div class="stat-icon"><i class="fas fa-crown"></i></div>
    <div class="stat-value"><?= number_format($premiumUsers) ?></div>
    <div class="stat-label">Premium Users</div>
  </div>
  <div class="stat-card" style="--accent-color:var(--success);--accent-bg:rgba(16,185,129,0.1)">
    <div class="stat-icon"><i class="fas fa-user-plus"></i></div>
    <div class="stat-value"><?= number_format($todayUsers) ?></div>
    <div class="stat-label">Joined Today</div>
  </div>
</div>

<!-- Header -->
<div class="flex-between mb-20">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">All Users</h2>
    <p class="text-muted"><?= number_format($total) ?> users found</p>
  </div>
  <a href="<?= ADMIN_URL ?>/users/export.php?search=<?= urlencode($search) ?>&filter=<?= $filter ?>"
     class="btn btn-secondary">
    <i class="fas fa-download"></i> Export CSV
  </a>
</div>

<!-- Filters -->
<div class="card mb-20">
  <form method="GET" style="display:flex;gap:12px;flex-wrap:wrap;align-items:flex-end">
    <div style="flex:1;min-width:200px">
      <label class="form-label">Search</label>
      <div style="position:relative">
        <input type="text" name="search" class="form-input"
          placeholder="Name or phone..."
          value="<?= htmlspecialchars($search) ?>"
          style="padding-left:38px">
        <i class="fas fa-search" style="position:absolute;left:12px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:13px"></i>
      </div>
    </div>
    <div>
      <label class="form-label">Filter</label>
      <select name="filter" class="form-select" style="width:140px">
        <option value="">All Users</option>
        <option value="premium" <?= $filter==='premium'?'selected':'' ?>>Premium Only</option>
        <option value="free"    <?= $filter==='free'   ?'selected':'' ?>>Free Only</option>
      </select>
    </div>
    <div style="display:flex;gap:8px">
      <button class="btn btn-primary"><i class="fas fa-search"></i> Search</button>
      <a href="<?= ADMIN_URL ?>/users/index.php" class="btn btn-secondary"><i class="fas fa-times"></i></a>
    </div>
  </form>
</div>

<!-- Table -->
<div class="card">
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>User</th>
          <th>Phone</th>
          <th>XP / Streak</th>
          <th>Tests</th>
          <th>Status</th>
          <th>Joined</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($users)): ?>
        <tr><td colspan="8" style="text-align:center;padding:40px;color:var(--muted)">
          <i class="fas fa-users" style="font-size:32px;display:block;margin-bottom:10px;opacity:0.3"></i>
          No users found
        </td></tr>
        <?php else: ?>
        <?php foreach ($users as $i => $u): ?>
        <tr>
          <td style="color:var(--muted);font-size:12px"><?= $offset+$i+1 ?></td>
          <td>
            <div style="display:flex;align-items:center;gap:10px">
              <div style="width:36px;height:36px;border-radius:10px;
                background:linear-gradient(135deg,rgba(0,229,255,0.2),rgba(0,229,255,0.05));
                border:1px solid rgba(0,229,255,0.2);
                display:flex;align-items:center;justify-content:center;
                font-weight:700;font-size:14px;color:var(--cyan);flex-shrink:0">
                <?= strtoupper(substr($u['name']?:'U',0,1)) ?>
              </div>
              <div>
                <div style="font-weight:600;color:var(--text);font-size:13px">
                  <?= htmlspecialchars($u['name'] ?: 'No Name') ?>
                </div>
                <div style="font-size:11px;color:var(--muted)">ID: <?= $u['id'] ?></div>
              </div>
            </div>
          </td>
          <td style="font-size:13px;color:var(--text2)"><?= htmlspecialchars($u['phone']) ?></td>
          <td>
            <div style="font-size:12px">
              <span style="color:var(--cyan);font-weight:600">⚡ <?= number_format($u['total_xp']) ?> XP</span>
              <br>
              <span style="color:var(--warning)">🔥 <?= $u['current_streak'] ?> day</span>
            </div>
          </td>
          <td style="font-weight:600;color:var(--text)"><?= $u['test_count'] ?></td>
          <td>
            <?php if ($u['is_premium']): ?>
            <span class="badge badge-warning"><i class="fas fa-crown"></i> Premium</span>
            <?php else: ?>
            <span class="badge badge-cyan">Free</span>
            <?php endif; ?>
          </td>
          <td style="color:var(--muted);font-size:12px">
            <?= date('d M Y', strtotime($u['created_at'])) ?>
          </td>
          <td>
            <div style="display:flex;gap:6px">
              <a href="<?= ADMIN_URL ?>/users/view.php?id=<?= $u['id'] ?>"
                 class="btn btn-secondary btn-sm" title="View">
                <i class="fas fa-eye"></i>
              </a>
              <a href="<?= ADMIN_URL ?>/users/edit.php?id=<?= $u['id'] ?>"
                 class="btn btn-secondary btn-sm" title="Edit">
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
      <a href="?page=<?=$page-1?>&search=<?=urlencode($search)?>&filter=<?=$filter?>"
         class="btn btn-secondary btn-sm"><i class="fas fa-chevron-left"></i></a>
      <?php endif; ?>
      <?php for ($p=max(1,$page-2); $p<=min($totalPages,$page+2); $p++): ?>
      <a href="?page=<?=$p?>&search=<?=urlencode($search)?>&filter=<?=$filter?>"
         class="btn <?=$p==$page?'btn-primary':'btn-secondary'?> btn-sm"><?=$p?></a>
      <?php endfor; ?>
      <?php if ($page<$totalPages): ?>
      <a href="?page=<?=$page+1?>&search=<?=urlencode($search)?>&filter=<?=$filter?>"
         class="btn btn-secondary btn-sm"><i class="fas fa-chevron-right"></i></a>
      <?php endif; ?>
    </div>
  </div>
  <?php endif; ?>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>