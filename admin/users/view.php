<?php
$pageTitle = 'User Detail';
require_once dirname(__DIR__) . '/includes/header.php';

$id = intval($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/users/index.php'); exit; }

$user = $pdo->prepare("SELECT * FROM users WHERE id = ?");
$user->execute([$id]);
$user = $user->fetch();
if (!$user) { header('Location: ' . ADMIN_URL . '/users/index.php'); exit; }

// Test history
$history = $pdo->prepare("
    SELECT * FROM user_test_history
    WHERE user_id = ?
    ORDER BY completed_at DESC
    LIMIT 20
");
$history->execute([$id]);
$history = $history->fetchAll();

// Stats
$totalTests  = count($history);
$avgAccuracy = $totalTests ? array_sum(array_column($history,'accuracy')) / $totalTests : 0;
$totalXP     = $user['total_xp'];
?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">
      User Profile
    </h2>
    <p class="text-muted">Complete details & test history</p>
  </div>
  <div style="display:flex;gap:8px">
    <a href="<?= ADMIN_URL ?>/users/edit.php?id=<?= $id ?>" class="btn btn-primary">
      <i class="fas fa-edit"></i> Edit User
    </a>
    <a href="<?= ADMIN_URL ?>/users/index.php" class="btn btn-secondary">
      <i class="fas fa-arrow-left"></i> Back
    </a>
  </div>
</div>

<div class="grid-2">

  <!-- Profile Card -->
  <div class="card">
    <div style="display:flex;align-items:center;gap:16px;margin-bottom:20px">
      <div style="width:64px;height:64px;border-radius:18px;
        background:linear-gradient(135deg,rgba(0,229,255,0.2),rgba(0,229,255,0.05));
        border:2px solid rgba(0,229,255,0.3);
        display:flex;align-items:center;justify-content:center;
        font-family:'Space Grotesk',sans-serif;font-weight:700;font-size:26px;color:var(--cyan)">
        <?= strtoupper(substr($user['name']?:'U',0,1)) ?>
      </div>
      <div>
        <div style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:700;color:var(--text)">
          <?= htmlspecialchars($user['name'] ?: 'No Name') ?>
        </div>
        <?php if ($user['is_premium']): ?>
        <span class="badge badge-warning" style="margin-top:4px">
          <i class="fas fa-crown"></i> Premium User
        </span>
        <?php else: ?>
        <span class="badge badge-cyan" style="margin-top:4px">Free User</span>
        <?php endif; ?>
      </div>
    </div>

    <?php
    $details = [
      ['fas fa-phone',        'Phone',        $user['phone']],
      ['fas fa-hashtag',      'User ID',      '#'.$user['id']],
      ['fas fa-calendar',     'Joined',        date('d M Y', strtotime($user['created_at']))],
      ['fas fa-clock',        'Last Active',  $user['last_active'] ? date('d M Y', strtotime($user['last_active'])) : 'N/A'],
      ['fas fa-trophy',       'Rank',         '#'.($user['rank_position'] ?: 'Unranked')],
    ];
    foreach ($details as [$icon, $label, $val]):
    ?>
    <div style="display:flex;justify-content:space-between;align-items:center;padding:10px 0;border-bottom:1px solid rgba(255,255,255,0.04)">
      <span style="font-size:13px;color:var(--muted);display:flex;align-items:center;gap:8px">
        <i class="<?= $icon ?>" style="width:14px"></i> <?= $label ?>
      </span>
      <span style="font-size:13px;font-weight:600;color:var(--text2)"><?= htmlspecialchars($val) ?></span>
    </div>
    <?php endforeach; ?>
  </div>

  <!-- Stats Card -->
  <div>
    <!-- XP / Streak / Accuracy -->
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:12px">
      <?php
      $statBoxes = [
        ['⚡', number_format($totalXP),             'Total XP',     'var(--cyan)'],
        ['🔥', $user['current_streak'].' days',      'Streak',       'var(--warning)'],
        ['📝', $totalTests,                           'Tests Taken',  'var(--success)'],
        ['🎯', number_format($avgAccuracy,1).'%',    'Avg Accuracy', 'var(--purple)'],
      ];
      foreach ($statBoxes as [$emoji,$val,$label,$color]):
      ?>
      <div style="background:var(--card);border:1px solid var(--border);border-radius:14px;padding:16px;border-top:2px solid <?= $color ?>">
        <div style="font-size:20px;margin-bottom:8px"><?= $emoji ?></div>
        <div style="font-family:'Space Grotesk',sans-serif;font-size:22px;font-weight:700;color:<?= $color ?>"><?= $val ?></div>
        <div style="font-size:12px;color:var(--muted)"><?= $label ?></div>
      </div>
      <?php endforeach; ?>
    </div>

    <!-- Premium Info -->
    <div style="background:<?= $user['is_premium'] ? 'linear-gradient(135deg,#1A1400,#2A2000)' : 'var(--card)' ?>;
      border:1px solid <?= $user['is_premium'] ? 'rgba(245,158,11,0.3)' : 'var(--border)' ?>;
      border-radius:14px;padding:16px">
      <div style="display:flex;align-items:center;justify-content:space-between">
        <div>
          <div style="font-weight:700;color:<?= $user['is_premium'] ? '#F59E0B' : 'var(--text)' ?>;margin-bottom:4px">
            <?= $user['is_premium'] ? '👑 Premium Active' : '🔒 Free User' ?>
          </div>
          <div style="font-size:12px;color:var(--muted)">
            <?php if ($user['is_premium'] && $user['premium_expiry']): ?>
              Expires: <?= date('d M Y', strtotime($user['premium_expiry'])) ?>
            <?php elseif ($user['is_premium']): ?>
              Lifetime Access
            <?php else: ?>
              Not subscribed
            <?php endif; ?>
          </div>
        </div>
        <?php if (!$user['is_premium']): ?>
        <a href="<?= ADMIN_URL ?>/users/edit.php?id=<?= $id ?>&give_premium=1" class="btn btn-secondary btn-sm">
          <i class="fas fa-crown" style="color:var(--warning)"></i> Give Premium
        </a>
        <?php else: ?>
        <a href="<?= ADMIN_URL ?>/users/edit.php?id=<?= $id ?>&revoke_premium=1"
           onclick="return confirm('Revoke premium?')"
           class="btn btn-danger btn-sm">
          Revoke
        </a>
        <?php endif; ?>
      </div>
    </div>
  </div>
</div>

<!-- Test History -->
<div class="card mt-16">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-history" style="color:var(--purple)"></i>
      Test History
    </div>
    <span class="badge badge-cyan"><?= $totalTests ?> tests</span>
  </div>
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Category</th>
          <th>Score</th>
          <th>Correct</th>
          <th>Wrong</th>
          <th>Accuracy</th>
          <th>Time</th>
          <th>XP</th>
          <th>Date</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($history)): ?>
        <tr><td colspan="8" style="text-align:center;padding:30px;color:var(--muted)">No tests yet</td></tr>
        <?php else: ?>
        <?php foreach ($history as $h): ?>
        <tr>
          <td>
            <span class="badge badge-cyan">
              <?= ucfirst(str_replace('_',' ',$h['category'])) ?>
            </span>
          </td>
          <td style="font-weight:700;color:var(--text)"><?= $h['score'] ?>/<?= $h['total_questions'] ?></td>
          <td style="color:var(--success);font-weight:600"><?= $h['correct'] ?></td>
          <td style="color:var(--error);font-weight:600"><?= $h['wrong'] ?></td>
          <td>
            <span style="font-weight:700;color:<?= $h['accuracy']>=70?'var(--success)':($h['accuracy']>=40?'var(--warning)':'var(--error)') ?>">
              <?= number_format($h['accuracy'],1) ?>%
            </span>
          </td>
          <td style="color:var(--muted);font-size:12px">
            <?= gmdate('i:s', $h['time_taken']) ?>
          </td>
          <td style="color:var(--cyan);font-weight:600">+<?= $h['xp_earned'] ?></td>
          <td style="color:var(--muted);font-size:12px">
            <?= date('d M, H:i', strtotime($h['completed_at'])) ?>
          </td>
        </tr>
        <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>