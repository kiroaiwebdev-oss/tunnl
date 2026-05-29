<?php
$pageTitle = 'Daily Dose';
require_once dirname(__DIR__) . '/includes/header.php';

$doses = $pdo->query("SELECT * FROM daily_dose ORDER BY dose_date DESC")->fetchAll();
$today = date('Y-m-d');
$todayDose = $pdo->prepare("SELECT id FROM daily_dose WHERE dose_date = ?");
$todayDose->execute([$today]);
$todayDose = $todayDose->fetch();
?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Daily Dose</h2>
    <p class="text-muted">Math tip shown on dashboard every day</p>
  </div>
  <a href="<?= ADMIN_URL ?>/daily_dose/add.php" class="btn btn-primary">
    <i class="fas fa-plus"></i> Add Today's Dose
  </a>
</div>

<?php if (!$todayDose): ?>
<div style="background:rgba(245,158,11,0.1);border:1px solid rgba(245,158,11,0.3);color:#FCD34D;
  padding:14px 18px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:10px">
  <i class="fas fa-exclamation-triangle fa-lg"></i>
  <div>
    <strong>Today's dose not added yet!</strong>
    <div style="font-size:12px;opacity:0.8">Add today's tip so users see fresh content on dashboard.</div>
  </div>
  <a href="<?= ADMIN_URL ?>/daily_dose/add.php" class="btn btn-secondary btn-sm" style="margin-left:auto">
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
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($doses)): ?>
        <tr><td colspan="5" style="text-align:center;padding:40px;color:var(--muted)">
          <i class="fas fa-sun" style="font-size:32px;display:block;margin-bottom:10px;opacity:0.3"></i>
          No doses added yet
        </td></tr>
        <?php else: ?>
        <?php foreach ($doses as $d): ?>
        <tr>
          <td>
            <div style="font-family:'Space Grotesk',sans-serif;font-weight:700;color:var(--cyan)">
              <?= date('d M Y', strtotime($d['dose_date'])) ?>
            </div>
            <?php if ($d['dose_date'] === $today): ?>
            <span class="badge badge-success" style="font-size:9px">TODAY</span>
            <?php endif; ?>
          </td>
          <td style="font-weight:600;color:var(--text);font-size:13px">
            <?= htmlspecialchars($d['title']) ?>
            <div style="font-size:11px;color:var(--muted);margin-top:2px">
              <?= htmlspecialchars(mb_substr($d['content'],0,60)) ?>...
            </div>
          </td>
          <td><span class="badge badge-cyan"><?= htmlspecialchars($d['category']) ?></span></td>
          <td>
            <?php if ($d['is_active']): ?>
            <span class="badge badge-success"><i class="fas fa-check"></i> Active</span>
            <?php else: ?>
            <span class="badge badge-error">Hidden</span>
            <?php endif; ?>
          </td>
          <td>
            <div style="display:flex;gap:6px">
              <a href="<?= ADMIN_URL ?>/daily_dose/edit.php?id=<?= $d['id'] ?>" class="btn btn-secondary btn-sm">
                <i class="fas fa-edit"></i>
              </a>
              <button onclick="deleteDose(<?= $d['id'] ?>)" class="btn btn-danger btn-sm">
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
function deleteDose(id) {
  if (!confirm('Delete this dose?')) return;
  fetch('', {method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'delete_id='+id})
    .then(()=>location.reload());
}
</script>

<?php
if (isset($_POST['delete_id'])) {
    $pdo->prepare("DELETE FROM daily_dose WHERE id=?")->execute([intval($_POST['delete_id'])]);
    exit;
}
require_once dirname(__DIR__) . '/includes/footer.php';
?>