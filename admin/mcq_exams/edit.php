<?php
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';

$id = (int)($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/mcq_exams/index.php'); exit; }

$stmt = $pdo->prepare("SELECT * FROM mcq_exams WHERE id = ?");
$stmt->execute([$id]);
$e = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$e) { header('Location: ' . ADMIN_URL . '/mcq_exams/index.php'); exit; }

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
        try {
            $pdo->prepare("
                UPDATE mcq_exams SET
                  exam_name=?, exam_full_name=?, exam_category=?, icon=?,
                  difficulty=?, is_premium=?, is_active=?, sort_order=?
                WHERE id=?
            ")->execute([
                $name,
                trim($_POST['exam_full_name'] ?? ''),
                $_POST['exam_category'] ?? 'OTHER',
                $_POST['icon'] ?? 'school',
                $_POST['difficulty'] ?? 'Medium',
                isset($_POST['is_premium']) ? 1 : 0,
                isset($_POST['is_active']) ? 1 : 0,
                (int)($_POST['sort_order'] ?? 1),
                $id,
            ]);
            header('Location: ' . ADMIN_URL . '/mcq_exams/index.php?msg=updated');
            exit;
        } catch (PDOException $ex) {
            $error = ($ex->getCode() === '23000')
                ? 'An exam with this name already exists.'
                : $ex->getMessage();
        }
        $e = array_merge($e, [
            'exam_name' => $name,
            'exam_full_name' => trim($_POST['exam_full_name'] ?? ''),
            'exam_category' => $_POST['exam_category'] ?? 'OTHER',
            'icon' => $_POST['icon'] ?? 'school',
            'difficulty' => $_POST['difficulty'] ?? 'Medium',
            'is_premium' => isset($_POST['is_premium']) ? 1 : 0,
            'is_active' => isset($_POST['is_active']) ? 1 : 0,
            'sort_order' => (int)($_POST['sort_order'] ?? 1),
        ]);
    }
}

$pageTitle = 'Edit MCQ Exam';
require_once dirname(__DIR__) . '/includes/header.php';
?>

<div style="max-width:640px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Edit MCQ Exam</h2>
    <p class="text-muted">#<?= $id ?> — <?= htmlspecialchars($e['exam_name']) ?></p>
  </div>
  <a href="<?= ADMIN_URL ?>/mcq_exams/index.php" class="btn btn-secondary"><i class="fas fa-arrow-left"></i> Back</a>
</div>

<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:20px">
  ⚠️ <?= htmlspecialchars($error) ?>
</div>
<?php endif; ?>

<form method="POST">
<div class="card">
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Exam Name *</label>
      <input type="text" name="exam_name" class="form-input" required value="<?= htmlspecialchars($e['exam_name']) ?>">
    </div>
    <div class="form-group">
      <label class="form-label">Full Name</label>
      <input type="text" name="exam_full_name" class="form-input" value="<?= htmlspecialchars($e['exam_full_name']) ?>">
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Category *</label>
      <select name="exam_category" class="form-select" required>
        <?php foreach (['SSC'=>'SSC','RAILWAY'=>'Railway','BANK'=>'Bank','DEFENCE'=>'Defence / Police','OTHER'=>'Other'] as $val=>$label): ?>
        <option value="<?= $val ?>" <?= $e['exam_category']===$val?'selected':'' ?>><?= $label ?></option>
        <?php endforeach; ?>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Icon *</label>
      <select name="icon" class="form-select" required>
        <?php foreach ($icons as $k => $label): ?>
        <option value="<?= $k ?>" <?= $e['icon']===$k?'selected':'' ?>><?= $label ?></option>
        <?php endforeach; ?>
      </select>
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Difficulty</label>
      <select name="difficulty" class="form-select">
        <?php foreach (['Easy','Medium','Hard'] as $d): ?>
        <option value="<?= $d ?>" <?= $e['difficulty']===$d?'selected':'' ?>><?= $d ?></option>
        <?php endforeach; ?>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Sort Order</label>
      <input type="number" name="sort_order" class="form-input" value="<?= (int)$e['sort_order'] ?>" min="1">
    </div>
  </div>

  <div style="display:flex;gap:24px;margin-bottom:16px">
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="is_active" <?= (int)$e['is_active']===1?'checked':'' ?> style="accent-color:var(--cyan);width:16px;height:16px">
      <span style="font-size:13px;color:var(--text2)">Active (visible in app)</span>
    </label>
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="is_premium" <?= (int)$e['is_premium']===1?'checked':'' ?> style="accent-color:var(--warning);width:16px;height:16px">
      <span style="font-size:13px;color:var(--text2)"><i class="fas fa-crown" style="color:var(--warning)"></i> Premium Only</span>
    </label>
  </div>

  <div style="display:flex;gap:12px">
    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Update Exam</button>
    <a href="<?= ADMIN_URL ?>/mcq_exams/index.php" class="btn btn-secondary">Cancel</a>
  </div>
</div>
</form>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
