<?php
$pageTitle = 'Notifications';
require_once dirname(__DIR__) . '/includes/header.php';

$notifications = $pdo->query("
    SELECT * FROM notifications ORDER BY sent_at DESC LIMIT 50
")->fetchAll();

$totalSent = $pdo->query("SELECT COUNT(*) FROM notifications")->fetchColumn();
$todaySent = $pdo->query("SELECT COUNT(*) FROM notifications WHERE DATE(sent_at)=CURDATE()")->fetchColumn();
$fcmUsers  = $pdo->query("SELECT COUNT(*) FROM users WHERE fcm_token IS NOT NULL AND fcm_token != ''")->fetchColumn();
?>

<!-- Stats -->
<div class="stats-grid" style="grid-template-columns:repeat(3,1fr);margin-bottom:24px">
  <div class="stat-card" style="--accent-color:var(--cyan);--accent-bg:rgba(0,229,255,0.1)">
    <div class="stat-icon"><i class="fas fa-bell"></i></div>
    <div class="stat-value"><?= number_format($totalSent) ?></div>
    <div class="stat-label">Total Sent</div>
  </div>
  <div class="stat-card" style="--accent-color:var(--success);--accent-bg:rgba(16,185,129,0.1)">
    <div class="stat-icon"><i class="fas fa-paper-plane"></i></div>
    <div class="stat-value"><?= number_format($todaySent) ?></div>
    <div class="stat-label">Sent Today</div>
  </div>
  <div class="stat-card" style="--accent-color:var(--purple);--accent-bg:rgba(139,92,246,0.1)">
    <div class="stat-icon"><i class="fas fa-users"></i></div>
    <div class="stat-value"><?= number_format($fcmUsers) ?></div>
    <div class="stat-label">Subscribed Users</div>
  </div>
</div>

<!-- Header -->
<div class="flex-between mb-20">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Push Notifications</h2>
    <p class="text-muted">Send FCM push notifications to users</p>
  </div>
  <a href="<?= ADMIN_URL ?>/notifications/send.php" class="btn btn-primary">
    <i class="fas fa-paper-plane"></i> Send Notification
  </a>
</div>

<!-- History -->
<div class="card">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-history" style="color:var(--purple)"></i> Notification History
    </div>
  </div>
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Title</th>
          <th>Message</th>
          <th>Target</th>
          <th>Type</th>
          <th>Sent To</th>
          <th>Status</th>
          <th>Date</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($notifications)): ?>
        <tr><td colspan="7" style="text-align:center;padding:40px;color:var(--muted)">
          <i class="fas fa-bell-slash" style="font-size:32px;display:block;margin-bottom:10px;opacity:0.3"></i>
          No notifications sent yet
        </td></tr>
        <?php else: ?>
        <?php foreach ($notifications as $n): ?>
        <tr>
          <td style="font-weight:600;color:var(--text);font-size:13px">
            <?= htmlspecialchars($n['title']) ?>
          </td>
          <td>
            <div style="font-size:12px;color:var(--muted);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:220px">
              <?= htmlspecialchars($n['message'] ?? '') ?>
            </div>
          </td>
          <td>
            <?php
            $tColors = ['all'=>'badge-cyan','premium'=>'badge-warning','free'=>'badge-success'];
            $target  = $n['target'] ?? 'all';
            ?>
            <span class="badge <?= $tColors[$target] ?? 'badge-cyan' ?>">
              <?= ucfirst($target) ?>
            </span>
          </td>
          <td>
            <?php
            $typeMap = [
              'general'    => ['fas fa-bell',    'var(--cyan)'],
              'new_content'=> ['fas fa-star',    'var(--warning)'],
              'offer'      => ['fas fa-tag',     'var(--success)'],
              'challenge'  => ['fas fa-trophy',  'var(--purple)'],
              'reminder'   => ['fas fa-clock',   'var(--muted)'],
            ];
            $type = $n['type'] ?? 'general';
            [$icon, $color] = $typeMap[$type] ?? ['fas fa-bell', 'var(--cyan)'];
            ?>
            <span style="font-size:12px;color:<?= $color ?>">
              <i class="<?= $icon ?>"></i> <?= ucfirst(str_replace('_',' ',$type)) ?>
            </span>
          </td>
          <td style="font-weight:600;color:var(--text)">
            <?= number_format($n['sent_count'] ?? 0) ?>
          </td>
          <td>
            <?php $status = $n['status'] ?? 'sent'; ?>
            <?php if ($status === 'sent'): ?>
            <span class="badge badge-success"><i class="fas fa-check"></i> Sent</span>
            <?php elseif ($status === 'failed'): ?>
            <span class="badge badge-error"><i class="fas fa-times"></i> Failed</span>
            <?php else: ?>
            <span class="badge badge-warning">Pending</span>
            <?php endif; ?>
          </td>
          <td style="color:var(--muted);font-size:12px">
            <?= date('d M, H:i', strtotime($n['sent_at'])) ?>
          </td>
        </tr>
        <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>