<?php
$pageTitle = 'Edit Daily Dose';
require_once dirname(__DIR__) . '/includes/header.php';

$id = intval($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/daily_dose/index.php'); exit; }

$dose = $pdo->prepare("SELECT * FROM daily_dose WHERE id = ?");
$dose->execute([$id]);
$dose = $dose->fetch();
if (!$dose) { header('Location: ' . ADMIN_URL . '/daily_dose/index.php'); exit; }

$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->prepare("
            UPDATE daily_dose SET
              dose_date=?, title=?, content=?,
              image_url=?, category=?, is_active=?
            WHERE id=?
        ")->execute([
            $_POST['dose_date'],
            trim($_POST['title']),
            trim($_POST['content']),
            trim($_POST['image_url'] ?? ''),
            trim($_POST['category']  ?? 'General'),
            isset($_POST['is_active']) ? 1 : 0,
            $id
        ]);
        $success = 'Dose updated!';
        $dose = $pdo->prepare("SELECT * FROM daily_dose WHERE id = ?");
        $dose->execute([$id]);
        $dose = $dose->fetch();
    } catch (Exception $e) { $error = $e->getMessage(); }
}

$categories = ['General','Percentage','Profit Loss','Speed Time','Simplification',
               'Number System','Algebra','Geometry','Tricks'];
?>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $success ?>
</div>
<?php endif; ?>

<div style="max-width:700px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Edit Daily Dose</h2>
    <p class="text-muted"><?= date('d M Y', strtotime($dose['dose_date'])) ?></p>
  </div>
  <a href="<?= ADMIN_URL ?>/daily_dose/index.php" class="btn btn-secondary"><i class="fas fa-arrow-left"></i> Back</a>
</div>

<form method="POST">
<div class="card mb-16">
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Date *</label>
      <input type="date" name="dose_date" class="form-input" value="<?= $dose['dose_date'] ?>" required>
    </div>
    <div class="form-group">
      <label class="form-label">Category</label>
      <select name="category" class="form-select">
        <?php foreach ($categories as $c): ?>
        <option value="<?= $c ?>" <?= $dose['category']===$c?'selected':'' ?>><?= $c ?></option>
        <?php endforeach; ?>
      </select>
    </div>
  </div>
  <div class="form-group">
    <label class="form-label">Title *</label>
    <input type="text" name="title" class="form-input" required value="<?= htmlspecialchars($dose['title']) ?>">
  </div>
  <div class="form-group">
    <label class="form-label">Content *</label>
    <textarea name="content" class="form-textarea" rows="6" required><?= htmlspecialchars($dose['content']) ?></textarea>
  </div>
  <div class="form-group">
    <label class="form-label">Image URL</label>
    <input type="url" name="image_url" class="form-input" value="<?= htmlspecialchars($dose['image_url']) ?>">
  </div>
  <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
    <input type="checkbox" name="is_active" style="accent-color:var(--cyan);width:16px;height:16px"
      <?= $dose['is_active']?'checked':'' ?>>
    <span style="font-size:13px;color:var(--text2)">Active (visible in app)</span>
  </label>
</div>
<div style="display:flex;gap:12px">
  <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Update</button>
  <a href="<?= ADMIN_URL ?>/daily_dose/index.php" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
</div>
</form>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>