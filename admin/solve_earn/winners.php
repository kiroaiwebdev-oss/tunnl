<?php
$pageTitle = 'Declare Winners';
require_once dirname(__DIR__) . '/includes/header.php';

$id = intval($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/solve_earn/index.php'); exit; }

$challenge = $pdo->prepare("SELECT * FROM weekly_challenges WHERE id=?");
$challenge->execute([$id]);
$challenge = $challenge->fetch();
if (!$challenge) { header('Location: ' . ADMIN_URL . '/solve_earn/index.php'); exit; }

$success = $error = '';

// DECLARE WINNERS
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['declare'])) {
    try {
        $pdo->beginTransaction();

        $winnerIds = $_POST['winner_ids'] ?? [];
        $prizes    = $_POST['prize']      ?? [];

        // Reset old winners
        $pdo->prepare("UPDATE challenge_entries SET is_winner=0, prize_won=NULL WHERE challenge_id=?")
            ->execute([$id]);

        foreach ($winnerIds as $entryId) {
            $entryId = intval($entryId);
            $prize   = floatval($prizes[$entryId] ?? 0);
            $pdo->prepare("UPDATE challenge_entries SET is_winner=1, prize_won=? WHERE id=?")
                ->execute([$prize, $entryId]);
        }

        // Mark challenge as completed
        $pdo->prepare("UPDATE weekly_challenges SET status='completed' WHERE id=?")
            ->execute([$id]);

        $pdo->commit();
        $success = count($winnerIds) . ' winners declared!';
    } catch (Exception $e) {
        $pdo->rollBack();
        $error = $e->getMessage();
    }
}

// MARK PAID
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['mark_paid'])) {
    $entryId = intval($_POST['entry_id']);
    $pdo->prepare("UPDATE challenge_entries SET payment_status='paid', paid_at=NOW() WHERE id=?")
        ->execute([$entryId]);
    $success = 'Marked as paid!';
}

// Top entries
$entries = $pdo->prepare("
    SELECT e.*, u.name, u.phone
    FROM challenge_entries e
    JOIN users u ON e.user_id = u.id
    WHERE e.challenge_id = ?
    ORDER BY e.score DESC, e.time_taken ASC
    LIMIT 20
");
$entries->execute([$id]);
$entries = $entries->fetchAll();
?>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;
  padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $success ?>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;
  padding:12px 16px;border-radius:12px;margin-bottom:20px">
  <?= $error ?>
</div>
<?php endif; ?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">
      Declare Winners
    </h2>
    <p class="text-muted">
      <?= htmlspecialchars($challenge['title']) ?> &middot;
      Prize Pool: <span style="color:var(--warning);font-weight:700">₹<?= number_format($challenge['prize_amount']) ?></span>
    </p>
  </div>
  <a href="<?= ADMIN_URL ?>/solve_earn/leaderboard.php?id=<?= $id ?>" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Leaderboard
  </a>
</div>

<!-- Declare Form -->
<?php if ($challenge['status'] !== 'completed'): ?>
<div class="card mb-20">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-crown" style="color:var(--warning)"></i>
      Select Winners & Assign Prize
    </div>
  </div>
  <form method="POST">
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Select</th>
            <th>Rank</th>
            <th>User</th>
            <th>Score</th>
            <th>Time</th>
            <th>Prize (₹)</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($entries as $i => $e): ?>
          <tr>
            <td>
              <input type="checkbox" name="winner_ids[]" value="<?= $e['id'] ?>"
                style="accent-color:var(--warning);width:16px;height:16px"
                <?= $e['is_winner'] ? 'checked':'' ?>>
            </td>
            <td>
              <?php $medals=[1=>'🥇',2=>'🥈',3=>'🥉']; ?>
              <span style="font-weight:700;color:var(--warning)">
                <?= $medals[$i+1] ?? '#'.($i+1) ?>
              </span>
            </td>
            <td>
              <div style="font-weight:600;color:var(--text);font-size:13px">
                <?= htmlspecialchars($e['name'] ?: 'User') ?>
              </div>
              <div style="font-size:11px;color:var(--muted)"><?= $e['phone'] ?></div>
            </td>
            <td style="font-weight:700;color:var(--success)">
              <?= $e['score'] ?>/<?= $challenge['total_questions'] ?>
            </td>
            <td style="color:var(--muted)"><?= gmdate('i:s',$e['time_taken']) ?></td>
            <td>
              <div style="display:flex;align-items:center;gap:6px">
                <span style="color:var(--warning);font-weight:700">₹</span>
                <input type="number" name="prize[<?= $e['id'] ?>]"
                  class="form-input" style="width:100px"
                  value="<?= $e['prize_won'] ?? ($i===0?intval($challenge['prize_amount']*0.5):($i===1?intval($challenge['prize_amount']*0.3):($i===2?intval($challenge['prize_amount']*0.2):0))) ?>"
                  min="0">
              </div>
            </td>
          </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
    <div style="margin-top:16px;display:flex;gap:12px">
      <button type="submit" name="declare" class="btn btn-primary"
        onclick="return confirm('Declare winners and close challenge?')">
        <i class="fas fa-crown"></i> Declare Winners & Close Challenge
      </button>
    </div>
  </form>
</div>
<?php else: ?>
<!-- Already completed — show payment status -->
<div class="card mb-20">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-rupee-sign" style="color:var(--success)"></i>
      Prize Payment Status
    </div>
    <span class="badge badge-warning">Challenge Completed</span>
  </div>

  <?php
  $winners = $pdo->prepare("
      SELECT e.*, u.name, u.phone
      FROM challenge_entries e
      JOIN users u ON e.user_id = u.id
      WHERE e.challenge_id = ? AND e.is_winner = 1
      ORDER BY e.prize_won DESC
  ");
  $winners->execute([$id]);
  $winners = $winners->fetchAll();
  ?>

  <div style="display:flex;flex-direction:column;gap:12px">
    <?php foreach ($winners as $i => $w): ?>
    <div style="display:flex;align-items:center;justify-content:space-between;
      padding:14px;background:var(--dark);border-radius:12px;
      border:1px solid <?= $w['payment_status']==='paid'?'rgba(16,185,129,0.3)':'var(--border)' ?>;
      flex-wrap:wrap;gap:10px">
      <div style="display:flex;align-items:center;gap:12px">
        <div style="font-size:24px"><?= ['🥇','🥈','🥉'][$i] ?? '🏅' ?></div>
        <div>
          <div style="font-weight:700;color:var(--text)"><?= htmlspecialchars($w['name']) ?></div>
          <div style="font-size:12px;color:var(--muted)"><?= $w['phone'] ?></div>
        </div>
      </div>
      <div style="font-size:20px;font-weight:700;color:var(--warning)">
        ₹<?= number_format($w['prize_won']) ?>
      </div>
      <div>
        <?php if ($w['payment_status'] === 'paid'): ?>
        <span class="badge badge-success">
          <i class="fas fa-check"></i> Paid — <?= date('d M', strtotime($w['paid_at'])) ?>
        </span>
        <?php else: ?>
        <form method="POST" style="display:inline">
          <input type="hidden" name="entry_id" value="<?= $w['id'] ?>">
          <button type="submit" name="mark_paid" class="btn btn-primary btn-sm"
            onclick="return confirm('Mark ₹<?= $w['prize_won'] ?> as paid to <?= htmlspecialchars($w['name']) ?>?')">
            <i class="fas fa-check"></i> Mark as Paid
          </button>
        </form>
        <?php endif; ?>
      </div>
    </div>
    <?php endforeach; ?>
  </div>
</div>
<?php endif; ?>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>