<?php
// Config FIRST (no HTML output) so header('Location') redirects work.
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';

$cat   = $_GET['cat'] ?? '';
$catQS = $cat !== '' ? '&cat=' . urlencode($cat) : '';

$id = intval($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/sets/index.php?' . ltrim($catQS, '&')); exit; }

$set = $pdo->prepare("SELECT * FROM sets WHERE id = ?");
$set->execute([$id]);
$set = $set->fetch();
if (!$set) { header('Location: ' . ADMIN_URL . '/sets/index.php?' . ltrim($catQS, '&')); exit; }

$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->prepare("
            UPDATE sets SET
              category=?, exam_name=?, set_number=?, title=?,
              level=?, total_questions=?, is_locked=?, is_premium=?
            WHERE id=?
        ")->execute([
            $_POST['category'],
            trim($_POST['exam_name'] ?? ''),
            intval($_POST['set_number']),
            trim($_POST['title'] ?? ''),
            $_POST['level'],
            min(10, max(1, intval($_POST['total_questions'] ?? 10))),
            isset($_POST['is_locked'])  ? 1 : 0,
            isset($_POST['is_premium']) ? 1 : 0,
            $id
        ]);
        $success = 'Set updated!';
        $set = $pdo->prepare("SELECT * FROM sets WHERE id = ?");
        $set->execute([$id]);
        $set = $set->fetch();
    } catch (Exception $e) { $error = $e->getMessage(); }
}

$qCount = $pdo->prepare("SELECT COUNT(*) FROM questions WHERE set_id = ?");
$qCount->execute([$id]);
$qCount = $qCount->fetchColumn();

$pageTitle = 'Edit Set';
require_once dirname(__DIR__) . '/includes/header.php';
?>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $success ?>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:20px">
  <?= $error ?>
</div>
<?php endif; ?>

<div style="max-width:600px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Edit Set #<?= $set['set_number'] ?></h2>
    <p class="text-muted"><?= $qCount ?> / 10 questions in this set</p>
  </div>
  <div style="display:flex;gap:8px">
    <a href="<?= ADMIN_URL ?>/questions/index.php?cat=<?= urlencode($set['category']) ?>&set_id=<?= $id ?>" class="btn btn-primary">
      <i class="fas fa-list-ol"></i> Questions
    </a>
    <a href="<?= ADMIN_URL ?>/sets/index.php?<?= ltrim($catQS, '&') ?>" class="btn btn-secondary">
      <i class="fas fa-arrow-left"></i> Back
    </a>
  </div>
</div>

<form method="POST">
<div class="card">
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Category *</label>
      <select name="category" class="form-select" required>
        <option value="mcq"            <?= $set['category']==='mcq'            ?'selected':'' ?>>5000 Speed Math MCQ (Practice Sets)</option>
        <option value="simplification" <?= $set['category']==='simplification' ?'selected':'' ?>>500 Simplification</option>
        <option value="tunnlity"        <?= $set['category']==='tunnlity'        ?'selected':'' ?>>Test Your Tunnlity</option>
        <option value="previous_year"  <?= $set['category']==='previous_year'  ?'selected':'' ?>>Previous Year</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Set Number *</label>
      <input type="number" name="set_number" class="form-input"
        value="<?= $set['set_number'] ?>" required min="1">
    </div>
  </div>
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Title</label>
      <input type="text" name="title" class="form-input"
        value="<?= htmlspecialchars($set['title']) ?>"
        placeholder="e.g. Percentage Basics">
    </div>
    <div class="form-group">
      <label class="form-label">Exam Name (PY / MCQ exam group)</label>
      <input type="text" name="exam_name" class="form-input"
        value="<?= htmlspecialchars($set['exam_name']) ?>"
        placeholder="e.g. SSC CGL 2023">
    </div>
  </div>
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Level *</label>
      <select name="level" class="form-select" required>
        <option value="beginner"     <?= $set['level']==='beginner'     ?'selected':'' ?>>Beginner</option>
        <option value="intermediate" <?= $set['level']==='intermediate' ?'selected':'' ?>>Intermediate</option>
        <option value="advanced"     <?= $set['level']==='advanced'     ?'selected':'' ?>>Advanced</option>
        <option value="expert"       <?= $set['level']==='expert'       ?'selected':'' ?>>Expert</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Total Questions *</label>
      <input type="number" name="total_questions" class="form-input"
        value="<?= min(10, (int)$set['total_questions']) ?>" required min="1" max="10">
      <p style="font-size:11px;color:var(--muted);margin-top:4px">Every set is capped at 10 questions.</p>
    </div>
  </div>
  <div style="display:flex;gap:24px;margin-bottom:20px">
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="is_locked" style="accent-color:var(--cyan);width:16px;height:16px"
        <?= $set['is_locked'] ? 'checked':'' ?>>
      <span style="font-size:13px;color:var(--text2)">
        <i class="fas fa-lock" style="color:var(--muted)"></i> Locked
      </span>
    </label>
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="is_premium" style="accent-color:var(--warning);width:16px;height:16px"
        <?= $set['is_premium'] ? 'checked':'' ?>>
      <span style="font-size:13px;color:var(--text2)">
        <i class="fas fa-crown" style="color:var(--warning)"></i> Premium Only
      </span>
    </label>
  </div>
  <div style="display:flex;gap:12px">
    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Update Set</button>
    <a href="<?= ADMIN_URL ?>/sets/index.php?<?= ltrim($catQS, '&') ?>" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
  </div>
</div>
</form>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
