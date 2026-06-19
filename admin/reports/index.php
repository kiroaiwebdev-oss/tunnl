<?php
// Technical error reports submitted by app users (tech_reports table).
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';

// ── Actions (resolve / reopen / delete) ──
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id     = intval($_POST['id'] ?? 0);
    $action = $_POST['action'] ?? '';
    if ($id > 0) {
        try {
            if ($action === 'resolve') {
                $pdo->prepare("UPDATE tech_reports SET status='resolved' WHERE id=?")->execute([$id]);
            } elseif ($action === 'reopen') {
                $pdo->prepare("UPDATE tech_reports SET status='open' WHERE id=?")->execute([$id]);
            } elseif ($action === 'delete') {
                $pdo->prepare("DELETE FROM tech_reports WHERE id=?")->execute([$id]);
            }
        } catch (Throwable $e) { /* ignore */ }
    }
    header('Location: index.php');
    exit;
}

try {
    $reports = $pdo->query("SELECT * FROM tech_reports ORDER BY created_at DESC, id DESC")->fetchAll();
} catch (Throwable $e) {
    $reports = [];
}
$openCount = 0;
foreach ($reports as $r) { if (($r['status'] ?? 'open') === 'open') $openCount++; }

$pageTitle = 'Technical Reports';
require_once dirname(__DIR__) . '/includes/header.php';
?>

<div class="flex-between mb-24">
  <div>
    <div class="card-title-text" style="font-size:18px;">
      ⚠️ Technical Error Reports
    </div>
    <p class="text-muted" style="margin-top:4px;">
      Issues reported by app users — <?= count($reports) ?> total,
      <?= $openCount ?> open
    </p>
  </div>
</div>

<div class="card">
  <?php if (empty($reports)): ?>
    <div style="text-align:center; padding:40px; color:var(--muted);">
      <i class="fas fa-inbox" style="font-size:32px; opacity:.5;"></i>
      <p style="margin-top:12px;">No technical reports yet.</p>
    </div>
  <?php else: ?>
    <div style="overflow-x:auto;">
      <table class="table" style="width:100%;">
        <thead>
          <tr>
            <th>#</th>
            <th>User</th>
            <th>Message</th>
            <th>App</th>
            <th>When</th>
            <th>Status</th>
            <th style="text-align:right;">Actions</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($reports as $r): ?>
          <?php $isOpen = ($r['status'] ?? 'open') === 'open'; ?>
          <tr>
            <td><?= intval($r['id']) ?></td>
            <td>
              <div style="font-weight:600;">
                <?= htmlspecialchars($r['name'] ?: 'Anonymous') ?>
              </div>
              <div style="font-size:11px; color:var(--muted);">
                <?= htmlspecialchars($r['phone'] ?: '—') ?>
              </div>
            </td>
            <td style="max-width:380px; white-space:pre-wrap;">
              <?= htmlspecialchars($r['message']) ?>
            </td>
            <td style="font-size:11px; color:var(--muted);">
              <?= htmlspecialchars($r['app_version'] ?: '—') ?>
            </td>
            <td style="font-size:11px; color:var(--muted); white-space:nowrap;">
              <?= htmlspecialchars($r['created_at'] ?? '') ?>
            </td>
            <td>
              <span class="badge <?= $isOpen ? 'badge-warning' : 'badge-success' ?>">
                <?= $isOpen ? 'OPEN' : 'RESOLVED' ?>
              </span>
            </td>
            <td style="text-align:right; white-space:nowrap;">
              <form method="POST" style="display:inline;">
                <input type="hidden" name="id" value="<?= intval($r['id']) ?>">
                <?php if ($isOpen): ?>
                  <button name="action" value="resolve" class="btn btn-secondary"
                          style="padding:6px 10px; font-size:12px;">
                    <i class="fas fa-check"></i> Resolve
                  </button>
                <?php else: ?>
                  <button name="action" value="reopen" class="btn btn-secondary"
                          style="padding:6px 10px; font-size:12px;">
                    <i class="fas fa-rotate-left"></i> Reopen
                  </button>
                <?php endif; ?>
                <button name="action" value="delete" class="btn btn-secondary"
                        style="padding:6px 10px; font-size:12px; color:#FCA5A5;"
                        onclick="return confirm('Delete this report?');">
                  <i class="fas fa-trash"></i>
                </button>
              </form>
            </td>
          </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  <?php endif; ?>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
