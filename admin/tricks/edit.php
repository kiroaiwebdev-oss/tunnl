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

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Local upload (if any) overrides the typed URL.
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
require_once dirname(__DIR__) . '/includes/footer.php';
