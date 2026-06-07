<?php
$pageTitle = 'Questions';
require_once dirname(__DIR__) . '/includes/header.php';

// ── FILTERS
$category   = $_GET['category']   ?? '';
$difficulty = $_GET['difficulty'] ?? '';
$search     = $_GET['search']     ?? '';
$page       = max(1, intval($_GET['page'] ?? 1));
$perPage    = 20;
$offset     = ($page - 1) * $perPage;

// ── BUILD QUERY
$where  = ['1=1'];
$params = [];

if ($category) {
    $where[]  = 'q.category = ?';
    $params[] = $category;
}
if ($difficulty) {
    $where[]  = 'q.difficulty = ?';
    $params[] = $difficulty;
}
if ($search) {
    $where[]  = 'q.question_text LIKE ?';
    $params[] = "%$search%";
}

$whereSQL = implode(' AND ', $where);

$totalStmt = $pdo->prepare("SELECT COUNT(*) FROM questions q WHERE $whereSQL");
$totalStmt->execute($params);
$total = $totalStmt->fetchColumn();
$totalPages = ceil($total / $perPage);

$params[] = $perPage;
$params[] = $offset;

$questions = $pdo->prepare("
    SELECT q.*, s.title as set_title
    FROM questions q
    LEFT JOIN sets s ON q.set_id = s.id
    WHERE $whereSQL
    ORDER BY q.id DESC
    LIMIT ? OFFSET ?
");
$questions->execute($params);
$questions = $questions->fetchAll();

// ── CATEGORY COUNTS
$counts = $pdo->query("
    SELECT category, COUNT(*) as cnt
    FROM questions GROUP BY category
")->fetchAll(PDO::FETCH_KEY_PAIR);
?>

<!-- ── HEADER ── -->
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700;color:var(--text)">
      Questions Bank
    </h2>
    <p class="text-muted"><?= number_format($total) ?> questions total</p>
  </div>
  <div style="display:flex;gap:10px">
    <a href="<?= ADMIN_URL ?>/questions/import_csv.php" class="btn btn-secondary">
      <i class="fas fa-file-csv"></i> Import CSV
    </a>
    <a href="<?= ADMIN_URL ?>/questions/add.php" class="btn btn-primary">
      <i class="fas fa-plus"></i> Add Question
    </a>
  </div>
</div>

<!-- ── CATEGORY CHIPS ── -->
<div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:20px">
  <?php
  $cats = [
    'all'            => ['label'=>'All',           'icon'=>'fas fa-list',        'color'=>'var(--cyan)'],
    'mcq'            => ['label'=>'5000 MCQ',       'icon'=>'fas fa-question',    'color'=>'var(--cyan)'],
    'simplification' => ['label'=>'500 Simplif.',   'icon'=>'fas fa-calculator',  'color'=>'var(--success)'],
    'previous_year'  => ['label'=>'Previous Year',  'icon'=>'fas fa-history',     'color'=>'var(--warning)'],
    'tunnlity'       => ['label'=>'Tunnlity',       'icon'=>'fas fa-bolt',        'color'=>'var(--cyan)'],
    'daily_practice' => ['label'=>'Daily Practice', 'icon'=>'fas fa-calendar',    'color'=>'var(--purple)'],
  ];
  foreach ($cats as $key => $cat):
    $active = ($key === 'all' && !$category) || $key === $category;
    $cnt    = $key === 'all' ? array_sum($counts) : ($counts[$key] ?? 0);
  ?>
  <a href="?category=<?= $key === 'all' ? '' : $key ?>"
     style="display:inline-flex;align-items:center;gap:7px;padding:8px 14px;border-radius:10px;font-size:12px;font-weight:600;text-decoration:none;border:1px solid <?= $active ? $cat['color'] : 'var(--border)' ?>;background:<?= $active ? 'rgba(0,0,0,0.3)' : 'var(--card)' ?>;color:<?= $active ? $cat['color'] : 'var(--muted)' ?>">
    <i class="<?= $cat['icon'] ?>"></i>
    <?= $cat['label'] ?>
    <span style="background:rgba(255,255,255,0.1);padding:1px 7px;border-radius:10px">
      <?= number_format($cnt) ?>
    </span>
  </a>
  <?php endforeach; ?>
</div>

<!-- ── SEARCH + FILTER ── -->
<div class="card mb-20">
  <form method="GET" style="display:flex;gap:12px;flex-wrap:wrap;align-items:flex-end">
    <input type="hidden" name="category" value="<?= htmlspecialchars($category) ?>">
    <div style="flex:1;min-width:200px">
      <label class="form-label">Search Question</label>
      <div style="position:relative">
        <input type="text" name="search" class="form-input"
          placeholder="Type to search..."
          value="<?= htmlspecialchars($search) ?>"
          style="padding-left:38px">
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
      <a href="<?= ADMIN_URL ?>/questions/index.php" class="btn btn-secondary"><i class="fas fa-times"></i></a>
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
          <th>Category</th>
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
            No questions found
          </td>
        </tr>
        <?php else: ?>
        <?php foreach ($questions as $i => $q): ?>
        <tr>
          <td style="color:var(--muted);font-size:12px"><?= $offset + $i + 1 ?></td>
          <td style="max-width:350px">
            <div style="font-size:13px;color:var(--text2);line-height:1.4;
              white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:350px"
              title="<?= htmlspecialchars($q['question_text']) ?>">
              <?= htmlspecialchars(mb_substr($q['question_text'], 0, 80)) ?>
              <?= mb_strlen($q['question_text']) > 80 ? '...' : '' ?>
            </div>
          </td>
          <td>
            <?php
            $catColors = [
              'mcq'            => 'badge-cyan',
              'simplification' => 'badge-success',
              'previous_year'  => 'badge-warning',
              'tunnlity'       => 'badge-cyan',
              'daily_practice' => 'badge-purple',
            ];
            ?>
            <span class="badge <?= $catColors[$q['category']] ?? 'badge-cyan' ?>">
              <?= ucfirst(str_replace('_',' ',$q['category'])) ?>
            </span>
          </td>
          <td style="color:var(--muted);font-size:12px">
            Set <?= $q['set_id'] ?>
          </td>
          <td>
            <?php
            $diffColors = ['easy'=>'badge-success','medium'=>'badge-warning','hard'=>'badge-error'];
            ?>
            <span class="badge <?= $diffColors[$q['difficulty']] ?? 'badge-cyan' ?>">
              <?= ucfirst($q['difficulty']) ?>
            </span>
          </td>
          <td>
            <span style="display:inline-flex;align-items:center;justify-content:center;
              width:28px;height:28px;background:rgba(16,185,129,0.15);
              border-radius:8px;font-weight:700;color:var(--success);font-size:13px">
              <?= $q['correct_option'] ?>
            </span>
          </td>
          <td>
            <div style="display:flex;gap:6px">
              <a href="<?= ADMIN_URL ?>/questions/edit.php?id=<?= $q['id'] ?>"
                 class="btn btn-secondary btn-sm" title="Edit">
                <i class="fas fa-edit"></i>
              </a>
              <button onclick="deleteQuestion(<?= $q['id'] ?>)"
                class="btn btn-danger btn-sm" title="Delete">
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

  <!-- Pagination -->
  <?php if ($totalPages > 1): ?>
  <div style="display:flex;align-items:center;justify-content:space-between;padding:16px 0 0;flex-wrap:wrap;gap:12px">
    <div style="font-size:13px;color:var(--muted)">
      Showing <?= $offset+1 ?>–<?= min($offset+$perPage, $total) ?> of <?= number_format($total) ?>
    </div>
    <div style="display:flex;gap:6px">
      <?php if ($page > 1): ?>
      <a href="?page=<?= $page-1 ?>&category=<?= $category ?>&search=<?= urlencode($search) ?>"
         class="btn btn-secondary btn-sm"><i class="fas fa-chevron-left"></i></a>
      <?php endif; ?>

      <?php for ($p = max(1,$page-2); $p <= min($totalPages,$page+2); $p++): ?>
      <a href="?page=<?= $p ?>&category=<?= $category ?>&search=<?= urlencode($search) ?>"
         class="btn <?= $p==$page ? 'btn-primary' : 'btn-secondary' ?> btn-sm"><?= $p ?></a>
      <?php endfor; ?>

      <?php if ($page < $totalPages): ?>
      <a href="?page=<?= $page+1 ?>&category=<?= $category ?>&search=<?= urlencode($search) ?>"
         class="btn btn-secondary btn-sm"><i class="fas fa-chevron-right"></i></a>
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
  .then(d => {
    if (d.success) location.reload();
    else alert('Error: ' + (d.message || 'Could not delete'));
  })
  .catch(() => alert('Network error — could not delete.'));
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>