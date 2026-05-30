<?php
$pageTitle = 'Edit PY Exam';
require_once dirname(__DIR__) . '/includes/header.php';

$id = intval($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/previous_year/index.php'); exit; }

$exam = $pdo->prepare("SELECT * FROM py_exams WHERE id=?");
$exam->execute([$id]);
$exam = $exam->fetch();
if (!$exam) { header('Location: ' . ADMIN_URL . '/previous_year/index.php'); exit; }

$success = $error = '';

$icons = [
    'school'           => 'School / SSC',
    'train'            => 'Railway',
    'account_balance'  => 'Bank',
    'security'         => 'Defence / Police',
    'flight'           => 'Airforce',
    'gavel'            => 'UPSC / Law',
    'medical_services' => 'Medical',
    'engineering'      => 'Engineering',
    'science'          => 'Science',
    'workspace_premium'=> 'Premium',
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->prepare("
            UPDATE py_exams SET
              exam_name=?, exam_full_name=?, exam_category=?, icon=?,
              exam_year=?, exam_date=?,
              total_sets=?, total_questions=?, difficulty=?,
              is_premium=?, is_active=?
            WHERE id=?
        ")->execute([
            trim($_POST['exam_name']),
            trim($_POST['exam_full_name'] ?? ''),
            $_POST['exam_category'] ?? 'OTHER',
            $_POST['icon']          ?? 'school',
            intval($_POST['exam_year']),
            !empty($_POST['exam_date']) ? $_POST['exam_date'] : null,
            intval($_POST['total_sets'] ?? 1),
            intval($_POST['total_questions'] ?? 25),
            $_POST['difficulty'] ?? 'Medium',
            isset($_POST['is_premium']) ? 1 : 0,
            isset($_POST['is_active'])  ? 1 : 0,
            $id,
        ]);
        $success = 'Exam updated!';
        $exam = $pdo->prepare("SELECT * FROM py_exams WHERE id=?");
        $exam->execute([$id]);
        $exam = $exam->fetch();
    } catch (Exception $e) { $error = $e->getMessage(); }
}
?>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;
  padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $success ?>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;
  padding:12px 16px;border-radius:12px;margin-bottom:20px"><?= $error ?></div>
<?php endif; ?>

<div style="max-width:700px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Edit Exam</h2>
    <p class="text-muted"><?= htmlspecialchars($exam['exam_name']) ?> <?= $exam['exam_year'] ?></p>
  </div>
  <div style="display:flex;gap:8px">
    <a href="<?= ADMIN_URL ?>/previous_year/manage_sets.php?exam_id=<?= $id ?>" class="btn btn-secondary">
      <i class="fas fa-layer-group"></i> Manage Sets
    </a>
    <a href="<?= ADMIN_URL ?>/previous_year/index.php" class="btn btn-secondary">
      <i class="fas fa-arrow-left"></i> Back
    </a>
  </div>
</div>

<form method="POST">
<div class="card">

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Short Name *</label>
      <input type="text" name="exam_name" class="form-input" required
        value="<?= htmlspecialchars($exam['exam_name']) ?>">
    </div>
    <div class="form-group">
      <label class="form-label">Full Name</label>
      <input type="text" name="exam_full_name" class="form-input"
        value="<?= htmlspecialchars($exam['exam_full_name'] ?? '') ?>">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Category *</label>
      <select name="exam_category" class="form-select" required>
        <?php foreach (['SSC','RAILWAY','BANK','DEFENCE','OTHER'] as $c): ?>
        <option value="<?= $c ?>" <?= ($exam['exam_category'] ?? '') === $c ? 'selected' : '' ?>><?= $c ?></option>
        <?php endforeach; ?>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Icon *</label>
      <select name="icon" class="form-select" required>
        <?php foreach ($icons as $k => $label): ?>
        <option value="<?= $k ?>" <?= ($exam['icon'] ?? 'school') === $k ? 'selected' : '' ?>>
          <?= $label ?> (<?= $k ?>)
        </option>
        <?php endforeach; ?>
      </select>
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Year *</label>
      <select name="exam_year" class="form-select" required>
        <?php for ($y=date('Y'); $y>=2015; $y--): ?>
        <option value="<?= $y ?>" <?= ($exam['exam_year'] ?? '') == $y ? 'selected' : '' ?>><?= $y ?></option>
        <?php endfor; ?>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Exam Date</label>
      <input type="date" name="exam_date" class="form-input"
        value="<?= htmlspecialchars($exam['exam_date'] ?? '') ?>">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Total Sets</label>
      <input type="number" name="total_sets" class="form-input" min="1"
        value="<?= intval($exam['total_sets'] ?? 1) ?>">
    </div>
    <div class="form-group">
      <label class="form-label">Total Questions</label>
      <input type="number" name="total_questions" class="form-input" min="1"
        value="<?= intval($exam['total_questions'] ?? 25) ?>">
    </div>
    <div class="form-group">
      <label class="form-label">Difficulty</label>
      <select name="difficulty" class="form-select">
        <?php foreach (['Easy','Medium','Hard'] as $d): ?>
        <option value="<?= $d ?>" <?= ($exam['difficulty'] ?? 'Medium') === $d ? 'selected' : '' ?>><?= $d ?></option>
        <?php endforeach; ?>
      </select>
    </div>
  </div>

  <div style="display:flex;gap:24px;margin-bottom:16px">
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="is_premium" <?= !empty($exam['is_premium']) ? 'checked' : '' ?>
        style="accent-color:var(--warning);width:16px;height:16px">
      <span style="font-size:13px;color:var(--text2)">
        <i class="fas fa-crown" style="color:var(--warning)"></i> Premium Only
      </span>
    </label>
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="is_active" <?= !empty($exam['is_active']) ? 'checked' : '' ?>
        style="accent-color:var(--success);width:16px;height:16px">
      <span style="font-size:13px;color:var(--text2)">
        <i class="fas fa-check-circle" style="color:var(--success)"></i> Active
      </span>
    </label>
  </div>

  <div style="display:flex;gap:12px">
    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Save Changes</button>
    <a href="<?= ADMIN_URL ?>/previous_year/index.php" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
  </div>
</div>
</form>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
