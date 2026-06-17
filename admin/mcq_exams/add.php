<?php
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';

$error = '';
$icons = [
    'school'           => 'School / SSC',
    'train'            => 'Railway',
    'account_balance'  => 'Bank',
    'security'         => 'Defence / Police',
    'flight'           => 'Airforce',
    'gavel'            => 'UPSC / Law',
    'science'          => 'Science',
    'workspace_premium'=> 'Premium',
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $name = trim($_POST['exam_name'] ?? '');
    if ($name === '') {
        $error = 'Exam name is required.';
    } else {
        // ── Optional custom icon image upload ──
        $iconUrl = trim($_POST['icon_url_manual'] ?? '');
        if (!empty($_FILES['icon_image']['name'])) {
            $ext     = strtolower(pathinfo($_FILES['icon_image']['name'], PATHINFO_EXTENSION));
            $allowed = ['jpg', 'jpeg', 'png', 'webp'];
            if (!in_array($ext, $allowed)) {
                $error = 'Icon must be a JPG, PNG, or WEBP image.';
            } elseif ($_FILES['icon_image']['size'] > 2 * 1024 * 1024) {
                $error = 'Maximum icon size is 2MB.';
            } else {
                $uploadDir = dirname(__DIR__) . '/uploads/exam_icons/';
                if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);
                $filename = 'mcq_' . time() . '_' . mt_rand(100, 999) . '.' . $ext;
                if (move_uploaded_file($_FILES['icon_image']['tmp_name'], $uploadDir . $filename)) {
                    $iconUrl = 'https://' . $_SERVER['HTTP_HOST'] . '/uploads/exam_icons/' . $filename;
                }
            }
        }
    }

    if ($name !== '' && $error === '') {
        try {
            $pdo->prepare("
                INSERT INTO mcq_exams
                  (exam_name, exam_full_name, exam_category, icon, icon_url, difficulty, is_premium, is_active, sort_order)
                VALUES (?,?,?,?,?,?,?,?,?)
            ")->execute([
                $name,
                trim($_POST['exam_full_name'] ?? ''),
                $_POST['exam_category'] ?? 'OTHER',
                $_POST['icon'] ?? 'school',
                $iconUrl,
                $_POST['difficulty'] ?? 'Medium',
                isset($_POST['is_premium']) ? 1 : 0,
                isset($_POST['is_active']) ? 1 : 0,
                (int)($_POST['sort_order'] ?? 1),
            ]);
            header('Location: ' . ADMIN_URL . '/mcq_exams/index.php?msg=added');
            exit;
        } catch (PDOException $e) {
            $error = ($e->getCode() === '23000')
                ? 'An exam with this name already exists.'
                : $e->getMessage();
        }
    }
}

$pageTitle = 'Add MCQ Exam';
require_once dirname(__DIR__) . '/includes/header.php';
?>

<div style="max-width:640px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Add MCQ Exam</h2>
    <p class="text-muted">Create an exam group for 5000 Speed MCQs</p>
  </div>
  <a href="<?= ADMIN_URL ?>/mcq_exams/index.php" class="btn btn-secondary"><i class="fas fa-arrow-left"></i> Back</a>
</div>

<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:20px">
  ⚠️ <?= htmlspecialchars($error) ?>
</div>
<?php endif; ?>

<form method="POST" enctype="multipart/form-data">
<div class="card">
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Exam Name *</label>
      <input type="text" name="exam_name" class="form-input" required placeholder="e.g. SSC"
             value="<?= htmlspecialchars($_POST['exam_name'] ?? '') ?>">
      <p style="font-size:11px;color:var(--muted);margin-top:4px">Sets with this exact Exam Name appear under this exam.</p>
    </div>
    <div class="form-group">
      <label class="form-label">Full Name</label>
      <input type="text" name="exam_full_name" class="form-input" placeholder="e.g. Staff Selection Commission"
             value="<?= htmlspecialchars($_POST['exam_full_name'] ?? '') ?>">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Category *</label>
      <select name="exam_category" class="form-select" required>
        <option value="SSC">SSC</option>
        <option value="RAILWAY">Railway</option>
        <option value="BANK">Bank</option>
        <option value="DEFENCE">Defence / Police</option>
        <option value="OTHER">Other</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Icon *</label>
      <select name="icon" class="form-select" required>
        <?php foreach ($icons as $k => $label): ?>
        <option value="<?= $k ?>"><?= $label ?></option>
        <?php endforeach; ?>
      </select>
      <p style="font-size:11px;color:var(--muted);margin-top:4px">Fallback icon (used if no custom image is uploaded below).</p>
    </div>
  </div>

  <!-- Custom Icon Image (shows in the app instead of the built-in icon) -->
  <div class="form-group">
    <label class="form-label">Custom Exam Icon (image)</label>
    <input type="file" name="icon_image" class="form-input" accept=".jpg,.jpeg,.png,.webp"
           style="padding:8px" onchange="previewIcon(this)">
    <p style="font-size:11px;color:var(--muted);margin-top:4px">
      JPG/PNG/WEBP · Max 2MB · Recommended square (e.g. 256×256). Shown in the app for this exam.
    </p>
    <div id="iconPreview" style="margin-top:10px"></div>
  </div>
  <div class="form-group">
    <label class="form-label">Or Paste Icon URL</label>
    <input type="url" name="icon_url_manual" class="form-input"
           placeholder="https://example.com/icon.png"
           value="<?= htmlspecialchars($_POST['icon_url_manual'] ?? '') ?>">
    <p style="font-size:11px;color:var(--muted);margin-top:4px">Use the upload above or a direct URL. Upload takes priority if both given.</p>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Difficulty</label>
      <select name="difficulty" class="form-select">
        <option value="Easy">Easy</option>
        <option value="Medium" selected>Medium</option>
        <option value="Hard">Hard</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Sort Order</label>
      <input type="number" name="sort_order" class="form-input" value="1" min="1">
    </div>
  </div>

  <div style="display:flex;gap:24px;margin-bottom:16px">
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="is_active" checked style="accent-color:var(--cyan);width:16px;height:16px">
      <span style="font-size:13px;color:var(--text2)">Active (visible in app)</span>
    </label>
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="is_premium" style="accent-color:var(--warning);width:16px;height:16px">
      <span style="font-size:13px;color:var(--text2)"><i class="fas fa-crown" style="color:var(--warning)"></i> Premium Only</span>
    </label>
  </div>

  <div style="display:flex;gap:12px">
    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Add Exam</button>
    <a href="<?= ADMIN_URL ?>/mcq_exams/index.php" class="btn btn-secondary">Cancel</a>
  </div>
</div>
</form>
</div>

<script>
function previewIcon(input) {
  const p = document.getElementById('iconPreview');
  if (input.files && input.files[0]) {
    const r = new FileReader();
    r.onload = e => {
      p.innerHTML = '<img src="' + e.target.result + '" style="height:64px;width:64px;object-fit:cover;border-radius:12px;border:2px solid var(--cyan)">';
    };
    r.readAsDataURL(input.files[0]);
  }
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
