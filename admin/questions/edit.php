<?php
// Config FIRST (no HTML output) so header('Location') redirects work.
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';

$id = intval($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/questions/index.php'); exit; }

$question = $pdo->prepare("SELECT * FROM questions WHERE id = ?");
$question->execute([$id]);
$question = $question->fetch();
if (!$question) { header('Location: ' . ADMIN_URL . '/questions/index.php'); exit; }

$sets    = $pdo->query("SELECT id, set_number, title, category FROM sets ORDER BY category, set_number")->fetchAll();
$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->prepare("
            UPDATE questions SET
              set_id=?, category=?, question_text=?,
              option_a=?, option_b=?, option_c=?, option_d=?,
              correct_option=?, explanation=?, difficulty=?
            WHERE id=?
        ")->execute([
            $_POST['set_id'], $_POST['category'],
            trim($_POST['question_text']),
            trim($_POST['option_a']), trim($_POST['option_b']),
            trim($_POST['option_c']), trim($_POST['option_d']),
            $_POST['correct_option'],
            trim($_POST['explanation'] ?? ''),
            $_POST['difficulty'],
            $id
        ]);
        $success = 'Question updated successfully!';
        $question = $pdo->prepare("SELECT * FROM questions WHERE id = ?");
        $question->execute([$id]);
        $question = $question->fetch();
    } catch (Exception $e) {
        $error = $e->getMessage();
    }
}

// Preserve the section context for the Back/Cancel links.
$cat   = $_GET['cat'] ?? ($_GET['category'] ?? $question['category']);
$setId = intval($_GET['set_id'] ?? $question['set_id']);
$scopeQS = '';
if ($cat)   $scopeQS .= '&cat=' . urlencode($cat);
if ($setId) $scopeQS .= '&set_id=' . $setId;

$pageTitle = 'Edit Question';
require_once dirname(__DIR__) . '/includes/header.php';
?>

<?php if ($success): ?>
<div class="alert" style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $success ?>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div class="alert" style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:20px">
  <?= $error ?>
</div>
<?php endif; ?>

<div style="max-width:800px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Edit Question #<?= $id ?></h2>
    <p class="text-muted">Update question details</p>
  </div>
  <a href="<?= ADMIN_URL ?>/questions/index.php?<?= ltrim($scopeQS, '&') ?>" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back
  </a>
</div>

<form method="POST">
  <div class="card mb-16">
    <div class="form-row">
      <div class="form-group">
        <label class="form-label">Category *</label>
        <select name="category" class="form-select" required>
          <option value="mcq"            <?= $question['category']==='mcq'            ?'selected':'' ?>>5000 MCQ</option>
          <option value="simplification" <?= $question['category']==='simplification' ?'selected':'' ?>>500 Simplification</option>
          <option value="previous_year"  <?= $question['category']==='previous_year'  ?'selected':'' ?>>Previous Year</option>
          <option value="tunnlity"        <?= $question['category']==='tunnlity'        ?'selected':'' ?>>Test Your Tunnlity</option>
          <option value="daily_practice" <?= $question['category']==='daily_practice' ?'selected':'' ?>>Daily Practice</option>
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Set *</label>
        <select name="set_id" class="form-select" required>
          <?php foreach ($sets as $set): ?>
          <option value="<?= $set['id'] ?>" <?= $question['set_id']==$set['id']?'selected':'' ?>>
            Set <?= $set['set_number'] ?>
          </option>
          <?php endforeach; ?>
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Difficulty *</label>
        <select name="difficulty" class="form-select" required>
          <option value="easy"   <?= $question['difficulty']==='easy'  ?'selected':'' ?>>🟢 Easy</option>
          <option value="medium" <?= $question['difficulty']==='medium'?'selected':'' ?>>🟡 Medium</option>
          <option value="hard"   <?= $question['difficulty']==='hard'  ?'selected':'' ?>>🔴 Hard</option>
        </select>
      </div>
    </div>
    <div class="form-group">
      <label class="form-label">Question Text *</label>
      <textarea name="question_text" class="form-textarea" rows="3" required><?= htmlspecialchars($question['question_text']) ?></textarea>
    </div>
  </div>

  <div class="card mb-16">
    <?php $opts = ['A','B','C','D']; $colors = ['A'=>'var(--cyan)','B'=>'var(--success)','C'=>'var(--warning)','D'=>'var(--error)']; ?>
    <?php foreach ($opts as $opt): ?>
    <div style="display:flex;align-items:center;gap:12px;margin-bottom:12px">
      <label style="display:flex;align-items:center;gap:6px;cursor:pointer;flex-shrink:0">
        <input type="radio" name="correct_option" value="<?= $opt ?>"
          <?= $question['correct_option']===$opt?'checked':'' ?> required
          style="accent-color:var(--cyan);width:16px;height:16px">
        <span style="width:28px;height:28px;border-radius:8px;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:13px;border:1px solid <?= $colors[$opt] ?>;color:<?= $colors[$opt] ?>">
          <?= $opt ?>
        </span>
      </label>
      <input type="text" name="option_<?= strtolower($opt) ?>" class="form-input"
        value="<?= htmlspecialchars($question['option_'.strtolower($opt)]) ?>" required>
    </div>
    <?php endforeach; ?>
    <div class="form-group mt-16">
      <label class="form-label">Explanation</label>
      <textarea name="explanation" class="form-textarea" rows="2"><?= htmlspecialchars($question['explanation']) ?></textarea>
    </div>
  </div>

  <div style="display:flex;gap:12px">
    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Update</button>
    <a href="<?= ADMIN_URL ?>/questions/index.php?<?= ltrim($scopeQS, '&') ?>" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
  </div>
</form>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>