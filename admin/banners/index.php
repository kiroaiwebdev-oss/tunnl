<?php
// ── Actions MUST run before header.php (which prints HTML). Otherwise
//    header('Location:') fails with "headers already sent" and the reorder
//    AJAX response gets polluted with HTML. So we include only the config
//    here, process the action, redirect/echo, then load the HTML chrome. ──
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';

// Delete
if (isset($_GET['delete'])) {
    $id = (int)$_GET['delete'];
    $s  = $pdo->prepare("SELECT image_url FROM carousel_banners WHERE id=?");
    $s->execute([$id]);
    $row = $s->fetch(PDO::FETCH_ASSOC);
    if ($row && !empty($row['image_url'])) {
        $file = '../uploads/banners/' . basename($row['image_url']);
        if (file_exists($file)) unlink($file);
    }
    $pdo->prepare("DELETE FROM carousel_banners WHERE id=?")->execute([$id]);
    header('Location: index.php?msg=deleted'); exit;
}

// Toggle active
if (isset($_GET['toggle'])) {
    $id  = (int)$_GET['toggle'];
    $val = (int)$_GET['val'];
    $pdo->prepare("UPDATE carousel_banners SET is_active=? WHERE id=?")->execute([$val, $id]);
    header('Location: index.php?msg=updated'); exit;
}

// Drag reorder (AJAX)
if (isset($_POST['reorder'])) {
    header('Content-Type: application/json');
    $ids = explode(',', $_POST['order']);
    foreach ($ids as $i => $rid) {
        $pdo->prepare("UPDATE carousel_banners SET sort_order=? WHERE id=?")
            ->execute([$i + 1, (int)$rid]);
    }
    echo json_encode(['success' => true]); exit;
}

$banners = $pdo->query("SELECT * FROM carousel_banners ORDER BY sort_order ASC")
               ->fetchAll(PDO::FETCH_ASSOC);

$pageTitle = 'Carousel Banners';
require_once '../includes/header.php';
?>

<!-- PAGE HEADER -->
<div class="flex-between mb-24">
  <div>
    <div class="card-title-text" style="font-size:18px;">
      🎠 Carousel Banners
    </div>
    <p class="text-muted" style="margin-top:4px;">
      App home screen ka carousel manage karo
    </p>
  </div>
  <a href="add.php" class="btn btn-primary">
    <i class="fas fa-plus"></i> Add Banner
  </a>
</div>

<?php if (isset($_GET['msg'])): ?>
<div style="
  background: rgba(16,185,129,0.12);
  border: 1px solid rgba(16,185,129,0.3);
  color: #6EE7B7;
  padding: 12px 16px;
  border-radius: 10px;
  margin-bottom: 20px;
  font-size: 13px;
">
 ✅ <?= $_GET['msg'] === 'deleted' ? 'Banner has been deleted!' : 'Banner has been updated!' ?>
</div>
<?php endif; ?>

<div class="card" style="padding:0;">

  <?php if (empty($banners)): ?>
    <div style="text-align:center; padding:60px 20px; color:var(--muted);">
      <i class="fas fa-images" style="font-size:40px; display:block; margin-bottom:12px; opacity:0.3;"></i>
      <p style="margin-bottom:16px;">Koi banner nahi hai abhi</p>
      <a href="add.php" class="btn btn-primary">
        <i class="fas fa-plus"></i> Pehla Banner Add Karo
      </a>
    </div>

  <?php else: ?>
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th width="40">#</th>
            <th width="100">Image</th>
            <th>Title</th>
            <th>Subtitle</th>
            <th width="110">Action</th>
            <th width="70">Order</th>
            <th width="100">Status</th>
            <th width="110">Actions</th>
          </tr>
        </thead>
        <tbody id="sortable-banners">
          <?php foreach ($banners as $b): ?>
          <tr data-id="<?= $b['id'] ?>">
            <td>
              <i class="fas fa-grip-vertical"
                 style="color:var(--muted); cursor:grab; font-size:12px;"></i>
            </td>
            <td>
              <?php if (!empty($b['image_url'])): ?>
                <img src="<?= htmlspecialchars($b['image_url']) ?>"
                     style="width:72px; height:40px; object-fit:cover;
                            border-radius:6px; border:1px solid var(--border2);">
              <?php else: ?>
                <div style="width:72px; height:40px; background:rgba(255,255,255,0.04);
                            border-radius:6px; border:1px solid var(--border);
                            display:flex; align-items:center; justify-content:center;">
                  <i class="fas fa-image" style="color:var(--muted); font-size:14px;"></i>
                </div>
              <?php endif; ?>
            </td>
            <td>
              <span style="color:var(--text); font-weight:600; font-size:13px;">
                <?= htmlspecialchars($b['title']) ?>
              </span>
            </td>
            <td>
              <span style="color:var(--muted); font-size:12px;">
                <?= htmlspecialchars($b['subtitle']) ?>
              </span>
            </td>
            <td>
              <span class="badge badge-cyan"><?= htmlspecialchars($b['action_value']) ?></span>
            </td>
            <td>
              <span class="badge badge-purple"><?= $b['sort_order'] ?></span>
            </td>
            <td>
              <?php if ($b['is_active']): ?>
                <a href="?toggle=<?= $b['id'] ?>&val=0"
                   class="badge badge-success"
                   style="text-decoration:none; cursor:pointer;"
                   title="Click to deactivate">
                  ● Active
                </a>
              <?php else: ?>
                <a href="?toggle=<?= $b['id'] ?>&val=1"
                   class="badge badge-error"
                   style="text-decoration:none; cursor:pointer;"
                   title="Click to activate">
                  ● Inactive
                </a>
              <?php endif; ?>
            </td>
            <td>
              <div style="display:flex; gap:6px;">
                <a href="edit.php?id=<?= $b['id'] ?>" class="btn btn-secondary btn-sm">
                  <i class="fas fa-edit"></i>
                </a>
                <a href="?delete=<?= $b['id'] ?>"
                   class="btn btn-sm"
                   style="background:rgba(239,68,68,0.1);
                          border:1px solid rgba(239,68,68,0.2);
                          color:#FCA5A5;"
                   onclick="return confirm('Delete karna chahte ho?')">
                  <i class="fas fa-trash"></i>
                </a>
              </div>
            </td>
          </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>

    <div style="padding:12px 16px; border-top:1px solid var(--border);
                display:flex; align-items:center; justify-content:space-between;">
      <span style="font-size:12px; color:var(--muted);">
        <i class="fas fa-info-circle" style="margin-right:4px;"></i>
        Rows drag karke order change kar sakte ho
      </span>
      <button id="save-order" class="btn btn-primary btn-sm"
              style="display:none;">
        <i class="fas fa-save"></i> Order Save Karo
      </button>
    </div>
  <?php endif; ?>

</div>

<!-- SortableJS -->
<script src="https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/Sortable.min.js"></script>
<script>
const tbody   = document.getElementById('sortable-banners');
const saveBtn = document.getElementById('save-order');

if (tbody) {
  Sortable.create(tbody, {
    handle: '.fa-grip-vertical',
    animation: 150,
    onEnd: () => saveBtn && (saveBtn.style.display = 'inline-flex')
  });
}

if (saveBtn) {
  saveBtn.addEventListener('click', () => {
    const ids = [...tbody.querySelectorAll('tr')]
                  .map(r => r.dataset.id).join(',');
    fetch('index.php', {
      method : 'POST',
      headers: {'Content-Type':'application/x-www-form-urlencoded'},
      body   : 'reorder=1&order=' + ids
    }).then(() => {
      saveBtn.style.display = 'none';
      location.reload();
    });
  });
}
</script>

<?php require_once '../includes/footer.php'; ?>