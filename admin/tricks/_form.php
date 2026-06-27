<?php
// Shared, high-level Trick editor used by add.php and edit.php.
// Renders: basic info, a rich article editor (formatting toolbar + live
// preview that mirrors the app), and a video block with YouTube live preview.

function renderTrickForm(array $cfg) {
    $mode    = $cfg['mode'];                 // 'add' | 'edit'
    $action  = $cfg['action'];
    $error   = $cfg['error']   ?? '';
    $success = $cfg['success'] ?? '';
    $cats    = $cfg['cats']    ?? [];
    $t       = $cfg['trick'];
    $h = fn($v) => htmlspecialchars((string)$v, ENT_QUOTES);
    $isEdit  = $mode === 'edit';
    $adminUrl = defined('ADMIN_URL') ? ADMIN_URL : '';
?>

<?php if ($success): ?>
<div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;padding:12px 16px;border-radius:12px;margin-bottom:20px;display:flex;align-items:center;gap:8px">
  <i class="fas fa-check-circle"></i> <?= $h($success) ?>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;padding:12px 16px;border-radius:12px;margin-bottom:20px">
  <i class="fas fa-exclamation-circle"></i> <?= $error ?>
</div>
<?php endif; ?>

<div style="max-width:1000px">
<div class="flex-between mb-24">
  <div>
    <h2 style="font-family:'Space Grotesk',sans-serif;font-size:20px;font-weight:700">
      <?= $isEdit ? 'Edit Trick' : 'Add New Trick' ?>
    </h2>
    <p class="text-muted"><?= $isEdit ? ('Chapter #' . $h($t['chapter_number'])) : 'Create a high-quality trick with article + video' ?></p>
  </div>
  <a href="<?= $adminUrl ?>/tricks/index.php" class="btn btn-secondary"><i class="fas fa-arrow-left"></i> Back</a>
</div>

<form method="POST" enctype="multipart/form-data" action="<?= $h($action) ?>">

  <!-- Basic Info -->
  <div class="card mb-16">
    <div class="card-header">
      <div class="card-title-text"><i class="fas fa-info-circle" style="color:var(--cyan)"></i> Basic Info</div>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label class="form-label">Chapter Number *</label>
        <input type="number" name="chapter_number" class="form-input" required min="1" value="<?= $h($t['chapter_number']) ?>" placeholder="1">
      </div>
      <div class="form-group">
        <label class="form-label">Category *</label>
        <input type="text" name="category" class="form-input" required list="catList"
          value="<?= $h($t['category']) ?>" placeholder="e.g. MULTIPLICATION" style="text-transform:uppercase">
        <datalist id="catList">
          <?php foreach ($cats as $c): ?><option value="<?= $h($c) ?>"></option><?php endforeach; ?>
          <option value="MULTIPLICATION"></option>
          <option value="DIVISION"></option>
          <option value="SQUARES"></option>
          <option value="FRACTIONS"></option>
          <option value="SHORTCUTS"></option>
          <option value="PERCENTAGE"></option>
          <option value="ALGEBRA"></option>
        </datalist>
        <div style="font-size:11px;color:var(--muted);margin-top:4px">Type your own — it becomes a filter tab in the app automatically.</div>
      </div>
      <div class="form-group">
        <label class="form-label">Difficulty *</label>
        <select name="difficulty" class="form-select" required>
          <?php foreach (['Beginner'=>'🟢 Beginner','Intermediate'=>'🟡 Intermediate','Advanced'=>'🔴 Advanced'] as $v=>$lbl): ?>
          <option value="<?= $v ?>" <?= $t['difficulty']===$v?'selected':'' ?>><?= $lbl ?></option>
          <?php endforeach; ?>
        </select>
      </div>
    </div>
    <div class="form-group">
      <label class="form-label">Title *</label>
      <input type="text" name="title" class="form-input" required value="<?= $h($t['title']) ?>" placeholder="e.g. Multiply any 2-digit number by 11">
    </div>
    <div class="form-group">
      <label class="form-label">Subtitle</label>
      <input type="text" name="subtitle" class="form-input" value="<?= $h($t['subtitle']) ?>" placeholder="Short one-line description shown under the title">
    </div>
    <?php $imgUrl = (string)($t['image_url'] ?? ''); ?>
    <div class="form-group">
      <label class="form-label"><i class="fas fa-image" style="color:var(--cyan)"></i> Trick Image <span style="color:var(--muted);font-weight:400">(shown at the top of the article in the app)</span></label>
      <input type="file" name="image_file" accept="image/png,image/jpeg,image/webp,image/gif" class="form-input" onchange="previewTrickImage(this)">
      <input type="url" name="image_url" class="form-input" style="margin-top:8px" value="<?= $h($imgUrl) ?>" placeholder="…or paste an image URL (https://…)">
      <p style="font-size:11px;color:var(--muted);margin-top:4px">Uploading a file replaces the URL above. jpg / png / webp / gif, max 8MB.</p>
      <div id="trickImagePreview" style="margin-top:10px">
        <?php if ($imgUrl !== ''): ?>
          <img src="<?= $h($imgUrl) ?>" alt="trick" style="max-width:220px;max-height:140px;border-radius:12px;border:1px solid var(--border)">
        <?php endif; ?>
      </div>
    </div>
    <div style="display:flex;gap:24px;flex-wrap:wrap">
      <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
        <input type="checkbox" name="is_new" style="accent-color:var(--success);width:16px;height:16px" <?= $t['is_new']?'checked':'' ?>>
        <span style="font-size:13px;color:var(--text2)">🆕 Mark as NEW</span>
      </label>
      <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
        <input type="checkbox" name="is_premium" style="accent-color:var(--warning);width:16px;height:16px" <?= !empty($t['is_premium'])?'checked':'' ?>>
        <span style="font-size:13px;color:var(--text2)"><i class="fas fa-crown" style="color:var(--warning)"></i> Premium Only (locked for free users)</span>
      </label>
      <?php if ($isEdit): ?>
      <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
        <input type="checkbox" name="is_active" style="accent-color:var(--cyan);width:16px;height:16px" <?= $t['is_active']?'checked':'' ?>>
        <span style="font-size:13px;color:var(--text2)">✅ Active (visible in app)</span>
      </label>
      <?php endif; ?>
    </div>
  </div>

  <!-- Video -->
  <div class="card mb-16">
    <div class="card-header">
      <div class="card-title-text"><i class="fab fa-youtube" style="color:#EF4444"></i> Video Content</div>
      <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
        <input type="checkbox" name="has_video" id="hasVideo" style="accent-color:var(--cyan);width:16px;height:16px"
          <?= $t['has_video']?'checked':'' ?> onchange="document.getElementById('videoFields').style.display=this.checked?'block':'none'">
        <span style="font-size:13px;color:var(--text2)">Has Video</span>
      </label>
    </div>
    <div id="videoFields" style="display:<?= $t['has_video']?'block':'none' ?>">
      <div class="form-row">
        <div class="form-group" style="flex:2">
          <label class="form-label">YouTube URL <span style="color:var(--muted);font-weight:400">(or a direct .mp4 link)</span></label>
          <input type="url" name="video_url" id="videoUrl" class="form-input"
            value="<?= $h($t['video_url']) ?>" placeholder="https://youtube.com/watch?v=..."
            oninput="renderVideoPreview()">
        </div>
        <div class="form-group">
          <label class="form-label">Duration (minutes)</label>
          <input type="number" name="video_duration" class="form-input" value="<?= $h($t['video_duration'] ?: 5) ?>" min="1">
        </div>
      </div>

      <div style="display:flex;align-items:center;gap:10px;margin:6px 0 12px">
        <div style="flex:1;height:1px;background:var(--border)"></div>
        <span style="font-size:11px;color:var(--muted)">OR UPLOAD A LOCAL VIDEO</span>
        <div style="flex:1;height:1px;background:var(--border)"></div>
      </div>

      <div class="form-group">
        <label class="form-label"><i class="fas fa-upload" style="color:var(--cyan)"></i> Upload Video File (mp4 / mov / webm, max 60MB)</label>
        <input type="file" name="video_file" accept="video/mp4,video/quicktime,video/webm,video/x-m4v" class="form-input">
        <p style="font-size:11px;color:var(--muted);margin-top:4px">
          If you upload a file it <strong>replaces the URL above</strong> and plays right inside the app.
        </p>
        <?php
          $vu = (string)($t['video_url'] ?? '');
          $isUploaded = strpos($vu, '/uploads/videos/') !== false;
        ?>
        <?php if ($isUploaded): ?>
        <div style="margin-top:8px;font-size:12px;color:var(--success)">
          <i class="fas fa-check-circle"></i> Current uploaded video:
          <a href="<?= $h($vu) ?>" target="_blank" style="color:var(--cyan)"><?= $h(basename($vu)) ?></a>
        </div>
        <?php endif; ?>
      </div>

      <div id="videoPreview" style="margin-top:8px"></div>
    </div>
  </div>

  <!-- Article -->
  <div class="card mb-16">
    <div class="card-header">
      <div class="card-title-text"><i class="fas fa-file-alt" style="color:var(--cyan)"></i> Article Content</div>
      <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
        <input type="checkbox" name="has_article" id="hasArticle" style="accent-color:var(--cyan);width:16px;height:16px"
          <?= $t['has_article']?'checked':'' ?> onchange="document.getElementById('articleFields').style.display=this.checked?'block':'none'">
        <span style="font-size:13px;color:var(--text2)">Has Article</span>
      </label>
    </div>
    <div id="articleFields" style="display:<?= $t['has_article']?'block':'none' ?>">
      <div class="form-group" style="max-width:200px">
        <label class="form-label">Read Duration (minutes)</label>
        <input type="number" name="read_duration" class="form-input" value="<?= $h($t['read_duration'] ?: 5) ?>" min="1">
      </div>

      <!-- Formatting toolbar -->
      <div style="display:flex;gap:6px;flex-wrap:wrap;margin-bottom:8px">
        <button type="button" class="btn btn-secondary btn-sm" onclick="fmt('heading')"><i class="fas fa-heading"></i> Heading</button>
        <button type="button" class="btn btn-secondary btn-sm" onclick="fmt('step')"><i class="fas fa-shoe-prints"></i> Step</button>
        <button type="button" class="btn btn-secondary btn-sm" onclick="fmt('bullet')"><i class="fas fa-list-ul"></i> Bullet</button>
        <button type="button" class="btn btn-secondary btn-sm" onclick="fmt('example')"><i class="fas fa-lightbulb"></i> Example</button>
        <button type="button" class="btn btn-secondary btn-sm" onclick="fmt('para')"><i class="fas fa-paragraph"></i> New Para</button>
      </div>

      <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px" id="editorGrid">
        <div class="form-group" style="margin:0">
          <label class="form-label">Write (plain text)</label>
          <textarea name="article_content" id="articleBox" class="form-textarea" rows="16"
            oninput="renderPreview()"
            placeholder="Tip: a SHORT line on its own (no full-stop) becomes a heading in the app.&#10;&#10;Multiply by 11&#10;&#10;Step 1: Write the two digits apart.&#10;Step 2: Add them and place in the middle.&#10;&#10;Example&#10;25 x 11 = 2 (2+5) 5 = 275"><?= $h($t['article_content']) ?></textarea>
        </div>
        <div class="form-group" style="margin:0">
          <label class="form-label">Live Preview (how the app shows it)</label>
          <div id="articlePreview" style="background:#0b1220;border:1px solid var(--border);border-radius:12px;padding:16px;min-height:360px;max-height:420px;overflow:auto"></div>
        </div>
      </div>
      <div style="font-size:11px;color:var(--muted);margin-top:6px">
        <i class="fas fa-info-circle"></i> Separate blocks with a blank line. Short heading-style lines render bold &amp; bigger automatically.
      </div>
    </div>
  </div>

  <!-- Rich Content Blocks (text / image / video, any order) -->
  <div class="card mb-16">
    <div class="card-header">
      <div class="card-title-text"><i class="fas fa-layer-group" style="color:var(--cyan)"></i> Rich Content Blocks
        <span style="color:var(--muted);font-weight:400">(text · image · video, in any order)</span></div>
    </div>
    <p class="text-muted" style="font-size:12px;margin:0 0 12px">
      Build the article by stacking blocks — heading, text, image or video — in <strong>any order</strong>.
      The app shows them exactly as arranged here. Leave empty to use the plain "Article Content" above instead.
    </p>
    <div style="display:flex;gap:6px;flex-wrap:wrap;margin-bottom:14px">
      <button type="button" class="btn btn-secondary btn-sm" onclick="addBlock('heading')"><i class="fas fa-heading"></i> Heading</button>
      <button type="button" class="btn btn-secondary btn-sm" onclick="addBlock('text')"><i class="fas fa-paragraph"></i> Text</button>
      <button type="button" class="btn btn-secondary btn-sm" onclick="addBlock('image')"><i class="fas fa-image"></i> Image</button>
      <button type="button" class="btn btn-secondary btn-sm" onclick="addBlock('video')"><i class="fas fa-video"></i> Video</button>
    </div>
    <div id="blockList"></div>
    <textarea name="article_blocks" id="blocksJson" style="display:none"><?= $h($t['article_blocks'] ?? '') ?></textarea>
  </div>

  <div style="display:flex;gap:12px;flex-wrap:wrap">
    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> <?= $isEdit ? 'Update Trick' : 'Save Trick' ?></button>
    <a href="<?= $adminUrl ?>/tricks/index.php" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
  </div>
</form>
</div>

<style>
@media (max-width: 820px){ #editorGrid{ grid-template-columns:1fr !important; } }
#articlePreview .ap-h{ color:#fff;font-weight:700;font-size:16px;margin:14px 0 6px; }
#articlePreview .ap-p{ color:#9fb3c8;font-size:13px;line-height:1.7;margin:0 0 10px;white-space:pre-wrap; }
</style>

<script>
// Insert formatting snippets at the cursor in the article textarea.
function fmt(kind) {
  const box = document.getElementById('articleBox');
  const start = box.selectionStart, end = box.selectionEnd;
  const val = box.value;
  let ins = '';
  if (kind === 'heading')  ins = (start>0?'\n\n':'') + 'Heading Title' + '\n\n';
  else if (kind === 'step') ins = (start>0?'\n':'') + 'Step 1: ';
  else if (kind === 'bullet') ins = (start>0?'\n':'') + '\u2022 ';
  else if (kind === 'example') ins = (start>0?'\n\n':'') + 'Example' + '\n\n';
  else if (kind === 'para') ins = '\n\n';
  box.value = val.slice(0, start) + ins + val.slice(end);
  const pos = start + ins.length;
  box.setSelectionRange(pos, pos);
  box.focus();
  renderPreview();
}

// Mirror the app's renderer: split on blank lines; a short line with no
// trailing period and no inner newline is a heading.
function renderPreview() {
  const txt = (document.getElementById('articleBox').value || '').replace(/\r\n/g, '\n');
  const blocks = txt.split(/\n{2,}/).map(s => s.trim()).filter(Boolean);
  const html = blocks.map(b => {
    const isHeading = b.length <= 60 && !b.endsWith('.') && !b.includes('\n');
    const safe = b.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
    return isHeading ? `<div class="ap-h">${safe}</div>` : `<div class="ap-p">${safe}</div>`;
  }).join('');
  document.getElementById('articlePreview').innerHTML =
    html || '<div style="color:#5b6b7c;font-size:12px">Preview will appear here…</div>';
}

function ytId(url) {
  if (!url) return '';
  const m = url.match(/(?:youtu\.be\/|v=|\/embed\/|\/shorts\/)([A-Za-z0-9_-]{11})/);
  return m ? m[1] : '';
}
function renderVideoPreview() {
  const url = document.getElementById('videoUrl').value.trim();
  const id = ytId(url);
  const box = document.getElementById('videoPreview');
  if (!box) return;
  box.innerHTML = id
    ? `<iframe width="100%" height="220" style="border-radius:12px;border:1px solid var(--border)" src="https://www.youtube.com/embed/${id}" frameborder="0" allowfullscreen></iframe>`
    : (url ? '<div style="color:var(--warning);font-size:12px"><i class="fas fa-exclamation-triangle"></i> Could not detect a YouTube video id from this URL.</div>' : '');
}

document.addEventListener('DOMContentLoaded', function(){ renderPreview(); renderVideoPreview(); });

// Live preview for the uploaded trick image.
function previewTrickImage(input) {
  const box = document.getElementById('trickImagePreview');
  if (!box) return;
  const file = input.files && input.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = e => {
    box.innerHTML = '<img src="' + e.target.result + '" alt="trick" style="max-width:220px;max-height:140px;border-radius:12px;border:1px solid var(--border)">';
  };
  reader.readAsDataURL(file);
}

// ── Rich Content Blocks editor ─────────────────────────────────────────────
var TBLOCKS = [];
var TUPLOAD_URL = '<?= $adminUrl ?>/tricks/upload_media.php';

function tbEsc(s){ return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

function tbLoad() {
  var raw = (document.getElementById('blocksJson').value || '').trim();
  if (raw) { try { TBLOCKS = JSON.parse(raw) || []; } catch(e) { TBLOCKS = []; } }
  if (!Array.isArray(TBLOCKS)) TBLOCKS = [];
  tbRender();
}
function addBlock(type) {
  TBLOCKS.push({ type: type, text: '', url: '' });
  tbRender(); tbSync();
}
function tbRemove(i){ TBLOCKS.splice(i,1); tbRender(); tbSync(); }
function tbMove(i,d){ var j=i+d; if(j<0||j>=TBLOCKS.length) return; var t=TBLOCKS[i]; TBLOCKS[i]=TBLOCKS[j]; TBLOCKS[j]=t; tbRender(); tbSync(); }
function tbSetText(i,v){ TBLOCKS[i].text=v; tbSync(); }
function tbSetUrl(i,v){ TBLOCKS[i].url=v; tbSync(); var p=document.getElementById('tbprev'+i); if(p) p.innerHTML=tbPreview(TBLOCKS[i]); }
function tbSync(){ document.getElementById('blocksJson').value = JSON.stringify(TBLOCKS); }

function tbUpload(i, input) {
  var file = input.files && input.files[0];
  if (!file) return;
  var status = document.getElementById('tbstatus'+i);
  if (status) status.textContent = 'Uploading…';
  var fd = new FormData(); fd.append('file', file);
  fetch(TUPLOAD_URL, { method:'POST', body: fd })
    .then(function(r){ return r.json(); })
    .then(function(d){
      if (d && d.success && d.url) {
        TBLOCKS[i].url = d.url; tbSync();
        var urlInput = document.getElementById('tburl'+i); if (urlInput) urlInput.value = d.url;
        var p = document.getElementById('tbprev'+i); if (p) p.innerHTML = tbPreview(TBLOCKS[i]);
        if (status) status.textContent = 'Uploaded ✓';
      } else {
        if (status) status.textContent = (d && d.message) ? d.message : 'Upload failed';
      }
    })
    .catch(function(){ if (status) status.textContent = 'Upload error'; });
}

function tbPreview(b) {
  if (b.type === 'image' && b.url) {
    return '<img src="'+tbEsc(b.url)+'" style="max-width:200px;max-height:130px;border-radius:10px;border:1px solid var(--border);margin-top:8px">';
  }
  if (b.type === 'video' && b.url) {
    var m = b.url.match(/(?:youtu\.be\/|v=|\/embed\/|\/shorts\/)([A-Za-z0-9_-]{11})/);
    if (m) return '<iframe width="100%" height="200" style="border-radius:10px;border:1px solid var(--border);margin-top:8px" src="https://www.youtube.com/embed/'+m[1]+'" frameborder="0" allowfullscreen></iframe>';
    return '<video src="'+tbEsc(b.url)+'" controls style="max-width:100%;max-height:200px;border-radius:10px;margin-top:8px"></video>';
  }
  return '';
}

function tbRender() {
  var host = document.getElementById('blockList');
  if (!host) return;
  if (!TBLOCKS.length) {
    host.innerHTML = '<div style="color:#5b6b7c;font-size:12px;padding:10px;border:1px dashed var(--border);border-radius:10px;text-align:center">No blocks yet — add Heading / Text / Image / Video above.</div>';
    return;
  }
  var labels = { heading:'Heading', text:'Text', image:'Image', video:'Video' };
  var icons  = { heading:'fa-heading', text:'fa-paragraph', image:'fa-image', video:'fa-video' };
  var html = '';
  for (var i=0;i<TBLOCKS.length;i++){
    var b = TBLOCKS[i];
    html += '<div style="border:1px solid var(--border);border-radius:12px;padding:12px;margin-bottom:10px;background:#0b1220">';
    html += '<div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">';
    html += '<span style="font-size:12px;font-weight:700;color:var(--cyan)"><i class="fas '+icons[b.type]+'"></i> '+labels[b.type]+' #'+(i+1)+'</span>';
    html += '<span style="display:flex;gap:6px">'
         + '<button type="button" class="btn btn-secondary btn-sm" onclick="tbMove('+i+',-1)" title="Move up"><i class="fas fa-arrow-up"></i></button>'
         + '<button type="button" class="btn btn-secondary btn-sm" onclick="tbMove('+i+',1)" title="Move down"><i class="fas fa-arrow-down"></i></button>'
         + '<button type="button" class="btn btn-secondary btn-sm" onclick="tbRemove('+i+')" title="Delete" style="color:#FCA5A5"><i class="fas fa-trash"></i></button>'
         + '</span></div>';
    if (b.type === 'heading' || b.type === 'text') {
      html += '<textarea class="form-textarea" rows="'+(b.type==='heading'?1:4)+'" oninput="tbSetText('+i+',this.value)" placeholder="'+(b.type==='heading'?'Section heading…':'Write text…')+'">'+tbEsc(b.text)+'</textarea>';
    } else {
      var accept = b.type==='image' ? 'image/*' : 'video/mp4,video/quicktime,video/webm';
      html += '<input type="file" accept="'+accept+'" class="form-input" style="padding:8px" onchange="tbUpload('+i+',this)">';
      html += '<input type="url" id="tburl'+i+'" class="form-input" style="margin-top:8px" value="'+tbEsc(b.url)+'" oninput="tbSetUrl('+i+',this.value)" placeholder="…or paste '+(b.type==='image'?'image':'YouTube / .mp4')+' URL">';
      html += '<div style="font-size:11px;color:var(--muted);margin-top:4px" id="tbstatus'+i+'"></div>';
      html += '<div id="tbprev'+i+'">'+tbPreview(b)+'</div>';
    }
    html += '</div>';
  }
  host.innerHTML = html;
}

document.addEventListener('DOMContentLoaded', tbLoad);

</script>

<?php } ?>
