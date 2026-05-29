<?php
$pageTitle = 'Dashboard';
require_once dirname(__DIR__) . '/includes/header.php';

// Stats
$stats['users']     = $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
$stats['premium']   = $pdo->query("SELECT COUNT(*) FROM users WHERE is_premium=1")->fetchColumn();
$stats['questions'] = $pdo->query("SELECT COUNT(*) FROM questions")->fetchColumn();
$stats['tricks']    = $pdo->query("SELECT COUNT(*) FROM tricks")->fetchColumn();
$stats['sets']      = $pdo->query("SELECT COUNT(*) FROM sets")->fetchColumn();

$challenge   = $pdo->query("SELECT * FROM weekly_challenges WHERE status='active' LIMIT 1")->fetch();
$recentUsers = $pdo->query("SELECT * FROM users ORDER BY created_at DESC LIMIT 5")->fetchAll();
$recentTests = $pdo->query("
    SELECT h.*, u.name, u.phone
    FROM user_test_history h
    JOIN users u ON h.user_id = u.id
    ORDER BY h.completed_at DESC LIMIT 8
")->fetchAll();
$monthlyData = $pdo->query("
    SELECT DATE_FORMAT(created_at,'%b %Y') as month, COUNT(*) as count
    FROM users
    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
    GROUP BY DATE_FORMAT(created_at,'%Y-%m')
    ORDER BY created_at ASC
")->fetchAll();
?>

<!-- STATS -->
<div class="stats-grid" style="grid-template-columns:repeat(3,1fr);margin-bottom:24px">
  <div class="stat-card" style="--accent-color:#00E5FF;--accent-bg:rgba(0,229,255,0.1)">
    <div class="stat-icon"><i class="fas fa-users"></i></div>
    <div class="stat-value"><?= number_format($stats['users']) ?></div>
    <div class="stat-label">Total Users</div>
  </div>
  <div class="stat-card" style="--accent-color:#F59E0B;--accent-bg:rgba(245,158,11,0.1)">
    <div class="stat-icon"><i class="fas fa-crown"></i></div>
    <div class="stat-value"><?= number_format($stats['premium']) ?></div>
    <div class="stat-label">Premium Users</div>
  </div>
  <div class="stat-card" style="--accent-color:#10B981;--accent-bg:rgba(16,185,129,0.1)">
    <div class="stat-icon"><i class="fas fa-question-circle"></i></div>
    <div class="stat-value"><?= number_format($stats['questions']) ?></div>
    <div class="stat-label">Total Questions</div>
  </div>
  <div class="stat-card" style="--accent-color:#8B5CF6;--accent-bg:rgba(139,92,246,0.1)">
    <div class="stat-icon"><i class="fas fa-bolt"></i></div>
    <div class="stat-value"><?= number_format($stats['tricks']) ?></div>
    <div class="stat-label">Tricks</div>
  </div>
  <div class="stat-card" style="--accent-color:#EF4444;--accent-bg:rgba(239,68,68,0.1)">
    <div class="stat-icon"><i class="fas fa-layer-group"></i></div>
    <div class="stat-value"><?= number_format($stats['sets']) ?></div>
    <div class="stat-label">Total Sets</div>
  </div>
  <div class="stat-card" style="--accent-color:#06B6D4;--accent-bg:rgba(6,182,212,0.1)">
    <div class="stat-icon"><i class="fas fa-trophy"></i></div>
    <div class="stat-value"><?= $challenge ? 'LIVE' : 'OFF' ?></div>
    <div class="stat-label">Weekly Challenge</div>
  </div>
</div>

<!-- CHART + QUICK ACTIONS -->
<div class="grid-2 mb-24">
  <div class="card">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-chart-line" style="color:var(--cyan)"></i> User Growth
      </div>
      <span class="badge badge-cyan">Last 6 Months</span>
    </div>
    <canvas id="userChart" height="200"></canvas>
  </div>

  <div class="card">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-bolt" style="color:var(--warning)"></i> Quick Actions
      </div>
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
      <a href="<?= ADMIN_URL ?>/questions/add.php"      class="btn btn-secondary" style="justify-content:center"><i class="fas fa-plus-circle"></i> Add Question</a>
      <a href="<?= ADMIN_URL ?>/questions/import_csv.php" class="btn btn-secondary" style="justify-content:center"><i class="fas fa-file-csv"></i> Import CSV</a>
      <a href="<?= ADMIN_URL ?>/tricks/add.php"         class="btn btn-secondary" style="justify-content:center"><i class="fas fa-bolt"></i> Add Trick</a>
      <a href="<?= ADMIN_URL ?>/daily_dose/add.php"     class="btn btn-secondary" style="justify-content:center"><i class="fas fa-sun"></i> Daily Dose</a>
      <a href="<?= ADMIN_URL ?>/users/index.php"        class="btn btn-secondary" style="justify-content:center"><i class="fas fa-users"></i> View Users</a>
      <a href="<?= ADMIN_URL ?>/solve_earn/add.php"     class="btn btn-secondary" style="justify-content:center"><i class="fas fa-trophy"></i> New Challenge</a>
      <a href="<?= ADMIN_URL ?>/notifications/index.php" class="btn btn-secondary" style="justify-content:center"><i class="fas fa-bell"></i> Notify Users</a>
      <a href="<?= ADMIN_URL ?>/app_settings/index.php" class="btn btn-primary"   style="justify-content:center"><i class="fas fa-cog"></i> App Settings</a>
    </div>
  </div>
</div>

<!-- RECENT ACTIVITY -->
<div class="grid-2">
  <div class="card">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-user-plus" style="color:var(--success)"></i> Recent Users
      </div>
      <a href="<?= ADMIN_URL ?>/users/index.php" class="btn btn-secondary btn-sm">View All</a>
    </div>
    <div class="table-wrap">
      <table>
        <thead><tr><th>Name</th><th>Phone</th><th>Status</th><th>Joined</th></tr></thead>
        <tbody>
          <?php if (empty($recentUsers)): ?>
          <tr><td colspan="4" style="text-align:center;color:var(--muted);padding:30px">No users yet</td></tr>
          <?php else: ?>
          <?php foreach ($recentUsers as $u): ?>
          <tr>
            <td>
              <div style="display:flex;align-items:center;gap:8px">
                <div style="width:28px;height:28px;background:rgba(0,229,255,0.15);border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;color:var(--cyan)">
                  <?= strtoupper(substr($u['name']?:'U',0,1)) ?>
                </div>
                <?= htmlspecialchars($u['name']?:'Unknown') ?>
              </div>
            </td>
            <td><?= htmlspecialchars($u['phone']) ?></td>
            <td>
              <?php if ($u['is_premium']): ?>
              <span class="badge badge-warning"><i class="fas fa-crown"></i> Pro</span>
              <?php else: ?>
              <span class="badge badge-cyan">Free</span>
              <?php endif; ?>
            </td>
            <td style="color:var(--muted);font-size:12px"><?= date('d M', strtotime($u['created_at'])) ?></td>
          </tr>
          <?php endforeach; ?>
          <?php endif; ?>
        </tbody>
      </table>
    </div>
  </div>

  <div class="card">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-clipboard-list" style="color:var(--purple)"></i> Recent Tests
      </div>
    </div>
    <div class="table-wrap">
      <table>
        <thead><tr><th>User</th><th>Category</th><th>Score</th><th>Accuracy</th></tr></thead>
        <tbody>
          <?php if (empty($recentTests)): ?>
          <tr><td colspan="4" style="text-align:center;color:var(--muted);padding:30px">No test history yet</td></tr>
          <?php else: ?>
          <?php foreach ($recentTests as $t): ?>
          <tr>
            <td><?= htmlspecialchars($t['name']?:$t['phone']) ?></td>
            <td><span class="badge badge-cyan"><?= ucfirst(str_replace('_',' ',$t['category'])) ?></span></td>
            <td style="font-weight:600;color:var(--text)"><?= $t['score'] ?>/<?= $t['total_questions'] ?></td>
            <td>
              <span style="color:<?= $t['accuracy']>=70?'var(--success)':($t['accuracy']>=40?'var(--warning)':'var(--error)') ?>;font-weight:600">
                <?= number_format($t['accuracy'],1) ?>%
              </span>
            </td>
          </tr>
          <?php endforeach; ?>
          <?php endif; ?>
        </tbody>
      </table>
    </div>
  </div>
</div>

<!-- Chart.js -->
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
const monthlyData = <?= json_encode($monthlyData) ?>;
new Chart(document.getElementById('userChart').getContext('2d'), {
  type: 'line',
  data: {
    labels: monthlyData.map(d => d.month),
    datasets: [{
      label: 'New Users',
      data: monthlyData.map(d => d.count),
      borderColor: '#00E5FF',
      backgroundColor: 'rgba(0,229,255,0.08)',
      borderWidth: 2,
      pointBackgroundColor: '#00E5FF',
      pointBorderColor: '#0A0E1A',
      pointBorderWidth: 2,
      pointRadius: 5,
      fill: true,
      tension: 0.4,
    }]
  },
  options: {
    responsive: true,
    plugins: {
      legend: { display: false },
      tooltip: {
        backgroundColor: '#1A2234',
        borderColor: '#1F2937',
        borderWidth: 1,
        titleColor: '#F9FAFB',
        bodyColor: '#9CA3AF',
        padding: 12,
      }
    },
    scales: {
      x: { grid: { color: 'rgba(255,255,255,0.04)' }, ticks: { color: '#6B7280', font: { size: 11 } } },
      y: { grid: { color: 'rgba(255,255,255,0.04)' }, ticks: { color: '#6B7280', font: { size: 11 } }, beginAtZero: true }
    }
  }
});
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>