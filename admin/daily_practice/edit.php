<?php
$pageTitle = 'Edit Daily Practice';
require_once dirname(__DIR__) . '/includes/header.php';

$id = intval($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/daily_practice/index.php'); exit; }

$practice = $pdo->prepare("SELECT * FROM daily_practice WHERE id = ?");
$practice->execute([$id]);
$practice = $practice->fetch();
if (!$practice) { header('Location: ' . ADMIN_URL . '/daily_practice/index.php'); exit; }

// Assigned question IDs
$assignedIds = $pdo->prepare("
    SELECT question_id FROM daily_practice_questions WHERE practice_id = ? ORDER BY order_num
");
$assignedIds->execute([$id]);
$assignedIds = array_column($assignedIds->fetchAll(), 'question_id');

$allQuestions = $pdo->query("
    SELECT id, question_text, category, difficulty FROM questions
    ORDER BY category, id DESC LIMIT 200
")->fetchAll();

$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->beginTransaction();

        $pdo->prepare("
            UPDATE daily_practice SET
              practice_date=?, title=?, category=?,
              total_questions=?, time_limit=?, xp_reward=?, is_active=?
            WHERE id=?
        ")->execute([
            $_POST['practice_date'],
            trim($_POST['title']),
            $_POST['category'],
            intval($_POST['total_questions']),
            intval($_POST['time_limit']),
            intval($_POST['xp_reward']),
            isset($_POST['is_active']) ? 1 : 0,
            $id
        ]);

        // Re-assign questions
        $pdo->prepare("DELETE FROM daily_practice_questions WHERE practice_id = ?")
            ->execute([$id]);

        if (!empty($_POST['question_ids'])) {
            $qStmt = $pdo->prepare("
                INSERT INTO daily_practice_questions (practice_id, question_id, order_num)
                VALUES (?,?,?)
            ");
            foreach ($_POST['question_ids'] as $order => $qid) {
                $qStmt->execute([$id, intval($qid), $order + 1]);
            }
        }

        $pdo->commit();
        $success = 'Practice updated!';
        $assignedIds = $_POST['question_ids'] ?? [];
    } catch (Exception $e) {
        $pdo->rollBack();
        $error = $e->getMessage();
    }
}
?>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;
  padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $success ?>
</div>
<?php endif; ?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Edit Practice Set</h2>
    <p class="text-muted"><?= date('d M Y', strtotime($practice['practice_date'])) ?></p>
  </div>
  <a href="<?= ADMIN_URL ?>/daily_practice/index.php" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back
  </a>
</div>

<form method="POST">
<div class="card mb-16">
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Date *</label>
      <input type="date" name="practice_date" class="form-input"
        value="<?= $practice['practice_date'] ?>" required>
    </div>
    <div class="form-group">
      <label class="form-label">Category *</label>
      <select name="category" class="form-select" required>
        <option value="mcq"            <?= $practice['category']==='mcq'           ?'selected':'' ?>>Speed Math MCQ</option>
        <option value="simplification" <?= $practice['category']==='simplification'?'selected':'' ?>>Simplification</option>
        <option value="mixed"          <?= $practice['category']==='mixed'         ?'selected':'' ?>>Mixed</option>
      </select>
    </div>
  </div>
  <div class="form-group">
    <label class="form-label">Title *</label>
    <input type="text" name="title" class="form-input" required
      value="<?= htmlspecialchars($practice['title']) ?>">
  </div>
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Total Questions</label>
      <input type="number" name="total_questions" class="form-input"
        value="<?= $practice['total_questions'] ?>" min="1">
    </div>
    <div class="form-group">
      <label class="form-label">Time Limit (min)</label>
      <input type="number" name="time_limit" class="form-input"
        value="<?= $practice['time_limit'] ?>" min="1">
    </div>
    <div class="form-group">
      <label class="form-label">XP Reward</label>
      <input type="number" name="xp_reward" class="form-input"
        value="<?= $practice['xp_reward'] ?>" min="0">
    </div>
  </div>
  <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
    <input type="checkbox" name="is_active" style="accent-color:var(--cyan);width:16px;height:16px"
      <?= $practice['is_active']?'checked':'' ?>>
    <span style="font-size:13px;color:var(--text2)">Active (visible in app)</span>
  </label>
</div>

<!-- Questions -->
<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-list-ol" style="color:var(--success)"></i> Assigned Questions
    </div>
    <span id="selectedCount" style="font-size:12px;color:var(--cyan);font-weight:700">
      <?= count($assignedIds) ?> selected
    </span>
  </div>
  <input type="text" class="form-input mb-16" placeholder="Search questions..."
    oninput="filterQuestions(this.value)" style="margin-bottom:12px">
  <div style="max-height:400px;overflow-y:auto">
    <?php foreach ($allQuestions as $q): ?>
    <label style="display:flex;align-items:flex-start;gap:10px;padding:8px;
      border-bottom:1px solid rgba(255,255,255,0.04);cursor:pointer;border-radius:8px"
      class="q-row" data-text="<?= htmlspecialchars(strtolower($q['question_text'])) ?>">
      <input type="checkbox" name="question_ids[]" value="<?= $q['id'] ?>"
        style="accent-color:var(--cyan);width:16px;height:16px;flex-shrink:0;margin-top:2px"
        <?= in_array($q['id'],$assignedIds)?'checked':'' ?>
        onchange="updateCount()">
      <div>
        <div style="font-size:13px;color:var(--text2);line-height:1.4">
          <?= htmlspecialchars(mb_substr($q['question_text'],0,100)) ?>
        </div>
        <div style="display:flex;gap:6px;margin-top:4px">
          <span class="badge badge-cyan" style="font-size:9px"><?= ucfirst($q['category']) ?></span>
          <?php $dc=['easy'=>'badge-success','medium'=>'badge-warning','hard'=>'badge-error']; ?>
          <span class="badge <?= $dc[$q['difficulty']]??'badge-cyan' ?>" style="font-size:9px">
            <?= ucfirst($q['difficulty']) ?>
          </span>
        </div>
      </div>
    </label>
    <?php endforeach; ?>
  </div>
</div>

<div style="display:flex;gap:12px">
  <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Update Practice</button>
  <a href="<?= ADMIN_URL ?>/daily_practice/index.php" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
</div>
</form>

<script>
function updateCount() {
  const n = document.querySelectorAll('[name="question_ids[]"]:checked').length;
  document.getElementById('selectedCount').textContent = n + ' selected';
}
function filterQuestions(q) {
  document.querySelectorAll('.q-row').forEach(row => {
    row.style.display = (!q || row.dataset.text.includes(q.toLowerCase())) ? '' : 'none';
  });
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>