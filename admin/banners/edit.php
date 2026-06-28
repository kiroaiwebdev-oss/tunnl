<?php ob_start();
$pageTitle = 'Banner Edit';
require_once '../includes/header.php';

$id = (int)($_GET['id'] ?? 0);
if (!$id) { header('Location: index.php'); exit; }

$stmt = $pdo->prepare("SELECT * FROM carousel_banners WHERE id = ?");
$stmt->execute([$id]);
$b = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$b) { header('Location: index.php'); exit; }

$error = '';

$actions = [
    'previous_year' => 'Previous Year Papers',
    'premium'       => 'Premium Screen',
    'mcq'           => 'MCQ / Test List',
    'leaderboard'   => 'Leaderboard',
    'shorts'        => 'Shorts',
    'tricks'        => 'Tunnl Tricks',
    'solve_earn'    => 'Solve & Earn',
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $title       = trim($_POST['title']        ?? '');
    $subtitle    = trim($_POST['subtitle']     ?? '');
    $actionValue = trim($_POST['action_value'] ?? 'mcq');
    $isActive    = isset($_POST['is_active']) ? 1 : 0;
    $sortOrder   = (int)($_POST['sort_order']  ?? $b['sort_order']);
    $imageUrl    = $b['image_url'];

    if (empty($title) || empty($subtitle)) {
        $error = 'Title aur subtitle required hain!';
    } else {

        // New image upload
        if (!empty($_FILES['image']['name']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $ext     = strtolower(pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION));
            $allowed = ['jpg', 'jpeg', 'png', 'webp'];
            if (!in_array($ext, $allowed)) {
                $error = 'Sirf JPG/PNG/WEBP allowed hai!';
            } elseif ($_FILES['image']['size'] > 2 * 1024 * 1024) {
                $error = 'Max 2MB image allowed hai!';
            } else {
                $uploadDir = '../uploads/banners/';
                if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);
                // Old local file delete karo
                if (!empty($b['image_url']) && strpos($b['image_url'], '/uploads/banners/') !== false) {
                    $oldFile = '../uploads/banners/' . basename($b['image_url']);
                    if (file_exists($oldFile)) unlink($oldFile);
                }
                $filename = 'banner_' . time() . '.' . $ext;
                if (move_uploaded_file($_FILES['image']['tmp_name'], $uploadDir . $filename)) {
                    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
                    $imageUrl = $protocol . '://' . $_SERVER['HTTP_HOST'] . '/uploads/banners/' . $filename;
                } else {
                    $error = 'Image upload fail hua. Folder permissions check karo.';
                }
            }
        }

        // Manual URL override
        if (empty($error) && !empty($_POST['image_url_manual'])) {
            $imageUrl = trim($_POST['image_url_manual']);
        }

        // DB Update
        if (empty($error)) {
            $upd = $pdo->prepare("
                UPDATE carousel_banners
                SET title        = ?,
                    subtitle     = ?,
                    image_url    = ?,
                    action_value = ?,
                    is_active    = ?,
                    sort_order   = ?
                WHERE id = ?
            ");
            $result = $upd->execute([
                $title, $subtitle, $imageUrl,
                $actionValue, $isActive, $sortOrder, $id
            ]);

            if ($result) {
                echo '<script>window.location.href = "index.php?msg=updated";</script>';
                exit;
            } else {
                $error = 'DB is Failed Please try Again.';
            }
        }
    }

    // Error ke case mein $b ko POST values se update karo
    if (!empty($error)) {
        $b['title']        = $title;
        $b['subtitle']     = $subtitle;
        $b['action_value'] = $actionValue;
        $b['is_active']    = $isActive;
        $b['sort_order']   = $sortOrder;
    }
}
?>

<!-- PAGE HEADER -->
<div class="flex-between mb-24">
  <div>
    <div class="card-title-text" style="font-size:18px;">
      ✏️ Edit Banner
    </div>
    <p class="text-muted" style="margin-top:4px;">
      ID #<?= $id ?> — <?= htmlspecialchars($b['title']) ?>
    </p>
  </div>
  <a href="index.php" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back
  </a>
</div>

<?php if (!empty($error)): ?>
<div style="
  background:rgba(239,68,68,0.12); border:1px solid rgba(239,68,68,0.3);
  color:#FCA5A5; padding:12px 16px; border-radius:10px;
  margin-bottom:20px; font-size:13px;">
  ⚠️ <?= htmlspecialchars($error) ?>
</div>
<?php endif; ?>

<div class="card">
  <form method="POST" enctype="multipart/form-data">

    <!-- Title + Subtitle -->
    <div class="form-row" style="margin-bottom:18px;">
      <div class="form-group" style="margin-bottom:0;">
        <label class="form-label">Title <span style="color:var(--error)">*</span></label>
        <input type="text" name="title" class="form-input"
               placeholder="e.g. NEW! SSC CGL 2024"
               value="<?= htmlspecialchars($b['title']) ?>"
               maxlength="100" required>
      </div>

      <div class="form-group" style="margin-bottom:0;">
        <label class="form-label">Subtitle <span style="color:var(--error)">*</span></label>
        <input type="text" name="subtitle" class="form-input"
               placeholder="e.g. Previous year papers live now"
               value="<?= htmlspecialchars($b['subtitle']) ?>"
               maxlength="200" required>
      </div>
    </div>

    <!-- Action + Sort Order -->
    <div class="form-row" style="margin-bottom:18px;">
      <div class="form-group" style="margin-bottom:0;">
        <label class="form-label">On Tap — Navigate To</label>
        <select name="action_value" class="form-select">
          <?php foreach ($actions as $val => $label): ?>
            <option value="<?= $val ?>"
              <?= ($b['action_value'] === $val) ? 'selected' : '' ?>>
              <?= htmlspecialchars($label) ?>
            </option>
          <?php endforeach; ?>
        </select>
      </div>

      <div class="form-group" style="margin-bottom:0;">
        <label class="form-label">Sort Order</label>
        <input type="number" name="sort_order" class="form-input"
               value="<?= (int)$b['sort_order'] ?>" min="1">
      </div>
    </div>

    <!-- Active Toggle -->
    <div class="form-group">
      <label class="form-label">Status</label>
      <label style="display:flex; align-items:center; gap:10px; cursor:pointer; margin-top:6px;">
        <input type="checkbox" name="is_active"
               <?= ((int)$b['is_active'] === 1) ? 'checked' : '' ?>
               style="width:16px; height:16px; accent-color:var(--cyan);">
        <span style="font-size:13px; color:var(--text2);">
          Active (app mein visible rahega)
        </span>
      </label>
    </div>

    <!-- Current Image Preview -->
    <?php if (!empty($b['image_url'])): ?>
    <div class="form-group">
      <label class="form-label">Current Image</label>
      <div style="display:flex; align-items:center; gap:12px; margin-top:6px;">
        <img src="<?= htmlspecialchars($b['image_url']) ?>"
             id="currentImg"
             style="height:80px; border-radius:8px;
                    border:1px solid var(--border2); object-fit:cover;">
        <span style="font-size:12px; color:var(--muted);">
          Naya upload karoge toh yeh replace ho jaayega
        </span>
      </div>
    </div>
    <?php endif; ?>

    <!-- New Image Upload -->
    <div class="form-group">
      <label class="form-label">Upload New Image</label>
      <input type="file" name="image" class="form-input"
             accept=".jpg,.jpeg,.png,.webp"
             style="padding:8px;"
             onchange="previewImg(this)">
      <p style="font-size:11px; color:var(--muted); margin-top:6px;">
        JPG / PNG / WEBP &nbsp;·&nbsp; Max 2MB &nbsp;·&nbsp; Recommended: 800×200px
      </p>
      <div id="preview" style="margin-top:8px;"></div>
    </div>

    <!-- Manual Image URL -->
    <div class="form-group">
      <label class="form-label">Ya Image URL Enter Karo</label>
      <input type="url" name="image_url_manual" class="form-input"
             placeholder="https://example.com/banner.jpg"
             value="<?= htmlspecialchars($_POST['image_url_manual'] ?? '') ?>">
      <p style="font-size:11px; color:var(--muted); margin-top:6px;">
        Upload ya URL — ek hi kafi hai. URL upload se override karta hai.
      </p>
    </div>

    <!-- Submit Buttons -->
    <div style="display:flex; gap:10px; margin-top:16px;">
      <button type="submit" class="btn btn-primary">
        <i class="fas fa-save"></i> Update Banner
      </button>
      <a href="index.php" class="btn btn-secondary">
        Cancel
      </a>
    </div>

  </form>
</div>

<script>
function previewImg(input) {
  const preview = document.getElementById('preview');
  if (input.files && input.files[0]) {
    const reader = new FileReader();
    reader.onload = e => {
      preview.innerHTML = `
        <img src="${e.target.result}"
             style="height:80px; border-radius:8px;
                    border:2px solid var(--cyan); object-fit:cover;">`;
      const cur = document.getElementById('currentImg');
      if (cur) cur.style.opacity = '0.4';
    };
    reader.readAsDataURL(input.files[0]);
  }
}
</script>

<?php require_once '../includes/footer.php'; ob_end_flush(); ?>