<?php
$pageTitle = 'Edit Short';
require_once dirname(__DIR__) . '/includes/header.php';

$id = intval($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/shorts/index.php'); exit; }

$short = $pdo->prepare("SELECT * FROM shorts WHERE id=?");
$short->execute([$id]);
$short = $short->fetch();
if (!$short) { header('Location: ' . ADMIN_URL . '/shorts/index.php'); exit; }

$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->prepare("
            UPDATE shorts SET
              title=?, youtube_url=?, category=?, duration=?, is_active=?
            WHERE id=?
        ")->execute([
            trim($_POST['title']),
            trim($_POST['youtube_url']),
            $_POST['category'],
            intval($_POST['duration'] ?? 0),
            isset($_POST['is_active']) ? 1 : 0,
            $id
        ]);
        $success = 'Short updated!';
        $short = $pdo->prepare("SELECT * FROM shorts WHERE id=?");
        $short->execute([$id]);
        $short = $short->fetch();
    } catch (Exception $e) { $error = $e->getMessage(); }
}
?>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;
  padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $success ?>
</div>
<?php endif; ?>

<div style="max-width:600px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Edit Short</h2>
  </div>
  <a href="<?= ADMIN_URL ?>/shorts/index.php" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back
  </a>
</div>

<form method="POST">
<div class="card mb-16">
  <div class="form-group">
    <label class="form-label">Title *</label>
    <input type="text" name="title" class="form-input" required
      value="<?= htmlspecialchars($short['title']) ?>">
  </div>
  <div class="form-group">
    <label class="form-label">YouTube URL *</label>
    <input type="url" name="youtube_url" id="ytUrl" class="form-input" required
      value="<?= htmlspecialchars($short['youtube_url']) ?>"
      oninput="updatePreview(this.value)">
  </div>
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Category *</label>
      <select name="category" class="form-select" required>
        <?php foreach (['trick'=>'⚡ Math Trick','mcq'=>'📝 MCQ','shortcut'=>'🚀 Shortcut','motivation'=>'🔥 Motivation','general'=>'📌 General'] as $v=>$l): ?>
        <option value="<?= $v ?>" <?= $short['category']===$v?'selected':'' ?>><?= $l ?></option>
        <?php endforeach; ?>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Duration (sec)</label>
      <input type="number" name="duration" class="form-input"
        value="<?= $short['duration'] ?>" min="0">
    </div>
  </div>
  <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
    <input type="checkbox" name="is_active" style="accent-color:var(--cyan);width:16px;height:16px"
      <?= $short['is_active']?'checked':'' ?>>
    <span style="font-size:13px;color:var(--text2)">Active (visible in app)</span>
  </label>

  <!-- Preview -->
  <div id="previewBox" style="margin-top:14px">
    <?php
    preg_match('/(?:v=|\/shorts\/|youtu\.be\/)([a-zA-Z0-9_-]{11})/', $short['youtube_url'], $m);
    $vid = $m[1] ?? '';
    if ($vid):
    ?>
    <img src="https://img.youtube.com/vi/<?= $vid ?>/mqdefault.jpg" alt="Thumb"
      id="thumbPreview" style="width:100%;border-radius:10px;max-height:180px;object-fit:cover">
    <?php endif; ?>
  </div>
</div>
<div style="display:flex;gap:12px">
  <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Update</button>
  <a href="<?= ADMIN_URL ?>/shorts/index.php" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
</div>
</form>
</div>

<script>
function updatePreview(url) {
  const m = url.match(/(?:v=|\/shorts\/|youtu\.be\/)([a-zA-Z0-9_-]{11})/);
  const box = document.getElementById('previewBox');
  if (m) {
    box.innerHTML = `<img src="https://img.youtube.com/vi/${m[1]}/mqdefault.jpg"
      style="width:100%;border-radius:10px;max-height:180px;object-fit:cover">`;
  }
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>