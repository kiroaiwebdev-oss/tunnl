<?php
$pageTitle = 'Previous Year Papers';
require_once dirname(__DIR__) . '/includes/header.php';

// sets table mein exam_id nahi — exam_name se join karo
$exams = $pdo->query("
    SELECT e.*,
      (SELECT COUNT(*) FROM sets s WHERE s.category='previous_year' AND s.exam_name = e.exam_name) as set_count,
      (SELECT COUNT(*) FROM questions q
         JOIN sets s ON q.set_id = s.id
         WHERE s.category='previous_year' AND s.exam_name = e.exam_name) as q_count
    FROM py_exams e
    ORDER BY e.exam_name ASC
")->fetchAll();

$grouped = [];
foreach ($exams as $e) {
    $grouped[$e['exam_name']][] = $e;
}
?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Previous Year Papers</h2>
    <p class="text-muted"><?= count($exams) ?> exam papers total</p>
  </div>
  <a href="<?= ADMIN_URL ?>/previous_year/add_exam.php" class="btn btn-primary">
    <i class="fas fa-plus"></i> Add Exam
  </a>
</div>

<?php if (empty($exams)): ?>
<div class="card" style="text-align:center;padding:60px">
  <i class="fas fa-history" style="font-size:48px;color:var(--border2);display:block;margin-bottom:16px"></i>
  <div style="font-size:16px;font-weight:600;color:var(--text);margin-bottom:8px">No exams added yet</div>
  <a href="<?= ADMIN_URL ?>/previous_year/add_exam.php" class="btn btn-primary">
    <i class="fas fa-plus"></i> Add First Exam
  </a>
</div>
<?php else: ?>

<?php foreach ($grouped as $examName => $papers): ?>
<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-graduation-cap" style="color:var(--warning)"></i>
      <?= htmlspecialchars($examName) ?>
      <span class="badge badge-warning"><?= count($papers) ?> papers</span>
    </div>
    <a href="<?= ADMIN_URL ?>/previous_year/add_exam.php?exam_name=<?= urlencode($examName) ?>"
       class="btn btn-secondary btn-sm">
      <i class="fas fa-plus"></i> Add Year
    </a>
  </div>

  <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:12px">
    <?php foreach ($papers as $p): ?>
    <div style="background:var(--dark);border:1px solid var(--border);border-radius:12px;padding:14px;transition:border-color 0.2s"
         onmouseover="this.style.borderColor='var(--cyan)'"
         onmouseout="this.style.borderColor='var(--border)'">

      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:10px">
        <span style="font-family:'Space Grotesk',sans-serif;font-size:18px;font-weight:700;color:var(--cyan)">
          <?= htmlspecialchars($p['exam_full_name'] ?: $p['exam_name']) ?>
        </span>
        <?php if ($p['is_active']): ?>
        <span class="badge badge-success" style="font-size:9px">Active</span>
        <?php else: ?>
        <span class="badge badge-error" style="font-size:9px">Inactive</span>
        <?php endif; ?>
      </div>

      <div style="font-size:12px;color:var(--muted);margin-bottom:6px">
        <span class="badge badge-purple" style="font-size:10px"><?= $p['exam_category'] ?></span>
        <span class="badge badge-cyan" style="font-size:10px;margin-left:4px"><?= $p['difficulty'] ?></span>
      </div>

      <div style="font-size:12px;color:var(--muted);margin-bottom:10px">
        <i class="fas fa-layer-group"></i> <?= $p['set_count'] ?> sets &nbsp;
        <i class="fas fa-question-circle"></i> <?= $p['q_count'] ?> questions
      </div>

      <div style="display:flex;gap:6px">
        <a href="<?= ADMIN_URL ?>/previous_year/manage_sets.php?exam_id=<?= $p['id'] ?>"
           class="btn btn-secondary btn-sm" style="flex:1;justify-content:center">
          <i class="fas fa-layer-group"></i> Sets
        </a>
        <a href="<?= ADMIN_URL ?>/previous_year/edit_exam.php?id=<?= $p['id'] ?>"
           class="btn btn-secondary btn-sm">
          <i class="fas fa-edit"></i>
        </a>
        <button onclick="deleteExam(<?= $p['id'] ?>)"
                class="btn btn-sm"
                style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <?php endforeach; ?>
  </div>
</div>
<?php endforeach; ?>
<?php endif; ?>

<script>
function deleteExam(id) {
  if (!confirm('Delete this exam? This cannot be undone!')) return;
  fetch('<?= ADMIN_URL ?>/previous_year/delete_exam.php', {
    method: 'POST',
    headers: {'Content-Type':'application/x-www-form-urlencoded'},
    body: 'id=' + id
  })
  .then(r => r.json())
  .then(d => { if (d.success) location.reload(); else alert(d.message); });
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>