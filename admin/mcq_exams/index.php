<?php
// 5000 MCQ — exam manager (SSC, Railway, …). Sets are linked by exam_name.
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';

try {
    $exams = $pdo->query("
        SELECT e.*,
          (SELECT COUNT(*) FROM sets s WHERE s.category='mcq' AND s.exam_name = e.exam_name) AS set_count,
          (SELECT COUNT(*) FROM questions q
             JOIN sets s ON q.set_id = s.id
             WHERE s.category='mcq' AND s.exam_name = e.exam_name) AS q_count
        FROM mcq_exams e
        ORDER BY e.sort_order ASC, e.exam_name ASC
    ")->fetchAll();
} catch (Throwable $e) {
    $exams = [];
}

$pageTitle = '5000 MCQ Exams';
require_once dirname(__DIR__) . '/includes/header.php';
?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">5000 MCQ — Exams</h2>
    <p class="text-muted"><?= count($exams) ?> exams &middot; Sets link to an exam by its name</p>
  </div>
  <a href="<?= ADMIN_URL ?>/mcq_exams/add.php" class="btn btn-primary">
    <i class="fas fa-plus"></i> Add Exam
  </a>
</div>

<?php if (isset($_GET['msg'])): ?>
<div style="background:rgba(16,185,129,0.12);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;
  padding:12px 16px;border-radius:10px;margin-bottom:20px;font-size:13px;">
  ✅ <?= $_GET['msg'] === 'added' ? 'Exam created!' : ($_GET['msg'] === 'updated' ? 'Exam updated!' : 'Exam deleted!') ?>
</div>
<?php endif; ?>

<?php if (empty($exams)): ?>
<div class="card" style="text-align:center;padding:60px">
  <i class="fas fa-bolt" style="font-size:48px;color:var(--border2);display:block;margin-bottom:16px"></i>
  <div style="font-size:16px;font-weight:600;color:var(--text);margin-bottom:8px">No MCQ exams yet</div>
  <p class="text-muted" style="margin-bottom:16px">Create exam groups like SSC, Railway, Banking. Then create Sets with the same Exam Name.</p>
  <a href="<?= ADMIN_URL ?>/mcq_exams/add.php" class="btn btn-primary"><i class="fas fa-plus"></i> Add First Exam</a>
</div>
<?php else: ?>
<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:16px">
  <?php foreach ($exams as $e): ?>
  <div style="background:var(--card);border:1px solid var(--border);border-radius:16px;padding:16px">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:10px">
      <span style="font-family:'Space Grotesk',sans-serif;font-size:16px;font-weight:700;color:var(--cyan)">
        <?= htmlspecialchars($e['exam_name']) ?>
      </span>
      <?php if ($e['is_active']): ?>
        <span class="badge badge-success" style="font-size:9px">Active</span>
      <?php else: ?>
        <span class="badge badge-error" style="font-size:9px">Hidden</span>
      <?php endif; ?>
    </div>
    <div style="margin-bottom:8px">
      <span class="badge badge-purple" style="font-size:10px"><?= htmlspecialchars($e['exam_category']) ?></span>
      <span class="badge badge-cyan" style="font-size:10px;margin-left:4px"><?= htmlspecialchars($e['difficulty']) ?></span>
      <?php if ($e['is_premium']): ?><span class="badge badge-warning" style="font-size:10px;margin-left:4px">Premium</span><?php endif; ?>
    </div>
    <div style="font-size:12px;color:var(--muted);margin-bottom:12px">
      <i class="fas fa-layer-group"></i> <?= (int)$e['set_count'] ?> sets &nbsp;
      <i class="fas fa-question-circle"></i> <?= (int)$e['q_count'] ?> questions
    </div>
    <div style="display:flex;gap:6px">
      <a href="<?= ADMIN_URL ?>/mcq_exams/manage_sets.php?exam_id=<?= $e['id'] ?>" class="btn btn-primary btn-sm" style="flex:1;justify-content:center" title="Open exam — manage its sets & questions">
        <i class="fas fa-layer-group"></i> Sets &amp; Questions
      </a>
      <a href="<?= ADMIN_URL ?>/mcq_exams/edit.php?id=<?= $e['id'] ?>" class="btn btn-secondary btn-sm" title="Edit exam">
        <i class="fas fa-edit"></i>
      </a>
      <button onclick="deleteMcqExam(<?= $e['id'] ?>)" class="btn btn-danger btn-sm" title="Delete exam">
        <i class="fas fa-trash"></i>
      </button>
    </div>
  </div>
  <?php endforeach; ?>
</div>
<?php endif; ?>

<script>
function deleteMcqExam(id) {
  if (!confirm('Delete this exam? Its sets stay but become unlinked.')) return;
  fetch('delete.php', {
    method: 'POST',
    headers: {'Content-Type':'application/x-www-form-urlencoded'},
    body: 'id=' + id
  }).then(r => r.json()).then(d => { if (d.success) location.reload(); else alert(d.message || 'Failed'); });
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
