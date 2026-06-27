<?php
// Config FIRST (no HTML output) so header('Location') redirects work.
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';
require_once __DIR__ . '/_video_upload.php';
require_once __DIR__ . '/_image_upload.php';

$success = $error = '';

// Existing distinct categories (so admin can reuse or type a brand-new one)
$existingCats = array_column($pdo->query(
    "SELECT DISTINCT category FROM tricks WHERE category <> '' ORDER BY category"
)->fetchAll(), 'category');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Local upload (if any) overrides the typed URL.
    $videoUrl = tunnl_trick_video_url($_POST['video_url'] ?? '', $error);
    $imageUrl = tunnl_trick_image_url($_POST['image_url'] ?? '', $error);
    $hasVideo = ($videoUrl !== '') ? 1 : (isset($_POST['has_video']) ? 1 : 0);
    $blocksJson = trim($_POST['article_blocks'] ?? '');
    $hasBlocks  = ($blocksJson !== '' && $blocksJson !== '[]');
    $hasArticle = (isset($_POST['has_article']) || $hasBlocks || trim($_POST['article_content'] ?? '') !== '') ? 1 : 0;
    if ($error === '') {
      try {
        $pdo->prepare("
            INSERT INTO tricks
              (chapter_number, title, subtitle, category, difficulty,
               image_url,
               has_video, video_url, video_duration,
               has_article, article_content, read_duration, article_blocks,
               is_new, is_premium, is_active)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,1)
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
            trim($_POST['article_content'] ?? ''),
            intval($_POST['read_duration']  ?? 5),
            $blocksJson,
            isset($_POST['is_new'])      ? 1 : 0,
            isset($_POST['is_premium'])  ? 1 : 0,
        ]);
        header('Location: ' . ADMIN_URL . '/tricks/index.php?added=1');
        exit;
      } catch (Exception $e) {
        $error = $e->getMessage();
        if (stripos($error, 'truncated') !== false || stripos($error, 'Incorrect') !== false) {
            $error = 'Could not save. If you used a custom category, open any admin page once '
                   . '(it auto-upgrades the category column), then try again.';
        }
      }
    }
}

$pageTitle = 'Add Trick';
require_once dirname(__DIR__) . '/includes/header.php';
require __DIR__ . '/_form.php';
renderTrickForm([
    'mode'     => 'add',
    'action'   => ADMIN_URL . '/tricks/add.php',
    'error'    => $error,
    'success'  => '',
    'cats'     => $existingCats,
    'trick'    => [
        'chapter_number' => $_POST['chapter_number'] ?? '',
        'title'          => $_POST['title'] ?? '',
        'subtitle'       => $_POST['subtitle'] ?? '',
        'category'       => $_POST['category'] ?? '',
        'difficulty'     => $_POST['difficulty'] ?? 'Beginner',
        'image_url'      => $_POST['image_url'] ?? '',
        'has_video'      => isset($_POST['has_video']) ? 1 : 0,
        'video_url'      => $_POST['video_url'] ?? '',
        'video_duration' => $_POST['video_duration'] ?? 5,
        'has_article'    => isset($_POST['has_article']) ? 1 : (($_SERVER['REQUEST_METHOD'] === 'POST') ? 0 : 1),
        'article_content'=> $_POST['article_content'] ?? '',
        'read_duration'  => $_POST['read_duration'] ?? 5,
        'article_blocks' => $_POST['article_blocks'] ?? '',
        'is_new'         => isset($_POST['is_new']) ? 1 : 0,
        'is_premium'     => isset($_POST['is_premium']) ? 1 : 0,
        'is_active'      => 1,
    ],
]);
require_once dirname(__DIR__) . '/includes/footer.php';
