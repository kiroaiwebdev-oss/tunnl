<?php
$pageTitle = 'Transactions';
require_once dirname(__DIR__) . '/includes/header.php';

$filter = $_GET['filter'] ?? '';
$page   = max(1, intval($_GET['page'] ?? 1));
$perPage= 25;
$offset = ($page - 1) * $perPage;

$where  = ['1=1'];
$params = [];
if ($filter === 'success') { $where[] = 't.status="success"'; }
if ($filter === 'failed')  { $where[] = 't.status="failed"'; }
if ($filter === 'manual')  { $where[] = 't.type="manual"'; }
$whereSQL = implode(' AND ', $where);

$total      = $pdo->prepare("SELECT COUNT(*) FROM transactions t WHERE $whereSQL");
$total->execute($params);
$total      = $total->fetchColumn();
$totalPages = ceil($total / $perPage);

$params[] = $perPage;
$params[] = $offset;

$txns = $pdo->prepare("
    SELECT t.*, u.name, u.phone
    FROM transactions t
    LEFT JOIN users u ON t.user_id = u.id
    WHERE $whereSQL
    ORDER BY t.created_at DESC
    LIMIT ? OFFSET ?
");
$txns->execute($params);
$txns = $txns->fetchAll();

// Revenue
$totalRev   = $pdo->query("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE status='success'")->fetchColumn();
$razorpayRev= $pdo->query("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE status='success' AND type='razorpay'")->fetchColumn();
$manualRev  = $pdo->query("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE status='success' AND type='manual'")->fetchColumn();
?>

<!-- Revenue -->
<div class="stats-grid" style="grid-template-columns:repeat(3,1fr);margin-bottom:24px">
  <div class="stat-card" style="--accent-color:var(--success);--accent-bg:rgba(16,185,129,0.1)">
    <div class="stat-icon"><i class="fas fa-rupee-sign"></i></div>
    <div class="stat-value">₹<?= number_format($totalRev) ?></div>
    <div class="stat-label">Total Revenue</div>
  </div>
  <div class="stat-card" style="--accent-color:var(--cyan);--accent-bg:rgba(0,229,255,0.1)">
    <div class="stat-icon"><i class="fas fa-credit-card"></i></div>
    <div class="stat-value">₹<?= number_format($razorpayRev) ?></div>
    <div class="stat-label">Razorpay</div>
  </div>
  <div class="stat-card" style="--accent-color:var(--purple);--accent-bg:rgba(139,92,246,0.1)">
    <div class="stat-icon"><i class="fas fa-hand-holding-usd"></i></div>
    <div class="stat-value">₹<?= number_format($manualRev) ?></div>
    <div class="stat-label">Manual</div>
  </div>
</div>

<!-- Header -->
<div class="flex-between mb-20">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Transactions</h2>
    <p class="text-muted"><?= number_format($total) ?> total transactions</p>
  </div>
  <!-- Filter -->
  <div style="display:flex;gap:6px">
    <?php foreach ([
      [''         , 'All'],
      ['success'  , '✅ Success'],
      ['failed'   , '❌ Failed'],
      ['manual'   , '👤 Manual'],
    ] as [$val,$label]): ?>
    <a href="?filter=<?= $val ?>"
       class="btn <?= $filter===$val?'btn-primary':'btn-secondary' ?> btn-sm">
      <?= $label ?>
    </a>
    <?php endforeach; ?>
  </div>
</div>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Order ID</th>
          <th>User</th>
          <th>Amount</th>
          <th>Type</th>
          <th>Status</th>
          <th>Note</th>
          <th>Date</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($txns)): ?>
        <tr><td colspan="7" style="text-align:center;padding:40px;color:var(--muted)">
          <i class="fas fa-receipt" style="font-size:32px;display:block;margin-bottom:10px;opacity:0.3"></i>
          No transactions found
        </td></tr>
        <?php else: ?>
        <?php foreach ($txns as $t): ?>
        <tr>
          <td>
            <code style="font-size:11px;color:var(--cyan);background:rgba(0,229,255,0.08);
              padding:2px 8px;border-radius:6px">
              <?= htmlspecialchars($t['razorpay_order_id'] ?: 'MANUAL-'.$t['id']) ?>
            </code>
          </td>
          <td>
            <div style="font-weight:600;color:var(--text);font-size:13px">
              <?= htmlspecialchars($t['name'] ?: 'Unknown') ?>
            </div>
            <div style="font-size:11px;color:var(--muted)"><?= $t['phone'] ?></div>
          </td>
          <td>
            <span style="font-weight:700;font-family:'Space Grotesk',sans-serif;
              color:<?= $t['status']==='success'?'var(--success)':'var(--muted)' ?>;font-size:15px">
              ₹<?= number_format($t['amount']) ?>
            </span>
          </td>
          <td>
            <?php
            $typeIcons = [
              'razorpay'=>['fab fa-cc-visa','var(--cyan)'],
              'manual'  =>['fas fa-user'   ,'var(--purple)'],
              'upi'     =>['fas fa-mobile' ,'var(--success)'],
            ];
            [$icon,$color] = $typeIcons[$t['type']] ?? ['fas fa-circle','var(--muted)'];
            ?>
            <span style="font-size:12px;color:<?= $color ?>">
              <i class="<?= $icon ?>"></i> <?= ucfirst($t['type']) ?>
            </span>
          </td>
          <td>
            <?php
            $sBadge = ['success'=>'badge-success','failed'=>'badge-error','pending'=>'badge-warning'];
            ?>
            <span class="badge <?= $sBadge[$t['status']] ?? 'badge-cyan' ?>">
              <?= ucfirst($t['status']) ?>
            </span>
          </td>
          <td style="font-size:12px;color:var(--muted);max-width:150px">
            <?= htmlspecialchars(mb_substr($t['note'] ?? '',0,40)) ?>
          </td>
          <td style="color:var(--muted);font-size:12px">
            <?= date('d M Y H:i', strtotime($t['created_at'])) ?>
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
      Showing <?= $offset+1 ?>–<?= min($offset+$perPage,$total) ?> of <?= number_format($total) ?>
    </div>
    <div style="display:flex;gap:6px">
      <?php if ($page>1): ?>
      <a href="?page=<?=$page-1?>&filter=<?=$filter?>" class="btn btn-secondary btn-sm">
        <i class="fas fa-chevron-left"></i>
      </a>
      <?php endif; ?>
      <?php for ($p=max(1,$page-2); $p<=min($totalPages,$page+2); $p++): ?>
      <a href="?page=<?=$p?>&filter=<?=$filter?>"
        class="btn <?=$p==$page?'btn-primary':'btn-secondary'?> btn-sm"><?=$p?></a>
      <?php endfor; ?>
      <?php if ($page<$totalPages): ?>
      <a href="?page=<?=$page+1?>&filter=<?=$filter?>" class="btn btn-secondary btn-sm">
        <i class="fas fa-chevron-right"></i>
      </a>
      <?php endif; ?>
    </div>
  </div>
  <?php endif; ?>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>