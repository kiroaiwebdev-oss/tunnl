<?php
$pageTitle = 'Add Trick';
require_once dirname(__DIR__) . '/includes/header.php';

$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo->prepare("
            INSERT INTO tricks
              (chapter_number, title, subtitle, category, difficulty,
               has_video, video_url, video_duration,
               has_article, article_content, read_duration,
               is_new, is_active)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,1)
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
        ]);
        header('Location: ' . ADMIN_URL . '/tricks/index.php?added=1');
        exit;
    } catch (Exception $e) { $error = $e->getMessage(); }
}
?>

<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:20px">
  <?= $error ?>
</div>
<?php endif; ?>

<div style="max-width:800px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Add New Trick</h2>
    <p class="text-muted">Create a tunnel trick with video or article</p>
  </div>
  <a href="<?= ADMIN_URL ?>/tricks/index.php" class="btn btn-secondary"><i class="fas fa-arrow-left"></i> Back</a>
</div>

<form method="POST">

<!-- Basic Info -->
<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text"><i class="fas fa-info-circle" style="color:var(--cyan)"></i> Basic Info</div>
  </div>
  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Chapter Number *</label>
      <input type="number" name="chapter_number" class="form-input" required min="1"
        value="<?= $_POST['chapter_number'] ?? '' ?>" placeholder="1">
    </div>
    <div class="form-group">
      <label class="form-label">Category *</label>
      <select name="category" class="form-select" required>
        <option value="MULTIPLICATION">⚡ Multiplication</option>
        <option value="DIVISION">➗ Division</option>
        <option value="SQUARES">² Squares</option>
        <option value="FRACTIONS">½ Fractions</option>
        <option value="SHORTCUTS">🚀 Shortcuts</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Difficulty *</label>
      <select name="difficulty" class="form-select" required>
        <option value="Beginner">🟢 Beginner</option>
        <option value="Intermediate">🟡 Intermediate</option>
        <option value="Advanced">🔴 Advanced</option>
      </select>
    </div>
  </div>
  <div class="form-group">
    <label class="form-label">Title *</label>
    <input type="text" name="title" class="form-input" required
      value="<?= htmlspecialchars($_POST['title'] ?? '') ?>"
      placeholder="e.g. Multiply any 2-digit number by 11">
  </div>
  <div class="form-group">
    <label class="form-label">Subtitle</label>
    <input type="text" name="subtitle" class="form-input"
      value="<?= htmlspecialchars($_POST['subtitle'] ?? '') ?>"
      placeholder="Short description...">
  </div>
  <div style="display:flex;gap:20px">
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="is_new" style="accent-color:var(--success);width:16px;height:16px"
        <?= isset($_POST['is_new']) ? 'checked':'' ?>>
      <span style="font-size:13px;color:var(--text2)">🆕 Mark as NEW</span>
    </label>
  </div>
</div>

<!-- Video Section -->
<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fab fa-youtube" style="color:#EF4444"></i> Video Content
    </div>
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="has_video" id="hasVideo"
        style="accent-color:var(--cyan);width:16px;height:16px"
        <?= isset($_POST['has_video']) ? 'checked':'' ?>
        onchange="document.getElementById('videoFields').style.display=this.checked?'block':'none'">
      <span style="font-size:13px;color:var(--text2)">Has Video</span>
    </label>
  </div>
  <div id="videoFields" style="display:<?= isset($_POST['has_video'])?'block':'none' ?>">
    <div class="form-row">
      <div class="form-group" style="flex:2">
        <label class="form-label">YouTube URL</label>
        <input type="url" name="video_url" class="form-input"
          value="<?= htmlspecialchars($_POST['video_url'] ?? '') ?>"
          placeholder="https://youtube.com/watch?v=...">
      </div>
      <div class="form-group">
        <label class="form-label">Duration (minutes)</label>
        <input type="number" name="video_duration" class="form-input"
          value="<?= $_POST['video_duration'] ?? 5 ?>" min="1">
      </div>
    </div>
  </div>
</div>

<!-- Article Section -->
<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-file-alt" style="color:var(--cyan)"></i> Article Content
    </div>
    <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
      <input type="checkbox" name="has_article" id="hasArticle"
        style="accent-color:var(--cyan);width:16px;height:16px"
        <?= !isset($_POST['has_article']) || isset($_POST['has_article']) ? 'checked':'' ?>
        onchange="document.getElementById('articleFields').style.display=this.checked?'block':'none'">
      <span style="font-size:13px;color:var(--text2)">Has Article</span>
    </label>
  </div>
  <div id="articleFields">
    <div class="form-row">
      <div class="form-group">
        <label class="form-label">Read Duration (minutes)</label>
        <input type="number" name="read_duration" class="form-input"
          value="<?= $_POST['read_duration'] ?? 5 ?>" min="1" style="width:120px">
      </div>
    </div>
    <div class="form-group">
      <label class="form-label">Article Content</label>
      <textarea name="article_content" class="form-textarea" rows="10"
        placeholder="Write the trick explanation here...&#10;&#10;Example:&#10;Step 1: ...&#10;Step 2: ..."><?= htmlspecialchars($_POST['article_content'] ?? '') ?></textarea>
    </div>
  </div>
</div>

<div style="display:flex;gap:12px">
  <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Save Trick</button>
  <a href="<?= ADMIN_URL ?>/tricks/index.php" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
</div>

</form>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>