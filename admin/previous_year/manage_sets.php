<?php
// Config FIRST so the JSON delete handler + redirects work (no HTML yet).
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';

$examId = intval($_GET['exam_id'] ?? 0);
if (!$examId) { header('Location: ' . ADMIN_URL . '/previous_year/index.php'); exit; }

$exam = $pdo->prepare("SELECT * FROM py_exams WHERE id=?");
$exam->execute([$examId]);
$exam = $exam->fetch();
if (!$exam) { header('Location: ' . ADMIN_URL . '/previous_year/index.php'); exit; }

$success = $error = '';

// DELETE SET (JSON) — must run before any HTML output
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete_set_id'])) {
    header('Content-Type: application/json');
    try {
        $sid = intval($_POST['delete_set_id']);
        $pdo->prepare("DELETE FROM questions WHERE set_id=?")->execute([$sid]);
        $pdo->prepare("DELETE FROM sets WHERE id=? AND exam_id=?")->execute([$sid,$examId]);
        echo json_encode(['success'=>true]); exit;
    } catch (Exception $e) {
        echo json_encode(['success'=>false,'message'=>$e->getMessage()]); exit;
    }
}

// ADD SET
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['add_set'])) {
    try {
        $pdo->prepare("
            INSERT INTO sets
              (exam_id, category, exam_name, set_number, title, level, total_questions, is_premium)
            VALUES (?,?,?,?,?,?,?,?)
        ")->execute([
            $examId,
            'previous_year',
            $exam['exam_name'],
            intval($_POST['set_number']),
            trim($_POST['set_title'] ?? ''),
            $_POST['level'],
            min(10, max(1, intval($_POST['set_questions'] ?? 10))),
            $exam['is_premium'],
        ]);
        $success = 'Set added!';
    } catch (Exception $e) { $error = $e->getMessage(); }
}

$sets = $pdo->prepare("
    SELECT s.*,
      (SELECT COUNT(*) FROM questions q WHERE q.set_id = s.id) as q_count
    FROM sets s WHERE s.exam_id = ?
    ORDER BY s.set_number ASC
");
$sets->execute([$examId]);
$sets = $sets->fetchAll();

$pageTitle = 'Manage PY Sets';
require_once dirname(__DIR__) . '/includes/header.php';
?>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;
  padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $success ?>
</div>
<?php endif; ?>

<!-- Header -->
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">
      <?= htmlspecialchars($exam['exam_name']) ?> <?= $exam['exam_year'] ?>
    </h2>
    <p class="text-muted"><?= count($sets) ?> sets &middot; Manage question sets</p>
  </div>
  <a href="<?= ADMIN_URL ?>/previous_year/index.php" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back
  </a>
</div>

<div class="grid-2">

  <!-- Add Set Form -->
  <div class="card">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-plus-circle" style="color:var(--cyan)"></i> Add New Set
      </div>
    </div>
    <form method="POST">
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">Set Number *</label>
          <input type="number" name="set_number" class="form-input" required min="1"
            value="<?= count($sets)+1 ?>">
        </div>
        <div class="form-group">
          <label class="form-label">Level</label>
          <select name="level" class="form-select">
            <option value="Beginner">Beginner</option>
            <option value="Intermediate" selected>Intermediate</option>
            <option value="Advanced">Advanced</option>
          </select>
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">Set Title</label>
        <input type="text" name="set_title" class="form-input"
          placeholder="e.g. Shift 1 - Morning">
      </div>
      <div class="form-group">
        <label class="form-label">Total Questions</label>
        <input type="number" name="set_questions" class="form-input"
          value="10" min="1" max="10">
        <p style="font-size:11px;color:var(--muted);margin-top:4px">Every set is a 10-question set.</p>
      </div>
      <button type="submit" name="add_set" class="btn btn-primary">
        <i class="fas fa-plus"></i> Add Set
      </button>
    </form>
  </div>

  <!-- Sets List -->
  <div>
    <?php if (empty($sets)): ?>
    <div class="card" style="text-align:center;padding:40px;color:var(--muted)">
      <i class="fas fa-layer-group" style="font-size:32px;display:block;margin-bottom:12px;opacity:0.3"></i>
      No sets yet. Add one →
    </div>
    <?php else: ?>
    <div style="display:flex;flex-direction:column;gap:10px">
      <?php foreach ($sets as $s): ?>
      <div style="background:var(--card);border:1px solid var(--border);border-radius:12px;padding:14px;
        display:flex;align-items:center;justify-content:space-between;gap:12px">
        <div>
          <div style="display:flex;align-items:center;gap:8px;margin-bottom:4px">
            <span style="font-family:'Space Grotesk',sans-serif;font-weight:700;color:var(--cyan)">
              Set <?= $s['set_number'] ?>
            </span>
            <?php if ($s['title']): ?>
            <span style="font-size:12px;color:var(--muted)">— <?= htmlspecialchars($s['title']) ?></span>
            <?php endif; ?>
          </div>
          <div style="font-size:12px;color:var(--muted)">
            <span style="color:<?= $s['q_count']>0?'var(--success)':'var(--warning)' ?>;font-weight:600">
              <?= $s['q_count'] ?>
            </span>/<?= $s['total_questions'] ?> questions &middot; <?= $s['level'] ?>
          </div>
        </div>
        <div style="display:flex;gap:6px">
          <a href="<?= ADMIN_URL ?>/questions/index.php?cat=previous_year&set_id=<?= $s['id'] ?>"
             class="btn btn-primary btn-sm" title="Manage Questions">
            <i class="fas fa-list-ol"></i>
          </a>
          <a href="<?= ADMIN_URL ?>/questions/add.php?cat=previous_year&set_id=<?= $s['id'] ?>"
             class="btn btn-secondary btn-sm" title="Add Question">
            <i class="fas fa-plus"></i>
          </a>
          <a href="<?= ADMIN_URL ?>/questions/import_csv.php?cat=previous_year&set_id=<?= $s['id'] ?>"
             class="btn btn-secondary btn-sm" title="Import CSV">
            <i class="fas fa-file-csv"></i>
          </a>
          <button onclick="deleteSet(<?= $s['id'] ?>)" class="btn btn-danger btn-sm" title="Delete Set">
            <i class="fas fa-trash"></i>
          </button>
        </div>
      </div>
      <?php endforeach; ?>
    </div>
    <?php endif; ?>
  </div>
</div>

<script>
function deleteSet(id) {
  if (!confirm('Delete this set and all its questions?')) return;
  fetch('', {
    method:'POST',
    headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:'delete_set_id='+id
  }).then(r=>r.json()).then(d=>{ if(d.success) location.reload(); else alert(d.message); });
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>