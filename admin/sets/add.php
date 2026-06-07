<?php
$pageTitle = 'Add Set';
require_once dirname(__DIR__) . '/includes/header.php';

$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->prepare("
            INSERT INTO sets
              (category, exam_name, set_number, title, level, total_questions, is_locked, is_premium)
            VALUES (?,?,?,?,?,?,?,?)
        ")->execute([
            $_POST['category'],
            trim($_POST['exam_name'] ?? ''),
            intval($_POST['set_number']),
            trim($_POST['title'] ?? ''),
            $_POST['level'],
            intval($_POST['total_questions']),
            isset($_POST['is_locked']) ? 1 : 0,
            isset($_POST['is_premium']) ? 1 : 0,
        ]);
        header('Location: ' . ADMIN_URL . '/sets/index.php?added=1');
        exit;
    } catch (Exception $e) {
        $error = $e->getMessage();
    }
}
?>

<div style="max-width:600px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Add New Set</h2>
    <p class="text-muted">Create a question set</p>
  </div>
  <a href="<?= ADMIN_URL ?>/sets/index.php" class="btn btn-secondary"><i class="fas fa-arrow-left"></i> Back</a>
</div>

<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:20px">
  <?= $error ?>
</div>
<?php endif; ?>

<form method="POST">
<div class="card">
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Category *</label>
      <select name="category" class="form-select" required>
        <option value="mcq">5000 Speed Math MCQ</option>
        <option value="simplification">500 Simplification</option>
        <option value="previous_year">Previous Year</option>
        <option value="tunnlity">Test Your Tunnlity</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Set Number *</label>
      <input type="number" name="set_number" class="form-input" required min="1" placeholder="1">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Title</label>
      <input type="text" name="title" class="form-input" placeholder="e.g. Percentage Basics">
    </div>
    <div class="form-group">
      <label class="form-label">Exam Name (PY only)</label>
      <input type="text" name="exam_name" class="form-input" placeholder="e.g. SSC CGL 2023">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Level *</label>
      <select name="level" class="form-select" required>
        <option value="beginner">Beginner</option>
        <option value="intermediate">Intermediate</option>
        <option value="advanced">Advanced</option>
        <option value="expert">Expert</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Total Questions *</label>
      <input type="number" name="total_questions" class="form-input" value="50" required min="1">
    </div>
  </div>

  <div style="display:flex;gap:24px;margin-bottom:16px">
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="is_locked" style="accent-color:var(--cyan);width:16px;height:16px">
      <span style="font-size:13px;color:var(--text2)"><i class="fas fa-lock" style="color:var(--muted)"></i> Locked</span>
    </label>
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="is_premium" style="accent-color:var(--warning);width:16px;height:16px">
      <span style="font-size:13px;color:var(--text2)"><i class="fas fa-crown" style="color:var(--warning)"></i> Premium Only</span>
    </label>
  </div>

  <div style="display:flex;gap:12px">
    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Create Set</button>
    <a href="<?= ADMIN_URL ?>/sets/index.php" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
  </div>
</div>
</form>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>