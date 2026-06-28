<?php
// Config FIRST (no HTML output) so header('Location') redirects work.
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';
require_once __DIR__ . '/_video_upload.php';
require_once __DIR__ . '/_image_upload.php';

$id = intval($_GET['id'] ?? 0);
if (!$id) { header('Location: ' . ADMIN_URL . '/tricks/index.php'); exit; }

$trick = $pdo->prepare("SELECT * FROM tricks WHERE id = ?");
$trick->execute([$id]);
$trick = $trick->fetch();
if (!$trick) { header('Location: ' . ADMIN_URL . '/tricks/index.php'); exit; }

$existingCats = array_column($pdo->query(
    "SELECT DISTINCT category FROM tricks WHERE category <> '' ORDER BY category"
)->fetchAll(), 'category');

$success = $error = '';
$studioAction = $_POST['studio_action'] ?? '';

// ── Practice Studio actions (create set / add question / bulk CSV) — all on
//    THIS page so the admin never has to leave the trick editor. ──
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $studioAction !== '') {
    try {
        if ($studioAction === 'create_set') {
            $title = trim($_POST['set_title'] ?? '');
            $num = (int)$pdo->query("SELECT COALESCE(MAX(set_number),0)+1 FROM sets WHERE category='tricks'")->fetchColumn();
            $pdo->prepare("INSERT INTO sets (category, exam_name, set_number, title, level, total_questions, is_locked, is_premium) VALUES ('tricks','',?,?,'beginner',10,0,0)")
                ->execute([$num, $title !== '' ? $title : ('Tricks Set ' . $num)]);
            $newSetId = (int)$pdo->lastInsertId();
            $pdo->prepare("UPDATE tricks SET practice_set_id=? WHERE id=?")->execute([$newSetId, $id]);
            header('Location: ' . ADMIN_URL . '/tricks/edit.php?id=' . $id . '&studio=set_created#studio'); exit;
        }
        if ($studioAction === 'add_question') {
            $setId = intval($_POST['set_id'] ?? 0);
            if ($setId > 0) {
                $pdo->prepare("INSERT INTO questions
                    (set_id, category, question_text, option_a, option_b, option_c, option_d,
                     correct_option, explanation, difficulty, is_active,
                     question_text_hi, option_a_hi, option_b_hi, option_c_hi, option_d_hi, explanation_hi)
                    VALUES (?,?,?,?,?,?,?,?,?,?,1,?,?,?,?,?,?)")
                  ->execute([
                    $setId, 'tricks',
                    trim($_POST['question_text'] ?? ''),
                    trim($_POST['option_a'] ?? ''), trim($_POST['option_b'] ?? ''),
                    trim($_POST['option_c'] ?? ''), trim($_POST['option_d'] ?? ''),
                    strtoupper(trim($_POST['correct_option'] ?? 'A')),
                    trim($_POST['explanation'] ?? ''),
                    $_POST['difficulty'] ?? 'medium',
                    trim($_POST['question_text_hi'] ?? ''),
                    trim($_POST['option_a_hi'] ?? ''), trim($_POST['option_b_hi'] ?? ''),
                    trim($_POST['option_c_hi'] ?? ''), trim($_POST['option_d_hi'] ?? ''),
                    trim($_POST['explanation_hi'] ?? ''),
                  ]);
            }
            header('Location: ' . ADMIN_URL . '/tricks/edit.php?id=' . $id . '&studio=q_added#studio'); exit;
        }
        if ($studioAction === 'upload_csv') {
            $setId = intval($_POST['set_id'] ?? 0);
            $count = 0;
            if ($setId > 0 && !empty($_FILES['csv_file']['tmp_name']) && is_uploaded_file($_FILES['csv_file']['tmp_name'])) {
                $h = fopen($_FILES['csv_file']['tmp_name'], 'r');
                fgetcsv($h); // header row
                $st = $pdo->prepare("INSERT INTO questions
                    (set_id, category, question_text, option_a, option_b, option_c, option_d,
                     correct_option, explanation, difficulty, is_active,
                     question_text_hi, option_a_hi, option_b_hi, option_c_hi, option_d_hi, explanation_hi)
                    VALUES (?,?,?,?,?,?,?,?,?,?,1,?,?,?,?,?,?)");
                while (($r = fgetcsv($h)) !== false) {
                    if (count($r) < 6) continue;
                    [$qt,$a,$b,$c,$d,$co,$ex,$df,$qh,$ah,$bh,$ch,$dh,$eh] = array_pad($r, 14, '');
                    if (trim($qt) === '') continue;
                    $st->execute([
                        $setId, 'tricks', trim($qt), trim($a), trim($b), trim($c), trim($d),
                        strtoupper(trim($co)) ?: 'A', trim($ex),
                        in_array(strtolower(trim($df)), ['easy','hard']) ? strtolower(trim($df)) : 'medium',
                        trim($qh), trim($ah), trim($bh), trim($ch), trim($dh), trim($eh),
                    ]);
                    $count++;
                }
                fclose($h);
            }
            header('Location: ' . ADMIN_URL . '/tricks/edit.php?id=' . $id . '&studio=csv_' . $count . '#studio'); exit;
        }
    } catch (Exception $e) {
        header('Location: ' . ADMIN_URL . '/tricks/edit.php?id=' . $id . '&studio_err=' . urlencode($e->getMessage()) . '#studio'); exit;
    }
}

// ── Main trick update ──
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $studioAction === '') {
    $videoUrl = tunnl_trick_video_url($_POST['video_url'] ?? '', $error);
    $imageUrl = tunnl_trick_image_url($_POST['image_url'] ?? '', $error);
    $hasVideo = ($videoUrl !== '') ? 1 : (isset($_POST['has_video']) ? 1 : 0);
    $articleHtml   = trim($_POST['article_html'] ?? '');
    $blocksJson    = trim($_POST['article_blocks'] ?? '');
    $articleText   = trim(strip_tags(str_replace(['<br>','<br/>','<br />','</p>','</div>','</li>'], "\n", $articleHtml)));
    $hasBlocks     = ($blocksJson !== '' && $blocksJson !== '[]');
    $hasArticle    = (isset($_POST['has_article']) || $hasBlocks || $articleHtml !== '') ? 1 : 0;
    $practiceSetId = intval($_POST['practice_set_id'] ?? 0);
    if ($error === '') {
      try {
        $pdo->prepare("
            UPDATE tricks SET
              chapter_number=?, title=?, subtitle=?, category=?, difficulty=?,
              image_url=?,
              has_video=?, video_url=?, video_duration=?,
              has_article=?, article_content=?, read_duration=?, article_blocks=?, article_html=?, practice_set_id=?,
              is_new=?, is_premium=?, is_active=?
            WHERE id=?
        ")->execute([
            intval($_POST['chapter_number']),
            trim($_POST['title']),
            trim($_POST['subtitle'] ?? ''),
            strtoupper(trim($_POST['category'])),
            $_POST['difficulty'],
            $imageUrl,
            $hasVideo,
            $videoUrl,
            intval($_POST['video_duration'] ?? 0),
            $hasArticle,
            $articleText,
            intval($_POST['read_duration']  ?? 5),
            $blocksJson,
            $articleHtml,
            $practiceSetId,
            isset($_POST['is_new'])      ? 1 : 0,
            isset($_POST['is_premium'])  ? 1 : 0,
            isset($_POST['is_active'])   ? 1 : 0,
            $id
        ]);
        $success = 'Trick updated!';
        $trick = $pdo->prepare("SELECT * FROM tricks WHERE id = ?");
        $trick->execute([$id]);
        $trick = $trick->fetch();
      } catch (Exception $e) {
        $error = $e->getMessage();
        if (stripos($error, 'truncated') !== false || stripos($error, 'Incorrect') !== false) {
            $error = 'Could not save. If you used a custom category, reload this page once '
                   . '(it auto-upgrades the category column), then try again.';
        }
      }
    }
}

// ── Linked practice set + its questions (for the Studio) ──
$linkedSetId = intval($trick['practice_set_id'] ?? 0);
$linkedSet = null; $linkedQs = [];
if ($linkedSetId > 0) {
    $s = $pdo->prepare("SELECT * FROM sets WHERE id=?"); $s->execute([$linkedSetId]);
    $linkedSet = $s->fetch();
    if ($linkedSet) {
        $q = $pdo->prepare("SELECT id, question_text, correct_option FROM questions WHERE set_id=? ORDER BY id DESC");
        $q->execute([$linkedSetId]);
        $linkedQs = $q->fetchAll();
    }
}
$studioMsg = '';
if (($_GET['studio'] ?? '') === 'set_created') $studioMsg = 'Practice set created & linked!';
elseif (($_GET['studio'] ?? '') === 'q_added')  $studioMsg = 'Question added!';
elseif (strpos(($_GET['studio'] ?? ''), 'csv_') === 0) $studioMsg = intval(substr($_GET['studio'],4)) . ' questions imported from CSV!';
$studioErr = $_GET['studio_err'] ?? '';

$pageTitle = 'Edit Trick';
require_once dirname(__DIR__) . '/includes/header.php';
require __DIR__ . '/_form.php';
$pracSets = $pdo->query("SELECT id, set_number, title FROM sets WHERE category='tricks' ORDER BY set_number")->fetchAll();
renderTrickForm([
    'mode'    => 'edit',
    'action'  => ADMIN_URL . '/tricks/edit.php?id=' . $id,
    'error'   => $error,
    'success' => $success,
    'cats'    => $existingCats,
    'practice_sets' => $pracSets,
    'trick'   => $trick,
]);

$h = fn($v) => htmlspecialchars((string)$v, ENT_QUOTES);
?>

<!-- ── PRACTICE STUDIO (create set + add questions, all here) ── -->
<div id="studio" style="max-width:1000px;margin-top:4px">
  <?php if ($studioMsg): ?>
  <div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:12px 16px;border-radius:12px;margin-bottom:16px"><i class="fas fa-check-circle"></i> <?= $h($studioMsg) ?></div>
  <?php endif; ?>
  <?php if ($studioErr): ?>
  <div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:16px"><i class="fas fa-exclamation-circle"></i> <?= $h($studioErr) ?></div>
  <?php endif; ?>

  <div class="card mb-16" style="border-color:rgba(0,229,255,0.25)">
    <div class="card-header">
      <div class="card-title-text"><i class="fas fa-flask" style="color:var(--cyan)"></i> Practice Studio <span style="color:var(--muted);font-weight:400">— build the practice MCQs right here, no need to leave this page</span></div>
    </div>

    <?php if (!$linkedSet): ?>
      <p class="text-muted" style="font-size:13px;margin:0 0 12px">No practice set linked yet. Create one — questions you add will power the "Take Practice Test" button after this article.</p>
      <form method="POST" action="<?= ADMIN_URL ?>/tricks/edit.php?id=<?= $id ?>" style="display:flex;gap:10px;flex-wrap:wrap;align-items:flex-end">
        <input type="hidden" name="studio_action" value="create_set">
        <div class="form-group" style="margin:0;flex:1;min-width:220px">
          <label class="form-label">New Practice Set Title</label>
          <input type="text" name="set_title" class="form-input" placeholder="e.g. <?= $h($trick['title']) ?> — Practice">
        </div>
        <button type="submit" class="btn btn-primary"><i class="fas fa-plus"></i> Create &amp; Link Set</button>
      </form>
    <?php else: ?>
      <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;margin-bottom:14px;padding:10px 14px;background:#0b1220;border:1px solid var(--border);border-radius:10px">
        <div style="font-size:13px;color:var(--text)">
          <i class="fas fa-layer-group" style="color:var(--cyan)"></i>
          Linked set: <strong>Set <?= (int)$linkedSet['set_number'] ?><?= $linkedSet['title'] ? ' — ' . $h($linkedSet['title']) : '' ?></strong>
          <span class="text-muted">· <?= count($linkedQs) ?> question(s)</span>
        </div>
        <form method="POST" action="<?= ADMIN_URL ?>/tricks/edit.php?id=<?= $id ?>" style="margin:0">
          <input type="hidden" name="studio_action" value="create_set">
          <button type="submit" class="btn btn-secondary btn-sm" title="Create a fresh set & link it"><i class="fas fa-plus"></i> New Set</button>
        </form>
      </div>

      <!-- Add a single question inline -->
      <form method="POST" action="<?= ADMIN_URL ?>/tricks/edit.php?id=<?= $id ?>" style="margin-bottom:18px">
        <input type="hidden" name="studio_action" value="add_question">
        <input type="hidden" name="set_id" value="<?= (int)$linkedSet['id'] ?>">
        <div class="card-title-text" style="font-size:14px;margin-bottom:10px"><i class="fas fa-plus-circle" style="color:var(--success)"></i> Add a Question</div>
        <div class="form-group">
          <label class="form-label">Question *</label>
          <textarea name="question_text" class="form-textarea" rows="2" required placeholder="Write the question…"></textarea>
        </div>
        <?php $opts=['A','B','C','D']; $colors=['A'=>'var(--cyan)','B'=>'var(--success)','C'=>'var(--warning)','D'=>'var(--error)']; foreach ($opts as $o): ?>
        <div style="display:flex;align-items:center;gap:12px;margin-bottom:10px">
          <label style="display:flex;align-items:center;gap:6px;cursor:pointer;flex-shrink:0">
            <input type="radio" name="correct_option" value="<?= $o ?>" <?= $o==='A'?'checked':'' ?> required style="accent-color:var(--cyan);width:16px;height:16px">
            <span style="width:28px;height:28px;border-radius:8px;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:13px;border:1px solid <?= $colors[$o] ?>;color:<?= $colors[$o] ?>"><?= $o ?></span>
          </label>
          <input type="text" name="option_<?= strtolower($o) ?>" class="form-input" placeholder="Option <?= $o ?>…" required>
        </div>
        <?php endforeach; ?>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Difficulty</label>
            <select name="difficulty" class="form-select">
              <option value="easy">🟢 Easy</option>
              <option value="medium" selected>🟡 Medium</option>
              <option value="hard">🔴 Hard</option>
            </select>
          </div>
          <div class="form-group" style="flex:2">
            <label class="form-label">Explanation (optional)</label>
            <input type="text" name="explanation" class="form-input" placeholder="Why is this correct?">
          </div>
        </div>
        <details style="margin:4px 0 12px">
          <summary style="cursor:pointer;font-size:12px;color:var(--cyan)"><i class="fas fa-language"></i> Add Hindi version (optional)</summary>
          <div style="margin-top:10px">
            <div class="form-group"><label class="form-label">Question (Hindi)</label><input type="text" name="question_text_hi" class="form-input" placeholder="प्रश्न…"></div>
            <div class="form-row">
              <div class="form-group"><label class="form-label">Option A (Hindi)</label><input type="text" name="option_a_hi" class="form-input"></div>
              <div class="form-group"><label class="form-label">Option B (Hindi)</label><input type="text" name="option_b_hi" class="form-input"></div>
            </div>
            <div class="form-row">
              <div class="form-group"><label class="form-label">Option C (Hindi)</label><input type="text" name="option_c_hi" class="form-input"></div>
              <div class="form-group"><label class="form-label">Option D (Hindi)</label><input type="text" name="option_d_hi" class="form-input"></div>
            </div>
            <div class="form-group"><label class="form-label">Explanation (Hindi)</label><input type="text" name="explanation_hi" class="form-input" placeholder="व्याख्या…"></div>
          </div>
        </details>
        <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Add Question</button>
      </form>

      <!-- Bulk CSV upload -->
      <form method="POST" action="<?= ADMIN_URL ?>/tricks/edit.php?id=<?= $id ?>" enctype="multipart/form-data" style="border-top:1px solid var(--border);padding-top:14px;margin-bottom:8px">
        <input type="hidden" name="studio_action" value="upload_csv">
        <input type="hidden" name="set_id" value="<?= (int)$linkedSet['id'] ?>">
        <div class="card-title-text" style="font-size:14px;margin-bottom:6px"><i class="fas fa-file-csv" style="color:var(--cyan)"></i> Bulk Upload (CSV)</div>
        <p style="font-size:11px;color:var(--muted);margin:0 0 8px">Columns: question_text, option_a, option_b, option_c, option_d, correct_option, explanation, difficulty (optional Hindi columns after).</p>
        <div style="display:flex;gap:10px;flex-wrap:wrap;align-items:center">
          <input type="file" name="csv_file" accept=".csv" required class="form-input" style="max-width:360px;padding:8px">
          <button type="submit" class="btn btn-secondary"><i class="fas fa-upload"></i> Import CSV</button>
        </div>
      </form>

      <!-- Existing questions -->
      <?php if ($linkedQs): ?>
      <div style="border-top:1px solid var(--border);padding-top:12px">
        <div class="card-title-text" style="font-size:13px;margin-bottom:8px">Questions in this set (<?= count($linkedQs) ?>)</div>
        <div style="max-height:240px;overflow:auto">
          <?php foreach ($linkedQs as $lq): ?>
          <div style="display:flex;align-items:center;gap:10px;padding:8px 10px;border:1px solid var(--border);border-radius:8px;margin-bottom:6px">
            <span style="font-size:11px;font-weight:700;color:var(--success);flex-shrink:0"><?= $h(strtoupper($lq['correct_option'])) ?></span>
            <span style="font-size:12px;color:var(--text2);flex:1"><?= $h(mb_strimwidth($lq['question_text'], 0, 90, '…')) ?></span>
            <a href="<?= ADMIN_URL ?>/questions/edit.php?id=<?= (int)$lq['id'] ?>&cat=tricks&set_id=<?= (int)$linkedSet['id'] ?>" class="btn btn-secondary btn-sm" title="Edit"><i class="fas fa-pen"></i></a>
          </div>
          <?php endforeach; ?>
        </div>
      </div>
      <?php endif; ?>
    <?php endif; ?>
  </div>
</div>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>
