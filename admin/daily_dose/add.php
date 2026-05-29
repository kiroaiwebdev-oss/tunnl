<?php
$pageTitle = 'Add Daily Dose';
require_once dirname(__DIR__) . '/includes/header.php';

$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->prepare("
            INSERT INTO daily_dose (dose_date, title, content, image_url, category, is_active)
            VALUES (?,?,?,?,?,1)
            ON DUPLICATE KEY UPDATE
              title=VALUES(title), content=VALUES(content),
              image_url=VALUES(image_url), category=VALUES(category)
        ")->execute([
            $_POST['dose_date'],
            trim($_POST['title']),
            trim($_POST['content']),
            trim($_POST['image_url'] ?? ''),
            trim($_POST['category']  ?? 'General'),
        ]);
        header('Location: ' . ADMIN_URL . '/daily_dose/index.php?added=1');
        exit;
    } catch (Exception $e) { $error = $e->getMessage(); }
}

$categories = ['General','Percentage','Profit Loss','Speed Time','Simplification',
               'Number System','Algebra','Geometry','Tricks'];
?>

<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:20px">
  <?= $error ?>
</div>
<?php endif; ?>

<div style="max-width:700px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Add Daily Dose</h2>
    <p class="text-muted">Daily math tip for dashboard card</p>
  </div>
  <a href="<?= ADMIN_URL ?>/daily_dose/index.php" class="btn btn-secondary"><i class="fas fa-arrow-left"></i> Back</a>
</div>

<form method="POST">
<div class="card mb-16">
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Date *</label>
      <input type="date" name="dose_date" class="form-input"
        value="<?= $_POST['dose_date'] ?? date('Y-m-d') ?>" required>
    </div>
    <div class="form-group">
      <label class="form-label">Category</label>
      <select name="category" class="form-select">
        <?php foreach ($categories as $c): ?>
        <option value="<?= $c ?>" <?= ($_POST['category']??'')===$c?'selected':'' ?>><?= $c ?></option>
        <?php endforeach; ?>
      </select>
    </div>
  </div>

  <div class="form-group">
    <label class="form-label">Title *</label>
    <input type="text" name="title" class="form-input" required
      value="<?= htmlspecialchars($_POST['title'] ?? '') ?>"
      placeholder="e.g. Quick Percentage Trick">
  </div>

  <div class="form-group">
    <label class="form-label">Content *</label>
    <textarea name="content" class="form-textarea" rows="6" required
      placeholder="Write today's math tip here...&#10;&#10;Example:&#10;To find 10% of any number, just move the decimal one place left.&#10;So 10% of 250 = 25"><?= htmlspecialchars($_POST['content'] ?? '') ?></textarea>
  </div>

  <div class="form-group">
    <label class="form-label">Image URL (Optional)</label>
    <input type="url" name="image_url" class="form-input"
      value="<?= htmlspecialchars($_POST['image_url'] ?? '') ?>"
      placeholder="https://...image.png">
  </div>

  <!-- Preview -->
  <div style="background:linear-gradient(135deg,#0D1F2D,#0A1520);border:1px solid rgba(0,229,255,0.2);border-radius:14px;padding:16px;margin-top:8px">
    <div style="font-size:11px;color:var(--muted);margin-bottom:10px;text-transform:uppercase;letter-spacing:1px">
      📱 App Preview:
    </div>
    <div style="font-size:10px;color:var(--cyan);letter-spacing:2px;font-weight:700;margin-bottom:4px">
      DAILY DOSE
    </div>
    <div style="font-weight:700;color:var(--text);margin-bottom:4px" id="previewTitle">
      <?= htmlspecialchars($_POST['title'] ?? 'Title will appear here') ?>
    </div>
    <div style="font-size:12px;color:var(--muted);line-height:1.5" id="previewContent">
      <?= nl2br(htmlspecialchars(mb_substr($_POST['content'] ?? 'Content will appear here...', 0, 100))) ?>
    </div>
  </div>
</div>

<div style="display:flex;gap:12px">
  <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Save Dose</button>
  <a href="<?= ADMIN_URL ?>/daily_dose/index.php" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
</div>
</form>
</div>

<script>
document.querySelector('[name="title"]').addEventListener('input', function() {
  document.getElementById('previewTitle').textContent = this.value || 'Title will appear here';
});
document.querySelector('[name="content"]').addEventListener('input', function() {
  document.getElementById('previewContent').textContent = this.value.substring(0,100) || 'Content...';
});
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>