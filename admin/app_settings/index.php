<?php
$pageTitle = 'App Settings';
require_once dirname(__DIR__) . '/includes/header.php';

$success = '';
$error   = '';

// ── SAVE SETTINGS
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $fields = [
            'app_name', 'app_tagline', 'primary_color',
            'contact_phone', 'contact_email',
            'youtube_url', 'telegram_url', 'instagram_url',
            'privacy_policy', 'about_us',
            'maintenance_mode', 'force_update',
            'min_app_version', 'premium_price',
            'premium_yearly_price', 'premium_lifetime_price',
            'daily_dose_text', 'daily_dose_active',
            // Razorpay
            'razorpay_enabled', 'razorpay_key_id', 'razorpay_key_secret',
            // OTP / SMS
            'sms_provider', 'sms_api_key', 'sms_sender_id',
            'otp_expiry_minutes', 'otp_message',
        ];

        $stmt = $pdo->prepare("
            INSERT INTO app_settings (setting_key, setting_value)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)
        ");

        foreach ($fields as $field) {
            $value = $_POST[$field] ?? '';
            $stmt->execute([$field, $value]);
        }

        $success = 'Settings saved successfully!';
    } catch (Exception $e) {
        $error = 'Error: ' . $e->getMessage();
    }
}

// ── LOAD SETTINGS
$settingsRaw = $pdo->query("SELECT setting_key, setting_value FROM app_settings")->fetchAll();
$s = [];
foreach ($settingsRaw as $row) {
    $s[$row['setting_key']] = $row['setting_value'];
}
?>

<?php if ($success): ?>
<div class="alert alert-success" style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $success ?>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div class="alert alert-error" style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-exclamation-circle"></i> <?= $error ?>
</div>
<?php endif; ?>

<form method="POST">

<!-- ── TABS ── -->
<div style="display:flex;gap:8px;margin-bottom:24px;flex-wrap:wrap">
  <button type="button" class="tab-btn active" onclick="showTab('general',this)">
    <i class="fas fa-mobile-alt"></i> General
  </button>
  <button type="button" class="tab-btn" onclick="showTab('contact',this)">
    <i class="fas fa-address-book"></i> Contact & Social
  </button>
  <button type="button" class="tab-btn" onclick="showTab('content',this)">
    <i class="fas fa-file-alt"></i> Content
  </button>
  <button type="button" class="tab-btn" onclick="showTab('premium',this)">
    <i class="fas fa-crown"></i> Premium
  </button>
  <button type="button" class="tab-btn" onclick="showTab('otp',this)">
    <i class="fas fa-sms"></i> OTP Service
  </button>
  <button type="button" class="tab-btn" onclick="showTab('danger',this)">
    <i class="fas fa-shield-alt"></i> System
  </button>
</div>

<style>
.tab-btn {
  padding: 9px 18px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--card);
  color: var(--muted);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  display: inline-flex;
  align-items: center;
  gap: 7px;
  font-family: 'Inter', sans-serif;
}
.tab-btn:hover { border-color: var(--cyan); color: var(--cyan); }
.tab-btn.active {
  background: rgba(0,229,255,0.1);
  border-color: rgba(0,229,255,0.3);
  color: var(--cyan);
}
.tab-panel { display: none; }
.tab-panel.active { display: block; }
.setting-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 0;
  border-bottom: 1px solid rgba(255,255,255,0.04);
}
.setting-row:last-child { border-bottom: none; }
.setting-info { flex: 1; margin-right: 20px; }
.setting-title { font-size: 14px; font-weight: 600; color: var(--text); margin-bottom: 3px; }
.setting-desc  { font-size: 12px; color: var(--muted); }
.setting-control { flex-shrink: 0; min-width: 200px; }
.toggle-wrap { display: flex; align-items: center; gap: 10px; }
.toggle {
  position: relative;
  width: 46px;
  height: 26px;
  cursor: pointer;
}
.toggle input { opacity: 0; width: 0; height: 0; }
.toggle-slider {
  position: absolute;
  inset: 0;
  background: var(--border2);
  border-radius: 13px;
  transition: 0.3s;
}
.toggle-slider::before {
  content: '';
  position: absolute;
  width: 18px;
  height: 18px;
  left: 4px;
  top: 4px;
  background: white;
  border-radius: 50%;
  transition: 0.3s;
}
.toggle input:checked + .toggle-slider { background: var(--cyan); }
.toggle input:checked + .toggle-slider::before { transform: translateX(20px); }
.color-preview { display: flex; align-items: center; gap: 10px; }
.color-swatch {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  border: 1px solid var(--border);
  cursor: pointer;
}
</style>

<!-- ════ TAB 1: GENERAL ════ -->
<div class="tab-panel active" id="tab-general">
  <div class="card mb-24">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-mobile-alt" style="color:var(--cyan)"></i> App Identity
      </div>
    </div>
    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">App Name</div>
        <div class="setting-desc">Shown in app header, splash screen & notifications</div>
      </div>
      <div class="setting-control">
        <input type="text" name="app_name" class="form-input"
          value="<?= htmlspecialchars($s['app_name'] ?? 'Mathematical Void') ?>">
      </div>
    </div>
    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">App Tagline</div>
        <div class="setting-desc">Subtitle shown on splash & dashboard</div>
      </div>
      <div class="setting-control">
        <input type="text" name="app_tagline" class="form-input"
          value="<?= htmlspecialchars($s['app_tagline'] ?? '') ?>">
      </div>
    </div>
    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">Primary Color</div>
        <div class="setting-desc">Main accent color used throughout the app</div>
      </div>
      <div class="setting-control">
        <div class="color-preview">
          <input type="color" name="primary_color" id="colorPicker"
            value="<?= $s['primary_color'] ?? '#00E5FF' ?>"
            class="color-swatch"
            onchange="document.getElementById('colorHex').value=this.value">
          <input type="text" id="colorHex" class="form-input"
            value="<?= $s['primary_color'] ?? '#00E5FF' ?>"
            style="width:110px"
            onchange="document.getElementById('colorPicker').value=this.value">
        </div>
      </div>
    </div>
    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">App Version</div>
        <div class="setting-desc">Minimum version required (force update)</div>
      </div>
      <div class="setting-control">
        <input type="text" name="min_app_version" class="form-input"
          value="<?= htmlspecialchars($s['min_app_version'] ?? '1.0.0') ?>"
          placeholder="1.0.0">
      </div>
    </div>
  </div>
</div>

<!-- ════ TAB 2: CONTACT & SOCIAL ════ -->
<div class="tab-panel" id="tab-contact">
  <div class="card mb-24">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-address-book" style="color:var(--success)"></i> Contact Information
      </div>
    </div>
    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">Support Phone</div>
        <div class="setting-desc">Shown in Help & Support section</div>
      </div>
      <div class="setting-control">
        <input type="text" name="contact_phone" class="form-input"
          value="<?= htmlspecialchars($s['contact_phone'] ?? '') ?>"
          placeholder="+91 XXXXXXXXXX">
      </div>
    </div>
    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">Support Email</div>
        <div class="setting-desc">Shown in Help & Support section</div>
      </div>
      <div class="setting-control">
        <input type="email" name="contact_email" class="form-input"
          value="<?= htmlspecialchars($s['contact_email'] ?? '') ?>"
          placeholder="support@yourapp.com">
      </div>
    </div>
  </div>
  <div class="card mb-24">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-share-alt" style="color:var(--purple)"></i> Social Links
      </div>
    </div>
    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title"><i class="fab fa-youtube" style="color:#FF0000"></i> YouTube Channel</div>
        <div class="setting-desc">Shown in Shorts & Help section</div>
      </div>
      <div class="setting-control">
        <input type="url" name="youtube_url" class="form-input"
          value="<?= htmlspecialchars($s['youtube_url'] ?? '') ?>"
          placeholder="https://youtube.com/@channel">
      </div>
    </div>
    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title"><i class="fab fa-telegram" style="color:#0088cc"></i> Telegram Group</div>
        <div class="setting-desc">Community Telegram link</div>
      </div>
      <div class="setting-control">
        <input type="url" name="telegram_url" class="form-input"
          value="<?= htmlspecialchars($s['telegram_url'] ?? '') ?>"
          placeholder="https://t.me/yourgroup">
      </div>
    </div>
    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title"><i class="fab fa-instagram" style="color:#E1306C"></i> Instagram</div>
        <div class="setting-desc">Instagram profile link</div>
      </div>
      <div class="setting-control">
        <input type="url" name="instagram_url" class="form-input"
          value="<?= htmlspecialchars($s['instagram_url'] ?? '') ?>"
          placeholder="https://instagram.com/yourpage">
      </div>
    </div>
  </div>
</div>

<!-- ════ TAB 3: CONTENT ════ -->
<div class="tab-panel" id="tab-content">
  <div class="card mb-24">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-sun" style="color:var(--warning)"></i> Daily Dose
      </div>
    </div>
    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">Daily Dose Status</div>
        <div class="setting-desc">Show/hide daily dose card on dashboard</div>
      </div>
      <div class="setting-control">
        <div class="toggle-wrap">
          <label class="toggle">
            <input type="checkbox" name="daily_dose_active" value="1"
              <?= ($s['daily_dose_active'] ?? '1') == '1' ? 'checked' : '' ?>>
            <span class="toggle-slider"></span>
          </label>
          <span style="font-size:13px;color:var(--muted)">Show on Dashboard</span>
        </div>
      </div>
    </div>
    <div class="setting-row" style="flex-direction:column;align-items:flex-start;gap:10px">
      <div class="setting-info" style="margin:0">
        <div class="setting-title">Default Daily Dose Text</div>
        <div class="setting-desc">Fallback text when no dose is scheduled</div>
      </div>
      <textarea name="daily_dose_text" class="form-textarea" style="width:100%"
        placeholder="Today's tip..."><?= htmlspecialchars($s['daily_dose_text'] ?? '') ?></textarea>
    </div>
  </div>
  <div class="card mb-24">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-shield-alt" style="color:var(--muted)"></i> Privacy Policy
      </div>
    </div>
    <textarea name="privacy_policy" class="form-textarea" rows="8" style="width:100%"
      placeholder="Write your privacy policy here..."><?= htmlspecialchars($s['privacy_policy'] ?? '') ?></textarea>
  </div>
  <div class="card mb-24">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-info-circle" style="color:var(--cyan)"></i> About Us
      </div>
    </div>
    <textarea name="about_us" class="form-textarea" rows="6" style="width:100%"
      placeholder="Write about your app..."><?= htmlspecialchars($s['about_us'] ?? '') ?></textarea>
  </div>
</div>

<!-- ════ TAB 4: PREMIUM ════ -->
<div class="tab-panel" id="tab-premium">
  <div class="card mb-24">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-crown" style="color:var(--warning)"></i> Premium Settings
      </div>
    </div>
    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">Premium Price (₹)</div>
        <div class="setting-desc">Lifetime premium price shown in app</div>
      </div>
      <div class="setting-control">
        <div style="display:flex;align-items:center;gap:8px">
          <span style="font-size:18px;color:var(--warning);font-weight:700">₹</span>
          <input type="number" name="premium_price" class="form-input"
            value="<?= htmlspecialchars($s['premium_price'] ?? '50') ?>"
            placeholder="50" style="width:120px">
        </div>
      </div>
    </div>
    <div style="background:linear-gradient(135deg,#1A1400,#2A2000);border:1px solid rgba(245,158,11,0.3);border-radius:14px;padding:16px;margin-top:16px">
      <div style="font-size:12px;color:var(--muted);margin-bottom:8px;text-transform:uppercase;letter-spacing:1px">Live Preview in App:</div>
      <div style="display:flex;align-items:center;justify-content:space-between">
        <div>
          <div style="font-weight:700;color:#F59E0B">Unlock Premium</div>
          <div style="font-size:12px;color:var(--muted)">Get complete access @ ₹<span id="pricePreview"><?= $s['premium_price'] ?? '50' ?></span></div>
        </div>
        <div style="background:linear-gradient(135deg,#FFD600,#FF8F00);padding:8px 16px;border-radius:20px;font-weight:700;color:#000">
          ₹<span id="pricePreview2"><?= $s['premium_price'] ?? '50' ?></span>
        </div>
      </div>
    </div>
  </div>

  <!-- ── Razorpay Gateway ── -->
  <div class="card mb-24">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-credit-card" style="color:#3B82F6"></i> Razorpay Payment Gateway
      </div>
    </div>

    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">Enable Razorpay</div>
        <div class="setting-desc">Turn on real payment via Razorpay (Test/Live)</div>
      </div>
      <div class="setting-control">
        <select name="razorpay_enabled" class="form-input" style="width:160px">
          <option value="1" <?= ($s['razorpay_enabled'] ?? '0') == '1' ? 'selected' : '' ?>>Enabled</option>
          <option value="0" <?= ($s['razorpay_enabled'] ?? '0') == '0' ? 'selected' : '' ?>>Disabled</option>
        </select>
      </div>
    </div>

    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">Razorpay Key ID</div>
        <div class="setting-desc">Public key (rzp_test_xxx or rzp_live_xxx) — exposed to app</div>
      </div>
      <div class="setting-control">
        <input type="text" name="razorpay_key_id" class="form-input"
          value="<?= htmlspecialchars($s['razorpay_key_id'] ?? '') ?>"
          placeholder="rzp_test_xxxxxxxxxxxx" style="width:280px;font-family:monospace">
      </div>
    </div>

    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">Razorpay Key Secret</div>
        <div class="setting-desc">Server-side only — never sent to app. Used to sign &amp; verify orders.</div>
      </div>
      <div class="setting-control">
        <input type="password" name="razorpay_key_secret" class="form-input"
          value="<?= htmlspecialchars($s['razorpay_key_secret'] ?? '') ?>"
          placeholder="••••••••••••••••" style="width:280px;font-family:monospace"
          autocomplete="new-password">
      </div>
    </div>

    <div style="background:rgba(59,130,246,0.08);border:1px solid rgba(59,130,246,0.3);border-radius:12px;padding:12px 14px;margin-top:12px;font-size:12px;color:var(--muted);line-height:1.6">
      <i class="fas fa-info-circle" style="color:#3B82F6"></i>
      <strong style="color:#93C5FD">How it works:</strong> Saving these fills the keys instantly — app refreshes settings on resume,
      no rebuild needed. Use <code>rzp_test_*</code> keys to test, switch to <code>rzp_live_*</code> when going live.
    </div>
  </div>

  <!-- ── Plan Pricing ── -->
  <div class="card mb-24">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-tags" style="color:var(--cyan)"></i> Plan Pricing (₹)
      </div>
    </div>

    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">Monthly / Default Price</div>
        <div class="setting-desc">Controlled by <strong>Premium Price</strong> field above (<code>premium_price</code>). This is the price the app charges.</div>
      </div>
      <div class="setting-control">
        <div style="font-size:18px;font-weight:700;color:var(--cyan)">₹<?= htmlspecialchars($s['premium_price'] ?? '50') ?></div>
      </div>
    </div>

    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">Yearly Price</div>
        <div class="setting-desc">Used when plan = yearly</div>
      </div>
      <div class="setting-control">
        <input type="number" name="premium_yearly_price" class="form-input"
          value="<?= htmlspecialchars($s['premium_yearly_price'] ?? '499') ?>"
          placeholder="499" style="width:140px">
      </div>
    </div>

    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">Lifetime Price</div>
        <div class="setting-desc">One-time payment, no expiry</div>
      </div>
      <div class="setting-control">
        <input type="number" name="premium_lifetime_price" class="form-input"
          value="<?= htmlspecialchars($s['premium_lifetime_price'] ?? '50') ?>"
          placeholder="50" style="width:140px">
      </div>
    </div>
  </div>
</div>

<!-- ════ TAB 5: OTP SERVICE ════ -->
<div class="tab-panel" id="tab-otp">
  <div class="card mb-24">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-sms" style="color:var(--cyan)"></i> OTP / SMS Service
      </div>
    </div>

    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">SMS Provider</div>
        <div class="setting-desc">Select which SMS service to use for OTP</div>
      </div>
      <div class="setting-control">
        <select name="sms_provider" class="form-input">
          <option value="fast2sms"  <?= ($s['sms_provider'] ?? 'fast2sms') == 'fast2sms'  ? 'selected' : '' ?>>Fast2SMS (India — Recommended)</option>
          <option value="msg91"     <?= ($s['sms_provider'] ?? '') == 'msg91'     ? 'selected' : '' ?>>MSG91</option>
          <option value="twilio"    <?= ($s['sms_provider'] ?? '') == 'twilio'    ? 'selected' : '' ?>>Twilio</option>
          <option value="textlocal" <?= ($s['sms_provider'] ?? '') == 'textlocal' ? 'selected' : '' ?>>TextLocal</option>
        </select>
      </div>
    </div>

    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">API Key</div>
        <div class="setting-desc">Fast2SMS/MSG91: API key &nbsp;|&nbsp; Twilio: AccountSID:AuthToken</div>
      </div>
      <div class="setting-control">
        <input type="text" name="sms_api_key" class="form-input"
          value="<?= htmlspecialchars($s['sms_api_key'] ?? '') ?>"
          placeholder="Paste your API key here">
      </div>
    </div>

    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">Sender ID / From</div>
        <div class="setting-desc">Fast2SMS: leave blank &nbsp;|&nbsp; MSG91: Template ID &nbsp;|&nbsp; Twilio: +1XXXXXXXXXX</div>
      </div>
      <div class="setting-control">
        <input type="text" name="sms_sender_id" class="form-input"
          value="<?= htmlspecialchars($s['sms_sender_id'] ?? '') ?>"
          placeholder="TUNNEL or +1XXXXXXXXXX">
      </div>
    </div>

    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">OTP Expiry (minutes)</div>
        <div class="setting-desc">How long OTP stays valid</div>
      </div>
      <div class="setting-control">
        <input type="number" name="otp_expiry_minutes" class="form-input"
          value="<?= htmlspecialchars($s['otp_expiry_minutes'] ?? '10') ?>"
          placeholder="10" style="width:120px">
      </div>
    </div>

    <div class="setting-row" style="flex-direction:column;align-items:flex-start;gap:10px">
      <div class="setting-info" style="margin:0">
        <div class="setting-title">OTP Message Template</div>
        <div class="setting-desc">Use <code style="background:rgba(0,229,255,0.1);padding:2px 6px;border-radius:4px;color:var(--cyan)">{otp}</code> as placeholder</div>
      </div>
      <input type="text" name="otp_message" class="form-input" style="width:100%"
        value="<?= htmlspecialchars($s['otp_message'] ?? 'Your TUNNEL OTP is {otp}. Valid for 10 minutes. Do not share.') ?>">
    </div>

    <!-- Test OTP Section -->
    <div style="margin-top:20px;padding:16px;background:rgba(0,229,255,0.05);border:1px solid rgba(0,229,255,0.15);border-radius:12px">
      <div style="font-size:13px;font-weight:600;color:var(--cyan);margin-bottom:12px">
        <i class="fas fa-vial"></i> Send Test OTP (save settings first)
      </div>
      <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap">
        <input type="text" id="testPhone" class="form-input"
          placeholder="10-digit mobile number" style="width:200px">
        <button type="button" class="btn btn-primary btn-sm" onclick="sendTestOtp()">
          <i class="fas fa-paper-plane"></i> Send Test OTP
        </button>
        <span id="testResult" style="font-size:13px;color:var(--muted)"></span>
      </div>
    </div>

    <!-- Provider Help -->
    <div style="margin-top:16px;padding:16px;background:rgba(255,255,255,0.02);border:1px solid rgba(255,255,255,0.06);border-radius:12px">
      <div style="font-size:12px;font-weight:600;color:var(--muted);margin-bottom:10px;text-transform:uppercase;letter-spacing:1px">Quick Setup Guide</div>
      <div style="font-size:12px;color:var(--muted);line-height:1.8">
        <b style="color:var(--cyan)">Fast2SMS</b> → fast2sms.com → Register → Dashboard → Dev API → Copy API Key → Paste above<br>
        <b style="color:var(--cyan)">MSG91</b> → msg91.com → API → Copy Auth Key → Create OTP template → Copy Template ID as Sender ID<br>
        <b style="color:var(--cyan)">Twilio</b> → twilio.com → Console → Account SID & Auth Token → Format: <code>SID:TOKEN</code>
      </div>
    </div>
  </div>
</div>

<!-- ════ TAB 6: SYSTEM ════ -->
<div class="tab-panel" id="tab-danger">
  <div class="card mb-24">
    <div class="card-header">
      <div class="card-title-text">
        <i class="fas fa-tools" style="color:var(--warning)"></i> System Controls
      </div>
    </div>
    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">🔧 Maintenance Mode</div>
        <div class="setting-desc">When ON — app shows maintenance screen to all users</div>
      </div>
      <div class="setting-control">
        <div class="toggle-wrap">
          <label class="toggle">
            <input type="checkbox" name="maintenance_mode" value="1"
              <?= ($s['maintenance_mode'] ?? '0') == '1' ? 'checked' : '' ?>>
            <span class="toggle-slider"></span>
          </label>
          <span style="font-size:13px;color:var(--muted)">Enable Maintenance</span>
        </div>
      </div>
    </div>
    <div class="setting-row">
      <div class="setting-info">
        <div class="setting-title">🚀 Force Update</div>
        <div class="setting-desc">Forces users to update app before using</div>
      </div>
      <div class="setting-control">
        <div class="toggle-wrap">
          <label class="toggle">
            <input type="checkbox" name="force_update" value="1"
              <?= ($s['force_update'] ?? '0') == '1' ? 'checked' : '' ?>>
            <span class="toggle-slider"></span>
          </label>
          <span style="font-size:13px;color:var(--muted)">Enable Force Update</span>
        </div>
      </div>
    </div>
  </div>
  <div class="card" style="border-color:rgba(239,68,68,0.3)">
    <div class="card-header">
      <div class="card-title-text" style="color:var(--error)">
        <i class="fas fa-exclamation-triangle"></i> Danger Zone
      </div>
    </div>
    <div style="display:flex;align-items:center;justify-content:space-between;padding:12px 0">
      <div>
        <div class="setting-title">Clear All User Sessions</div>
        <div class="setting-desc">Force logout all users from app</div>
      </div>
      <button type="button" class="btn btn-danger btn-sm"
        onclick="if(confirm('Clear all sessions?')) window.location='clear_sessions.php'">
        <i class="fas fa-sign-out-alt"></i> Clear Sessions
      </button>
    </div>
  </div>
</div>

<!-- ── SAVE BUTTON ── -->
<div style="position:sticky;bottom:0;background:var(--dark);padding:16px 0;border-top:1px solid var(--border);margin-top:24px;display:flex;gap:12px;z-index:50">
  <button type="submit" class="btn btn-primary" style="min-width:160px">
    <i class="fas fa-save"></i> Save All Settings
  </button>
  <a href="<?= ADMIN_URL ?>/dashboard/index.php" class="btn btn-secondary">
    <i class="fas fa-times"></i> Cancel
  </a>
</div>

</form>

<script>
function showTab(name, btn) {
  document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  document.getElementById('tab-' + name).classList.add('active');
  btn.classList.add('active');
}

// Price live preview
document.querySelector('[name="premium_price"]').addEventListener('input', function() {
  document.getElementById('pricePreview').textContent  = this.value;
  document.getElementById('pricePreview2').textContent = this.value;
});

// Color sync
document.getElementById('colorPicker').addEventListener('input', function() {
  document.getElementById('colorHex').value = this.value;
});
document.getElementById('colorHex').addEventListener('input', function() {
  document.getElementById('colorPicker').value = this.value;
});

// Test OTP
function sendTestOtp() {
  const phone  = document.getElementById('testPhone').value.trim();
  const result = document.getElementById('testResult');
  if (!phone || phone.length !== 10) {
    result.style.color = '#EF4444';
    result.textContent = '❌ Enter valid 10-digit number';
    return;
  }
  result.style.color = 'var(--muted)';
  result.textContent = '⏳ Sending...';
  fetch('../api/login.php', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({phone: phone, step: 'send'})
  })
  .then(r => r.json())
  .then(d => {
    result.style.color = (d.success || d.status) ? '#10B981' : '#EF4444';
    result.textContent = (d.success || d.status)
      ? '✅ OTP Sent! Check phone.'
      : '❌ ' + (d.message || 'Failed — check API key');
  })
  .catch(() => {
    result.style.color = '#EF4444';
    result.textContent = '❌ Network error';
  });
}
</script>

<?php require_once dirname(__DIR__) . '/includes/footer.php'; ?>