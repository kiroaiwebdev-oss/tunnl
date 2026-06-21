<?php
// Config FIRST (no HTML output) so header('Location') redirects work.
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';

$labels = [
    'mcq'            => '5000 Speed Math MCQ (Practice Sets)',
    'tunnlity'       => 'Test Your Tunnlity',
    'previous_year'  => 'Previous Year',
];
$cat = $_GET['cat'] ?? '';
if ($cat !== '' && !isset($labels[$cat])) $cat = '';
$catQS = $cat !== '' ? '&cat=' . urlencode($cat) : '';

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $postCat = $_POST['category'] ?? $cat;
        $pdo->prepare("
            INSERT INTO sets
              (category, exam_name, set_number, title, level, total_questions, is_locked, is_premium)
            VALUES (?,?,?,?,?,?,?,?)
        ")->execute([
            $postCat,
            trim($_POST['exam_name'] ?? ''),
            intval($_POST['set_number']),
            trim($_POST['title'] ?? ''),
            $_POST['level'],
            max(1, intval($_POST['total_questions'] ?? 10)),
            isset($_POST['is_locked']) ? 1 : 0,
            isset($_POST['is_premium']) ? 1 : 0,
        ]);
        $back = '&cat=' . urlencode($postCat);
        header('Location: ' . ADMIN_URL . '/sets/index.php?added=1' . $back);
        exit;
    } catch (Exception $e) {
        $error = $e->getMessage();
        if (stripos($error, 'Data truncated') !== false || stripos($error, 'Incorrect') !== false) {
            $error = 'Could not save: the "' . htmlspecialchars($_POST['category'] ?? '')
                   . '" category is not enabled in the database. Run migration v5_complete_fix.sql.';
        }
    }
}

$pageTitle = 'Add Set';
require_once dirname(__DIR__) . '/includes/header.php';
?>

<div style="max-width:600px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Add New Set</h2>
    <p class="text-muted"><?= $cat !== '' ? htmlspecialchars($labels[$cat]) : 'Create a question set' ?></p>
  </div>
  <a href="<?= ADMIN_URL ?>/sets/index.php?<?= ltrim($catQS, '&') ?>" class="btn btn-secondary"><i class="fas fa-arrow-left"></i> Back</a>
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
      <?php if ($cat !== ''): ?>
        <input type="text" class="form-input" value="<?= htmlspecialchars($labels[$cat]) ?>" disabled>
        <input type="hidden" name="category" value="<?= htmlspecialchars($cat) ?>">
      <?php else: ?>
        <select name="category" class="form-select" required>
          <option value="mcq">5000 Speed Math MCQ (Practice Sets)</option>
          <option value="tunnlity">Test Your Tunnlity</option>
          <option value="previous_year">Previous Year</option>
        </select>
      <?php endif; ?>
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
      <label class="form-label">Exam Name (PY / MCQ exam group)</label>
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
      <input type="number" name="total_questions" class="form-input" value="10" required min="1" max="200">
      <p style="font-size:11px;color:var(--muted);margin-top:4px">Default 10. Increase if you want a longer test. For a random pool (e.g. Tunnlity), upload more questions than this and each attempt picks this many at random.</p>
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
    <a href="<?= ADMIN_URL ?>/sets/index.php?<?= ltrim($catQS, '&') ?>" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
  </div>
</div>
</form>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
