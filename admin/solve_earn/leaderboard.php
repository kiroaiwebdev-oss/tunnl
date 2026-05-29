<?php
$pageTitle = 'Leaderboard';
require_once dirname(__DIR__) . '/includes/header.php';

$id = intval($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/solve_earn/index.php'); exit; }

$challenge = $pdo->prepare("SELECT * FROM weekly_challenges WHERE id=?");
$challenge->execute([$id]);
$challenge = $challenge->fetch();
if (!$challenge) { header('Location: ' . ADMIN_URL . '/solve_earn/index.php'); exit; }

$entries = $pdo->prepare("
    SELECT e.*, u.name, u.phone,
      RANK() OVER (ORDER BY e.score DESC, e.time_taken ASC) as `rank`
    FROM challenge_entries e
    JOIN users u ON e.user_id = u.id
    WHERE e.challenge_id = ?
    ORDER BY e.score DESC, e.time_taken ASC
    LIMIT 100
");
$entries->execute([$id]);
$entries = $entries->fetchAll();

$totalEntries = count($entries);
$avgScore     = $totalEntries ? array_sum(array_column($entries,'score')) / $totalEntries : 0;
?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">
      <?= htmlspecialchars($challenge['title']) ?>
    </h2>
    <p class="text-muted">
      Leaderboard &middot; <?= $totalEntries ?> entries &middot;
      Prize: <span style="color:var(--warning);font-weight:700">₹<?= number_format($challenge['prize_amount']) ?></span>
    </p>
  </div>
  <div style="display:flex;gap:8px">
    <?php if ($challenge['status'] === 'active'): ?>
    <a href="<?= ADMIN_URL ?>/solve_earn/winners.php?id=<?= $id ?>" class="btn btn-primary">
      <i class="fas fa-crown"></i> Declare Winners
    </a>
    <?php endif; ?>
    <a href="<?= ADMIN_URL ?>/solve_earn/index.php" class="btn btn-secondary">
      <i class="fas fa-arrow-left"></i> Back
    </a>
  </div>
</div>

<!-- Top 3 Podium -->
<?php if (count($entries) >= 3): ?>
<div style="display:flex;align-items:flex-end;justify-content:center;gap:16px;
  margin-bottom:28px;flex-wrap:wrap">

  <?php
  $podium = [
    1 => ['#CD7F32', '🥉', '3rd', 3, '80px'],
    0 => ['#FFD700', '🥇', '1st', 1, '100px'],
    2 => ['#C0C0C0', '🥈', '2nd', 2, '90px'],
  ];
  foreach ($podium as $idx => [$color, $medal, $pos, $rank, $height]):
    if (!isset($entries[$idx])) continue;
    $e = $entries[$idx];
  ?>
  <div style="text-align:center;flex:1;max-width:200px">
    <div style="font-size:24px;margin-bottom:6px"><?= $medal ?></div>
    <div style="width:56px;height:56px;border-radius:16px;
      background:linear-gradient(135deg,<?= $color ?>33,<?= $color ?>11);
      border:2px solid <?= $color ?>;
      display:flex;align-items:center;justify-content:center;
      font-weight:700;font-size:20px;color:<?= $color ?>;
      margin:0 auto 8px">
      <?= strtoupper(substr($e['name']?:'U',0,1)) ?>
    </div>
    <div style="font-weight:700;color:var(--text);font-size:13px">
      <?= htmlspecialchars($e['name'] ?: 'User') ?>
    </div>
    <div style="font-size:12px;color:var(--muted)"><?= $e['phone'] ?></div>
    <div style="font-weight:700;color:<?= $color ?>;font-size:14px;margin-top:4px">
      <?= $e['score'] ?>/<?= $challenge['total_questions'] ?>
    </div>
    <div style="font-size:11px;color:var(--muted)">
      <?= gmdate('i:s',$e['time_taken']) ?> min
    </div>
    <div style="background:<?= $color ?>22;border:1px solid <?= $color ?>44;
      border-radius:8px;padding:4px 10px;margin-top:6px;
      font-size:11px;font-weight:700;color:<?= $color ?>">
      <?= $pos ?>
    </div>
  </div>
  <?php endforeach; ?>
</div>
<?php endif; ?>

<!-- Full Table -->
<div class="card">
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Rank</th>
          <th>User</th>
          <th>Score</th>
          <th>Accuracy</th>
          <th>Time Taken</th>
          <th>Submitted</th>
          <th>Winner</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($entries)): ?>
        <tr><td colspan="7" style="text-align:center;padding:40px;color:var(--muted)">
          No entries yet
        </td></tr>
        <?php else: ?>
        <?php foreach ($entries as $e): ?>
        <tr style="<?= $e['rank'] <= 3 ? 'background:rgba(245,158,11,0.04)':'' ?>">
          <td>
            <?php
            $medals = [1=>'🥇',2=>'🥈',3=>'🥉'];
            if (isset($medals[$e['rank']])):
            ?>
            <span style="font-size:18px"><?= $medals[$e['rank']] ?></span>
            <?php else: ?>
            <span style="font-family:'Space Grotesk',sans-serif;font-weight:700;
              color:var(--muted)">#<?= $e['rank'] ?></span>
            <?php endif; ?>
          </td>
          <td>
            <div style="display:flex;align-items:center;gap:8px">
              <div style="width:32px;height:32px;border-radius:8px;
                background:rgba(0,229,255,0.1);border:1px solid rgba(0,229,255,0.2);
                display:flex;align-items:center;justify-content:center;
                font-weight:700;font-size:12px;color:var(--cyan);flex-shrink:0">
                <?= strtoupper(substr($e['name']?:'U',0,1)) ?>
              </div>
              <div>
                <div style="font-weight:600;color:var(--text);font-size:13px">
                  <?= htmlspecialchars($e['name'] ?: 'User') ?>
                </div>
                <div style="font-size:11px;color:var(--muted)"><?= $e['phone'] ?></div>
              </div>
            </div>
          </td>
          <td>
            <span style="font-weight:700;font-family:'Space Grotesk',sans-serif;
              color:<?= $e['rank']<=3?'var(--warning)':'var(--text)' ?>">
              <?= $e['score'] ?>/<?= $challenge['total_questions'] ?>
            </span>
          </td>
          <td>
            <span style="font-weight:700;color:<?= $e['accuracy']>=70?'var(--success)':($e['accuracy']>=40?'var(--warning)':'var(--error)') ?>">
              <?= number_format($e['accuracy'],1) ?>%
            </span>
          </td>
          <td style="color:var(--text2);font-size:13px">
            <?= gmdate('i:s',$e['time_taken']) ?>
          </td>
          <td style="color:var(--muted);font-size:12px">
            <?= date('d M, H:i',strtotime($e['submitted_at'])) ?>
          </td>
          <td>
            <?php if ($e['is_winner']): ?>
            <span class="badge badge-warning"><i class="fas fa-crown"></i> Winner</span>
            <?php else: ?>
            <span style="color:var(--border2)">—</span>
            <?php endif; ?>
          </td>
        </tr>
        <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>