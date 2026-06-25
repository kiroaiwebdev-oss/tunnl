<?php
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';

$id = intval($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/shorts/index.php'); exit; }

$short = $pdo->prepare("SELECT * FROM shorts WHERE id=?");
$short->execute([$id]);
$short = $short->fetch();
if (!$short) { header('Location: ' . ADMIN_URL . '/shorts/index.php'); exit; }

$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $platform  = strtolower(trim($_POST['platform'] ?? 'youtube'));
        if (!in_array($platform, ['youtube', 'instagram', 'facebook', 'local'], true)) {
            $platform = 'youtube';
        }
        $videoUrl  = trim($_POST['video_url'] ?? '');
        $thumbnail = trim($_POST['thumbnail_url'] ?? '');

        // Optional: replace with a locally-uploaded video file
        if (!empty($_FILES['video_file']['name'])) {
            $ext     = strtolower(pathinfo($_FILES['video_file']['name'], PATHINFO_EXTENSION));
            $allowed = ['mp4', 'webm', 'mov', 'm4v'];
            if (!in_array($ext, $allowed)) {
                throw new Exception('Only MP4, WEBM, MOV or M4V videos are allowed.');
            }
            if ($_FILES['video_file']['size'] > 60 * 1024 * 1024) {
                throw new Exception('Maximum video size is 60MB.');
            }
            $dir = dirname(__DIR__) . '/uploads/shorts/';
            if (!is_dir($dir)) mkdir($dir, 0755, true);
            $fname = 'short_' . time() . '_' . mt_rand(100, 999) . '.' . $ext;
            if (move_uploaded_file($_FILES['video_file']['tmp_name'], $dir . $fname)) {
                $videoUrl = 'https://' . $_SERVER['HTTP_HOST'] . '/uploads/shorts/' . $fname;
                $platform = 'local';
            } else {
                throw new Exception('Failed to save the uploaded video.');
            }
        }

        if ($thumbnail === '' && $platform === 'youtube') {
            if (preg_match('/(?:v=|\/shorts\/|youtu\.be\/|\/embed\/)([a-zA-Z0-9_-]{11})/', $videoUrl, $m)) {
                $thumbnail = 'https://img.youtube.com/vi/' . $m[1] . '/mqdefault.jpg';
            }
        }

        $pdo->prepare("
            UPDATE shorts SET
              platform=?, title=?, url=?, youtube_url=?, thumbnail_url=?, category=?, duration=?, is_active=?
            WHERE id=?
        ")->execute([
            $platform,
            trim($_POST['title']),
            $videoUrl,
            $videoUrl,
            $thumbnail,
            $_POST['category'],
            intval($_POST['duration'] ?? 0),
            isset($_POST['is_active']) ? 1 : 0,
            $id
        ]);
        header('Location: ' . ADMIN_URL . '/shorts/index.php?updated=1');
        exit;
    } catch (Exception $e) { $error = $e->getMessage(); }
}

$pageTitle = 'Edit Short';
require_once dirname(__DIR__) . '/includes/header.php';

$curUrl      = !empty($short['youtube_url']) ? $short['youtube_url'] : ($short['url'] ?? '');
$curPlatform = strtolower($short['platform'] ?? 'youtube');
if (!in_array($curPlatform, ['youtube', 'instagram', 'facebook', 'local'], true)) {
    $curPlatform = 'youtube';
}
$curThumb = $short['thumbnail_url'] ?? '';
?>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;
  padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $success ?>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;
  padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-exclamation-circle"></i> <?= htmlspecialchars($error) ?>
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

<form method="POST" enctype="multipart/form-data">
<div class="card mb-16">
  <div class="form-group">
    <label class="form-label">Platform *</label>
    <select name="platform" id="platform" class="form-select" required onchange="onPlatformChange()">
      <?php foreach (['youtube'=>'▶️ YouTube','instagram'=>'📸 Instagram','facebook'=>'📘 Facebook','local'=>'📁 Local Upload'] as $v=>$l): ?>
      <option value="<?= $v ?>" <?= $curPlatform===$v?'selected':'' ?>><?= $l ?></option>
      <?php endforeach; ?>
    </select>
    <div id="platformHint" style="font-size:11px;color:var(--muted);margin-top:4px"></div>
  </div>

  <div class="form-group">
    <label class="form-label">Title *</label>
    <input type="text" name="title" class="form-input" required
      value="<?= htmlspecialchars($short['title']) ?>">
  </div>

  <div class="form-group">
    <label class="form-label">Video URL *</label>
    <input type="url" name="video_url" id="videoUrl" class="form-input" required
      value="<?= htmlspecialchars($curUrl) ?>"
      oninput="updatePreview()">
  </div>

  <div class="form-group">
    <label class="form-label">Replace with Local Video (optional)</label>
    <input type="file" name="video_file" class="form-input" accept=".mp4,.webm,.mov,.m4v" style="padding:8px">
    <div style="font-size:11px;color:var(--muted);margin-top:4px">
      Upload to replace with a local video (MP4/WEBM/MOV, max 60MB). This switches the platform to Local.
    </div>
  </div>

  <div class="form-group">
    <label class="form-label">Thumbnail URL <span id="thumbReq" style="color:var(--muted)">(optional)</span></label>
    <input type="url" name="thumbnail_url" id="thumbUrl" class="form-input"
      value="<?= htmlspecialchars($curThumb) ?>"
      placeholder="https://..."
      oninput="updatePreview()">
    <div style="font-size:11px;color:var(--muted);margin-top:4px">
      YouTube auto-generates a thumbnail. For Instagram & Facebook, paste an image URL.
    </div>
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
  <div id="previewBox" style="display:none;background:var(--dark);border:1px solid var(--border);
    border-radius:12px;overflow:hidden;margin-top:14px">
    <img id="thumbPreview" src="" alt="Thumb"
      style="width:100%;max-height:180px;object-fit:cover">
    <div style="padding:10px;font-size:12px;color:var(--muted);display:flex;align-items:center;gap:6px">
      <i id="platformIcon" class="fab fa-youtube" style="color:#EF4444"></i>
      <span id="previewLabel"></span>
    </div>
  </div>
</div>
<div style="display:flex;gap:12px">
  <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Update</button>
  <a href="<?= ADMIN_URL ?>/shorts/index.php" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
</div>
</form>
</div>

<script>
function ytIdFromUrl(url) {
  const m = url.match(/(?:v=|\/shorts\/|youtu\.be\/|\/embed\/)([a-zA-Z0-9_-]{11})/);
  return m ? m[1] : null;
}

function onPlatformChange() {
  const p = document.getElementById('platform').value;
  const url = document.getElementById('videoUrl');
  const hint = document.getElementById('platformHint');
  const thumbReq = document.getElementById('thumbReq');
  const icon = document.getElementById('platformIcon');

  if (p === 'youtube') {
    url.placeholder = 'https://youtube.com/shorts/...';
    hint.textContent = 'Paste a YouTube Shorts/video link. Thumbnail is auto-generated.';
    thumbReq.textContent = '(optional)';
    icon.className = 'fab fa-youtube'; icon.style.color = '#EF4444';
  } else if (p === 'instagram') {
    url.placeholder = 'https://www.instagram.com/reel/...';
    hint.textContent = 'Paste an Instagram Reel/post link. Add a thumbnail image URL below.';
    thumbReq.textContent = '(recommended)';
    icon.className = 'fab fa-instagram'; icon.style.color = '#E1306C';
  } else if (p === 'facebook') {
    url.placeholder = 'https://www.facebook.com/watch/?v=... or https://fb.watch/...';
    hint.textContent = 'Paste a Facebook video/reel link. Add a thumbnail image URL below.';
    thumbReq.textContent = '(recommended)';
    icon.className = 'fab fa-facebook'; icon.style.color = '#1877F2';
  }
  updatePreview();
}

function updatePreview() {
  const p = document.getElementById('platform').value;
  const url = document.getElementById('videoUrl').value.trim();
  const thumb = document.getElementById('thumbUrl').value.trim();
  const box = document.getElementById('previewBox');
  const img = document.getElementById('thumbPreview');
  const label = document.getElementById('previewLabel');

  let thumbSrc = thumb;
  let labelText = p.charAt(0).toUpperCase() + p.slice(1);

  if (p === 'youtube' && !thumbSrc) {
    const vid = ytIdFromUrl(url);
    if (vid) { thumbSrc = `https://img.youtube.com/vi/${vid}/mqdefault.jpg`; labelText = 'YouTube • ' + vid; }
  }

  if (thumbSrc) {
    img.src = thumbSrc;
    label.textContent = labelText;
    box.style.display = 'block';
  } else {
    box.style.display = 'none';
  }
}

onPlatformChange();
updatePreview();
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
