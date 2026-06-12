<?php
// Config FIRST (no HTML output) so header('Location') redirects work.
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';

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
    try {
        $pdo->prepare("
            UPDATE tricks SET
              chapter_number=?, title=?, subtitle=?, category=?, difficulty=?,
              has_video=?, video_url=?, video_duration=?,
              has_article=?, article_content=?, read_duration=?,
              is_new=?, is_active=?
            WHERE id=?
        ")->execute([
            intval($_POST['chapter_number']),
            trim($_POST['title']),
            trim($_POST['subtitle'] ?? ''),
            strtoupper(trim($_POST['category'])),
            $_POST['difficulty'],
            isset($_POST['has_video'])   ? 1 : 0,
            trim($_POST['video_url']     ?? ''),
            intval($_POST['video_duration'] ?? 0),
            isset($_POST['has_article']) ? 1 : 0,
            trim($_POST['article_content'] ?? ''),
            intval($_POST['read_duration']  ?? 5),
            isset($_POST['is_new'])      ? 1 : 0,
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

$pageTitle = 'Edit Trick';
require_once dirname(__DIR__) . '/includes/header.php';
require __DIR__ . '/_form.php';
renderTrickForm([
    'mode'    => 'edit',
    'action'  => ADMIN_URL . '/tricks/edit.php?id=' . $id,
    'error'   => $error,
    'success' => $success,
    'cats'    => $existingCats,
    'trick'   => $trick,
]);
require_once dirname(__DIR__) . '/includes/footer.php';
