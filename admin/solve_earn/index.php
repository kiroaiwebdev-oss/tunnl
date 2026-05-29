
<?php

$pageTitle = 'Solve & Earn';
require_once dirname(__DIR__) . '/includes/header.php';

// Safe queries — columns check karke
$challenges = $pdo->query("
    SELECT c.*,
      (SELECT COUNT(*) FROM challenge_entries WHERE challenge_id = c.id) as total_entries,
      (SELECT COUNT(*) FROM challenge_entries WHERE challenge_id = c.id AND is_winner = 1) as winner_count
    FROM weekly_challenges c
    ORDER BY c.created_at DESC
")->fetchAll();

$activeChallenge = $pdo->query("
    SELECT * FROM weekly_challenges
    WHERE status = 'active'
    LIMIT 1
")->fetch();

$totalPrizeGiven = $pdo->query("
    SELECT COALESCE(SUM(prize_amount),0) FROM weekly_challenges WHERE status='completed'
")->fetchColumn();

$totalEntries = $pdo->query("SELECT COUNT(*) FROM challenge_entries")->fetchColumn();
?>

<!-- Stats -->
<div class="stats-grid" style="grid-template-columns:repeat(4,1fr);margin-bottom:24px">
  <div class="stat-card" style="--accent-color:var(--warning);--accent-bg:rgba(245,158,11,0.1)">
    <div class="stat-icon"><i class="fas fa-trophy"></i></div>
    <div class="stat-value"><?= count($challenges) ?></div>
    <div class="stat-label">Total Challenges</div>
  </div>
  <div class="stat-card" style="--accent-color:var(--success);--accent-bg:rgba(16,185,129,0.1)">
    <div class="stat-icon"><i class="fas fa-users"></i></div>
    <div class="stat-value"><?= number_format($totalEntries) ?></div>
    <div class="stat-label">Total Entries</div>
  </div>
  <div class="stat-card" style="--accent-color:var(--cyan);--accent-bg:rgba(0,229,255,0.1)">
    <div class="stat-icon"><i class="fas fa-rupee-sign"></i></div>
    <div class="stat-value">₹<?= number_format($totalPrizeGiven) ?></div>
    <div class="stat-label">Prize Given</div>
  </div>
  <div class="stat-card" style="--accent-color:var(--purple);--accent-bg:rgba(139,92,246,0.1)">
    <div class="stat-icon"><i class="fas fa-bolt"></i></div>
    <div class="stat-value"><?= $activeChallenge ? '1' : '0' ?></div>
    <div class="stat-label">Active Now</div>
  </div>
</div>

<!-- Header -->
<div class="flex-between mb-20">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Solve & Earn</h2>
    <p class="text-muted">Weekly math challenges with cash prizes</p>
  </div>
  <a href="<?= ADMIN_URL ?>/solve_earn/add.php" class="btn btn-primary">
    <i class="fas fa-plus"></i> New Challenge
  </a>
</div>

<?php if ($activeChallenge): ?>
<div style="background:linear-gradient(135deg,rgba(245,158,11,0.15),rgba(245,158,11,0.05));
  border:1px solid rgba(245,158,11,0.3);border-radius:16px;padding:20px;margin-bottom:20px;
  display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px">
  <div style="display:flex;align-items:center;gap:14px">
    <div style="width:48px;height:48px;background:rgba(245,158,11,0.2);border-radius:14px;
      display:flex;align-items:center;justify-content:center;font-size:22px">🏆</div>
    <div>
      <div style="font-family:'Space Grotesk',sans-serif;font-weight:700;color:var(--text);font-size:16px">
        <?= htmlspecialchars($activeChallenge['title']) ?>
        <span class="badge badge-success" style="margin-left:8px">LIVE</span>
      </div>
      <div style="font-size:13px;color:var(--muted);margin-top:2px">
        Prize: <strong style="color:#F59E0B">₹<?= number_format($activeChallenge['prize_amount'] ?? 0) ?></strong>
        &middot; Ends: <?= date('d M Y', strtotime($activeChallenge['end_date'])) ?>
      </div>
    </div>
  </div>
  <div style="display:flex;gap:8px">
    <a href="<?= ADMIN_URL ?>/solve_earn/leaderboard.php?id=<?= $activeChallenge['id'] ?>" class="btn btn-secondary">
      <i class="fas fa-list-ol"></i> Leaderboard
    </a>
    <a href="<?= ADMIN_URL ?>/solve_earn/winners.php?id=<?= $activeChallenge['id'] ?>" class="btn btn-primary">
      <i class="fas fa-crown"></i> Declare Winners
    </a>
  </div>
</div>
<?php endif; ?>

<!-- Table -->
<div class="card">
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Title</th>
          <th>Dates</th>
          <th>Prize</th>
          <th>Entries</th>
          <th>Winners</th>
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($challenges)): ?>
        <tr><td colspan="7" style="text-align:center;padding:40px;color:var(--muted)">
          <i class="fas fa-trophy" style="font-size:32px;display:block;margin-bottom:10px;opacity:0.3"></i>
          No challenges yet. <a href="<?= ADMIN_URL ?>/solve_earn/add.php" style="color:var(--cyan)">Create first challenge</a>
        </td></tr>
        <?php else: ?>
        <?php foreach ($challenges as $c): ?>
        <tr>
          <td>
            <div style="font-weight:600;color:var(--text);font-size:13px">
              <?= htmlspecialchars($c['title']) ?>
            </div>
            <div style="font-size:11px;color:var(--muted)"><?= $c['total_questions'] ?? 0 ?> questions</div>
          </td>
          <td style="font-size:12px;color:var(--muted)">
            <div><?= date('d M', strtotime($c['start_date'])) ?></div>
            <div style="opacity:.4">to</div>
            <div><?= date('d M Y', strtotime($c['end_date'])) ?></div>
          </td>
          <td>
            <span style="font-weight:700;color:#F59E0B;font-family:'Space Grotesk',sans-serif">
              ₹<?= number_format($c['prize_amount'] ?? 0) ?>
            </span>
          </td>
          <td style="font-weight:600;color:var(--text)"><?= number_format($c['total_entries']) ?></td>
          <td><span style="color:var(--success);font-weight:600"><?= $c['winner_count'] ?></span></td>
          <td>
            <?php
            $sColors = ['upcoming'=>'badge-cyan','active'=>'badge-success','completed'=>'badge-warning','cancelled'=>'badge-error'];
            ?>
            <span class="badge <?= $sColors[$c['status']] ?? 'badge-cyan' ?>">
              <?= ucfirst($c['status']) ?>
            </span>
          </td>
          <td>
            <div style="display:flex;gap:6px">
              <a href="<?= ADMIN_URL ?>/solve_earn/leaderboard.php?id=<?= $c['id'] ?>"
                 class="btn btn-secondary btn-sm" title="Leaderboard">
                <i class="fas fa-list-ol"></i>
              </a>
              <?php if ($c['status'] === 'active'): ?>
              <a href="<?= ADMIN_URL ?>/solve_earn/winners.php?id=<?= $c['id'] ?>"
                 class="btn btn-primary btn-sm" title="Winners">
                <i class="fas fa-crown"></i>
              </a>
              <?php endif; ?>
              <a href="<?= ADMIN_URL ?>/solve_earn/edit.php?id=<?= $c['id'] ?>"
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
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>