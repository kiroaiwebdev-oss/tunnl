<?php
$pageTitle = 'New Challenge';
require_once dirname(__DIR__) . '/includes/header.php';

$success = $error = '';

// All questions for assignment
$questions = $pdo->query("
    SELECT id, question_text, category, difficulty FROM questions
    ORDER BY RAND() LIMIT 100
")->fetchAll();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->beginTransaction();

        $stmt = $pdo->prepare("
            INSERT INTO weekly_challenges
              (title, description, start_date, end_date, prize_amount,
               total_questions, time_limit, status)
            VALUES (?,?,?,?,?,?,?,'upcoming')
        ");
        $stmt->execute([
            trim($_POST['title']),
            trim($_POST['description'] ?? ''),
            $_POST['start_date'],
            $_POST['end_date'],
            floatval($_POST['prize_amount']),
            intval($_POST['total_questions']),
            intval($_POST['time_limit']),
        ]);
        $cId = $pdo->lastInsertId();

        if (!empty($_POST['question_ids'])) {
            $qStmt = $pdo->prepare("
                INSERT INTO challenge_questions (challenge_id, question_id, order_num)
                VALUES (?,?,?)
            ");
            foreach ($_POST['question_ids'] as $order => $qid) {
                $qStmt->execute([$cId, intval($qid), $order + 1]);
            }
        }

        $pdo->commit();
        header('Location: ' . ADMIN_URL . '/solve_earn/index.php?added=1');
        exit;
    } catch (Exception $e) {
        $pdo->rollBack();
        $error = $e->getMessage();
    }
}
?>

<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;
  padding:12px 16px;border-radius:12px;margin-bottom:20px">
  <?= $error ?>
</div>
<?php endif; ?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">
      Create Weekly Challenge
    </h2>
    <p class="text-muted">Set prize, dates and assign questions</p>
  </div>
  <a href="<?= ADMIN_URL ?>/solve_earn/index.php" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back
  </a>
</div>

<form method="POST">

<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-trophy" style="color:var(--warning)"></i> Challenge Details
    </div>
  </div>

  <div class="form-group">
    <label class="form-label">Challenge Title *</label>
    <input type="text" name="title" class="form-input" required
      value="<?= htmlspecialchars($_POST['title'] ?? '') ?>"
      placeholder="e.g. Speed Math Challenge — Week 12">
  </div>

  <div class="form-group">
    <label class="form-label">Description</label>
    <textarea name="description" class="form-textarea" rows="2"
      placeholder="Solve all questions as fast and accurately as possible to win!"><?= htmlspecialchars($_POST['description'] ?? '') ?></textarea>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Start Date *</label>
      <input type="date" name="start_date" class="form-input" required
        value="<?= $_POST['start_date'] ?? date('Y-m-d') ?>">
    </div>
    <div class="form-group">
      <label class="form-label">End Date *</label>
      <input type="date" name="end_date" class="form-input" required
        value="<?= $_POST['end_date'] ?? date('Y-m-d', strtotime('+7 days')) ?>">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">💰 Prize Amount (₹) *</label>
      <div style="display:flex;align-items:center;gap:8px">
        <span style="font-size:20px;color:var(--warning);font-weight:700">₹</span>
        <input type="number" name="prize_amount" class="form-input" required
          value="<?= $_POST['prize_amount'] ?? 500 ?>" min="1" step="1">
      </div>
    </div>
    <div class="form-group">
      <label class="form-label">Total Questions *</label>
      <input type="number" name="total_questions" class="form-input" required
        value="<?= $_POST['total_questions'] ?? 20 ?>" min="5">
    </div>
    <div class="form-group">
      <label class="form-label">Time Limit (minutes) *</label>
      <input type="number" name="time_limit" class="form-input" required
        value="<?= $_POST['time_limit'] ?? 10 ?>" min="1">
    </div>
  </div>
</div>

<!-- Assign Questions -->
<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-list-ol" style="color:var(--success)"></i> Assign Questions
    </div>
    <span id="selectedCount" style="font-size:12px;color:var(--cyan);font-weight:700">0 selected</span>
  </div>

  <div style="display:flex;gap:8px;margin-bottom:12px">
    <input type="text" class="form-input" placeholder="Search questions..."
      oninput="filterQ(this.value)" style="flex:1">
    <button type="button" onclick="selectAll()" class="btn btn-secondary btn-sm">
      Select All
    </button>
    <button type="button" onclick="clearAll()" class="btn btn-secondary btn-sm">
      Clear
    </button>
  </div>

  <div id="qList" style="max-height:350px;overflow-y:auto">
    <?php foreach ($questions as $q): ?>
    <label style="display:flex;align-items:flex-start;gap:10px;padding:8px;
      border-bottom:1px solid rgba(255,255,255,0.04);cursor:pointer;border-radius:8px"
      class="q-row" data-text="<?= htmlspecialchars(strtolower($q['question_text'])) ?>">
      <input type="checkbox" name="question_ids[]" value="<?= $q['id'] ?>"
        style="accent-color:var(--cyan);width:16px;height:16px;flex-shrink:0;margin-top:3px"
        onchange="updateCount()">
      <div>
        <div style="font-size:13px;color:var(--text2)">
          <?= htmlspecialchars(mb_substr($q['question_text'],0,90)) ?>
        </div>
        <div style="display:flex;gap:6px;margin-top:4px">
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
  <button type="submit" class="btn btn-primary">
    <i class="fas fa-save"></i> Create Challenge
  </button>
  <a href="<?= ADMIN_URL ?>/solve_earn/index.php" class="btn btn-secondary">
    <i class="fas fa-times"></i> Cancel
  </a>
</div>

</form>

<script>
function updateCount() {
  document.getElementById('selectedCount').textContent =
    document.querySelectorAll('[name="question_ids[]"]:checked').length + ' selected';
}
function filterQ(q) {
  document.querySelectorAll('.q-row').forEach(r => {
    r.style.display = (!q || r.dataset.text.includes(q.toLowerCase())) ? '' : 'none';
  });
}
function selectAll() {
  document.querySelectorAll('[name="question_ids[]"]').forEach(c => c.checked = true);
  updateCount();
}
function clearAll() {
  document.querySelectorAll('[name="question_ids[]"]').forEach(c => c.checked = false);
  updateCount();
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>