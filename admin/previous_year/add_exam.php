<?php
$pageTitle = 'Add PY Exam';
require_once dirname(__DIR__) . '/includes/header.php';

$success = $error = '';
$prefill = htmlspecialchars($_GET['exam_name'] ?? '');

$examNames = [
    'SSC CGL'    => ['icon' => 'school',          'cat' => 'SSC'],
    'SSC CHSL'   => ['icon' => 'school',          'cat' => 'SSC'],
    'SSC MTS'    => ['icon' => 'school',          'cat' => 'SSC'],
    'SSC CPO'    => ['icon' => 'security',        'cat' => 'SSC'],
    'SSC GD'     => ['icon' => 'security',        'cat' => 'SSC'],
    'IBPS PO'    => ['icon' => 'account_balance', 'cat' => 'BANK'],
    'IBPS Clerk' => ['icon' => 'account_balance', 'cat' => 'BANK'],
    'SBI PO'     => ['icon' => 'account_balance', 'cat' => 'BANK'],
    'SBI Clerk'  => ['icon' => 'account_balance', 'cat' => 'BANK'],
    'RRB NTPC'   => ['icon' => 'train',           'cat' => 'RAILWAY'],
    'RRB Group D'=> ['icon' => 'train',           'cat' => 'RAILWAY'],
    'CDS'        => ['icon' => 'security',        'cat' => 'DEFENCE'],
    'NDA'        => ['icon' => 'security',        'cat' => 'DEFENCE'],
    'AIRFORCE'   => ['icon' => 'flight',          'cat' => 'DEFENCE'],
    'UPSC'       => ['icon' => 'gavel',           'cat' => 'OTHER'],
];

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
            INSERT INTO py_exams
              (exam_name, exam_full_name, exam_category, icon,
               exam_year, exam_date, total_sets, total_questions,
               difficulty, is_premium, is_active)
            VALUES (?,?,?,?,?,?,?,?,?,?,1)
        ")->execute([
            trim($_POST['exam_name']),
            trim($_POST['exam_full_name'] ?? ''),
            $_POST['exam_category']  ?? 'OTHER',
            $_POST['icon']           ?? 'school',
            intval($_POST['exam_year']),
            !empty($_POST['exam_date']) ? $_POST['exam_date'] : null,
            intval($_POST['total_sets']     ?? 1),
            intval($_POST['total_questions']?? 25),
            $_POST['difficulty']     ?? 'Medium',
            isset($_POST['is_premium']) ? 1 : 0,
        ]);
        header('Location: ' . ADMIN_URL . '/previous_year/index.php?added=1');
        exit;
    } catch (Exception $e) {
        $error = $e->getMessage();
    }
}
?>

<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;
  padding:12px 16px;border-radius:12px;margin-bottom:20px">
  <?= $error ?>
</div>
<?php endif; ?>

<div style="max-width:700px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Add PY Exam</h2>
    <p class="text-muted">Add a previous year paper exam (with icon &amp; category)</p>
  </div>
  <a href="<?= ADMIN_URL ?>/previous_year/index.php" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back
  </a>
</div>

<form method="POST" id="examForm">
<div class="card mb-16">

  <!-- Quick presets -->
  <div class="form-group">
    <label class="form-label">Quick Pick</label>
    <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:8px">
      <?php foreach ($examNames as $en => $meta): ?>
      <button type="button"
        onclick="applyPreset('<?= $en ?>','<?= $meta['cat'] ?>','<?= $meta['icon'] ?>')"
        style="padding:6px 12px;border-radius:8px;border:1px solid var(--border);
          background:var(--dark);color:var(--muted);font-size:12px;cursor:pointer;
          transition:all 0.2s;font-family:'Inter',sans-serif"
        onmouseover="this.style.borderColor='var(--cyan)';this.style.color='var(--cyan)'"
        onmouseout="this.style.borderColor='var(--border)';this.style.color='var(--muted)'">
        <?= $en ?>
      </button>
      <?php endforeach; ?>
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Short Name *</label>
      <input type="text" name="exam_name" id="examNameInput" class="form-input" required
        value="<?= $prefill ?>" placeholder="e.g. SSC CGL">
    </div>
    <div class="form-group">
      <label class="form-label">Full Name</label>
      <input type="text" name="exam_full_name" class="form-input"
        placeholder="e.g. SSC Combined Graduate Level">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Category *</label>
      <select name="exam_category" id="catSelect" class="form-select" required>
        <option value="SSC">SSC</option>
        <option value="RAILWAY">Railway</option>
        <option value="BANK">Bank</option>
        <option value="DEFENCE">Defence / Police</option>
        <option value="OTHER">Other</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Icon *</label>
      <select name="icon" id="iconSelect" class="form-select" required>
        <?php foreach ($icons as $k => $label): ?>
        <option value="<?= $k ?>"><?= $label ?> (<?= $k ?>)</option>
        <?php endforeach; ?>
      </select>
      <div style="font-size:11px;color:var(--muted);margin-top:4px">
        Icon name from <a href="https://fonts.google.com/icons" target="_blank" style="color:var(--cyan)">Material Icons</a>
      </div>
    </div>
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
        <option value="Easy">Easy</option>
        <option value="Medium" selected>Medium</option>
        <option value="Hard">Hard</option>
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
function applyPreset(name, cat, icon) {
  document.getElementById('examNameInput').value = name;
  document.getElementById('catSelect').value     = cat;
  document.getElementById('iconSelect').value    = icon;
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
