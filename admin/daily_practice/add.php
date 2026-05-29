<?php
$pageTitle = 'Add Daily Practice';
require_once dirname(__DIR__) . '/includes/header.php';

$success = $error = '';
$newId   = null;

// Get available questions for assignment
$availableQuestions = $pdo->query("
    SELECT id, question_text, category, difficulty
    FROM questions
    ORDER BY category, id DESC
    LIMIT 200
")->fetchAll();

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['save_practice'])) {
    try {
        $pdo->beginTransaction();

        // Insert practice set
        $stmt = $pdo->prepare("
            INSERT INTO daily_practice
              (practice_date, title, category, total_questions, time_limit, xp_reward, is_active)
            VALUES (?,?,?,?,?,?,1)
        ");
        $stmt->execute([
            $_POST['practice_date'],
            trim($_POST['title']),
            $_POST['category'],
            intval($_POST['total_questions']),
            intval($_POST['time_limit']),
            intval($_POST['xp_reward']),
        ]);
        $newId = $pdo->lastInsertId();

        // Assign selected questions
        if (!empty($_POST['question_ids'])) {
            $qStmt = $pdo->prepare("
                INSERT INTO daily_practice_questions (practice_id, question_id, order_num)
                VALUES (?,?,?)
            ");
            foreach ($_POST['question_ids'] as $order => $qid) {
                $qStmt->execute([$newId, intval($qid), $order + 1]);
            }
        }

        $pdo->commit();
        header('Location: ' . ADMIN_URL . '/daily_practice/index.php?added=1');
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
      Add Daily Practice Set
    </h2>
    <p class="text-muted">Create and assign questions for today's practice</p>
  </div>
  <a href="<?= ADMIN_URL ?>/daily_practice/index.php" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back
  </a>
</div>

<form method="POST">

<!-- Practice Info -->
<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-calendar-check" style="color:var(--cyan)"></i> Practice Info
    </div>
  </div>
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Date *</label>
      <input type="date" name="practice_date" class="form-input"
        value="<?= $_POST['practice_date'] ?? date('Y-m-d') ?>" required>
    </div>
    <div class="form-group">
      <label class="form-label">Category *</label>
      <select name="category" class="form-select" required id="catFilter">
        <option value="mcq">Speed Math MCQ</option>
        <option value="simplification">Simplification</option>
        <option value="mixed">Mixed</option>
      </select>
    </div>
  </div>
  <div class="form-group">
    <label class="form-label">Title *</label>
    <input type="text" name="title" class="form-input" required
      value="<?= htmlspecialchars($_POST['title'] ?? '') ?>"
      placeholder="e.g. Speed Math - Day 42">
  </div>
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Total Questions</label>
      <input type="number" name="total_questions" class="form-input"
        value="<?= $_POST['total_questions'] ?? 20 ?>" min="1" max="50">
    </div>
    <div class="form-group">
      <label class="form-label">Time Limit (minutes)</label>
      <input type="number" name="time_limit" class="form-input"
        value="<?= $_POST['time_limit'] ?? 10 ?>" min="1">
    </div>
    <div class="form-group">
      <label class="form-label">XP Reward</label>
      <input type="number" name="xp_reward" class="form-input"
        value="<?= $_POST['xp_reward'] ?? 50 ?>" min="0">
    </div>
  </div>
</div>

<!-- Assign Questions -->
<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-list-ol" style="color:var(--success)"></i>
      Assign Questions
    </div>
    <div style="display:flex;gap:8px;align-items:center">
      <span id="selectedCount" style="font-size:12px;color:var(--cyan);font-weight:700">0 selected</span>
      <input type="text" id="questionSearch" class="form-input"
        placeholder="Search questions..." style="width:200px"
        oninput="filterQuestions(this.value)">
    </div>
  </div>

  <div id="questionsList" style="max-height:400px;overflow-y:auto">
    <?php foreach ($availableQuestions as $i => $q): ?>
    <label style="display:flex;align-items:flex-start;gap:10px;padding:10px 0;
      border-bottom:1px solid rgba(255,255,255,0.04);cursor:pointer;
      transition:background 0.15s;border-radius:8px;padding:8px"
      class="q-row" data-text="<?= htmlspecialchars(strtolower($q['question_text'])) ?>"
      data-cat="<?= $q['category'] ?>">
      <input type="checkbox" name="question_ids[]" value="<?= $q['id'] ?>"
        style="accent-color:var(--cyan);width:16px;height:16px;flex-shrink:0;margin-top:2px"
        onchange="updateCount()">
      <div style="flex:1">
        <div style="font-size:13px;color:var(--text2);line-height:1.4">
          <?= htmlspecialchars(mb_substr($q['question_text'],0,100)) ?>
          <?= mb_strlen($q['question_text'])>100?'...':'' ?>
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
  <button type="submit" name="save_practice" class="btn btn-primary">
    <i class="fas fa-save"></i> Save Practice Set
  </button>
  <a href="<?= ADMIN_URL ?>/daily_practice/index.php" class="btn btn-secondary">
    <i class="fas fa-times"></i> Cancel
  </a>
</div>

</form>

<script>
function updateCount() {
  const n = document.querySelectorAll('[name="question_ids[]"]:checked').length;
  document.getElementById('selectedCount').textContent = n + ' selected';
}

function filterQuestions(q) {
  document.querySelectorAll('.q-row').forEach(row => {
    const match = !q || row.dataset.text.includes(q.toLowerCase());
    row.style.display = match ? '' : 'none';
  });
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>