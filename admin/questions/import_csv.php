<?php
$pageTitle = 'Import Questions CSV';
require_once dirname(__DIR__) . '/includes/header.php';

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
$imported = 0;

// Sets dropdown — scoped to the section's category when present.
if ($cat !== '') {
    $sQ = $pdo->prepare("SELECT id, set_number, category, title, exam_name FROM sets WHERE category = ? ORDER BY set_number");
    $sQ->execute([$cat]);
    $sets = $sQ->fetchAll();
} else {
    $sets = $pdo->query("SELECT id, set_number, category, title, exam_name FROM sets ORDER BY category, set_number")->fetchAll();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['csv_file'])) {
    try {
        $category = $_POST['category'] ?: $cat;
        $set_id   = intval($_POST['set_id']);
        $file     = $_FILES['csv_file']['tmp_name'];

        if (!$set_id) throw new Exception('Please choose a target set.');
        if (!$file)   throw new Exception('No file uploaded');

        $handle = fopen($file, 'r');
        fgetcsv($handle); // skip header row

        $stmt = $pdo->prepare("
            INSERT INTO questions
              (set_id, category, question_text, option_a, option_b, option_c, option_d,
               correct_option, explanation, difficulty, is_active,
               question_text_hi, option_a_hi, option_b_hi, option_c_hi, option_d_hi, explanation_hi)
            VALUES (?,?,?,?,?,?,?,?,?,?,1,?,?,?,?,?,?)
        ");

        while (($row = fgetcsv($handle)) !== false) {
            if (count($row) < 6) continue;
            [$question_text, $option_a, $option_b, $option_c, $option_d,
             $correct_option, $explanation, $difficulty,
             $q_hi, $a_hi, $b_hi, $c_hi, $d_hi, $e_hi] = array_pad($row, 14, '');

            if (empty(trim($question_text))) continue;

            $stmt->execute([
                $set_id, $category,
                trim($question_text),
                trim($option_a), trim($option_b),
                trim($option_c), trim($option_d),
                strtoupper(trim($correct_option)) ?: 'A',
                trim($explanation),
                in_array(strtolower(trim($difficulty)), ['easy','hard']) ? strtolower(trim($difficulty)) : 'medium',
                trim($q_hi), trim($a_hi), trim($b_hi), trim($c_hi), trim($d_hi), trim($e_hi),
            ]);
            $imported++;
        }
        fclose($handle);
        $success = "$imported questions imported successfully!";
    } catch (Exception $e) {
        $error = $e->getMessage();
    }
}
?>

<div style="max-width:700px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Import Questions via CSV</h2>
    <p class="text-muted"><?= $cat !== '' ? htmlspecialchars($catLabels[$cat]) . ' · bulk upload' : 'Bulk upload questions from Excel/CSV' ?></p>
  </div>
  <a href="<?= $ret !== '' ? htmlspecialchars($ret) : ADMIN_URL . '/questions/index.php?' . ltrim($scopeQS, '&') ?>" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back
  </a>
</div>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;justify-content:space-between;gap:8px">
  <div><i class="fas fa-check-circle"></i> <strong><?= $success ?></strong></div>
  <a href="<?= ADMIN_URL ?>/questions/index.php?<?= ltrim($scopeQS, '&') ?>" class="btn btn-primary btn-sm">View Questions</a>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:16px;border-radius:12px;margin-bottom:20px">
  <i class="fas fa-exclamation-circle"></i> <?= htmlspecialchars($error) ?>
</div>
<?php endif; ?>

<!-- CSV Format Info -->
<div class="card mb-20" style="border-color:rgba(0,229,255,0.2)">
  <div class="card-header">
    <div class="card-title-text"><i class="fas fa-info-circle" style="color:var(--cyan)"></i> CSV Format</div>
    <a href="javascript:void(0)" onclick="downloadSample()" class="btn btn-secondary btn-sm">
      <i class="fas fa-download"></i> Download Sample CSV
    </a>
  </div>
  <div style="background:var(--dark);border-radius:10px;padding:14px;font-family:monospace;font-size:12px;color:var(--success);overflow-x:auto">
    question_text, option_a, option_b, option_c, option_d, correct_option, explanation, difficulty<br>
    "What is 15% of 200?", "25", "30", "35", "40", "B", "15/100 × 200 = 30", "easy"<br>
    "Simplify: 3/4 + 1/4", "1/2", "1", "3/2", "2", "B", "3+1/4 = 4/4 = 1", "medium"
    <br><br>
    <span style="color:var(--muted)">Optional Hindi columns (append after difficulty, in order):</span><br>
    question_text_hi, option_a_hi, option_b_hi, option_c_hi, option_d_hi, explanation_hi
  </div>
  <div style="margin-top:12px;display:flex;gap:16px;flex-wrap:wrap">
    <span style="font-size:12px;color:var(--muted)"><i class="fas fa-check" style="color:var(--success)"></i> correct_option: A / B / C / D</span>
    <span style="font-size:12px;color:var(--muted)"><i class="fas fa-check" style="color:var(--success)"></i> difficulty: easy / medium / hard</span>
    <span style="font-size:12px;color:var(--muted)"><i class="fas fa-check" style="color:var(--success)"></i> explanation is optional</span>
  </div>
</div>

<!-- Upload Form -->
<div class="card">
  <form method="POST" enctype="multipart/form-data">
    <div class="form-row">
      <div class="form-group">
        <label class="form-label">Category *</label>
        <?php if ($cat !== ''): ?>
          <input type="text" class="form-input" value="<?= htmlspecialchars($catLabels[$cat]) ?>" disabled>
          <input type="hidden" name="category" id="categorySelect" value="<?= htmlspecialchars($cat) ?>">
        <?php else: ?>
          <select name="category" id="categorySelect" class="form-select" required onchange="filterSets()">
            <?php foreach ($catLabels as $k => $lbl): ?>
            <option value="<?= $k ?>"><?= htmlspecialchars($lbl) ?></option>
            <?php endforeach; ?>
          </select>
        <?php endif; ?>
      </div>
      <div class="form-group">
        <label class="form-label">Target Set *</label>
        <select name="set_id" id="setSelect" class="form-select" required>
          <option value="">Select Set</option>
          <?php foreach ($sets as $set):
            $label = '';
            if ($cat === '') $label .= '[' . strtoupper($set['category']) . '] ';
            if (!empty($set['exam_name'])) $label .= $set['exam_name'] . ' • ';
            $label .= 'Set ' . $set['set_number'];
            if (!empty($set['title'])) $label .= ' — ' . $set['title'];
          ?>
          <option value="<?= $set['id'] ?>" data-category="<?= htmlspecialchars($set['category']) ?>"
            <?= $setId == $set['id'] ? 'selected' : '' ?>>
            <?= htmlspecialchars($label) ?>
          </option>
          <?php endforeach; ?>
        </select>
        <div style="font-size:11px;color:var(--muted);margin-top:4px">
          Questions will be imported into this set.
        </div>
      </div>
    </div>

    <div class="form-group">
      <label class="form-label">CSV File *</label>
      <label for="csvFile" style="display:block;border:2px dashed var(--border2);border-radius:14px;padding:40px;text-align:center;cursor:pointer;transition:all 0.2s" id="dropZone">
        <i class="fas fa-file-csv" style="font-size:36px;color:var(--cyan);margin-bottom:12px;display:block"></i>
        <div style="font-weight:600;color:var(--text);margin-bottom:4px">Click to upload or drag & drop</div>
        <div style="font-size:12px;color:var(--muted)" id="fileName">CSV files only (max 10MB)</div>
      </label>
      <input type="file" name="csv_file" id="csvFile" accept=".csv" required style="display:none"
        onchange="document.getElementById('fileName').textContent = this.files[0].name">
    </div>

    <button type="submit" class="btn btn-primary"><i class="fas fa-upload"></i> Import Questions</button>
  </form>
</div>
</div>

<script>
function filterSets() {
  const el = document.getElementById('categorySelect');
  const cat = el ? (el.value || el.getAttribute('value')) : '';
  const setSel = document.getElementById('setSelect');
  if (!setSel) return;
  Array.from(setSel.options).forEach(opt => {
    if (!opt.value) return;
    const match = !cat || opt.getAttribute('data-category') === cat;
    opt.hidden = !match;
    opt.disabled = !match;
  });
  const cur = setSel.options[setSel.selectedIndex];
  if (cur && cur.hidden) setSel.value = '';
}

function downloadSample() {
  const csv = `question_text,option_a,option_b,option_c,option_d,correct_option,explanation,difficulty
"What is 15% of 200?","25","30","35","40","B","15/100 × 200 = 30","easy"
"Simplify: 3/4 + 1/4","1/2","1","3/2","2","B","3+1/4 = 4/4 = 1","medium"`;
  const blob = new Blob([csv], {type:'text/csv'});
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'sample_questions.csv';
  a.click();
}

const dz = document.getElementById('dropZone');
dz.addEventListener('dragover', e => { e.preventDefault(); dz.style.borderColor = 'var(--cyan)'; dz.style.background = 'rgba(0,229,255,0.04)'; });
dz.addEventListener('dragleave', () => { dz.style.borderColor = 'var(--border2)'; dz.style.background = ''; });
dz.addEventListener('drop', e => {
  e.preventDefault();
  dz.style.borderColor = 'var(--border2)';
  const f = e.dataTransfer.files[0];
  if (f) { document.getElementById('csvFile').files = e.dataTransfer.files; document.getElementById('fileName').textContent = f.name; }
});

// Only meaningful in the "All" view (when category is a <select>)
<?php if ($cat === ''): ?>filterSets();<?php endif; ?>
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
