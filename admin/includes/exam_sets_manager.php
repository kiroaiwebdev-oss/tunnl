<?php
// ─────────────────────────────────────────────────────────────────────────
// Shared "Exam → Sets → Questions" master-detail manager.
//
// Used by 5000-MCQ exams and Previous-Year exams. Shows the exam's sets on
// the LEFT and the selected set's questions on the RIGHT (like Tunnlity but
// in one screen).
//
// The including page MUST set $pdo and $cfg BEFORE requiring this file, and
// must NOT have produced any output yet (we send JSON / redirect headers).
//
// $cfg keys:
//   category     'mcq' | 'previous_year'
//   examId       int
//   exam         row (needs is_premium)
//   title        heading text
//   subtitle     small text under heading
//   backUrl      link to the exams index
//   selfBase     ADMIN_URL.'/.../manage_sets.php?exam_id='.$examId
//   accent       css colour
//   icon         fontawesome class (e.g. 'fa-bolt')
//   matchSql     WHERE fragment selecting this exam's sets, uses alias s
//   matchParams  params for matchSql
//   addSet       closure(PDO $pdo, array $post, array $exam): void
// ─────────────────────────────────────────────────────────────────────────

$category    = $cfg['category'];
$examId      = (int)$cfg['examId'];
$matchSql    = $cfg['matchSql'];
$matchParams = $cfg['matchParams'];
$accent      = $cfg['accent'];
$ADMIN       = defined('ADMIN_URL') ? ADMIN_URL : '';

// Set ids that belong to this exam (for ownership checks)
$loadOwnIds = function () use ($pdo, $matchSql, $matchParams): array {
    $st = $pdo->prepare("SELECT s.id FROM sets s WHERE $matchSql");
    $st->execute($matchParams);
    return array_map('intval', array_column($st->fetchAll(), 'id'));
};
$ownIds = $loadOwnIds();

$selSet  = intval($_GET['set_id'] ?? 0);
$success = $error = '';

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

// ── DELETE QUESTION (JSON) ──
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete_question_id'])) {
    header('Content-Type: application/json');
    try {
        $qid = intval($_POST['delete_question_id']);
        $chk = $pdo->prepare("SELECT set_id FROM questions WHERE id = ?");
        $chk->execute([$qid]);
        $qSet = (int)$chk->fetchColumn();
        if (!in_array($qSet, $ownIds, true)) throw new Exception('Question not in this exam');
        $pdo->prepare("DELETE FROM questions WHERE id = ?")->execute([$qid]);
        echo json_encode(['success' => true]); exit;
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]); exit;
    }
}

// ── ADD SET ──
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['add_set'])) {
    try {
        ($cfg['addSet'])($pdo, $_POST, $cfg['exam']);
        $success = 'Set added!';
        $ownIds  = $loadOwnIds();
    } catch (Exception $e) { $error = $e->getMessage(); }
}

// ── ADD QUESTION (inline, into the selected set) ──
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['add_question'])) {
    try {
        $sid = intval($_POST['set_id']);
        if (!in_array($sid, $ownIds, true)) throw new Exception('Pick a valid set first.');
        $pdo->prepare("
            INSERT INTO questions
              (set_id, category, question_text, option_a, option_b, option_c, option_d,
               correct_option, explanation, difficulty, is_active)
            VALUES (?,?,?,?,?,?,?,?,?,?,1)
        ")->execute([
            $sid, $category,
            trim($_POST['question_text']),
            trim($_POST['option_a']), trim($_POST['option_b']),
            trim($_POST['option_c']), trim($_POST['option_d']),
            $_POST['correct_option'],
            trim($_POST['explanation'] ?? ''),
            $_POST['difficulty'],
        ]);
        $success = 'Question added!';
        $selSet  = $sid;
    } catch (Exception $e) { $error = $e->getMessage(); }
}

// ── Load sets (with question counts) ──
$setsStmt = $pdo->prepare("
    SELECT s.*, (SELECT COUNT(*) FROM questions q WHERE q.set_id = s.id) AS q_count
    FROM sets s WHERE $matchSql ORDER BY s.set_number ASC
");
$setsStmt->execute($matchParams);
$sets = $setsStmt->fetchAll();

// ── Load selected set + its questions ──
$selRow = null; $questions = [];
if ($selSet && in_array($selSet, $ownIds, true)) {
    $r = $pdo->prepare("SELECT * FROM sets WHERE id = ?");
    $r->execute([$selSet]);
    $selRow = $r->fetch();
    $q = $pdo->prepare("SELECT * FROM questions WHERE set_id = ? ORDER BY id ASC");
    $q->execute([$selSet]);
    $questions = $q->fetchAll();
} elseif (!$selSet && !empty($sets)) {
    // Auto-select the first set so the right panel isn't empty
    $selSet = (int)$sets[0]['id'];
    $selRow = $sets[0];
    $q = $pdo->prepare("SELECT * FROM questions WHERE set_id = ? ORDER BY id ASC");
    $q->execute([$selSet]);
    $questions = $q->fetchAll();
}

$pageTitle = 'Manage Sets';
require_once dirname(__DIR__) . '/includes/header.php';

$h = fn($v) => htmlspecialchars((string)$v, ENT_QUOTES);
?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">
      <i class="fas <?= $h($cfg['icon']) ?>" style="color:<?= $accent ?>"></i> <?= $h($cfg['title']) ?>
    </h2>
    <p class="text-muted"><?= $h($cfg['subtitle']) ?> &middot; <?= count($sets) ?> sets &middot; each set = 10 questions</p>
  </div>
  <a href="<?= $h($cfg['backUrl']) ?>" class="btn btn-secondary"><i class="fas fa-arrow-left"></i> Back to Exams</a>
</div>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:12px 16px;border-radius:12px;margin-bottom:16px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $h($success) ?>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:16px">
  <i class="fas fa-exclamation-circle"></i> <?= $h($error) ?>
</div>
<?php endif; ?>

<div style="display:grid;grid-template-columns:330px 1fr;gap:16px;align-items:start" id="esmGrid">

  <!-- LEFT: SETS -->
  <div style="display:flex;flex-direction:column;gap:14px">
    <div class="card">
      <div class="card-header"><div class="card-title-text"><i class="fas fa-plus-circle" style="color:<?= $accent ?>"></i> Add Set</div></div>
      <form method="POST" action="<?= $h($cfg['selfBase']) ?>">
        <div class="form-row">
          <div class="form-group" style="margin-bottom:10px">
            <label class="form-label">Set #</label>
            <input type="number" name="set_number" class="form-input" required min="1" value="<?= count($sets)+1 ?>">
          </div>
          <div class="form-group" style="margin-bottom:10px">
            <label class="form-label">Level</label>
            <select name="level" class="form-select">
              <option value="beginner">Beginner</option>
              <option value="intermediate" selected>Intermediate</option>
              <option value="advanced">Advanced</option>
              <option value="expert">Expert</option>
            </select>
          </div>
        </div>
        <div class="form-group" style="margin-bottom:10px">
          <label class="form-label">Title (optional)</label>
          <input type="text" name="set_title" class="form-input" placeholder="e.g. Set 1">
        </div>
        <input type="hidden" name="set_questions" value="10">
        <button type="submit" name="add_set" class="btn btn-primary" style="width:100%"><i class="fas fa-plus"></i> Add Set</button>
      </form>
    </div>

    <div class="card" style="padding:10px">
      <?php if (empty($sets)): ?>
      <div style="text-align:center;padding:24px;color:var(--muted)">
        <i class="fas fa-layer-group" style="font-size:24px;display:block;margin-bottom:8px;opacity:0.3"></i>
        No sets yet — add one above.
      </div>
      <?php else: ?>
      <?php foreach ($sets as $s):
        $isSel = (int)$s['id'] === $selSet; ?>
      <div style="display:flex;align-items:center;justify-content:space-between;gap:8px;padding:10px 12px;border-radius:10px;margin-bottom:6px;cursor:pointer;
        background:<?= $isSel ? 'rgba(0,229,255,0.08)' : 'transparent' ?>;
        border:1px solid <?= $isSel ? $accent : 'var(--border)' ?>"
        onclick="location.href='<?= $h($cfg['selfBase']) ?>&set_id=<?= $s['id'] ?>'">
        <div>
          <div style="font-family:'Space Grotesk',sans-serif;font-weight:700;color:<?= $isSel ? $accent : 'var(--text)' ?>">
            Set <?= $s['set_number'] ?>
          </div>
          <div style="font-size:11px;color:var(--muted)">
            <span style="color:<?= $s['q_count']>0?'var(--success)':'var(--warning)' ?>;font-weight:600"><?= $s['q_count'] ?></span>/10 Q
            <?= $s['title'] ? ' &middot; ' . $h($s['title']) : '' ?>
          </div>
        </div>
        <button onclick="event.stopPropagation();deleteSet(<?= $s['id'] ?>)" class="btn btn-danger btn-sm" title="Delete set">
          <i class="fas fa-trash"></i>
        </button>
      </div>
      <?php endforeach; ?>
      <?php endif; ?>
    </div>
  </div>

  <!-- RIGHT: QUESTIONS of selected set -->
  <div class="card">
    <?php if (!$selRow): ?>
    <div style="text-align:center;padding:60px 20px;color:var(--muted)">
      <i class="fas fa-hand-pointer" style="font-size:32px;display:block;margin-bottom:12px;opacity:0.3"></i>
      Select a set on the left to see &amp; add its questions.
    </div>
    <?php else: ?>
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-list-ol" style="color:<?= $accent ?>"></i>
        Set <?= $selRow['set_number'] ?> — Questions
        <span style="font-size:12px;color:var(--muted);font-weight:400">(<?= count($questions) ?>/10)</span>
      </div>
      <a href="<?= $ADMIN ?>/questions/import_csv.php?cat=<?= urlencode($category) ?>&set_id=<?= $selSet ?>" class="btn btn-secondary btn-sm">
        <i class="fas fa-file-csv"></i> Import CSV
      </a>
    </div>

    <!-- Inline add-question -->
    <details <?= empty($questions) ? 'open' : '' ?> style="margin-bottom:14px;border:1px solid var(--border);border-radius:12px;padding:12px">
      <summary style="cursor:pointer;font-weight:600;color:var(--text2);font-size:13px"><i class="fas fa-plus"></i> Add a question</summary>
      <form method="POST" action="<?= $h($cfg['selfBase']) ?>&set_id=<?= $selSet ?>" style="margin-top:12px">
        <input type="hidden" name="set_id" value="<?= $selSet ?>">
        <div class="form-group" style="margin-bottom:10px">
          <label class="form-label">Question *</label>
          <textarea name="question_text" class="form-textarea" rows="2" required placeholder="Write the question..."></textarea>
        </div>
        <div class="form-row">
          <?php foreach (['a'=>'A','b'=>'B','c'=>'C','d'=>'D'] as $k=>$lbl): ?>
          <div class="form-group" style="margin-bottom:10px">
            <label class="form-label">Option <?= $lbl ?> *</label>
            <input type="text" name="option_<?= $k ?>" class="form-input" required>
          </div>
          <?php endforeach; ?>
        </div>
        <div class="form-row">
          <div class="form-group" style="margin-bottom:10px">
            <label class="form-label">Correct *</label>
            <select name="correct_option" class="form-select" required>
              <option value="A">A</option><option value="B">B</option>
              <option value="C">C</option><option value="D">D</option>
            </select>
          </div>
          <div class="form-group" style="margin-bottom:10px">
            <label class="form-label">Difficulty</label>
            <select name="difficulty" class="form-select">
              <option value="easy">Easy</option>
              <option value="medium" selected>Medium</option>
              <option value="hard">Hard</option>
            </select>
          </div>
        </div>
        <div class="form-group" style="margin-bottom:10px">
          <label class="form-label">Explanation (optional)</label>
          <input type="text" name="explanation" class="form-input" placeholder="Why this answer is correct">
        </div>
        <button type="submit" name="add_question" class="btn btn-primary"><i class="fas fa-save"></i> Add Question</button>
      </form>
    </details>

    <!-- Questions list -->
    <?php if (empty($questions)): ?>
    <div style="text-align:center;padding:30px;color:var(--muted)">No questions in this set yet.</div>
    <?php else: ?>
    <div style="display:flex;flex-direction:column;gap:8px">
      <?php foreach ($questions as $i => $q): ?>
      <div style="border:1px solid var(--border);border-radius:10px;padding:12px;display:flex;gap:10px;align-items:flex-start;justify-content:space-between">
        <div style="flex:1">
          <div style="font-size:13px;color:var(--text2);line-height:1.4;margin-bottom:6px">
            <span style="color:var(--muted)"><?= $i+1 ?>.</span> <?= $h(mb_substr($q['question_text'],0,120)) ?><?= mb_strlen($q['question_text'])>120?'…':'' ?>
          </div>
          <div style="display:flex;gap:10px;flex-wrap:wrap;font-size:11px">
            <span style="color:var(--success)">Ans: <strong><?= $h($q['correct_option']) ?></strong></span>
            <span class="badge <?= ['easy'=>'badge-success','medium'=>'badge-warning','hard'=>'badge-error'][$q['difficulty']] ?? 'badge-cyan' ?>" style="font-size:9px"><?= ucfirst($q['difficulty']) ?></span>
          </div>
        </div>
        <div style="display:flex;gap:6px;flex-shrink:0">
          <a href="<?= $ADMIN ?>/questions/edit.php?id=<?= $q['id'] ?>&cat=<?= urlencode($category) ?>&set_id=<?= $selSet ?>" class="btn btn-secondary btn-sm" title="Edit"><i class="fas fa-edit"></i></a>
          <button onclick="deleteQuestion(<?= $q['id'] ?>)" class="btn btn-danger btn-sm" title="Delete"><i class="fas fa-trash"></i></button>
        </div>
      </div>
      <?php endforeach; ?>
    </div>
    <?php endif; ?>
    <?php endif; ?>
  </div>
</div>

<style>@media (max-width: 860px){ #esmGrid{ grid-template-columns:1fr !important; } }</style>

<script>
function deleteSet(id) {
  if (!confirm('Delete this set and all its questions?')) return;
  postJson('<?= $h($cfg['selfBase']) ?>', 'delete_set_id=' + id);
}
function deleteQuestion(id) {
  if (!confirm('Delete this question?')) return;
  postJson('<?= $h($cfg['selfBase']) ?>', 'delete_question_id=' + id);
}
function postJson(url, body) {
  fetch(url, { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body: body })
    .then(r => r.json())
    .then(d => { if (d.success) location.reload(); else alert(d.message || 'Failed'); })
    .catch(() => alert('Network error.'));
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
