<?php
// ── Config FIRST (no HTML output yet) so header('Location') redirects work ──
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';

$catLabels = [
    'mcq'            => '5000 Speed Math MCQ (Practice Sets)',
    'simplification' => '500 Simplification',
    'tunnlity'       => 'Test Your Tunnlity',
    'previous_year'  => 'Previous Year',
    'daily_practice' => 'Daily Practice',
];
$cat   = $_GET['cat'] ?? ($_GET['category'] ?? '');
if ($cat !== '' && !isset($catLabels[$cat])) $cat = '';
$setId = intval($_GET['set_id'] ?? 0);
$ret   = $_GET['ret'] ?? '';
if ($ret !== '' && strpos($ret, 'manage_sets.php') === false) $ret = '';

$scopeQS = '';
if ($cat)   $scopeQS .= '&cat=' . urlencode($cat);
if ($setId) $scopeQS .= '&set_id=' . $setId;
if ($ret)   $scopeQS .= '&ret=' . urlencode($ret);

$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $stmt = $pdo->prepare("
            INSERT INTO questions
              (set_id, category, question_text, option_a, option_b, option_c, option_d,
               correct_option, explanation, difficulty, is_active,
               question_text_hi, option_a_hi, option_b_hi, option_c_hi, option_d_hi, explanation_hi)
            VALUES (?,?,?,?,?,?,?,?,?,?,1,?,?,?,?,?,?)
        ");
        $stmt->execute([
            $_POST['set_id'],
            $_POST['category'],
            trim($_POST['question_text']),
            trim($_POST['option_a']),
            trim($_POST['option_b']),
            trim($_POST['option_c']),
            trim($_POST['option_d']),
            $_POST['correct_option'],
            trim($_POST['explanation'] ?? ''),
            $_POST['difficulty'],
            trim($_POST['question_text_hi'] ?? ''),
            trim($_POST['option_a_hi'] ?? ''),
            trim($_POST['option_b_hi'] ?? ''),
            trim($_POST['option_c_hi'] ?? ''),
            trim($_POST['option_d_hi'] ?? ''),
            trim($_POST['explanation_hi'] ?? ''),
        ]);

        if (isset($_POST['add_another'])) {
            $success = 'Question added! Add another:';
        } else {
            header('Location: ' . ADMIN_URL . '/questions/index.php?added=1' . $scopeQS);
            exit;
        }
    } catch (Exception $e) {
        $error = $e->getMessage();
        if (stripos($error, 'Data truncated') !== false || stripos($error, 'Incorrect') !== false) {
            $error = 'Could not save: the "' . htmlspecialchars($_POST['category'] ?? '')
                   . '" category is not enabled in the database yet. '
                   . 'Run admin/migrations/v5_complete_fix.sql, then try again.';
        }
    }
}

$pageTitle = 'Add Question';
require_once dirname(__DIR__) . '/includes/header.php';

// Sets dropdown — scoped to the section's category when present.
// For Previous Year we also surface the exam name + year so the admin always
// knows which exam/year a set belongs to before adding questions to it.
if ($cat !== '') {
    $sQ = $pdo->prepare("
        SELECT s.id, s.set_number, s.title, s.category, s.exam_name, pe.exam_year
        FROM sets s
        LEFT JOIN py_exams pe ON pe.id = s.exam_id
        WHERE s.category = ? ORDER BY s.set_number");
    $sQ->execute([$cat]);
    $sets = $sQ->fetchAll();
} else {
    $sets = $pdo->query("
        SELECT s.id, s.set_number, s.title, s.category, s.exam_name, pe.exam_year
        FROM sets s
        LEFT JOIN py_exams pe ON pe.id = s.exam_id
        ORDER BY s.category, s.set_number")->fetchAll();
}

$selCat = $_POST['category'] ?? $cat;
$selSet = $_POST['set_id']   ?? $setId;
?>

<?php if ($success): ?>
<div class="alert" style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $success ?>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div class="alert" style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-exclamation-circle"></i> <?= $error ?>
</div>
<?php endif; ?>

<div style="max-width:800px">

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700;color:var(--text)">
      Add New Question
    </h2>
    <p class="text-muted"><?= $cat !== '' ? htmlspecialchars($catLabels[$cat]) : 'Fill all fields carefully' ?></p>
  </div>
  <a href="<?= ADMIN_URL ?>/questions/index.php?<?= ltrim($scopeQS, '&') ?>" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back
  </a>
</div>

<form method="POST">

  <div class="card mb-16">
    <div class="card-header">
      <div class="card-title-text"><i class="fas fa-info-circle" style="color:var(--cyan)"></i> Question Info</div>
    </div>

    <div class="form-row">
      <div class="form-group">
        <label class="form-label">Category *</label>
        <?php if ($cat !== ''): ?>
          <input type="text" class="form-input" value="<?= htmlspecialchars($catLabels[$cat]) ?>" disabled>
          <input type="hidden" name="category" value="<?= htmlspecialchars($cat) ?>">
        <?php else: ?>
          <select name="category" class="form-select" required onchange="filterSets(this.value)">
            <option value="">Select Category</option>
            <?php foreach ($catLabels as $k => $lbl): ?>
            <option value="<?= $k ?>" <?= $selCat===$k ?'selected':'' ?>><?= htmlspecialchars($lbl) ?></option>
            <?php endforeach; ?>
          </select>
        <?php endif; ?>
      </div>

      <div class="form-group">
        <label class="form-label">Set *</label>
        <select name="set_id" class="form-select" required id="setSelect">
          <option value="">Select Set</option>
          <?php foreach ($sets as $set):
            $label = '';
            if (!empty($set['exam_name'])) {
              $label .= $set['exam_name'];
              if (!empty($set['exam_year'])) $label .= ' ' . intval($set['exam_year']);
              $label .= ' • ';
            }
            $label .= 'Set ' . $set['set_number'];
            if (!empty($set['title'])) $label .= ' — ' . $set['title'];
          ?>
          <option value="<?= $set['id'] ?>" data-category="<?= htmlspecialchars($set['category']) ?>"
            <?= $selSet==$set['id'] ? 'selected':'' ?>>
            <?= htmlspecialchars($label) ?>
          </option>
          <?php endforeach; ?>
        </select>
      </div>

      <div class="form-group">
        <label class="form-label">Difficulty *</label>
        <select name="difficulty" class="form-select" required>
          <option value="easy"   <?= ($_POST['difficulty']??'')==='easy'   ?'selected':'' ?>>🟢 Easy</option>
          <option value="medium" <?= ($_POST['difficulty']??'medium')==='medium' ?'selected':'' ?>>🟡 Medium</option>
          <option value="hard"   <?= ($_POST['difficulty']??'')==='hard'   ?'selected':'' ?>>🔴 Hard</option>
        </select>
      </div>
    </div>

    <div class="form-group">
      <label class="form-label">Question Text *</label>
      <textarea name="question_text" class="form-textarea" rows="3" placeholder="Write the question here..." required><?= htmlspecialchars($_POST['question_text']??'') ?></textarea>
    </div>
  </div>

  <div class="card mb-16">
    <div class="card-header">
      <div class="card-title-text"><i class="fas fa-list-ol" style="color:var(--success)"></i> Answer Options</div>
      <span class="badge badge-cyan">Select correct answer</span>
    </div>

    <?php
    $opts = ['A','B','C','D'];
    $colors = ['A'=>'var(--cyan)','B'=>'var(--success)','C'=>'var(--warning)','D'=>'var(--error)'];
    foreach ($opts as $opt):
    ?>
    <div style="display:flex;align-items:center;gap:12px;margin-bottom:12px">
      <label style="display:flex;align-items:center;gap:6px;cursor:pointer;flex-shrink:0">
        <input type="radio" name="correct_option" value="<?= $opt ?>"
          <?= ($_POST['correct_option']??'')===$opt ? 'checked':'' ?> required
          style="accent-color:var(--cyan);width:16px;height:16px">
        <span style="width:28px;height:28px;border-radius:8px;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:13px;border:1px solid <?= $colors[$opt] ?>;color:<?= $colors[$opt] ?>;background:rgba(0,0,0,0.2)"><?= $opt ?></span>
      </label>
      <input type="text" name="option_<?= strtolower($opt) ?>" class="form-input"
        placeholder="Option <?= $opt ?>..." value="<?= htmlspecialchars($_POST['option_'.strtolower($opt)]??'') ?>" required>
    </div>
    <?php endforeach; ?>

    <div class="form-group mt-16">
      <label class="form-label">Explanation (Optional)</label>
      <textarea name="explanation" class="form-textarea" rows="2" placeholder="Why is this the correct answer?"><?= htmlspecialchars($_POST['explanation']??'') ?></textarea>
    </div>
  </div>

  <div class="card mb-16">
    <div class="card-header">
      <div class="card-title-text"><i class="fas fa-language" style="color:var(--purple)"></i> Hindi Version (Optional)</div>
    </div>
    <p class="text-muted" style="font-size:12px;margin:0 0 10px">Fill these so users can switch this question to Hindi in the app. Leave blank to show English only.</p>
    <div class="form-group">
      <label class="form-label">Question (Hindi)</label>
      <textarea name="question_text_hi" class="form-textarea" rows="2" placeholder="प्रश्न..."><?= htmlspecialchars($_POST['question_text_hi']??'') ?></textarea>
    </div>
    <div class="form-row">
      <div class="form-group"><label class="form-label">Option A (Hindi)</label><input type="text" name="option_a_hi" class="form-input" value="<?= htmlspecialchars($_POST['option_a_hi']??'') ?>"></div>
      <div class="form-group"><label class="form-label">Option B (Hindi)</label><input type="text" name="option_b_hi" class="form-input" value="<?= htmlspecialchars($_POST['option_b_hi']??'') ?>"></div>
    </div>
    <div class="form-row">
      <div class="form-group"><label class="form-label">Option C (Hindi)</label><input type="text" name="option_c_hi" class="form-input" value="<?= htmlspecialchars($_POST['option_c_hi']??'') ?>"></div>
      <div class="form-group"><label class="form-label">Option D (Hindi)</label><input type="text" name="option_d_hi" class="form-input" value="<?= htmlspecialchars($_POST['option_d_hi']??'') ?>"></div>
    </div>
    <div class="form-group">
      <label class="form-label">Explanation (Hindi)</label>
      <textarea name="explanation_hi" class="form-textarea" rows="2" placeholder="व्याख्या..."><?= htmlspecialchars($_POST['explanation_hi']??'') ?></textarea>
    </div>
  </div>

  <div style="display:flex;gap:12px;flex-wrap:wrap">
    <button type="submit" name="save" class="btn btn-primary"><i class="fas fa-save"></i> Save Question</button>
    <button type="submit" name="add_another" class="btn btn-secondary"><i class="fas fa-plus"></i> Save & Add Another</button>
    <a href="<?= ADMIN_URL ?>/questions/index.php?<?= ltrim($scopeQS, '&') ?>" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
  </div>

</form>
</div>

<script>
function filterSets(category) {
  const select = document.getElementById('setSelect');
  Array.from(select.options).forEach(opt => {
    if (!opt.value) return;
    opt.style.display = (!category || opt.dataset.category === category) ? '' : 'none';
  });
  select.value = '';
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
