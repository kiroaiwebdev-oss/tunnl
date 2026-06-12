<?php
// Previous Year — exam manager. Same card-grid design as 5000 MCQ Exams.
// Each exam → click "Sets & Questions" → manage_sets.php (sets + questions + CSV).
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';

// Count sets/questions by exam_id (manage_sets links sets via exam_id).
$exams = $pdo->query("
    SELECT e.*,
      (SELECT COUNT(*) FROM sets s
        WHERE s.category='previous_year' AND s.exam_id = e.id) as set_count,
      (SELECT COUNT(*) FROM questions q
         JOIN sets s ON q.set_id = s.id
        WHERE s.category='previous_year' AND s.exam_id = e.id) as q_count
    FROM py_exams e
    ORDER BY e.exam_name ASC, e.exam_year DESC
")->fetchAll();

$pageTitle = 'Previous Year Papers';
require_once dirname(__DIR__) . '/includes/header.php';
?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">
      <i class="fas fa-archive" style="color:var(--warning)"></i> Previous Year Exams
    </h2>
    <p class="text-muted"><?= count($exams) ?> exams &middot; click an exam to manage its sets &amp; questions</p>
  </div>
  <a href="<?= ADMIN_URL ?>/previous_year/add_exam.php" class="btn btn-primary">
    <i class="fas fa-plus"></i> Add Exam
  </a>
</div>

<?php if (isset($_GET['added']) || isset($_GET['updated'])): ?>
<div style="background:rgba(16,185,129,0.12);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;
  padding:12px 16px;border-radius:10px;margin-bottom:20px;font-size:13px">
  ✅ <?= isset($_GET['added']) ? 'Exam added!' : 'Exam updated!' ?>
</div>
<?php endif; ?>

<?php if (empty($exams)): ?>
<div class="card" style="text-align:center;padding:60px">
  <i class="fas fa-archive" style="font-size:48px;color:var(--border2);display:block;margin-bottom:16px"></i>
  <div style="font-size:16px;font-weight:600;color:var(--text);margin-bottom:8px">No exams added yet</div>
  <p class="text-muted" style="margin-bottom:16px">Add an exam (SSC CGL, RRB NTPC…). Then open it to add sets &amp; questions.</p>
  <a href="<?= ADMIN_URL ?>/previous_year/add_exam.php" class="btn btn-primary">
    <i class="fas fa-plus"></i> Add First Exam
  </a>
</div>
<?php else: ?>
<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:16px">
  <?php foreach ($exams as $e): ?>
  <div style="background:var(--card);border:1px solid var(--border);border-radius:16px;padding:16px">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:10px">
      <span style="font-family:'Space Grotesk',sans-serif;font-size:16px;font-weight:700;color:var(--warning)">
        <?= htmlspecialchars($e['exam_name']) ?>
        <?php if (!empty($e['exam_year'])): ?>
        <span style="font-size:12px;color:var(--muted);font-weight:500"><?= (int)$e['exam_year'] ?></span>
        <?php endif; ?>
      </span>
      <?php if ($e['is_active']): ?>
        <span class="badge badge-success" style="font-size:9px">Active</span>
      <?php else: ?>
        <span class="badge badge-error" style="font-size:9px">Hidden</span>
      <?php endif; ?>
    </div>

    <?php if (!empty($e['exam_full_name'])): ?>
    <div style="font-size:11px;color:var(--muted);margin-bottom:8px"><?= htmlspecialchars($e['exam_full_name']) ?></div>
    <?php endif; ?>

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
      <a href="<?= ADMIN_URL ?>/previous_year/manage_sets.php?exam_id=<?= $e['id'] ?>"
         class="btn btn-primary btn-sm" style="flex:1;justify-content:center" title="Open exam — manage its sets & questions">
        <i class="fas fa-layer-group"></i> Sets &amp; Questions
      </a>
      <a href="<?= ADMIN_URL ?>/previous_year/edit_exam.php?id=<?= $e['id'] ?>" class="btn btn-secondary btn-sm" title="Edit exam">
        <i class="fas fa-edit"></i>
      </a>
      <button onclick="deleteExam(<?= $e['id'] ?>)" class="btn btn-danger btn-sm" title="Delete exam">
        <i class="fas fa-trash"></i>
      </button>
    </div>
  </div>
  <?php endforeach; ?>
</div>
<?php endif; ?>

<script>
function deleteExam(id) {
  if (!confirm('Delete this exam? Its sets & questions will also be removed. This cannot be undone!')) return;
  fetch('<?= ADMIN_URL ?>/previous_year/delete_exam.php', {
    method: 'POST',
    headers: {'Content-Type':'application/x-www-form-urlencoded'},
    body: 'id=' + id
  })
  .then(r => r.json())
  .then(d => { if (d.success) location.reload(); else alert(d.message || 'Failed'); })
  .catch(() => alert('Network error.'));
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
