<?php
$pageTitle = 'Import Questions CSV';
require_once dirname(__DIR__) . '/includes/header.php';

$success = $error = '';
$imported = 0;

$sets = $pdo->query("SELECT id, set_number, category, title, exam_name FROM sets ORDER BY category, set_number")->fetchAll();

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['csv_file'])) {
    try {
        $category = $_POST['category'];
        $set_id   = intval($_POST['set_id']);
        $file     = $_FILES['csv_file']['tmp_name'];

        if (!$file) throw new Exception('No file uploaded');

        $handle = fopen($file, 'r');
        $header = fgetcsv($handle); // Skip header row

        $stmt = $pdo->prepare("
            INSERT INTO questions
              (set_id, category, question_text, option_a, option_b, option_c, option_d,
               correct_option, explanation, difficulty, is_active)
            VALUES (?,?,?,?,?,?,?,?,?,?,1)
        ");

        while (($row = fgetcsv($handle)) !== false) {
            if (count($row) < 6) continue;
            [$question_text, $option_a, $option_b, $option_c, $option_d,
             $correct_option, $explanation, $difficulty] = array_pad($row, 8, '');

            if (empty(trim($question_text))) continue;

            $stmt->execute([
                $set_id, $category,
                trim($question_text),
                trim($option_a), trim($option_b),
                trim($option_c), trim($option_d),
                strtoupper(trim($correct_option)) ?: 'A',
                trim($explanation),
                in_array(strtolower(trim($difficulty)), ['easy','hard']) ? strtolower(trim($difficulty)) : 'medium',
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
    <p class="text-muted">Bulk upload questions from Excel/CSV</p>
  </div>
  <a href="<?= ADMIN_URL ?>/questions/index.php" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back
  </a>
</div>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle fa-lg"></i>
  <div><strong><?= $success ?></strong></div>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:16px;border-radius:12px;margin-bottom:20px">
  <i class="fas fa-exclamation-circle"></i> <?= $error ?>
</div>
<?php endif; ?>

<!-- CSV Format Info -->
<div class="card mb-20" style="border-color:rgba(0,229,255,0.2)">
  <div class="card-header">
    <div class="card-title-text"><i class="fas fa-info-circle" style="color:var(--cyan)"></i> CSV Format</div>
    <a href="#" onclick="downloadSample()" class="btn btn-secondary btn-sm">
      <i class="fas fa-download"></i> Sample CSV
    </a>
  </div>
  <div style="background:var(--dark);border-radius:10px;padding:14px;font-family:monospace;font-size:12px;color:var(--success);overflow-x:auto">
    question_text, option_a, option_b, option_c, option_d, correct_option, explanation, difficulty<br>
    "What is 15% of 200?", "25", "30", "35", "40", "B", "15/100 × 200 = 30", "easy"<br>
    "Simplify: 3/4 + 1/4", "1/2", "1", "3/2", "2", "B", "3+1/4 = 4/4 = 1", "medium"
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
        <select name="category" id="categorySelect" class="form-select" required onchange="filterSets()">
          <option value="mcq">5000 Speed Math MCQ</option>
          <option value="simplification">500 Simplification</option>
          <option value="previous_year">Previous Year</option>
          <option value="daily_practice">Daily Practice</option>
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Target Set *</label>
        <select name="set_id" id="setSelect" class="form-select" required>
          <option value="">Select Set</option>
          <?php foreach ($sets as $set):
            $label = '[' . strtoupper($set['category']) . '] ';
            if (!empty($set['exam_name'])) $label .= $set['exam_name'] . ' • ';
            $label .= 'Set ' . $set['set_number'];
            if (!empty($set['title'])) $label .= ' — ' . $set['title'];
          ?>
          <option value="<?= $set['id'] ?>" data-category="<?= htmlspecialchars($set['category']) ?>">
            <?= htmlspecialchars($label) ?>
          </option>
          <?php endforeach; ?>
        </select>
        <div style="font-size:11px;color:var(--muted);margin-top:4px">
          Sets are filtered by the selected category. <code>previous_year</code> sets show their exam name.
        </div>
      </div>
    </div>

    <!-- File Drop Zone -->
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

    <button type="submit" class="btn btn-primary">
      <i class="fas fa-upload"></i> Import Questions
    </button>
  </form>
</div>
</div>

<script>
// Show only sets that belong to the selected category
function filterSets() {
  const cat = document.getElementById('categorySelect').value;
  const setSel = document.getElementById('setSelect');
  let firstVisible = '';
  Array.from(setSel.options).forEach(opt => {
    if (!opt.value) return; // keep placeholder
    const match = opt.getAttribute('data-category') === cat;
    opt.hidden = !match;
    opt.disabled = !match;
    if (match && !firstVisible) firstVisible = opt.value;
  });
  // Reset selection if current pick doesn't match category
  const cur = setSel.options[setSel.selectedIndex];
  if (!cur || cur.hidden) setSel.value = '';
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

// Drag & Drop styling
const dz = document.getElementById('dropZone');
dz.addEventListener('dragover', e => { e.preventDefault(); dz.style.borderColor = 'var(--cyan)'; dz.style.background = 'rgba(0,229,255,0.04)'; });
dz.addEventListener('dragleave', () => { dz.style.borderColor = 'var(--border2)'; dz.style.background = ''; });
dz.addEventListener('drop', e => {
  e.preventDefault();
  dz.style.borderColor = 'var(--border2)';
  const f = e.dataTransfer.files[0];
  if (f) {
    document.getElementById('csvFile').files = e.dataTransfer.files;
    document.getElementById('fileName').textContent = f.name;
  }
});

// Filter sets on initial load to match the default category
filterSets();
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>