<?php
$pageTitle = 'Edit Trick';
require_once dirname(__DIR__) . '/includes/header.php';

$id = intval($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/tricks/index.php'); exit; }

$trick = $pdo->prepare("SELECT * FROM tricks WHERE id = ?");
$trick->execute([$id]);
$trick = $trick->fetch();
if (!$trick) { header('Location: ' . ADMIN_URL . '/tricks/index.php'); exit; }

$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->prepare("
            UPDATE tricks SET
              chapter_number=?, title=?, subtitle=?, category=?, difficulty=?,
              has_video=?, video_url=?, video_duration=?,
              has_article=?, article_content=?, read_duration=?,
              is_new=?, is_active=?
            WHERE id=?
        ")->execute([
            intval($_POST['chapter_number']),
            trim($_POST['title']),
            trim($_POST['subtitle'] ?? ''),
            $_POST['category'],
            $_POST['difficulty'],
            isset($_POST['has_video'])   ? 1 : 0,
            trim($_POST['video_url']     ?? ''),
            intval($_POST['video_duration'] ?? 0),
            isset($_POST['has_article']) ? 1 : 0,
            trim($_POST['article_content'] ?? ''),
            intval($_POST['read_duration']  ?? 5),
            isset($_POST['is_new'])      ? 1 : 0,
            isset($_POST['is_active'])   ? 1 : 0,
            $id
        ]);
        $success = 'Trick updated!';
        $trick = $pdo->prepare("SELECT * FROM tricks WHERE id = ?");
        $trick->execute([$id]);
        $trick = $trick->fetch();
    } catch (Exception $e) { $error = $e->getMessage(); }
}
?>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $success ?>
</div>
<?php endif; ?>

<div style="max-width:800px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Edit Trick</h2>
    <p class="text-muted">Chapter #<?= $trick['chapter_number'] ?></p>
  </div>
  <a href="<?= ADMIN_URL ?>/tricks/index.php" class="btn btn-secondary"><i class="fas fa-arrow-left"></i> Back</a>
</div>

<form method="POST">
<div class="card mb-16">
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Chapter Number *</label>
      <input type="number" name="chapter_number" class="form-input"
        value="<?= $trick['chapter_number'] ?>" required min="1">
    </div>
    <div class="form-group">
      <label class="form-label">Category *</label>
      <select name="category" class="form-select" required>
        <?php foreach (['MULTIPLICATION','DIVISION','SQUARES','FRACTIONS','SHORTCUTS'] as $c): ?>
        <option value="<?= $c ?>" <?= $trick['category']===$c?'selected':'' ?>><?= ucfirst(strtolower($c)) ?></option>
        <?php endforeach; ?>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Difficulty *</label>
      <select name="difficulty" class="form-select" required>
        <?php foreach (['Beginner','Intermediate','Advanced'] as $d): ?>
        <option value="<?= $d ?>" <?= $trick['difficulty']===$d?'selected':'' ?>><?= $d ?></option>
        <?php endforeach; ?>
      </select>
    </div>
  </div>
  <div class="form-group">
    <label class="form-label">Title *</label>
    <input type="text" name="title" class="form-input" required value="<?= htmlspecialchars($trick['title']) ?>">
  </div>
  <div class="form-group">
    <label class="form-label">Subtitle</label>
    <input type="text" name="subtitle" class="form-input" value="<?= htmlspecialchars($trick['subtitle']) ?>">
  </div>
  <div style="display:flex;gap:20px">
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="is_new" style="accent-color:var(--success);width:16px;height:16px" <?= $trick['is_new']?'checked':'' ?>>
      <span style="font-size:13px;color:var(--text2)">🆕 Mark as NEW</span>
    </label>
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="is_active" style="accent-color:var(--cyan);width:16px;height:16px" <?= $trick['is_active']?'checked':'' ?>>
      <span style="font-size:13px;color:var(--text2)">✅ Active (visible in app)</span>
    </label>
  </div>
</div>

<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text"><i class="fab fa-youtube" style="color:#EF4444"></i> Video</div>
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="has_video" id="hasVideo"
        style="accent-color:var(--cyan);width:16px;height:16px" <?= $trick['has_video']?'checked':'' ?>
        onchange="document.getElementById('videoFields').style.display=this.checked?'block':'none'">
      <span style="font-size:13px;color:var(--text2)">Has Video</span>
    </label>
  </div>
  <div id="videoFields" style="display:<?= $trick['has_video']?'block':'none' ?>">
    <div class="form-row">
      <div class="form-group" style="flex:2">
        <label class="form-label">YouTube URL</label>
        <input type="url" name="video_url" class="form-input" value="<?= htmlspecialchars($trick['video_url']) ?>">
      </div>
      <div class="form-group">
        <label class="form-label">Duration (min)</label>
        <input type="number" name="video_duration" class="form-input" value="<?= $trick['video_duration'] ?>">
      </div>
    </div>
  </div>
</div>

<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text"><i class="fas fa-file-alt" style="color:var(--cyan)"></i> Article</div>
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="has_article" id="hasArticle"
        style="accent-color:var(--cyan);width:16px;height:16px" <?= $trick['has_article']?'checked':'' ?>
        onchange="document.getElementById('articleFields').style.display=this.checked?'block':'none'">
      <span style="font-size:13px;color:var(--text2)">Has Article</span>
    </label>
  </div>
  <div id="articleFields" style="display:<?= $trick['has_article']?'block':'none' ?>">
    <div class="form-group">
      <label class="form-label">Read Duration (min)</label>
      <input type="number" name="read_duration" class="form-input" value="<?= $trick['read_duration'] ?>" style="width:120px">
    </div>
    <div class="form-group">
      <label class="form-label">Article Content</label>
      <textarea name="article_content" class="form-textarea" rows="10"><?= htmlspecialchars($trick['article_content']) ?></textarea>
    </div>
  </div>
</div>

<div style="display:flex;gap:12px">
  <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Update Trick</button>
  <a href="<?= ADMIN_URL ?>/tricks/index.php" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
</div>
</form>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>