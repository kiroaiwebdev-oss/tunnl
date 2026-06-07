<?php
$pageTitle = 'Daily Practice';
require_once dirname(__DIR__) . '/includes/header.php';

$practices = $pdo->query("
    SELECT dp.*,
      (SELECT COUNT(*) FROM daily_practice_questions WHERE practice_id = dp.id) as q_count
    FROM daily_practice dp
    ORDER BY dp.practice_date DESC
")->fetchAll();

$today = date('Y-m-d');
$todayExists = $pdo->prepare("SELECT id FROM daily_practice WHERE practice_date = ?");
$todayExists->execute([$today]);
$todayExists = $todayExists->fetch();
?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Daily Practice</h2>
    <p class="text-muted">Daily quiz sets shown to users every day</p>
  </div>
  <a href="<?= ADMIN_URL ?>/daily_practice/add.php" class="btn btn-primary">
    <i class="fas fa-plus"></i> Add Practice Set
  </a>
</div>

<?php if (!$todayExists): ?>
<div style="background:rgba(245,158,11,0.1);border:1px solid rgba(245,158,11,0.3);color:#FCD34D;
  padding:14px 18px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:10px">
  <i class="fas fa-exclamation-triangle fa-lg"></i>
  <div>
    <strong>Today's practice not scheduled!</strong>
    <div style="font-size:12px;opacity:0.8">Users will see no quiz today.</div>
  </div>
  <a href="<?= ADMIN_URL ?>/daily_practice/add.php" class="btn btn-secondary btn-sm" style="margin-left:auto">
    Add Now
  </a>
</div>
<?php endif; ?>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Date</th>
          <th>Title</th>
          <th>Category</th>
          <th>Questions</th>
          <th>Time Limit</th>
          <th>XP Reward</th>
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($practices)): ?>
        <tr><td colspan="8" style="text-align:center;padding:40px;color:var(--muted)">
          <i class="fas fa-calendar-check" style="font-size:32px;display:block;margin-bottom:10px;opacity:0.3"></i>
          No practice sets yet.
        </td></tr>
        <?php else: ?>
        <?php foreach ($practices as $p): ?>
        <tr>
          <td>
            <div style="font-family:'Space Grotesk',sans-serif;font-weight:700;color:var(--cyan)">
              <?= date('d M Y', strtotime($p['practice_date'])) ?>
            </div>
            <?php if ($p['practice_date'] === $today): ?>
            <span class="badge badge-success" style="font-size:9px">TODAY</span>
            <?php endif; ?>
          </td>
          <td style="font-weight:600;color:var(--text);font-size:13px">
            <?= htmlspecialchars($p['title']) ?>
          </td>
          <td><span class="badge badge-cyan"><?= ucfirst(str_replace('_',' ',$p['category'])) ?></span></td>
          <td>
            <span style="font-weight:700;color:<?= $p['q_count']>0?'var(--success)':'var(--error)' ?>">
              <?= $p['q_count'] ?>
            </span>
            <span style="color:var(--muted);font-size:12px">/<?= $p['total_questions'] ?></span>
          </td>
          <td style="color:var(--text2);font-size:13px">
            <i class="fas fa-clock" style="color:var(--muted)"></i> <?= $p['time_limit'] ?> min
          </td>
          <td style="color:var(--cyan);font-weight:700">+<?= $p['xp_reward'] ?> XP</td>
          <td>
            <?php if ($p['is_active']): ?>
            <span class="badge badge-success"><i class="fas fa-check"></i> Active</span>
            <?php else: ?>
            <span class="badge badge-error">Hidden</span>
            <?php endif; ?>
          </td>
          <td>
            <div style="display:flex;gap:6px">
              <a href="<?= ADMIN_URL ?>/daily_practice/edit.php?id=<?= $p['id'] ?>"
                 class="btn btn-secondary btn-sm" title="Edit">
                <i class="fas fa-edit"></i>
              </a>
              <button onclick="deletePractice(<?= $p['id'] ?>)"
                class="btn btn-danger btn-sm" title="Delete">
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
function deletePractice(id) {
  if (!confirm('Delete this practice set and all its questions?')) return;
  fetch('delete.php', {
    method:'POST',
    headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:'id='+id
  }).then(r=>r.json()).then(d=>{ if(d.success) location.reload(); else alert(d.message); });
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>