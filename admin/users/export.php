<?php
require_once dirname(__DIR__) . '/config/auth_check.php';
require_once dirname(__DIR__) . '/config/db.php';

$search = $_GET['search'] ?? '';
$filter = $_GET['filter'] ?? '';

$where  = ['1=1'];
$params = [];

if ($search) {
    $where[]  = '(name LIKE ? OR phone LIKE ?)';
    $params[] = "%$search%";
    $params[] = "%$search%";
}
if ($filter === 'premium') { $where[] = 'is_premium = 1'; }
if ($filter === 'free')    { $where[] = 'is_premium = 0'; }

$whereSQL = implode(' AND ', $where);

$users = $pdo->prepare("
    SELECT id, name, phone, is_premium, total_xp,
           current_streak, rank_position, created_at
    FROM users WHERE $whereSQL ORDER BY created_at DESC
");
$users->execute($params);
$users = $users->fetchAll();

header('Content-Type: text/csv');
header('Content-Disposition: attachment; filename="users_' . date('Y-m-d') . '.csv"');

$out = fopen('php://output', 'w');
fputcsv($out, ['ID','Name','Phone','Premium','XP','Streak','Rank','Joined']);

foreach ($users as $u) {
    fputcsv($out, [
        $u['id'],
        $u['name'],
        $u['phone'],
        $u['is_premium'] ? 'YES' : 'NO',
        $u['total_xp'],
        $u['current_streak'],
        $u['rank_position'] ?: '-',
        date('d M Y', strtotime($u['created_at'])),
    ]);
}

fclose($out);
exit;