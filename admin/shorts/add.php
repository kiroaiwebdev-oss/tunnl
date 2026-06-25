<?php
// Process the form BEFORE any HTML output so header('Location') can redirect
// cleanly (a large 60MB upload otherwise flushes output → "headers already
// sent" → blank content + no success message).
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';

$success = $error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $platform  = strtolower(trim($_POST['platform'] ?? 'youtube'));
        if (!in_array($platform, ['youtube', 'instagram', 'facebook', 'local'], true)) {
            $platform = 'youtube';
        }
        $videoUrl  = trim($_POST['video_url'] ?? '');
        $thumbnail = trim($_POST['thumbnail_url'] ?? '');

        // Local video file upload
        if ($platform === 'local' && !empty($_FILES['video_file']['name'])) {
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
            } else {
                throw new Exception('Failed to save the uploaded video.');
            }
        }

        if ($videoUrl === '') {
            throw new Exception('Provide a video URL or upload a video file.');
        }

        // Auto-derive YouTube thumbnail if admin left it empty.
        if ($thumbnail === '' && $platform === 'youtube') {
            if (preg_match('/(?:v=|\/shorts\/|youtu\.be\/|\/embed\/)([a-zA-Z0-9_-]{11})/', $videoUrl, $m)) {
                $thumbnail = 'https://img.youtube.com/vi/' . $m[1] . '/mqdefault.jpg';
            }
        }

        // Store the URL in BOTH columns so the API (which prefers youtube_url
        // then falls back to url) always finds it, regardless of platform.
        $pdo->prepare("
            INSERT INTO shorts
              (platform, title, url, youtube_url, thumbnail_url, category, duration, is_active)
            VALUES (?,?,?,?,?,?,?,1)
        ")->execute([
            $platform,
            trim($_POST['title']),
            $videoUrl,
            $videoUrl,
            $thumbnail,
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

$pageTitle = 'Add Short';
require_once dirname(__DIR__) . '/includes/header.php';
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
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Add Short</h2>
    <p class="text-muted">Add a video from YouTube, Instagram or Facebook</p>
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
      <option value="youtube">▶️ YouTube</option>
      <option value="instagram">📸 Instagram</option>
      <option value="facebook">📘 Facebook</option>
      <option value="local">📁 Local Upload</option>
    </select>
    <div id="platformHint" style="font-size:11px;color:var(--muted);margin-top:4px">
      Paste a YouTube Shorts/video link.
    </div>
  </div>

  <div class="form-group">
    <label class="form-label">Title *</label>
    <input type="text" name="title" class="form-input" required
      value="<?= htmlspecialchars($_POST['title'] ?? '') ?>"
      placeholder="e.g. 11 ka table ek second mein!">
  </div>

  <div class="form-group" id="urlGroup">
    <label class="form-label">Video URL <span id="urlReq">*</span></label>
    <input type="url" name="video_url" id="videoUrl" class="form-input"
      value="<?= htmlspecialchars($_POST['video_url'] ?? '') ?>"
      placeholder="https://youtube.com/shorts/..."
      oninput="updatePreview()">
  </div>

  <div class="form-group" id="fileGroup" style="display:none">
    <label class="form-label">Upload Video File *</label>
    <input type="file" name="video_file" class="form-input" accept=".mp4,.webm,.mov,.m4v" style="padding:8px">
    <div style="font-size:11px;color:var(--muted);margin-top:4px">
      MP4 / WEBM / MOV · Max 60MB. Uploaded videos play directly in the app.
    </div>
  </div>

  <div class="form-group">
    <label class="form-label">Thumbnail URL <span id="thumbReq" style="color:var(--muted)">(optional)</span></label>
    <input type="url" name="thumbnail_url" id="thumbUrl" class="form-input"
      value="<?= htmlspecialchars($_POST['thumbnail_url'] ?? '') ?>"
      placeholder="https://..."
      oninput="updatePreview()">
    <div style="font-size:11px;color:var(--muted);margin-top:4px">
      YouTube auto-generates a thumbnail. For Instagram & Facebook, paste an image URL
      so the app card shows a preview.
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
      <i id="platformIcon" class="fab fa-youtube" style="color:#EF4444"></i>
      <span id="previewLabel"></span>
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
  } else if (p === 'local') {
    hint.textContent = 'Upload a video file (MP4/WEBM/MOV). It will play directly in the app.';
    thumbReq.textContent = '(recommended)';
    icon.className = 'fas fa-file-video'; icon.style.color = '#10B981';
  }

  // Toggle URL vs file-upload inputs for local platform
  const isLocal = (p === 'local');
  document.getElementById('urlGroup').style.display  = isLocal ? 'none' : 'block';
  document.getElementById('fileGroup').style.display = isLocal ? 'block' : 'none';
  document.getElementById('urlReq').textContent = isLocal ? '' : '*';

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

// Init
onPlatformChange();
updatePreview();
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
