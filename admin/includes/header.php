<?php
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';
require_once dirname(__DIR__) . '/config/constants.php';

$currentPage = basename(dirname($_SERVER['PHP_SELF']));
$currentCat  = $_GET['cat'] ?? ($_GET['category'] ?? '');
$adminName   = $_SESSION['admin_username'] ?? 'Admin';

// Highlights a content section when on its sets/questions/import pages.
function navSectionActive($currentPage, $currentCat, $cat) {
    return (in_array($currentPage, ['sets', 'questions']) && $currentCat === $cat) ? 'active' : '';
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><?= $pageTitle ?? 'Admin Panel' ?> · Tunnel</title>

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">

  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
      --bg:       #0A0A0F;
      --sidebar:  #0D0D14;
      --card:     #12121A;
      --card2:    #16161F;
      --border:   rgba(255,255,255,0.06);
      --border2:  rgba(255,255,255,0.10);
      --text:     #F1F5F9;
      --text2:    #CBD5E1;
      --muted:    #64748B;
      --cyan:     #00E5FF;
      --purple:   #8B5CF6;
      --success:  #10B981;
      --warning:  #F59E0B;
      --error:    #EF4444;
      --dark:     #0A0A0F;
      --sidebar-w:240px;
    }

    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'Inter', sans-serif;
      min-height: 100vh;
      display: flex;
    }

    /* ── SIDEBAR ── */
    .sidebar {
      width: var(--sidebar-w);
      background: var(--sidebar);
      border-right: 1px solid var(--border);
      height: 100vh;
      position: fixed;
      top: 0; left: 0;
      display: flex;
      flex-direction: column;
      z-index: 100;
      overflow-y: auto;
    }

    .sidebar-logo {
      padding: 20px 18px 16px;
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .sidebar-logo .icon {
      width: 36px; height: 36px;
      background: linear-gradient(135deg, rgba(0,229,255,0.2), rgba(0,229,255,0.05));
      border: 1px solid rgba(0,229,255,0.3);
      border-radius: 10px;
      display: flex; align-items: center; justify-content: center;
      font-size: 16px; flex-shrink: 0;
    }

    .sidebar-logo .name {
      font-family: 'Space Grotesk', sans-serif;
      font-weight: 700; font-size: 14px;
      background: linear-gradient(135deg, #fff 0%, #00E5FF 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      line-height: 1.2;
    }

    .sidebar-logo .sub {
      font-size: 10px; color: var(--muted);
    }

    .sidebar-nav { flex: 1; padding: 12px 0; }

    .nav-section {
      padding: 8px 18px 4px;
      font-size: 10px;
      font-weight: 700;
      color: var(--muted);
      text-transform: uppercase;
      letter-spacing: 1px;
    }

    .nav-item {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 9px 18px;
      color: var(--muted);
      text-decoration: none;
      font-size: 13px;
      font-weight: 500;
      transition: all 0.2s;
      border-left: 2px solid transparent;
      margin: 1px 0;
    }

    .nav-item:hover {
      color: var(--text);
      background: rgba(255,255,255,0.04);
    }

    .nav-item.active {
      color: var(--cyan);
      background: rgba(0,229,255,0.06);
      border-left-color: var(--cyan);
    }

    .nav-item i { width: 16px; text-align: center; font-size: 13px; }

    .sidebar-footer {
      padding: 14px 18px;
      border-top: 1px solid var(--border);
    }

    .admin-info {
      display: flex; align-items: center; gap: 10px;
      margin-bottom: 10px;
    }

    .admin-avatar {
      width: 32px; height: 32px;
      background: linear-gradient(135deg, rgba(0,229,255,0.2), rgba(139,92,246,0.2));
      border: 1px solid rgba(0,229,255,0.3);
      border-radius: 8px;
      display: flex; align-items: center; justify-content: center;
      font-size: 13px; font-weight: 700; color: var(--cyan);
    }

    .admin-name { font-size: 12px; font-weight: 600; color: var(--text2); }
    .admin-role { font-size: 10px; color: var(--muted); }

    .logout-btn {
      display: flex; align-items: center; gap: 8px;
      padding: 8px 12px;
      background: rgba(239,68,68,0.08);
      border: 1px solid rgba(239,68,68,0.2);
      border-radius: 8px;
      color: #FCA5A5;
      text-decoration: none;
      font-size: 12px; font-weight: 600;
      transition: all 0.2s; width: 100%;
      justify-content: center;
    }

    .logout-btn:hover {
      background: rgba(239,68,68,0.15);
      border-color: rgba(239,68,68,0.4);
    }

    /* ── MAIN ── */
    .main-wrap {
      margin-left: var(--sidebar-w);
      flex: 1;
      display: flex;
      flex-direction: column;
      min-height: 100vh;
    }

    /* ── TOPBAR ── */
    .topbar {
      background: var(--sidebar);
      border-bottom: 1px solid var(--border);
      padding: 0 24px;
      height: 56px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      position: sticky; top: 0; z-index: 50;
    }

    .topbar-title {
      font-family: 'Space Grotesk', sans-serif;
      font-size: 16px; font-weight: 600; color: var(--text);
    }

    .topbar-right {
      display: flex; align-items: center; gap: 12px;
    }

    .topbar-time {
      font-size: 12px; color: var(--muted);
    }

    /* ── CONTENT ── */
    .content {
      padding: 24px;
      flex: 1;
    }

    /* ── CARDS ── */
    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 20px;
    }

    .card-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 16px;
      padding-bottom: 14px;
      border-bottom: 1px solid var(--border);
    }

    .card-title-text {
      font-family: 'Space Grotesk', sans-serif;
      font-size: 15px; font-weight: 700;
      color: var(--text);
      display: flex; align-items: center; gap: 8px;
    }

    /* ── STATS ── */
    .stats-grid {
      display: grid;
      gap: 16px;
      margin-bottom: 24px;
    }

    .stat-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 18px;
      position: relative;
      overflow: hidden;
      transition: transform 0.2s, border-color 0.2s;
    }

    .stat-card:hover {
      transform: translateY(-2px);
      border-color: var(--accent-color, var(--cyan));
    }

    .stat-card::before {
      content: '';
      position: absolute;
      top: 0; right: 0;
      width: 80px; height: 80px;
      background: var(--accent-bg, rgba(0,229,255,0.1));
      border-radius: 0 14px 0 80px;
    }

    .stat-icon {
      width: 38px; height: 38px;
      background: var(--accent-bg, rgba(0,229,255,0.1));
      border-radius: 10px;
      display: flex; align-items: center; justify-content: center;
      font-size: 16px;
      color: var(--accent-color, var(--cyan));
      margin-bottom: 12px;
    }

    .stat-value {
      font-family: 'Space Grotesk', sans-serif;
      font-size: 24px; font-weight: 700;
      color: var(--text);
      line-height: 1;
      margin-bottom: 4px;
    }

    .stat-label {
      font-size: 12px; color: var(--muted); font-weight: 500;
    }

    /* ── BUTTONS ── */
    .btn {
      display: inline-flex; align-items: center; gap: 6px;
      padding: 8px 16px;
      border-radius: 10px;
      font-size: 13px; font-weight: 600;
      cursor: pointer; border: none;
      text-decoration: none;
      transition: all 0.2s;
      font-family: 'Inter', sans-serif;
    }

    .btn-primary {
      background: linear-gradient(135deg, #00E5FF, #00B8D4);
      color: #000;
    }

    .btn-primary:hover {
      transform: translateY(-1px);
      box-shadow: 0 4px 15px rgba(0,229,255,0.3);
    }

    .btn-secondary {
      background: rgba(255,255,255,0.06);
      border: 1px solid var(--border2);
      color: var(--text2);
    }

    .btn-secondary:hover {
      background: rgba(255,255,255,0.1);
      color: var(--text);
    }

    .btn-danger {
      background: rgba(239,68,68,0.1);
      border: 1px solid rgba(239,68,68,0.25);
      color: #FCA5A5;
    }

    .btn-danger:hover {
      background: rgba(239,68,68,0.18);
      border-color: rgba(239,68,68,0.45);
      color: #FECACA;
    }

    .btn-sm { padding: 6px 12px; font-size: 12px; }

    /* ── TABLE ── */
    .table-wrap { overflow-x: auto; }

    table { width: 100%; border-collapse: collapse; }

    th {
      background: rgba(255,255,255,0.03);
      color: var(--muted);
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      padding: 10px 14px;
      text-align: left;
      border-bottom: 1px solid var(--border);
    }

    td {
      padding: 12px 14px;
      border-bottom: 1px solid rgba(255,255,255,0.03);
      font-size: 13px;
      color: var(--text2);
      vertical-align: middle;
    }

    tr:hover td { background: rgba(255,255,255,0.02); }
    tr:last-child td { border-bottom: none; }

    /* ── BADGES ── */
    .badge {
      display: inline-flex; align-items: center; gap: 4px;
      padding: 3px 8px;
      border-radius: 6px;
      font-size: 11px; font-weight: 700;
      text-transform: uppercase; letter-spacing: 0.3px;
    }

    .badge-success { background: rgba(16,185,129,0.15); color: #6EE7B7; border: 1px solid rgba(16,185,129,0.3); }
    .badge-error   { background: rgba(239,68,68,0.15);  color: #FCA5A5; border: 1px solid rgba(239,68,68,0.3);  }
    .badge-warning { background: rgba(245,158,11,0.15); color: #FCD34D; border: 1px solid rgba(245,158,11,0.3); }
    .badge-cyan    { background: rgba(0,229,255,0.1);   color: #67E8F9; border: 1px solid rgba(0,229,255,0.2);  }
    .badge-purple  { background: rgba(139,92,246,0.15); color: #C4B5FD; border: 1px solid rgba(139,92,246,0.3); }

    /* ── FORMS ── */
    .form-group { margin-bottom: 18px; }

    .form-label {
      display: block;
      font-size: 12px; font-weight: 600;
      color: var(--muted);
      text-transform: uppercase; letter-spacing: 0.5px;
      margin-bottom: 8px;
    }

    .form-input, .form-select, .form-textarea {
      width: 100%;
      background: rgba(255,255,255,0.04);
      border: 1px solid var(--border2);
      border-radius: 10px;
      padding: 10px 14px;
      color: var(--text);
      font-size: 14px;
      font-family: 'Inter', sans-serif;
      outline: none;
      transition: border-color 0.2s, background 0.2s;
    }

    .form-input:focus, .form-select:focus, .form-textarea:focus {
      border-color: rgba(0,229,255,0.4);
      background: rgba(0,229,255,0.03);
    }

    .form-select { cursor: pointer; }
    .form-select option { background: var(--card); }
    .form-textarea { resize: vertical; min-height: 80px; }

    .form-row {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 16px;
    }

    /* ── UTILS ── */
    .mb-16 { margin-bottom: 16px; }
    .mb-20 { margin-bottom: 20px; }
    .mb-24 { margin-bottom: 24px; }
    .text-muted { color: var(--muted); font-size: 13px; }
    .flex-between { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px; }
    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }

    /* ── SCROLLBAR ── */
    ::-webkit-scrollbar { width: 6px; height: 6px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 3px; }
    ::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.2); }

    /* ── RESPONSIVE ── */
    @media (max-width: 768px) {
      .sidebar { transform: translateX(-100%); }
      .main-wrap { margin-left: 0; }
      .grid-2 { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>

<!-- SIDEBAR -->
<aside class="sidebar">
  <div class="sidebar-logo">
    <div class="icon">⚡</div>
    <div>
      <div class="name">Tunnel</div>
      <div class="sub">Admin Panel</div>
    </div>
  </div>

  <nav class="sidebar-nav">
    <div class="nav-section">Main</div>
    <a href="<?= ADMIN_URL ?>/dashboard/index.php"
       class="nav-item <?= $currentPage === 'dashboard' ? 'active' : '' ?>">
      <i class="fas fa-tachometer-alt"></i> Dashboard
    </a>

    <div class="nav-section">Content</div>
    <a href="<?= ADMIN_URL ?>/mcq_exams/index.php"
       class="nav-item <?= $currentPage === 'mcq_exams' ? 'active' : '' ?>">
      <i class="fas fa-bolt"></i> Practice Sets (5000 MCQ)
    </a>
    <a href="<?= ADMIN_URL ?>/sets/index.php?cat=mcq&ungrouped=1"
       class="nav-item <?= navSectionActive($currentPage, $currentCat, 'mcq') ?>">
      <i class="fas fa-quote-right"></i> Free Practice MCQs
    </a>
    <a href="<?= ADMIN_URL ?>/sets/index.php?cat=tunnlity"
       class="nav-item <?= navSectionActive($currentPage, $currentCat, 'tunnlity') ?>">
      <i class="fas fa-bolt"></i> Test Your Tunnlity
    </a>
    <a href="<?= ADMIN_URL ?>/tricks/index.php"
       class="nav-item <?= $currentPage === 'tricks' ? 'active' : '' ?>">
      <i class="fas fa-magic"></i> Tricks
    </a>
    <a href="<?= ADMIN_URL ?>/shorts/index.php"
       class="nav-item <?= $currentPage === 'shorts' ? 'active' : '' ?>">
      <i class="fab fa-youtube"></i> Shorts
    </a>
    <a href="<?= ADMIN_URL ?>/previous_year/index.php"
       class="nav-item <?= $currentPage === 'previous_year' ? 'active' : '' ?>">
      <i class="fas fa-archive"></i> Previous Year
    </a>

    <!-- ✅ CAROUSEL BANNERS — Content ke end mein -->
    <a href="<?= ADMIN_URL ?>/banners/index.php"
       class="nav-item <?= $currentPage === 'banners' ? 'active' : '' ?>">
      <i class="fas fa-images"></i> Carousel Banners
    </a>

    <div class="nav-section">Practice</div>
    <a href="<?= ADMIN_URL ?>/daily_dose/index.php"
       class="nav-item <?= $currentPage === 'daily_dose' ? 'active' : '' ?>">
      <i class="fas fa-bolt"></i> Daily Dose
    </a>
    <a href="<?= ADMIN_URL ?>/daily_practice/index.php"
       class="nav-item <?= $currentPage === 'daily_practice' ? 'active' : '' ?>">
      <i class="fas fa-dumbbell"></i> Daily Practice
    </a>

    <div class="nav-section">Engage</div>
    <a href="<?= ADMIN_URL ?>/solve_earn/index.php"
       class="nav-item <?= $currentPage === 'solve_earn' ? 'active' : '' ?>">
      <i class="fas fa-trophy"></i> Solve & Earn
    </a>
    <a href="<?= ADMIN_URL ?>/notifications/index.php"
       class="nav-item <?= $currentPage === 'notifications' ? 'active' : '' ?>">
      <i class="fas fa-bell"></i> Notifications
    </a>
    <a href="<?= ADMIN_URL ?>/reports/index.php"
       class="nav-item <?= $currentPage === 'reports' ? 'active' : '' ?>">
      <i class="fas fa-triangle-exclamation"></i> Technical Reports
    </a>

    <div class="nav-section">Users</div>
    <a href="<?= ADMIN_URL ?>/users/index.php"
       class="nav-item <?= $currentPage === 'users' ? 'active' : '' ?>">
      <i class="fas fa-users"></i> Users
    </a>
    <a href="<?= ADMIN_URL ?>/premium/index.php"
       class="nav-item <?= $currentPage === 'premium' ? 'active' : '' ?>">
      <i class="fas fa-crown"></i> Premium
    </a>
    <a href="<?= ADMIN_URL ?>/coupons/index.php"
       class="nav-item <?= $currentPage === 'coupons' ? 'active' : '' ?>">
      <i class="fas fa-ticket-alt"></i> Coupons
    </a>

    <div class="nav-section">System</div>
    <a href="<?= ADMIN_URL ?>/app_settings/index.php"
       class="nav-item <?= $currentPage === 'app_settings' ? 'active' : '' ?>">
      <i class="fas fa-cog"></i> App Settings
    </a>
  </nav>

  <div class="sidebar-footer">
    <div class="admin-info">
      <div class="admin-avatar"><?= strtoupper(substr($adminName, 0, 1)) ?></div>
      <div>
        <div class="admin-name"><?= htmlspecialchars($adminName) ?></div>
        <div class="admin-role"><?= $_SESSION['admin_role'] ?? 'Admin' ?></div>
      </div>
    </div>
    <a href="<?= ADMIN_URL ?>/auth/logout.php" class="logout-btn">
      <i class="fas fa-sign-out-alt"></i> Logout
    </a>
  </div>
</aside>

<!-- MAIN -->
<div class="main-wrap">
  <div class="topbar">
    <div class="topbar-title"><?= $pageTitle ?? 'Dashboard' ?></div>
    <div class="topbar-right">
      <span class="topbar-time" id="clock"></span>
    </div>
  </div>
  <div class="content">

<script>
(function tick() {
  const n = new Date();
  const t = n.toLocaleTimeString('en-IN', {hour:'2-digit',minute:'2-digit',second:'2-digit'});
  const d = n.toLocaleDateString('en-IN', {weekday:'short',day:'numeric',month:'short'});
  const el = document.getElementById('clock');
  if (el) el.textContent = d + ' · ' + t;
  setTimeout(tick, 1000);
})();
</script>