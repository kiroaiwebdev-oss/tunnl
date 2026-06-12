<?php
$pageTitle = 'Manage Sets';
require_once dirname(__DIR__) . '/includes/header.php';

// Section is scoped by category. ?cat=mcq|simplification|tunnlity|previous_year
$labels = [
    'mcq'            => ['Practice Sets',       'fa-layer-group', 'var(--cyan)'],
    'simplification' => ['500 Simplification',  'fa-calculator',  'var(--success)'],
    'tunnlity'       => ['Test Your Tunnlity',  'fa-bolt',        'var(--cyan)'],
    'previous_year'  => ['Previous Year',       'fa-archive',     'var(--warning)'],
];

$cat = $_GET['cat'] ?? ($_GET['category'] ?? '');
if ($cat !== '' && !isset($labels[$cat])) $cat = '';   // ignore unknown
$catQS = $cat !== '' ? '&cat=' . urlencode($cat) : '';

if ($cat !== '') {
    [$sectionName, $sectionIcon, $sectionColor] = $labels[$cat];
    $stmt = $pdo->prepare("
        SELECT s.*,
          (SELECT COUNT(*) FROM questions q WHERE q.set_id = s.id) as q_count
        FROM sets s
        WHERE s.category = ?
        ORDER BY s.set_number
    ");
    $stmt->execute([$cat]);
    $sets = $stmt->fetchAll();
} else {
    $sectionName = 'All Sets'; $sectionIcon = 'fa-layer-group'; $sectionColor = 'var(--cyan)';
    $sets = $pdo->query("
        SELECT s.*,
          (SELECT COUNT(*) FROM questions q WHERE q.set_id = s.id) as q_count
        FROM sets s
        ORDER BY s.category, s.set_number
    ")->fetchAll();
}
?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">
      <i class="fas <?= $sectionIcon ?>" style="color:<?= $sectionColor ?>"></i>
      <?= htmlspecialchars($sectionName) ?>
    </h2>
    <p class="text-muted"><?= count($sets) ?> set<?= count($sets) === 1 ? '' : 's' ?> &middot; every set is a 10-question test</p>
  </div>
  <div style="display:flex;gap:10px;flex-wrap:wrap">
    <a href="<?= ADMIN_URL ?>/questions/import_csv.php?<?= ltrim($catQS, '&') ?>" class="btn btn-secondary">
      <i class="fas fa-file-csv"></i> Import CSV
    </a>
    <a href="<?= ADMIN_URL ?>/sets/add.php?<?= ltrim($catQS, '&') ?>" class="btn btn-primary">
      <i class="fas fa-plus"></i> Add Set
    </a>
  </div>
</div>

<?php if (isset($_GET['added']) || isset($_GET['updated']) || isset($_GET['deleted'])): ?>
<div style="background:rgba(16,185,129,0.12);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:12px 16px;border-radius:10px;margin-bottom:20px;font-size:13px">
  ✅ <?= isset($_GET['added']) ? 'Set added!' : (isset($_GET['updated']) ? 'Set updated!' : 'Set deleted!') ?>
</div>
<?php endif; ?>

<?php if ($cat === ''): ?>
<!-- Legacy "All" view keeps category chips -->
<div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:20px">
  <?php
  $filters = [
    ''               => ['All Sets',   'var(--cyan)'],
    'mcq'            => ['Practice',    'var(--cyan)'],
    'simplification' => ['Simplific.',  'var(--success)'],
    'tunnlity'       => ['Tunnlity',    'var(--cyan)'],
    'previous_year'  => ['Prev. Year',  'var(--warning)'],
  ];
  foreach ($filters as $val => [$label, $color]):
    $active = $val === $cat;
  ?>
  <a href="?cat=<?= $val ?>"
    style="padding:8px 14px;border-radius:10px;font-size:12px;font-weight:600;text-decoration:none;border:1px solid <?= $active?$color:'var(--border)' ?>;background:var(--card);color:<?= $active?$color:'var(--muted)' ?>">
    <?= $label ?>
  </a>
  <?php endforeach; ?>
</div>
<?php endif; ?>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Set #</th>
          <?php if ($cat === ''): ?><th>Category</th><?php endif; ?>
          <th>Title</th>
          <th>Level</th>
          <th>Questions</th>
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($sets)): ?>
        <tr><td colspan="7" style="text-align:center;padding:40px;color:var(--muted)">
          <i class="fas fa-inbox" style="font-size:32px;display:block;margin-bottom:10px;opacity:0.3"></i>
          No sets here yet. <a href="<?= ADMIN_URL ?>/sets/add.php?<?= ltrim($catQS, '&') ?>" style="color:var(--cyan)">Add one!</a>
        </td></tr>
        <?php else: ?>
        <?php foreach ($sets as $set): ?>
        <tr>
          <td><span style="font-family:'Space Grotesk',sans-serif;font-weight:700;color:var(--cyan)">
            #<?= $set['set_number'] ?>
          </span></td>
          <?php if ($cat === ''): ?>
          <td>
            <?php $catColors = ['mcq'=>'badge-cyan','simplification'=>'badge-success','previous_year'=>'badge-warning','tunnlity'=>'badge-cyan']; ?>
            <span class="badge <?= $catColors[$set['category']] ?? 'badge-cyan' ?>">
              <?= ucfirst(str_replace('_',' ',$set['category'])) ?>
            </span>
          </td>
          <?php endif; ?>
          <td style="font-weight:500;color:var(--text)">
            <?= htmlspecialchars($set['title'] ?: 'Set '.$set['set_number']) ?>
            <?php if ($set['exam_name']): ?>
            <div style="font-size:11px;color:var(--muted)"><?= htmlspecialchars($set['exam_name']) ?></div>
            <?php endif; ?>
          </td>
          <td>
            <?php $lvlColors = ['beginner'=>'badge-success','intermediate'=>'badge-warning','advanced'=>'badge-error','expert'=>'badge-purple']; ?>
            <span class="badge <?= $lvlColors[$set['level']] ?? 'badge-cyan' ?>">
              <?= ucfirst($set['level']) ?>
            </span>
          </td>
          <td>
            <span style="font-weight:700;color:<?= $set['q_count'] >= 10 ? 'var(--success)' : 'var(--warning)' ?>">
              <?= $set['q_count'] ?>
            </span>
            <span style="color:var(--muted);font-size:12px">/10</span>
          </td>
          <td>
            <?php if ($set['is_locked']): ?>
            <span class="badge badge-error"><i class="fas fa-lock"></i> Locked</span>
            <?php else: ?>
            <span class="badge badge-success"><i class="fas fa-unlock"></i> Open</span>
            <?php endif; ?>
          </td>
          <td>
            <div style="display:flex;gap:6px">
              <a href="<?= ADMIN_URL ?>/questions/index.php?cat=<?= urlencode($set['category']) ?>&set_id=<?= $set['id'] ?>" class="btn btn-primary btn-sm" title="Manage Questions">
                <i class="fas fa-list-ol"></i> Questions
              </a>
              <a href="<?= ADMIN_URL ?>/questions/import_csv.php?cat=<?= urlencode($set['category']) ?>&set_id=<?= $set['id'] ?>" class="btn btn-secondary btn-sm" title="Import CSV into this set">
                <i class="fas fa-file-csv"></i>
              </a>
              <a href="<?= ADMIN_URL ?>/sets/edit.php?id=<?= $set['id'] ?><?= $catQS ?>" class="btn btn-secondary btn-sm" title="Edit Set">
                <i class="fas fa-edit"></i>
              </a>
              <button onclick="deleteSet(<?= $set['id'] ?>)" class="btn btn-danger btn-sm" title="Delete Set">
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
function deleteSet(id) {
  if (!confirm('Delete this set AND all its questions? This cannot be undone.')) return;
  fetch('delete.php', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'id=' + id
  })
  .then(r => r.json())
  .then(d => { if (d.success) location.reload(); else alert('Error: ' + (d.message || 'Could not delete')); })
  .catch(() => alert('Network error.'));
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
