<?php
$pageTitle = 'Questions';
require_once dirname(__DIR__) . '/includes/header.php';

// ── SCOPE: category + (optional) a single set ──
$labels = [
    'mcq'            => 'Practice Sets',
    'simplification' => '500 Simplification',
    'tunnlity'       => 'Test Your Tunnlity',
    'previous_year'  => 'Previous Year',
    'daily_practice' => 'Daily Practice',
];
$cat        = $_GET['cat'] ?? ($_GET['category'] ?? '');
if ($cat !== '' && !isset($labels[$cat])) $cat = '';
$setId      = intval($_GET['set_id'] ?? 0);
// Return URL — when we came from an exam's "Sets" page, go back THERE.
$ret = $_GET['ret'] ?? '';
if ($ret !== '' && strpos($ret, 'manage_sets.php') === false) $ret = '';
$difficulty = $_GET['difficulty'] ?? '';
$search     = $_GET['search']     ?? '';
$page       = max(1, intval($_GET['page'] ?? 1));
$perPage    = 20;
$offset     = ($page - 1) * $perPage;

// Lookup the set we are scoped to (for header + "add" defaults)
$setRow = null;
if ($setId) {
    $s = $pdo->prepare("SELECT * FROM sets WHERE id = ?");
    $s->execute([$setId]);
    $setRow = $s->fetch();
    if ($setRow && $cat === '') $cat = $setRow['category'];
}

// ── BUILD QUERY ──
$where  = ['1=1'];
$params = [];
if ($cat)        { $where[] = 'q.category = ?'; $params[] = $cat; }
if ($setId)      { $where[] = 'q.set_id = ?';   $params[] = $setId; }
if ($difficulty) { $where[] = 'q.difficulty = ?'; $params[] = $difficulty; }
if ($search)     { $where[] = 'q.question_text LIKE ?'; $params[] = "%$search%"; }
$whereSQL = implode(' AND ', $where);

$totalStmt = $pdo->prepare("SELECT COUNT(*) FROM questions q WHERE $whereSQL");
$totalStmt->execute($params);
$total = $totalStmt->fetchColumn();
$totalPages = max(1, ceil($total / $perPage));

$listParams = $params;
$listParams[] = $perPage;
$listParams[] = $offset;
$questions = $pdo->prepare("
    SELECT q.*, s.title as set_title, s.set_number
    FROM questions q
    LEFT JOIN sets s ON q.set_id = s.id
    WHERE $whereSQL
    ORDER BY q.id DESC
    LIMIT ? OFFSET ?
");
$questions->execute($listParams);
$questions = $questions->fetchAll();

// Build query-string suffix that preserves scope across links/pagination
$scopeQS = '';
if ($cat)   $scopeQS .= '&cat=' . urlencode($cat);
if ($setId) $scopeQS .= '&set_id=' . $setId;
if ($ret)   $scopeQS .= '&ret=' . urlencode($ret);

$sectionName = $cat !== '' ? ($labels[$cat] ?? ucfirst($cat)) : 'All';
?>

<!-- ── HEADER ── -->
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700;color:var(--text)">
      <?= htmlspecialchars($sectionName) ?> — Questions
    </h2>
    <p class="text-muted">
      <?php if ($setRow): ?>
        Set #<?= $setRow['set_number'] ?><?= $setRow['title'] ? ' · ' . htmlspecialchars($setRow['title']) : '' ?>
        · <?= number_format($total) ?> / 10 questions
      <?php else: ?>
        <?= number_format($total) ?> questions total
      <?php endif; ?>
    </p>
  </div>
  <div style="display:flex;gap:10px;flex-wrap:wrap">
    <?php if ($ret !== ''): ?>
    <a href="<?= htmlspecialchars($ret) ?>" class="btn btn-secondary">
      <i class="fas fa-arrow-left"></i> Back to Sets
    </a>
    <?php elseif ($cat !== ''): ?>
    <a href="<?= ADMIN_URL ?>/sets/index.php?cat=<?= urlencode($cat) ?>" class="btn btn-secondary">
      <i class="fas fa-arrow-left"></i> Back to Sets
    </a>
    <?php endif; ?>
    <a href="<?= ADMIN_URL ?>/questions/import_csv.php?<?= ltrim($scopeQS, '&') ?>" class="btn btn-secondary">
      <i class="fas fa-file-csv"></i> Import CSV
    </a>
    <a href="<?= ADMIN_URL ?>/questions/add.php?<?= ltrim($scopeQS, '&') ?>" class="btn btn-primary">
      <i class="fas fa-plus"></i> Add Question
    </a>
  </div>
</div>

<?php if ($cat === '' && !$setId): ?>
<!-- Legacy "All" view keeps category chips -->
<div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:20px">
  <?php
  $counts = $pdo->query("SELECT category, COUNT(*) as cnt FROM questions GROUP BY category")->fetchAll(PDO::FETCH_KEY_PAIR);
  $cats = [
    'all'            => ['label'=>'All',           'color'=>'var(--cyan)'],
    'mcq'            => ['label'=>'Practice',       'color'=>'var(--cyan)'],
    'simplification' => ['label'=>'500 Simplif.',   'color'=>'var(--success)'],
    'tunnlity'       => ['label'=>'Tunnlity',       'color'=>'var(--cyan)'],
    'previous_year'  => ['label'=>'Previous Year',  'color'=>'var(--warning)'],
    'daily_practice' => ['label'=>'Daily Practice', 'color'=>'var(--purple)'],
  ];
  foreach ($cats as $key => $c):
    $active = ($key === 'all' && !$cat) || $key === $cat;
    $cnt    = $key === 'all' ? array_sum($counts) : ($counts[$key] ?? 0);
  ?>
  <a href="?<?= $key === 'all' ? '' : 'cat=' . $key ?>"
     style="display:inline-flex;align-items:center;gap:7px;padding:8px 14px;border-radius:10px;font-size:12px;font-weight:600;text-decoration:none;border:1px solid <?= $active ? $c['color'] : 'var(--border)' ?>;background:<?= $active ? 'rgba(0,0,0,0.3)' : 'var(--card)' ?>;color:<?= $active ? $c['color'] : 'var(--muted)' ?>">
    <?= $c['label'] ?>
    <span style="background:rgba(255,255,255,0.1);padding:1px 7px;border-radius:10px"><?= number_format($cnt) ?></span>
  </a>
  <?php endforeach; ?>
</div>
<?php endif; ?>

<!-- ── SEARCH + FILTER ── -->
<div class="card mb-20">
  <form method="GET" style="display:flex;gap:12px;flex-wrap:wrap;align-items:flex-end">
    <?php if ($cat): ?><input type="hidden" name="cat" value="<?= htmlspecialchars($cat) ?>"><?php endif; ?>
    <?php if ($setId): ?><input type="hidden" name="set_id" value="<?= $setId ?>"><?php endif; ?>
    <div style="flex:1;min-width:200px">
      <label class="form-label">Search Question</label>
      <div style="position:relative">
        <input type="text" name="search" class="form-input" placeholder="Type to search..."
          value="<?= htmlspecialchars($search) ?>" style="padding-left:38px">
        <i class="fas fa-search" style="position:absolute;left:12px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:13px"></i>
      </div>
    </div>
    <div>
      <label class="form-label">Difficulty</label>
      <select name="difficulty" class="form-select" style="width:140px">
        <option value="">All</option>
        <option value="easy"   <?= $difficulty==='easy'   ? 'selected':'' ?>>Easy</option>
        <option value="medium" <?= $difficulty==='medium' ? 'selected':'' ?>>Medium</option>
        <option value="hard"   <?= $difficulty==='hard'   ? 'selected':'' ?>>Hard</option>
      </select>
    </div>
    <div style="display:flex;gap:8px">
      <button class="btn btn-primary"><i class="fas fa-search"></i> Filter</button>
      <a href="<?= ADMIN_URL ?>/questions/index.php?<?= ltrim($scopeQS, '&') ?>" class="btn btn-secondary"><i class="fas fa-times"></i></a>
    </div>
  </form>
</div>

<!-- ── TABLE ── -->
<div class="card">
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Question</th>
          <?php if ($cat === ''): ?><th>Category</th><?php endif; ?>
          <th>Set</th>
          <th>Difficulty</th>
          <th>Answer</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($questions)): ?>
        <tr>
          <td colspan="7" style="text-align:center;padding:40px;color:var(--muted)">
            <i class="fas fa-inbox" style="font-size:32px;display:block;margin-bottom:10px;opacity:0.3"></i>
            No questions yet.
            <a href="<?= ADMIN_URL ?>/questions/add.php?<?= ltrim($scopeQS, '&') ?>" style="color:var(--cyan)">Add one</a>
            or <a href="<?= ADMIN_URL ?>/questions/import_csv.php?<?= ltrim($scopeQS, '&') ?>" style="color:var(--cyan)">import a CSV</a>.
          </td>
        </tr>
        <?php else: ?>
        <?php foreach ($questions as $i => $q): ?>
        <tr>
          <td style="color:var(--muted);font-size:12px"><?= $offset + $i + 1 ?></td>
          <td style="max-width:350px">
            <div style="font-size:13px;color:var(--text2);line-height:1.4;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:350px"
              title="<?= htmlspecialchars($q['question_text']) ?>">
              <?= htmlspecialchars(mb_substr($q['question_text'], 0, 80)) ?><?= mb_strlen($q['question_text']) > 80 ? '...' : '' ?>
            </div>
          </td>
          <?php if ($cat === ''): ?>
          <td>
            <?php $catColors = ['mcq'=>'badge-cyan','simplification'=>'badge-success','previous_year'=>'badge-warning','tunnlity'=>'badge-cyan','daily_practice'=>'badge-purple']; ?>
            <span class="badge <?= $catColors[$q['category']] ?? 'badge-cyan' ?>"><?= ucfirst(str_replace('_',' ',$q['category'])) ?></span>
          </td>
          <?php endif; ?>
          <td style="color:var(--muted);font-size:12px">
            <?= $q['set_number'] ? 'Set #' . $q['set_number'] : 'Set ' . $q['set_id'] ?>
          </td>
          <td>
            <?php $diffColors = ['easy'=>'badge-success','medium'=>'badge-warning','hard'=>'badge-error']; ?>
            <span class="badge <?= $diffColors[$q['difficulty']] ?? 'badge-cyan' ?>"><?= ucfirst($q['difficulty']) ?></span>
          </td>
          <td>
            <span style="display:inline-flex;align-items:center;justify-content:center;width:28px;height:28px;background:rgba(16,185,129,0.15);border-radius:8px;font-weight:700;color:var(--success);font-size:13px">
              <?= $q['correct_option'] ?>
            </span>
          </td>
          <td>
            <div style="display:flex;gap:6px">
              <a href="<?= ADMIN_URL ?>/questions/edit.php?id=<?= $q['id'] ?><?= $scopeQS ?>" class="btn btn-secondary btn-sm" title="Edit">
                <i class="fas fa-edit"></i>
              </a>
              <button onclick="deleteQuestion(<?= $q['id'] ?>)" class="btn btn-danger btn-sm" title="Delete">
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

  <?php if ($totalPages > 1): ?>
  <div style="display:flex;align-items:center;justify-content:space-between;padding:16px 0 0;flex-wrap:wrap;gap:12px">
    <div style="font-size:13px;color:var(--muted)">
      Showing <?= $offset+1 ?>–<?= min($offset+$perPage, $total) ?> of <?= number_format($total) ?>
    </div>
    <div style="display:flex;gap:6px">
      <?php if ($page > 1): ?>
      <a href="?page=<?= $page-1 ?><?= $scopeQS ?>&search=<?= urlencode($search) ?>&difficulty=<?= urlencode($difficulty) ?>" class="btn btn-secondary btn-sm"><i class="fas fa-chevron-left"></i></a>
      <?php endif; ?>
      <?php for ($p = max(1,$page-2); $p <= min($totalPages,$page+2); $p++): ?>
      <a href="?page=<?= $p ?><?= $scopeQS ?>&search=<?= urlencode($search) ?>&difficulty=<?= urlencode($difficulty) ?>" class="btn <?= $p==$page ? 'btn-primary' : 'btn-secondary' ?> btn-sm"><?= $p ?></a>
      <?php endfor; ?>
      <?php if ($page < $totalPages): ?>
      <a href="?page=<?= $page+1 ?><?= $scopeQS ?>&search=<?= urlencode($search) ?>&difficulty=<?= urlencode($difficulty) ?>" class="btn btn-secondary btn-sm"><i class="fas fa-chevron-right"></i></a>
      <?php endif; ?>
    </div>
  </div>
  <?php endif; ?>
</div>

<script>
function deleteQuestion(id) {
  if (!confirm('Delete this question permanently?')) return;
  fetch('delete.php', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'id=' + id
  })
  .then(r => r.json())
  .then(d => { if (d.success) location.reload(); else alert('Error: ' + (d.message || 'Could not delete')); })
  .catch(() => alert('Network error — could not delete.'));
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
