<?php
// ─────────────────────────────────────────────────────────────────────────
// Shared "Exam → Sets" manager — same table layout as the Tunnlity sets view.
//
// Used by 5000-MCQ exams and Previous-Year exams. Lists the exam's sets in a
// table; each row's "Questions" button opens the scoped questions page
// (questions/index.php?cat=...&set_id=...), exactly like Tunnlity.
//
// The including page MUST set $pdo and $cfg BEFORE requiring this file and
// must NOT have produced output yet (JSON / redirect headers are sent here).
//
// $cfg keys:
//   category, examId, exam(row), title, subtitle, backUrl, selfBase,
//   accent, icon, matchSql (alias s), matchParams, addSet(closure)
// ─────────────────────────────────────────────────────────────────────────

$category    = $cfg['category'];
$examId      = (int)$cfg['examId'];
$matchSql    = $cfg['matchSql'];
$matchParams = $cfg['matchParams'];
$accent      = $cfg['accent'];
$ADMIN       = defined('ADMIN_URL') ? ADMIN_URL : '';

$ownIds = (function () use ($pdo, $matchSql, $matchParams): array {
    $st = $pdo->prepare("SELECT s.id FROM sets s WHERE $matchSql");
    $st->execute($matchParams);
    return array_map('intval', array_column($st->fetchAll(), 'id'));
})();

$error = '';

// ── DELETE SET (JSON) ──
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete_set_id'])) {
    header('Content-Type: application/json');
    try {
        $sid = intval($_POST['delete_set_id']);
        if (!in_array($sid, $ownIds, true)) throw new Exception('Set not in this exam');
        $pdo->prepare("DELETE FROM questions WHERE set_id = ?")->execute([$sid]);
        $pdo->prepare("DELETE FROM sets WHERE id = ?")->execute([$sid]);
        echo json_encode(['success' => true]); exit;
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]); exit;
    }
}

// ── ADD SET ──
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['add_set'])) {
    try {
        ($cfg['addSet'])($pdo, $_POST, $cfg['exam']);
        header('Location: ' . $cfg['selfBase'] . '&added=1');
        exit;
    } catch (Exception $e) { $error = $e->getMessage(); }
}

// ── Load sets ──
$setsStmt = $pdo->prepare("
    SELECT s.*, (SELECT COUNT(*) FROM questions q WHERE q.set_id = s.id) AS q_count
    FROM sets s WHERE $matchSql ORDER BY s.set_number ASC
");
$setsStmt->execute($matchParams);
$sets = $setsStmt->fetchAll();

$pageTitle = 'Manage Sets';
require_once dirname(__DIR__) . '/includes/header.php';

$h = fn($v) => htmlspecialchars((string)$v, ENT_QUOTES);
$catQS  = 'cat=' . urlencode($category);
// Return URL so the questions/CSV pages can come back to THIS exam's sets.
$retEnc = urlencode($cfg['selfBase']);
?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">
      <i class="fas <?= $h($cfg['icon']) ?>" style="color:<?= $accent ?>"></i> <?= $h($cfg['title']) ?>
    </h2>
    <p class="text-muted"><?= count($sets) ?> sets &middot; every set is a 10-question test</p>
  </div>
  <div style="display:flex;gap:10px;flex-wrap:wrap">
    <a href="<?= $h($cfg['backUrl']) ?>" class="btn btn-secondary"><i class="fas fa-arrow-left"></i> Back</a>
    <a href="<?= $ADMIN ?>/questions/import_csv.php?<?= $catQS ?>&ret=<?= $retEnc ?>" class="btn btn-secondary"><i class="fas fa-file-csv"></i> Import CSV</a>
    <button onclick="openAddSet()" class="btn btn-primary"><i class="fas fa-plus"></i> Add Set</button>
  </div>
</div>

<?php if (isset($_GET['added'])): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:12px 16px;border-radius:12px;margin-bottom:16px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> Set added!
</div>
<?php endif; ?>
<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:16px">
  <i class="fas fa-exclamation-circle"></i> <?= $h($error) ?>
</div>
<?php endif; ?>

<div class="card">
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Set #</th>
          <th>Title</th>
          <th>Level</th>
          <th>Questions</th>
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($sets)): ?>
        <tr><td colspan="6" style="text-align:center;padding:40px;color:var(--muted)">
          <i class="fas fa-layer-group" style="font-size:32px;display:block;margin-bottom:10px;opacity:0.3"></i>
          No sets yet. <a href="javascript:void(0)" onclick="openAddSet()" style="color:var(--cyan)">Add the first set!</a>
        </td></tr>
        <?php else: ?>
        <?php foreach ($sets as $s): ?>
        <tr>
          <td><span style="font-family:'Space Grotesk',sans-serif;font-weight:700;color:<?= $accent ?>">#<?= $s['set_number'] ?></span></td>
          <td style="font-weight:500;color:var(--text)">
            <?= $h($s['title'] ?: 'Set ' . $s['set_number']) ?>
            <?php if (!empty($s['exam_name'])): ?>
            <div style="font-size:11px;color:var(--muted)"><?= $h($s['exam_name']) ?></div>
            <?php endif; ?>
          </td>
          <td>
            <?php $lvl = ['beginner'=>'badge-success','intermediate'=>'badge-warning','advanced'=>'badge-error','expert'=>'badge-purple']; ?>
            <span class="badge <?= $lvl[strtolower($s['level'])] ?? 'badge-cyan' ?>"><?= ucfirst($s['level']) ?></span>
          </td>
          <td>
            <span style="font-weight:700;color:<?= $s['q_count']>0 ? 'var(--success)' : 'var(--warning)' ?>"><?= $s['q_count'] ?></span>
            <span style="color:var(--muted);font-size:12px">/10</span>
          </td>
          <td>
            <?php if (!empty($s['is_locked'])): ?>
            <span class="badge badge-error"><i class="fas fa-lock"></i> Locked</span>
            <?php else: ?>
            <span class="badge badge-success"><i class="fas fa-unlock"></i> Open</span>
            <?php endif; ?>
          </td>
          <td>
            <div style="display:flex;gap:6px">
              <a href="<?= $ADMIN ?>/questions/index.php?<?= $catQS ?>&set_id=<?= $s['id'] ?>&ret=<?= $retEnc ?>" class="btn btn-primary btn-sm" title="Manage Questions">
                <i class="fas fa-list-ol"></i> Questions
              </a>
              <a href="<?= $ADMIN ?>/questions/import_csv.php?<?= $catQS ?>&set_id=<?= $s['id'] ?>&ret=<?= $retEnc ?>" class="btn btn-secondary btn-sm" title="Import CSV into this set">
                <i class="fas fa-file-csv"></i>
              </a>
              <a href="<?= $ADMIN ?>/sets/edit.php?id=<?= $s['id'] ?>&<?= $catQS ?>&ret=<?= $retEnc ?>" class="btn btn-secondary btn-sm" title="Edit set">
                <i class="fas fa-edit"></i>
              </a>
              <button onclick="deleteSet(<?= $s['id'] ?>)" class="btn btn-danger btn-sm" title="Delete set">
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

<!-- Add Set modal -->
<div id="addSetModal" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,0.6);z-index:1000;align-items:center;justify-content:center;padding:20px">
  <div style="background:var(--card);border:1px solid var(--border);border-radius:16px;max-width:460px;width:100%;padding:22px">
    <div class="flex-between" style="margin-bottom:16px">
      <h3 style="font-family:'Space Grotesk',sans-serif;font-size:17px;font-weight:700;color:var(--text)">
        <i class="fas fa-plus-circle" style="color:<?= $accent ?>"></i> Add New Set
      </h3>
      <button onclick="closeAddSet()" class="btn btn-secondary btn-sm"><i class="fas fa-times"></i></button>
    </div>
    <form method="POST" action="<?= $h($cfg['selfBase']) ?>">
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">Set Number *</label>
          <input type="number" name="set_number" class="form-input" required min="1" value="<?= count($sets)+1 ?>">
        </div>
        <div class="form-group">
          <label class="form-label">Level</label>
          <select name="level" class="form-select">
            <option value="beginner">Beginner</option>
            <option value="intermediate" selected>Intermediate</option>
            <option value="advanced">Advanced</option>
            <option value="expert">Expert</option>
          </select>
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">Title (optional)</label>
        <input type="text" name="set_title" class="form-input" placeholder="e.g. Set 1">
      </div>
      <input type="hidden" name="set_questions" value="10">
      <div style="display:flex;gap:10px;margin-top:8px">
        <button type="submit" name="add_set" class="btn btn-primary" style="flex:1;justify-content:center"><i class="fas fa-save"></i> Add Set</button>
        <button type="button" onclick="closeAddSet()" class="btn btn-secondary">Cancel</button>
      </div>
    </form>
  </div>
</div>

<script>
function openAddSet(){ document.getElementById('addSetModal').style.display='flex'; }
function closeAddSet(){ document.getElementById('addSetModal').style.display='none'; }
document.getElementById('addSetModal').addEventListener('click', function(e){ if(e.target===this) closeAddSet(); });

function deleteSet(id) {
  if (!confirm('Delete this set and all its questions?')) return;
  fetch('<?= $h($cfg['selfBase']) ?>', {
    method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'delete_set_id='+id
  }).then(r => r.json()).then(d => { if (d.success) location.reload(); else alert(d.message || 'Failed'); })
    .catch(() => alert('Network error.'));
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
