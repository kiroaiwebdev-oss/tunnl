<?php
$current = basename($_SERVER['PHP_SELF']);
$currentDir = basename(dirname($_SERVER['PHP_SELF']));

function isActive($dir) {
    global $currentDir;
    return $currentDir === $dir ? 'active' : '';
}
?>

<aside class="sidebar" id="sidebar">
  <!-- Logo -->
  <div class="sidebar-logo">
    <div class="logo-icon-sm">⚡</div>
    <div class="logo-text">
      <span class="logo-name">Tunnl</span>
      <span class="logo-badge">ADMIN</span>
    </div>
    <button class="sidebar-close" onclick="toggleSidebar()">
      <i class="fas fa-times"></i>
    </button>
  </div>

  <!-- Admin info -->
  <div class="admin-info">
    <div class="admin-avatar">
      <?= strtoupper(substr($_SESSION['admin_username'], 0, 1)) ?>
    </div>
    <div class="admin-details">
      <div class="admin-name"><?= htmlspecialchars($_SESSION['admin_username']) ?></div>
      <div class="admin-role"><?= ucfirst($_SESSION['admin_role']) ?></div>
    </div>
    <div class="admin-dot"></div>
  </div>

  <!-- Nav -->
  <nav class="sidebar-nav">

    <div class="nav-section">OVERVIEW</div>
    <a href="<?= ADMIN_URL ?>/dashboard/index.php" class="nav-item <?= isActive('dashboard') ?>">
      <i class="fas fa-chart-pie nav-icon"></i>
      <span>Dashboard</span>
    </a>

    <div class="nav-section">CONTENT</div>
    <a href="<?= ADMIN_URL ?>/sets/index.php?category=mcq" class="nav-item">
      <i class="fas fa-bolt nav-icon"></i>
      <span>5000 Speed MCQs</span>
      <span class="nav-badge">SETS</span>
    </a>
    <a href="<?= ADMIN_URL ?>/sets/index.php?category=simplification" class="nav-item">
      <i class="fas fa-divide nav-icon"></i>
      <span>Simplification</span>
    </a>
    <a href="<?= ADMIN_URL ?>/questions/index.php" class="nav-item <?= isActive('questions') ?>">
      <i class="fas fa-question-circle nav-icon"></i>
      <span>All Questions</span>
      <span class="nav-badge">5000+</span>
    </a>
    <a href="<?= ADMIN_URL ?>/sets/index.php" class="nav-item <?= isActive('sets') ?>">
      <i class="fas fa-layer-group nav-icon"></i>
      <span>All Sets</span>
    </a>
    <a href="<?= ADMIN_URL ?>/tricks/index.php" class="nav-item <?= isActive('tricks') ?>">
      <i class="fas fa-bolt nav-icon"></i>
      <span>Tunnl Tricks</span>
    </a>
    <a href="<?= ADMIN_URL ?>/sets/index.php?category=tricks" class="nav-item">
      <i class="fas fa-lightbulb nav-icon"></i>
      <span>Tricks Practice</span>
      <span class="nav-badge">SETS</span>
    </a>
    <a href="<?= ADMIN_URL ?>/shorts/index.php" class="nav-item <?= isActive('shorts') ?>">
      <i class="fas fa-play-circle nav-icon"></i>
      <span>Shorts</span>
    </a>
    <a href="<?= ADMIN_URL ?>/daily_dose/index.php" class="nav-item <?= isActive('daily_dose') ?>">
      <i class="fas fa-sun nav-icon"></i>
      <span>Daily Dose</span>
    </a>
    <a href="<?= ADMIN_URL ?>/daily_practice/index.php" class="nav-item <?= isActive('daily_practice') ?>">
      <i class="fas fa-calendar-check nav-icon"></i>
      <span>Daily Practice</span>
    </a>
    <a href="<?= ADMIN_URL ?>/previous_year/index.php" class="nav-item <?= isActive('previous_year') ?>">
      <i class="fas fa-history nav-icon"></i>
      <span>Previous Year</span>
    </a>

    <div class="nav-section">ENGAGEMENT</div>
    <a href="<?= ADMIN_URL ?>/solve_earn/index.php" class="nav-item <?= isActive('solve_earn') ?>">
      <i class="fas fa-trophy nav-icon"></i>
      <span>Solve & Earn</span>
      <span class="nav-badge new">LIVE</span>
    </a>
    <a href="<?= ADMIN_URL ?>/notifications/index.php" class="nav-item <?= isActive('notifications') ?>">
      <i class="fas fa-bell nav-icon"></i>
      <span>Notifications</span>
    </a>

    <div class="nav-section">USERS</div>
    <a href="<?= ADMIN_URL ?>/users/index.php" class="nav-item <?= isActive('users') ?>">
      <i class="fas fa-users nav-icon"></i>
      <span>All Users</span>
    </a>
    <a href="<?= ADMIN_URL ?>/premium/index.php" class="nav-item <?= isActive('premium') ?>">
      <i class="fas fa-crown nav-icon"></i>
      <span>Premium</span>
    </a>

    <div class="nav-section">SETTINGS</div>
    <a href="<?= ADMIN_URL ?>/app_settings/index.php" class="nav-item <?= isActive('app_settings') ?>">
      <i class="fas fa-cog nav-icon"></i>
      <span>App Settings</span>
    </a>

    <div class="nav-section"></div>
    <a href="<?= ADMIN_URL ?>/auth/logout.php" class="nav-item logout-item">
      <i class="fas fa-sign-out-alt nav-icon"></i>
      <span>Logout</span>
    </a>

  </nav>
</nav>