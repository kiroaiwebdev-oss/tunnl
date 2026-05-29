<?php
$pageTitle = 'Add Short';
require_once dirname(__DIR__) . '/includes/header.php';

$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->prepare("
            INSERT INTO shorts
              (title, youtube_url, category, duration, is_active)
            VALUES (?,?,?,?,1)
        ")->execute([
            trim($_POST['title']),
            trim($_POST['youtube_url']),
            $_POST['category'],
            intval($_POST['duration'] ?? 0),
        ]);
        if (isset($_POST['add_another'])) {
            $success = 'Short added! Add another:';
        } else {
            header('Location: ' . ADMIN_URL . '/shorts/index.php?added=1');
            exit;
        }
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
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Add Short</h2>
    <p class="text-muted">Add a YouTube short video</p>
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
      value="<?= htmlspecialchars($_POST['title'] ?? '') ?>"
      placeholder="e.g. 11 ka table ek second mein!">
  </div>

  <div class="form-group">
    <label class="form-label">YouTube URL *</label>
    <input type="url" name="youtube_url" id="ytUrl" class="form-input" required
      value="<?= htmlspecialchars($_POST['youtube_url'] ?? '') ?>"
      placeholder="https://youtube.com/shorts/..."
      oninput="updatePreview(this.value)">
    <div style="font-size:11px;color:var(--muted);margin-top:4px">
      Paste YouTube Shorts or regular video URL
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Category *</label>
      <select name="category" class="form-select" required>
        <option value="trick">⚡ Math Trick</option>
        <option value="mcq">📝 MCQ Explanation</option>
        <option value="shortcut">🚀 Shortcut</option>
        <option value="motivation">🔥 Motivation</option>
        <option value="general">📌 General</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Duration (seconds)</label>
      <input type="number" name="duration" class="form-input"
        value="<?= $_POST['duration'] ?? 60 ?>" min="0" max="600">
    </div>
  </div>

  <!-- Preview -->
  <div id="previewBox" style="display:none;background:var(--dark);border:1px solid var(--border);
    border-radius:12px;overflow:hidden;margin-top:8px">
    <img id="thumbPreview" src="" alt="Preview"
      style="width:100%;max-height:200px;object-fit:cover">
    <div style="padding:10px;font-size:12px;color:var(--muted);display:flex;align-items:center;gap:6px">
      <i class="fab fa-youtube" style="color:#EF4444"></i>
      <span id="thumbVideoId"></span>
    </div>
  </div>
</div>

<div style="display:flex;gap:12px">
  <button type="submit" name="save" class="btn btn-primary">
    <i class="fas fa-save"></i> Save Short
  </button>
  <button type="submit" name="add_another" class="btn btn-secondary">
    <i class="fas fa-plus"></i> Save & Add Another
  </button>
  <a href="<?= ADMIN_URL ?>/shorts/index.php" class="btn btn-secondary">
    <i class="fas fa-times"></i>
  </a>
</div>
</form>
</div>

<script>
function updatePreview(url) {
  const m = url.match(/(?:v=|\/shorts\/|youtu\.be\/)([a-zA-Z0-9_-]{11})/);
  if (m) {
    const vid = m[1];
    document.getElementById('thumbPreview').src = `https://img.youtube.com/vi/${vid}/mqdefault.jpg`;
    document.getElementById('thumbVideoId').textContent = 'Video ID: ' + vid;
    document.getElementById('previewBox').style.display = 'block';
  } else {
    document.getElementById('previewBox').style.display = 'none';
  }
}
// Init if editing
const v = document.getElementById('ytUrl').value;
if (v) updatePreview(v);
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>