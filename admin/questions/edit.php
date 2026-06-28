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
              correct_option=?, explanation=?, difficulty=?,
              question_text_hi=?, option_a_hi=?, option_b_hi=?, option_c_hi=?, option_d_hi=?, explanation_hi=?,
              exam_name=?, exam_year=?
            WHERE id=?
        ")->execute([
            $_POST['set_id'], $_POST['category'],
            trim($_POST['question_text']),
            trim($_POST['option_a']), trim($_POST['option_b']),
            trim($_POST['option_c']), trim($_POST['option_d']),
            $_POST['correct_option'],
            trim($_POST['explanation'] ?? ''),
            $_POST['difficulty'],
            trim($_POST['question_text_hi'] ?? ''),
            trim($_POST['option_a_hi'] ?? ''),
            trim($_POST['option_b_hi'] ?? ''),
            trim($_POST['option_c_hi'] ?? ''),
            trim($_POST['option_d_hi'] ?? ''),
            trim($_POST['explanation_hi'] ?? ''),
            trim($_POST['exam_name'] ?? ''),
            trim($_POST['exam_year'] ?? ''),
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
$ret   = $_GET['ret'] ?? '';
if ($ret !== '' && strpos($ret, 'manage_sets.php') === false) $ret = '';
$scopeQS = '';
if ($cat)   $scopeQS .= '&cat=' . urlencode($cat);
if ($setId) $scopeQS .= '&set_id=' . $setId;
if ($ret)   $scopeQS .= '&ret=' . urlencode($ret);

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
          <option value="tricks"          <?= $question['category']==='tricks'          ?'selected':'' ?>>Tunnl Tricks Practice</option>
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

  <div class="card mb-16">
    <div class="card-header">
      <div class="card-title-text"><i class="fas fa-language" style="color:var(--purple)"></i> Hindi Version (Optional)</div>
    </div>
    <p class="text-muted" style="font-size:12px;margin:0 0 10px">Fill these so users can switch this question to Hindi in the app.</p>
    <div class="form-group">
      <label class="form-label">Question (Hindi)</label>
      <textarea name="question_text_hi" class="form-textarea" rows="2" placeholder="प्रश्न..."><?= htmlspecialchars($question['question_text_hi'] ?? '') ?></textarea>
    </div>
    <div class="form-row">
      <div class="form-group"><label class="form-label">Option A (Hindi)</label><input type="text" name="option_a_hi" class="form-input" value="<?= htmlspecialchars($question['option_a_hi'] ?? '') ?>"></div>
      <div class="form-group"><label class="form-label">Option B (Hindi)</label><input type="text" name="option_b_hi" class="form-input" value="<?= htmlspecialchars($question['option_b_hi'] ?? '') ?>"></div>
    </div>
    <div class="form-row">
      <div class="form-group"><label class="form-label">Option C (Hindi)</label><input type="text" name="option_c_hi" class="form-input" value="<?= htmlspecialchars($question['option_c_hi'] ?? '') ?>"></div>
      <div class="form-group"><label class="form-label">Option D (Hindi)</label><input type="text" name="option_d_hi" class="form-input" value="<?= htmlspecialchars($question['option_d_hi'] ?? '') ?>"></div>
    </div>
    <div class="form-group">
      <label class="form-label">Explanation (Hindi)</label>
      <textarea name="explanation_hi" class="form-textarea" rows="2" placeholder="व्याख्या..."><?= htmlspecialchars($question['explanation_hi'] ?? '') ?></textarea>
    </div>
  </div>

  <div class="card mb-16">
    <div class="card-header">
      <div class="card-title-text"><i class="fas fa-history" style="color:var(--warning)"></i> Previous Year Tag (Exam &amp; Year)</div>
    </div>
    <p class="text-muted" style="font-size:12px;margin:0 0 10px">Shown above the question in the app (e.g. "SSC CGL · 2023"). Leave blank for non-PYQ.</p>
    <div class="form-row">
      <div class="form-group"><label class="form-label">Exam Name</label><input type="text" name="exam_name" class="form-input" placeholder="e.g. SSC CGL" value="<?= htmlspecialchars($question['exam_name'] ?? '') ?>"></div>
      <div class="form-group"><label class="form-label">Year</label><input type="text" name="exam_year" class="form-input" placeholder="e.g. 2023" value="<?= htmlspecialchars($question['exam_year'] ?? '') ?>"></div>
    </div>
  </div>

  <div style="display:flex;gap:12px">
    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Update</button>
    <a href="<?= ADMIN_URL ?>/questions/index.php?<?= ltrim($scopeQS, '&') ?>" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
  </div>
</form>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>