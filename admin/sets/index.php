<?php
$pageTitle = 'Manage Sets';
require_once dirname(__DIR__) . '/includes/header.php';

$category = $_GET['category'] ?? '';
$where    = $category ? "WHERE s.category = '$category'" : '';

$sets = $pdo->query("
    SELECT s.*,
      (SELECT COUNT(*) FROM questions q WHERE q.set_id = s.id) as q_count
    FROM sets s
    $where
    ORDER BY s.category, s.set_number
")->fetchAll();
?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Sets Management</h2>
    <p class="text-muted"><?= count($sets) ?> sets total</p>
  </div>
  <a href="<?= ADMIN_URL ?>/sets/add.php" class="btn btn-primary">
    <i class="fas fa-plus"></i> Add Set
  </a>
</div>

<!-- Category Filter -->
<div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:20px">
  <?php
  $filters = [
    ''               => ['All Sets',    'var(--cyan)'],
    'mcq'            => ['5000 MCQ',    'var(--cyan)'],
    'simplification' => ['Simplific.',  'var(--success)'],
    'previous_year'  => ['Prev. Year',  'var(--warning)'],
  ];
  foreach ($filters as $val => [$label, $color]):
    $active = $val === $category;
  ?>
  <a href="?category=<?= $val ?>"
    style="padding:8px 14px;border-radius:10px;font-size:12px;font-weight:600;text-decoration:none;border:1px solid <?= $active?$color:'var(--border)' ?>;background:var(--card);color:<?= $active?$color:'var(--muted)' ?>">
    <?= $label ?>
  </a>
  <?php endforeach; ?>
</div>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Set #</th>
          <th>Category</th>
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
          No sets found. <a href="<?= ADMIN_URL ?>/sets/add.php" style="color:var(--cyan)">Add one!</a>
        </td></tr>
        <?php else: ?>
        <?php foreach ($sets as $set): ?>
        <tr>
          <td><span style="font-family:'Space Grotesk',sans-serif;font-weight:700;color:var(--cyan)">
            #<?= $set['set_number'] ?>
          </span></td>
          <td>
            <?php $catColors = ['mcq'=>'badge-cyan','simplification'=>'badge-success','previous_year'=>'badge-warning']; ?>
            <span class="badge <?= $catColors[$set['category']] ?? 'badge-cyan' ?>">
              <?= ucfirst(str_replace('_',' ',$set['category'])) ?>
            </span>
          </td>
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
            <span style="font-weight:700;color:<?= $set['q_count'] >= $set['total_questions'] ? 'var(--success)' : 'var(--warning)' ?>">
              <?= $set['q_count'] ?>
            </span>
            <span style="color:var(--muted);font-size:12px">/<?= $set['total_questions'] ?></span>
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
              <a href="<?= ADMIN_URL ?>/sets/edit.php?id=<?= $set['id'] ?>" class="btn btn-secondary btn-sm">
                <i class="fas fa-edit"></i>
              </a>
              <a href="<?= ADMIN_URL ?>/questions/index.php?set_id=<?= $set['id'] ?>" class="btn btn-secondary btn-sm" title="View Questions">
                <i class="fas fa-list"></i>
              </a>
            </div>
          </td>
        </tr>
        <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>