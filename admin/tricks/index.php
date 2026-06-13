<?php
$pageTitle = 'Tunnel Tricks';
require_once dirname(__DIR__) . '/includes/header.php';

$category = $_GET['category'] ?? '';
$search   = $_GET['search']   ?? '';

$where  = ['1=1'];
$params = [];
if ($category) { $where[] = 'category = ?'; $params[] = $category; }
if ($search)   { $where[] = 'title LIKE ?'; $params[] = "%$search%"; }

$whereSQL = implode(' AND ', $where);
$tricks = $pdo->prepare("SELECT * FROM tricks WHERE $whereSQL ORDER BY chapter_number ASC");
$tricks->execute($params);
$tricks = $tricks->fetchAll();

$cats = ['MULTIPLICATION','DIVISION','SQUARES','FRACTIONS','SHORTCUTS'];
?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Tunnel Tricks</h2>
    <p class="text-muted"><?= count($tricks) ?> tricks</p>
  </div>
  <a href="<?= ADMIN_URL ?>/tricks/add.php" class="btn btn-primary">
    <i class="fas fa-plus"></i> Add Trick
  </a>
</div>

<!-- Category Filter -->
<div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:20px">
  <a href="?category=" style="padding:8px 14px;border-radius:10px;font-size:12px;font-weight:600;text-decoration:none;border:1px solid <?= !$category?'var(--cyan)':'var(--border)' ?>;color:<?= !$category?'var(--cyan)':'var(--muted)' ?>;background:var(--card)">
    All
  </a>
  <?php foreach ($cats as $cat): ?>
  <a href="?category=<?= $cat ?>"
    style="padding:8px 14px;border-radius:10px;font-size:12px;font-weight:600;text-decoration:none;border:1px solid <?= $category===$cat?'var(--cyan)':'var(--border)' ?>;color:<?= $category===$cat?'var(--cyan)':'var(--muted)' ?>;background:var(--card)">
    <?= ucfirst(strtolower($cat)) ?>
  </a>
  <?php endforeach; ?>
</div>

<!-- Search -->
<div class="card mb-20">
  <form method="GET" style="display:flex;gap:12px">
    <input type="hidden" name="category" value="<?= htmlspecialchars($category) ?>">
    <div style="flex:1;position:relative">
      <input type="text" name="search" class="form-input"
        placeholder="Search trick title..."
        value="<?= htmlspecialchars($search) ?>"
        style="padding-left:38px">
      <i class="fas fa-search" style="position:absolute;left:12px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:13px"></i>
    </div>
    <button class="btn btn-primary"><i class="fas fa-search"></i> Search</button>
    <a href="<?= ADMIN_URL ?>/tricks/index.php" class="btn btn-secondary"><i class="fas fa-times"></i></a>
  </form>
</div>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Ch#</th>
          <th>Title</th>
          <th>Category</th>
          <th>Difficulty</th>
          <th>Content</th>
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($tricks)): ?>
        <tr><td colspan="7" style="text-align:center;padding:40px;color:var(--muted)">
          <i class="fas fa-bolt" style="font-size:32px;display:block;margin-bottom:10px;opacity:0.3"></i>
          No tricks yet. <a href="<?= ADMIN_URL ?>/tricks/add.php" style="color:var(--cyan)">Add one!</a>
        </td></tr>
        <?php else: ?>
        <?php foreach ($tricks as $t): ?>
        <tr>
          <td>
            <span style="font-family:'Space Grotesk',sans-serif;font-weight:700;color:var(--cyan)">
              <?= str_pad($t['chapter_number'],2,'0',STR_PAD_LEFT) ?>
            </span>
          </td>
          <td>
            <div style="font-weight:600;color:var(--text);font-size:13px">
              <?= htmlspecialchars($t['title']) ?>
              <?php if ($t['is_new']): ?>
              <span class="badge badge-success" style="margin-left:6px;font-size:9px">NEW</span>
              <?php endif; ?>
            </div>
            <?php if ($t['subtitle']): ?>
            <div style="font-size:11px;color:var(--muted)"><?= htmlspecialchars(mb_substr($t['subtitle'],0,50)) ?></div>
            <?php endif; ?>
          </td>
          <td>
            <span class="badge badge-cyan"><?= ucfirst(strtolower($t['category'])) ?></span>
          </td>
          <td>
            <?php $d=['Beginner'=>'badge-success','Intermediate'=>'badge-warning','Advanced'=>'badge-error']; ?>
            <span class="badge <?= $d[$t['difficulty']]??'badge-cyan' ?>"><?= $t['difficulty'] ?></span>
          </td>
          <td>
            <div style="display:flex;gap:6px">
              <?php if ($t['has_video']): ?>
              <span style="font-size:11px;background:rgba(239,68,68,0.1);color:#F87171;padding:2px 8px;border-radius:6px">
                <i class="fab fa-youtube"></i> Video
              </span>
              <?php endif; ?>
              <?php if ($t['has_article']): ?>
              <span style="font-size:11px;background:rgba(0,229,255,0.1);color:var(--cyan);padding:2px 8px;border-radius:6px">
                <i class="fas fa-file-alt"></i> Article
              </span>
              <?php endif; ?>
            </div>
          </td>
          <td>
            <?php if ($t['is_active']): ?>
            <span class="badge badge-success"><i class="fas fa-check"></i> Active</span>
            <?php else: ?>
            <span class="badge badge-error"><i class="fas fa-times"></i> Hidden</span>
            <?php endif; ?>
          </td>
          <td>
            <div style="display:flex;gap:6px">
              <a href="<?= ADMIN_URL ?>/tricks/edit.php?id=<?= $t['id'] ?>" class="btn btn-secondary btn-sm">
                <i class="fas fa-edit"></i>
              </a>
              <button onclick="deleteTrick(<?= $t['id'] ?>)" class="btn btn-danger btn-sm">
                <i class="fas fa-trash"></i>
              </button>
            </div>
          </td>
        </tr>
        <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<script>
function deleteTrick(id) {
  if (!confirm('Delete this trick permanently?')) return;
  fetch('delete.php', {
    method:'POST',
    headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:'id='+id
  }).then(r=>r.json()).then(d=>{ if(d.success) location.reload(); else alert(d.message); });
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>