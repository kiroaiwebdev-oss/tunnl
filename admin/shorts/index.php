<?php
$pageTitle = 'Shorts';
require_once dirname(__DIR__) . '/includes/header.php';

$shorts = $pdo->query("SELECT * FROM shorts ORDER BY created_at DESC")->fetchAll();
?>
<?php if (isset($_GET['added']) || isset($_GET['updated'])): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;
  padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i>
  <?= isset($_GET['updated']) ? 'Short updated successfully!' : 'Short added successfully!' ?>
</div>
<?php endif; ?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Shorts</h2>
    <p class="text-muted"><?= count($shorts) ?> shorts total &middot; YouTube, Instagram, Facebook &amp; Local</p>
  </div>
  <a href="<?= ADMIN_URL ?>/shorts/add.php" class="btn btn-primary">
    <i class="fas fa-plus"></i> Add Short
  </a>
</div>

<!-- Grid View -->
<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:16px">
  <?php if (empty($shorts)): ?>
  <div class="card" style="grid-column:1/-1;text-align:center;padding:60px;color:var(--muted)">
    <i class="fas fa-play-circle" style="font-size:48px;display:block;margin-bottom:16px;opacity:0.3"></i>
    No shorts yet. <a href="<?= ADMIN_URL ?>/shorts/add.php" style="color:var(--cyan)">Add one!</a>
  </div>
  <?php else: ?>
  <?php
  $platMeta = [
    'youtube'   => ['#EF4444', 'fab fa-youtube',     'YouTube'],
    'instagram' => ['#E1306C', 'fab fa-instagram',   'Instagram'],
    'facebook'  => ['#1877F2', 'fab fa-facebook',    'Facebook'],
    'telegram'  => ['#0088CC', 'fab fa-telegram',    'Telegram'],
    'local'     => ['#10B981', 'fas fa-folder-open', 'Local'],
  ];
  foreach ($shorts as $s):
    $sUrl = !empty($s['youtube_url']) ? $s['youtube_url'] : ($s['url'] ?? '');
    // Resolve platform (stored column first, then URL sniff).
    $plat = strtolower(trim($s['platform'] ?? ''));
    if (!isset($platMeta[$plat])) {
      $lu = strtolower($sUrl);
      if (strpos($lu, 'instagram') !== false)       $plat = 'instagram';
      elseif (strpos($lu, 'facebook') !== false || strpos($lu, 'fb.watch') !== false) $plat = 'facebook';
      elseif (strpos($lu, 't.me') !== false || strpos($lu, 'telegram') !== false)     $plat = 'telegram';
      elseif (preg_match('/\.(mp4|webm|mov|m4v)(\?|$)/', $lu))                         $plat = 'local';
      else $plat = 'youtube';
    }
    [$pColor, $pIcon, $pLabel] = $platMeta[$plat] ?? $platMeta['youtube'];

    // Thumbnail: admin-provided first, then YouTube auto-thumb.
    $thumb = $s['thumbnail_url'] ?? '';
    if ($thumb === '' && $plat === 'youtube') {
      preg_match('/(?:v=|\/shorts\/|youtu\.be\/)([a-zA-Z0-9_-]{11})/', $sUrl, $m);
      $vid   = $m[1] ?? '';
      $thumb = $vid ? "https://img.youtube.com/vi/$vid/mqdefault.jpg" : '';
    }
  ?>
  <div style="background:var(--card);border:1px solid var(--border);border-radius:16px;overflow:hidden;
    transition:all 0.2s" onmouseover="this.style.borderColor='var(--cyan)';this.style.transform='translateY(-2px)'"
    onmouseout="this.style.borderColor='var(--border)';this.style.transform=''">

    <!-- Thumbnail -->
    <div style="position:relative;aspect-ratio:16/9;background:var(--dark);overflow:hidden">
      <?php if ($thumb): ?>
      <img src="<?= $thumb ?>" alt="Thumb"
        style="width:100%;height:100%;object-fit:cover;opacity:0.8">
      <?php else: ?>
      <div style="display:flex;align-items:center;justify-content:center;height:100%;color:var(--border2)">
        <i class="fas fa-video" style="font-size:32px"></i>
      </div>
      <?php endif; ?>
      <div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center">
        <a href="<?= htmlspecialchars($sUrl) ?>" target="_blank"
          style="width:44px;height:44px;background:<?= $pColor ?>E6;border-radius:50%;
            display:flex;align-items:center;justify-content:center;color:white;font-size:16px;
            text-decoration:none;transition:transform 0.2s"
          onmouseover="this.style.transform='scale(1.1)'"
          onmouseout="this.style.transform=''">
          <i class="fas fa-play" style="margin-left:3px"></i>
        </a>
      </div>
      <!-- Platform badge -->
      <div style="position:absolute;top:8px;left:8px">
        <span style="background:<?= $pColor ?>;color:#fff;font-size:9px;font-weight:700;
          padding:3px 8px;border-radius:20px;display:inline-flex;align-items:center;gap:4px">
          <i class="<?= $pIcon ?>"></i> <?= $pLabel ?>
        </span>
      </div>
      <!-- Status badge -->
      <div style="position:absolute;top:8px;right:8px">
        <?php if ($s['is_active']): ?>
        <span class="badge badge-success" style="font-size:9px">LIVE</span>
        <?php else: ?>
        <span class="badge badge-error" style="font-size:9px">HIDDEN</span>
        <?php endif; ?>
      </div>
    </div>

    <!-- Info -->
    <div style="padding:14px">
      <div style="font-weight:600;color:var(--text);font-size:13px;margin-bottom:4px;
        white-space:nowrap;overflow:hidden;text-overflow:ellipsis">
        <?= htmlspecialchars($s['title']) ?>
      </div>
      <div style="display:flex;align-items:center;gap:8px;margin-bottom:12px">
        <span class="badge badge-cyan" style="font-size:10px">
          <?= ucfirst(str_replace('_',' ',$s['category'])) ?>
        </span>
        <?php if ($s['duration']): ?>
        <span style="font-size:11px;color:var(--muted)">
          <i class="fas fa-clock"></i> <?= $s['duration'] ?>s
        </span>
        <?php endif; ?>
        <span style="font-size:11px;color:var(--muted);margin-left:auto">
          <?= date('d M', strtotime($s['created_at'])) ?>
        </span>
      </div>
      <div style="display:flex;gap:6px">
        <a href="<?= ADMIN_URL ?>/shorts/edit.php?id=<?= $s['id'] ?>"
           class="btn btn-secondary btn-sm" style="flex:1;justify-content:center">
          <i class="fas fa-edit"></i> Edit
        </a>
        <button onclick="deleteShort(<?= $s['id'] ?>)" class="btn btn-danger btn-sm">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
  </div>
  <?php endforeach; ?>
  <?php endif; ?>
</div>

<script>
function deleteShort(id) {
  if (!confirm('Delete this short?')) return;
  fetch('delete.php', {
    method:'POST',
    headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:'id='+id
  }).then(r=>r.json()).then(d=>{ if(d.success) location.reload(); else alert(d.message); });
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>