<?php
$pageTitle = 'Add PY Exam';
require_once dirname(__DIR__) . '/includes/header.php';

$success = $error = '';
$prefill = htmlspecialchars($_GET['exam_name'] ?? '');

$examNames = ['SSC CGL','SSC CHSL','SSC MTS','SSC CPO',
              'IBPS PO','IBPS Clerk','SBI PO','SBI Clerk',
              'RRB NTPC','RRB Group D','RBI Grade B'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->prepare("
            INSERT INTO py_exams
              (exam_name, exam_year, exam_date, total_sets,
               total_questions, difficulty, is_premium, is_active)
            VALUES (?,?,?,?,?,?,?,1)
        ")->execute([
            trim($_POST['exam_name']),
            intval($_POST['exam_year']),
            !empty($_POST['exam_date']) ? $_POST['exam_date'] : null,
            intval($_POST['total_sets']),
            intval($_POST['total_questions']),
            $_POST['difficulty'],
            isset($_POST['is_premium']) ? 1 : 0,
        ]);
        header('Location: ' . ADMIN_URL . '/previous_year/index.php?added=1');
        exit;
    } catch (Exception $e) { $error = $e->getMessage(); }
}
?>

<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;
  padding:12px 16px;border-radius:12px;margin-bottom:20px">
  <?= $error ?>
</div>
<?php endif; ?>

<div style="max-width:600px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Add PY Exam</h2>
    <p class="text-muted">Add a previous year paper exam</p>
  </div>
  <a href="<?= ADMIN_URL ?>/previous_year/index.php" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back
  </a>
</div>

<form method="POST">
<div class="card mb-16">

  <div class="form-group">
    <label class="form-label">Exam Name *</label>
    <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:8px">
      <?php foreach ($examNames as $en): ?>
      <button type="button" onclick="setExam('<?= $en ?>')"
        style="padding:6px 12px;border-radius:8px;border:1px solid var(--border);
          background:var(--dark);color:var(--muted);font-size:12px;cursor:pointer;
          transition:all 0.2s;font-family:'Inter',sans-serif"
        onmouseover="this.style.borderColor='var(--cyan)';this.style.color='var(--cyan)'"
        onmouseout="this.style.borderColor='var(--border)';this.style.color='var(--muted)'">
        <?= $en ?>
      </button>
      <?php endforeach; ?>
    </div>
    <input type="text" name="exam_name" id="examNameInput" class="form-input" required
      value="<?= $prefill ?>" placeholder="e.g. SSC CGL">
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Year *</label>
      <select name="exam_year" class="form-select" required>
        <?php for ($y = date('Y'); $y >= 2015; $y--): ?>
        <option value="<?= $y ?>"><?= $y ?></option>
        <?php endfor; ?>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Exam Date</label>
      <input type="date" name="exam_date" class="form-input">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Total Sets</label>
      <input type="number" name="total_sets" class="form-input" value="1" min="1">
    </div>
    <div class="form-group">
      <label class="form-label">Total Questions</label>
      <input type="number" name="total_questions" class="form-input" value="25" min="1">
    </div>
    <div class="form-group">
      <label class="form-label">Difficulty</label>
      <select name="difficulty" class="form-select">
        <option value="Beginner">Beginner</option>
        <option value="Intermediate" selected>Intermediate</option>
        <option value="Advanced">Advanced</option>
      </select>
    </div>
  </div>

  <label style="display:flex;align-items:center;gap:8px;cursor:pointer;margin-bottom:16px">
    <input type="checkbox" name="is_premium" style="accent-color:var(--warning);width:16px;height:16px">
    <span style="font-size:13px;color:var(--text2)">
      <i class="fas fa-crown" style="color:var(--warning)"></i> Premium Only
    </span>
  </label>

  <div style="display:flex;gap:12px">
    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Add Exam</button>
    <a href="<?= ADMIN_URL ?>/previous_year/index.php" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
  </div>
</div>
</form>
</div>

<script>
function setExam(name) {
  document.getElementById('examNameInput').value = name;
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>