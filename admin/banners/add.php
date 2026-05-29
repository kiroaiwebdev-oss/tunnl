<?php
$pageTitle = 'Add Banner';
require_once '../includes/header.php';

$error = '';

$actions = [
    'previous_year' => 'Previous Year Papers',
    'premium'       => 'Premium Screen',
    'mcq'           => 'MCQ / Test List',
    'leaderboard'   => 'Leaderboard',
    'shorts'        => 'Shorts',
    'tricks'        => 'Tunnel Tricks',
    'solve_earn'    => 'Solve & Earn',
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $title       = trim($_POST['title']        ?? '');
    $subtitle    = trim($_POST['subtitle']     ?? '');
    $actionValue = trim($_POST['action_value'] ?? 'mcq');
    $isActive    = isset($_POST['is_active']) ? 1 : 0;
    $imageUrl    = '';

    $maxOrder  = $pdo->query("SELECT MAX(sort_order) FROM carousel_banners")->fetchColumn();
    $sortOrder = ($maxOrder ?? 0) + 1;

    if (empty($title) || empty($subtitle)) {
        $error = 'Title and subtitle are required!';
    } else {
        if (!empty($_FILES['image']['name'])) {
            $ext     = strtolower(pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION));
            $allowed = ['jpg', 'jpeg', 'png', 'webp'];
            if (!in_array($ext, $allowed)) {
                $error = 'Only JPG, PNG, or WEBP images are allowed.';
            } elseif ($_FILES['image']['size'] > 2 * 1024 * 1024) {
                $error = 'Maximum image size is 2MB.';
            } else {
                $uploadDir = '../uploads/banners/';
                if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);
                $filename = 'banner_' . time() . '.' . $ext;
                if (move_uploaded_file($_FILES['image']['tmp_name'], $uploadDir . $filename)) {
                    $imageUrl = 'https://' . $_SERVER['HTTP_HOST'] . '/uploads/banners/' . $filename;
                }
            }
        }

        if (!empty($_POST['image_url_manual'])) {
            $imageUrl = trim($_POST['image_url_manual']);
        }

        if (empty($error)) {
            $stmt = $pdo->prepare("
                INSERT INTO carousel_banners
                  (title, subtitle, image_url, action_value, is_active, sort_order)
                VALUES (?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([$title, $subtitle, $imageUrl, $actionValue, $isActive, $sortOrder]);
            header('Location: index.php?msg=added'); exit;
        }
    }
}
?>

<!-- PAGE HEADER -->
<div class="flex-between mb-24">
  <div>
    <div class="card-title-text" style="font-size:18px;">
      ➕ Add New Banner
    </div>
    <p class="text-muted" style="margin-top:4px;">
      Create a new banner for the app home screen carousel
    </p>
  </div>
  <a href="index.php" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> Back to Banners
  </a>
</div>

<?php if ($error): ?>
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
        <label class="form-label">
          Title <span style="color:var(--error)">*</span>
        </label>
        <input type="text" name="title" class="form-input"
               placeholder="e.g. NEW! SSC CGL 2024"
               value="<?= htmlspecialchars($_POST['title'] ?? '') ?>"
               maxlength="100" required>
        <p style="font-size:11px; color:var(--muted); margin-top:5px;">
          Max 100 characters
        </p>
      </div>

      <div class="form-group" style="margin-bottom:0;">
        <label class="form-label">
          Subtitle <span style="color:var(--error)">*</span>
        </label>
        <input type="text" name="subtitle" class="form-input"
               placeholder="e.g. Previous year papers are now live"
               value="<?= htmlspecialchars($_POST['subtitle'] ?? '') ?>"
               maxlength="200" required>
        <p style="font-size:11px; color:var(--muted); margin-top:5px;">
          Max 200 characters
        </p>
      </div>
    </div>

    <!-- Action + Status -->
    <div class="form-row" style="margin-bottom:18px;">
      <div class="form-group" style="margin-bottom:0;">
        <label class="form-label">On Tap — Navigate To</label>
        <select name="action_value" class="form-select">
          <?php foreach ($actions as $val => $label): ?>
            <option value="<?= $val ?>"
              <?= (($_POST['action_value'] ?? '') === $val) ? 'selected' : '' ?>>
              <?= $label ?>
            </option>
          <?php endforeach; ?>
        </select>
        <p style="font-size:11px; color:var(--muted); margin-top:5px;">
          Screen that opens when user taps this banner
        </p>
      </div>

      <div class="form-group" style="margin-bottom:0;">
        <label class="form-label">Visibility</label>
        <label style="
          display:flex; align-items:center; gap:10px;
          cursor:pointer; margin-top:10px;">
          <input type="checkbox" name="is_active" checked
                 style="width:16px; height:16px; accent-color:var(--cyan);">
          <span style="font-size:13px; color:var(--text2);">
            Active — visible to app users
          </span>
        </label>
      </div>
    </div>

    <!-- Image Upload -->
    <div class="form-group">
      <label class="form-label">Banner Image</label>
      <input type="file" name="image" class="form-input"
             accept=".jpg,.jpeg,.png,.webp"
             style="padding:8px;"
             onchange="previewImg(this)">
      <p style="font-size:11px; color:var(--muted); margin-top:6px;">
        Accepted formats: JPG, PNG, WEBP &nbsp;·&nbsp;
        Max size: 2MB &nbsp;·&nbsp;
        Recommended dimensions: 800 × 200px
      </p>
      <div id="preview" style="margin-top:10px;"></div>
    </div>

    <!-- Image URL -->
    <div class="form-group">
      <label class="form-label">Or Paste Image URL</label>
      <input type="url" name="image_url_manual" class="form-input"
             placeholder="https://example.com/banner.jpg"
             value="<?= htmlspecialchars($_POST['image_url_manual'] ?? '') ?>">
      <p style="font-size:11px; color:var(--muted); margin-top:6px;">
        Use either file upload above or a direct URL — not both.
        URL takes priority if both are provided.
      </p>
    </div>

    <!-- Divider -->
    <div style="border-top:1px solid var(--border); margin:20px 0;"></div>

    <!-- Actions -->
    <div style="display:flex; gap:10px;">
      <button type="submit" class="btn btn-primary">
        <i class="fas fa-save"></i> Save Banner
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
        <div style="display:inline-block;">
          <img src="${e.target.result}"
               style="height:80px; border-radius:8px;
                      border:2px solid var(--cyan);
                      object-fit:cover; display:block;">
          <p style="font-size:11px; color:var(--muted); margin-top:4px;">
            Preview
          </p>
        </div>`;
    };
    reader.readAsDataURL(input.files[0]);
  }
}
</script>

<?php require_once '../includes/footer.php'; ?>