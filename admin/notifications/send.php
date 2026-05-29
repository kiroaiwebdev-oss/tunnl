<?php
$pageTitle = 'Send Notification';
require_once dirname(__DIR__) . '/includes/header.php';
require_once dirname(__DIR__) . '/config/constants.php';

$success = $error = '';
$sentCount = 0;

function sendFCMNotification($tokens, $title, $message, $data = []) {
    $url = 'https://fcm.googleapis.com/fcm/send';

    $payload = [
        'registration_ids' => $tokens,
        'notification'     => [
            'title' => $title,
            'body'  => $message,
            'sound' => 'default',
            'badge' => '1',
        ],
        'data'    => $data,
        'priority'=> 'high',
    ];

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_HTTPHEADER     => [
            'Authorization: key=' . FCM_SERVER_KEY,
            'Content-Type: application/json',
        ],
        CURLOPT_POSTFIELDS     => json_encode($payload),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_SSL_VERIFYPEER => false,
    ]);
    $result = curl_exec($ch);
    curl_close($ch);
    return json_decode($result, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $title   = trim($_POST['title']   ?? '');
    $message = trim($_POST['message'] ?? '');
    $target  = $_POST['target']  ?? 'all';
    $type    = $_POST['type']    ?? 'general';
    $link    = trim($_POST['link'] ?? '');

    if (empty($title) || empty($message)) {
        $error = 'Title and message are required!';
    } else {
        // Get FCM tokens
        $where = "fcm_token IS NOT NULL AND fcm_token != ''";
        if ($target === 'premium') $where .= " AND is_premium = 1";
        if ($target === 'free')    $where .= " AND is_premium = 0";

        $tokens = $pdo->query("SELECT fcm_token FROM users WHERE $where")
                      ->fetchAll(PDO::FETCH_COLUMN);

        if (empty($tokens)) {
            $error = 'No users with FCM tokens found for this target!';
        } else {
            // Send in batches of 500 (FCM limit)
            $batches   = array_chunk($tokens, 500);
            $failCount = 0;

            foreach ($batches as $batch) {
                $data = ['type' => $type];
                if ($link) $data['link'] = $link;

                $res = sendFCMNotification($batch, $title, $message, $data);
                if ($res) {
                    $sentCount += ($res['success'] ?? 0);
                    $failCount += ($res['failure'] ?? 0);
                }
            }

            // Log to DB
            $pdo->prepare("
                INSERT INTO notifications
                  (title, message, target, type, link, sent_count, status, sent_at)
                VALUES (?,?,?,?,?,?,'sent',NOW())
            ")->execute([$title, $message, $target, $type, $link, $sentCount]);

            $success = "✅ Notification sent to $sentCount users!";
            if ($failCount > 0) {
                $success .= " ($failCount failed — stale tokens)";
            }
        }
    }
}

// Templates
$templates = [
    'new_content' => ['🆕 New Content Available!',   'Check out the latest tricks and questions added for you!'],
    'challenge'   => ['🏆 Weekly Challenge is LIVE!', 'Solve this week\'s challenge and win exciting prizes!'],
    'reminder'    => ['📚 Daily Practice Reminder',   'Don\'t break your streak! Complete today\'s practice now.'],
    'offer'       => ['🔥 Special Offer!',            'Get Premium access at a special discounted price today only!'],
    'daily_dose'  => ['💡 Today\'s Math Dose',        'A fresh math tip is waiting for you on the dashboard!'],
];
?>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;
  padding:14px 18px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:10px">
  <i class="fas fa-check-circle fa-lg"></i>
  <div style="font-weight:600"><?= $success ?></div>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;
  padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-exclamation-circle"></i> <?= $error ?>
</div>
<?php endif; ?>

<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">Send Notification</h2>
    <p class="text-muted">Push notification to app users via FCM</p>
  </div>
  <a href="<?= ADMIN_URL ?>/notifications/index.php" class="btn btn-secondary">
    <i class="fas fa-arrow-left"></i> History
  </a>
</div>

<div class="grid-2">

<!-- Send Form -->
<form method="POST">
<div class="card mb-16">
  <div class="card-header">
    <div class="card-title-text">
      <i class="fas fa-paper-plane" style="color:var(--cyan)"></i> Compose
    </div>
  </div>

  <!-- Quick Templates -->
  <div style="margin-bottom:16px">
    <div class="form-label" style="margin-bottom:8px">⚡ Quick Templates</div>
    <div style="display:flex;gap:6px;flex-wrap:wrap">
      <?php foreach ($templates as $key => [$t,$m]): ?>
      <button type="button"
        onclick="fillTemplate('<?= addslashes($t) ?>','<?= addslashes($m) ?>','<?= $key ?>')"
        style="padding:5px 10px;border-radius:8px;border:1px solid var(--border);
          background:var(--dark);color:var(--muted);font-size:11px;cursor:pointer;
          transition:all 0.2s;font-family:'Inter',sans-serif"
        onmouseover="this.style.borderColor='var(--cyan)';this.style.color='var(--cyan)'"
        onmouseout="this.style.borderColor='var(--border)';this.style.color='var(--muted)'">
        <?= $t ?>
      </button>
      <?php endforeach; ?>
    </div>
  </div>

  <div class="form-group">
    <label class="form-label">Title * <span style="color:var(--muted);font-weight:400">(max 50 chars)</span></label>
    <input type="text" name="title" id="notifTitle" class="form-input" required
      maxlength="50"
      value="<?= htmlspecialchars($_POST['title'] ?? '') ?>"
      placeholder="Notification title..."
      oninput="updatePreview()">
  </div>

  <div class="form-group">
    <label class="form-label">Message * <span style="color:var(--muted);font-weight:400">(max 150 chars)</span></label>
    <textarea name="message" id="notifMessage" class="form-textarea" required
      maxlength="150" rows="3"
      placeholder="Notification body..."
      oninput="updatePreview()"><?= htmlspecialchars($_POST['message'] ?? '') ?></textarea>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label">Target Users</label>
      <select name="target" id="notifTarget" class="form-select" onchange="updateCount()">
        <option value="all"     <?= ($_POST['target']??'')==='all'    ?'selected':'' ?>>
          🌐 All Users
        </option>
        <option value="premium" <?= ($_POST['target']??'')==='premium'?'selected':'' ?>>
          👑 Premium Only
        </option>
        <option value="free"    <?= ($_POST['target']??'')==='free'   ?'selected':'' ?>>
          🆓 Free Only
        </option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Type</label>
      <select name="type" id="notifType" class="form-select">
        <option value="general">🔔 General</option>
        <option value="new_content">⭐ New Content</option>
        <option value="offer">🏷️ Offer</option>
        <option value="challenge">🏆 Challenge</option>
        <option value="reminder">⏰ Reminder</option>
      </select>
    </div>
  </div>

  <div class="form-group">
    <label class="form-label">Deep Link (Optional)</label>
    <input type="text" name="link" class="form-input"
      value="<?= htmlspecialchars($_POST['link'] ?? '') ?>"
      placeholder="e.g. app://daily_practice or app://challenge">
  </div>

  <div style="background:rgba(239,68,68,0.08);border:1px solid rgba(239,68,68,0.2);
    border-radius:10px;padding:12px;margin-bottom:16px;display:flex;align-items:center;gap:10px">
    <i class="fas fa-exclamation-triangle" style="color:var(--error)"></i>
    <span style="font-size:12px;color:var(--muted)">
      This will send to <strong id="targetCount" style="color:var(--error)">all</strong> users.
      Cannot be undone!
    </span>
  </div>

  <button type="submit" class="btn btn-primary" style="width:100%"
    onclick="return confirm('Send this notification to all target users?')">
    <i class="fas fa-paper-plane"></i> Send Notification Now
  </button>
</div>
</form>

<!-- Live Preview -->
<div>
  <div class="card">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-mobile-alt" style="color:var(--success)"></i> Live Preview
      </div>
    </div>

    <!-- Android Notification Mock -->
    <div style="background:#1C1C1E;border-radius:16px;padding:16px;margin-bottom:16px">
      <div style="font-size:10px;color:#888;margin-bottom:10px;text-transform:uppercase;
        letter-spacing:1px">Android Preview</div>
      <div style="background:#2C2C2E;border-radius:12px;padding:14px">
        <div style="display:flex;align-items:flex-start;gap:10px">
          <div style="width:36px;height:36px;background:linear-gradient(135deg,#00E5FF,#00B8D4);
            border-radius:10px;display:flex;align-items:center;justify-content:center;
            font-size:16px;flex-shrink:0">⚡</div>
          <div style="flex:1">
            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:3px">
              <span style="font-size:11px;color:#888;font-weight:600">Mathematical Void</span>
              <span style="font-size:10px;color:#666">now</span>
            </div>
            <div id="prevTitle" style="font-size:13px;font-weight:700;color:#FFF;margin-bottom:2px">
              Notification Title
            </div>
            <div id="prevMessage" style="font-size:12px;color:#AAA;line-height:1.4">
              Notification message appears here...
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- User Count Info -->
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
      <?php
      $allTokens     = $pdo->query("SELECT COUNT(*) FROM users WHERE fcm_token IS NOT NULL")->fetchColumn();
      $premiumTokens = $pdo->query("SELECT COUNT(*) FROM users WHERE fcm_token IS NOT NULL AND is_premium=1")->fetchColumn();
      $freeTokens    = $allTokens - $premiumTokens;
      ?>
      <?php foreach ([
        ['All Users',     $allTokens,     'var(--cyan)'],
        ['Premium',       $premiumTokens, 'var(--warning)'],
        ['Free Users',    $freeTokens,    'var(--success)'],
      ] as [$label,$count,$color]): ?>
      <div style="background:var(--dark);border:1px solid var(--border);border-radius:10px;padding:12px;text-align:center">
        <div style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700;color:<?= $color ?>">
          <?= number_format($count) ?>
        </div>
        <div style="font-size:11px;color:var(--muted)"><?= $label ?></div>
      </div>
      <?php endforeach; ?>
    </div>
  </div>
</div>

</div>

<script>
const allTokens     = <?= $allTokens ?>;
const premiumTokens = <?= $premiumTokens ?>;
const freeTokens    = <?= $freeTokens ?>;

function updatePreview() {
  const title = document.getElementById('notifTitle').value   || 'Notification Title';
  const msg   = document.getElementById('notifMessage').value || 'Notification message appears here...';
  document.getElementById('prevTitle').textContent   = title;
  document.getElementById('prevMessage').textContent = msg;
}

function updateCount() {
  const target = document.getElementById('notifTarget').value;
  const counts = { all: allTokens, premium: premiumTokens, free: freeTokens };
  document.getElementById('targetCount').textContent =
    (counts[target] || 0).toLocaleString() + ' ' + target;
}

function fillTemplate(title, msg, type) {
  document.getElementById('notifTitle').value   = title;
  document.getElementById('notifMessage').value = msg;
  document.getElementById('notifType').value    = type;
  updatePreview();
}

updateCount();
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>