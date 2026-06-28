<?php
// Shared, high-level Trick editor used by add.php and edit.php.
// Renders: basic info, a video block, a WYSIWYG rich-text article editor
// (single box + live preview, with inline image upload), and a "practice set"
// the user attempts after reading the article.

function renderTrickForm(array $cfg) {
    $mode    = $cfg['mode'];                 // 'add' | 'edit'
    $action  = $cfg['action'];
    $error   = $cfg['error']   ?? '';
    $success = $cfg['success'] ?? '';
    $cats    = $cfg['cats']    ?? [];
    $pracSets= $cfg['practice_sets'] ?? [];
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
    <p class="text-muted"><?= $isEdit ? ('Chapter #' . $h($t['chapter_number'])) : 'Create a high-quality trick: article + image + video + practice MCQs' ?></p>
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
      <label class="form-label"><i class="fas fa-image" style="color:var(--cyan)"></i> Cover Image <span style="color:var(--muted);font-weight:400">(shown at the top of the article)</span></label>
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
        <p style="font-size:11px;color:var(--muted);margin-top:4px">If you upload a file it <strong>replaces the URL above</strong> and plays right inside the app.</p>
        <?php $vu = (string)($t['video_url'] ?? ''); $isUploaded = strpos($vu, '/uploads/videos/') !== false; ?>
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

  <!-- Article — WYSIWYG rich editor -->
  <div class="card mb-16">
    <div class="card-header">
      <div class="card-title-text"><i class="fas fa-file-alt" style="color:var(--cyan)"></i> Article (Rich Editor)</div>
      <label style="display:flex;align-items:center;gap:8px;cursor:pointer">
        <input type="checkbox" name="has_article" id="hasArticle" style="accent-color:var(--cyan);width:16px;height:16px"
          <?= $t['has_article']?'checked':'' ?> onchange="document.getElementById('articleFields').style.display=this.checked?'block':'none'">
        <span style="font-size:13px;color:var(--text2)">Has Article</span>
      </label>
    </div>
    <div id="articleFields" style="display:<?= $t['has_article']?'block':'none' ?>">
      <div class="form-row">
        <div class="form-group" style="max-width:200px">
          <label class="form-label">Read Duration (minutes)</label>
          <input type="number" name="read_duration" class="form-input" value="<?= $h($t['read_duration'] ?: 5) ?>" min="1">
        </div>
      </div>

      <!-- Toolbar -->
      <div style="display:flex;gap:6px;flex-wrap:wrap;margin-bottom:8px;padding:8px;background:#0b1220;border:1px solid var(--border);border-radius:10px 10px 0 0">
        <button type="button" class="btn btn-secondary btn-sm" onmousedown="event.preventDefault()" onclick="rtCmd('formatBlock','H2')" title="Heading"><i class="fas fa-heading"></i></button>
        <button type="button" class="btn btn-secondary btn-sm" onmousedown="event.preventDefault()" onclick="rtCmd('formatBlock','H3')" title="Sub-heading">H3</button>
        <button type="button" class="btn btn-secondary btn-sm" onmousedown="event.preventDefault()" onclick="rtCmd('bold')" title="Bold"><i class="fas fa-bold"></i></button>
        <button type="button" class="btn btn-secondary btn-sm" onmousedown="event.preventDefault()" onclick="rtCmd('italic')" title="Italic"><i class="fas fa-italic"></i></button>
        <button type="button" class="btn btn-secondary btn-sm" onmousedown="event.preventDefault()" onclick="rtCmd('insertUnorderedList')" title="Bullet list"><i class="fas fa-list-ul"></i></button>
        <button type="button" class="btn btn-secondary btn-sm" onmousedown="event.preventDefault()" onclick="rtCmd('insertOrderedList')" title="Numbered list"><i class="fas fa-list-ol"></i></button>
        <button type="button" class="btn btn-secondary btn-sm" onmousedown="event.preventDefault()" onclick="rtCmd('formatBlock','P')" title="Normal text"><i class="fas fa-paragraph"></i></button>
        <button type="button" class="btn btn-primary btn-sm" onclick="rtImage()" title="Insert image"><i class="fas fa-image"></i> Image</button>
        <button type="button" class="btn btn-primary btn-sm" onclick="rtVideoUpload()" title="Upload &amp; insert a video"><i class="fas fa-video"></i> Video</button>
        <button type="button" class="btn btn-secondary btn-sm" onclick="rtVideoUrl()" title="Insert a YouTube / mp4 URL"><i class="fab fa-youtube"></i> Video URL</button>
        <span id="rtStatus" style="align-self:center;font-size:11px;color:var(--muted)"></span>
      </div>

      <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px" id="rtGrid">
        <div>
          <div style="font-size:11px;color:var(--muted);margin-bottom:4px">Write here (formatting + images)</div>
          <div id="rtEditor" contenteditable="true"
            style="background:#0b1220;border:1px solid var(--border);border-top:none;border-radius:0 0 12px 12px;padding:16px;min-height:340px;max-height:460px;overflow:auto;color:#dCE6F0;font-size:14px;line-height:1.7"
            oninput="rtSync()"></div>
        </div>
        <div>
          <div style="font-size:11px;color:var(--muted);margin-bottom:4px">Live Preview (how the app shows it)</div>
          <div id="rtPreview" class="rt-render" style="background:#0F1923;border:1px solid var(--border);border-radius:12px;padding:16px;min-height:360px;max-height:486px;overflow:auto"></div>
        </div>
      </div>
      <input type="file" id="rtImageInput" accept="image/png,image/jpeg,image/webp,image/gif" style="display:none" onchange="rtImageUpload(this)">
      <input type="file" id="rtVideoInput" accept="video/mp4,video/quicktime,video/webm,video/x-m4v" style="display:none" onchange="rtVideoFile(this)">
      <textarea name="article_html" id="rtHtml" style="display:none"><?= $h($t['article_html'] ?? '') ?></textarea>
      <textarea name="article_blocks" id="rtBlocks" style="display:none"><?= $h($t['article_blocks'] ?? '') ?></textarea>
      <div style="font-size:11px;color:var(--muted);margin-top:6px">
        <i class="fas fa-info-circle"></i> Write the article naturally — headings, bold, lists and inline images all show in the app exactly as here.
      </div>
    </div>
  </div>

  <!-- Practice MCQs (after the article) -->
  <div class="card mb-16">
    <div class="card-header">
      <div class="card-title-text"><i class="fas fa-pen-to-square" style="color:var(--success)"></i> Practice MCQs <span style="color:var(--muted);font-weight:400">(user takes this test AFTER reading the article)</span></div>
    </div>
    <div class="form-group">
      <label class="form-label">Practice Set</label>
      <select name="practice_set_id" class="form-select">
        <option value="0">— None (use the general Tricks practice) —</option>
        <?php foreach ($pracSets as $s):
          $lbl = 'Set ' . $s['set_number'] . (!empty($s['title']) ? ' — ' . $s['title'] : '');
        ?>
        <option value="<?= (int)$s['id'] ?>" <?= ((int)($t['practice_set_id'] ?? 0) === (int)$s['id']) ? 'selected' : '' ?>><?= $h($lbl) ?></option>
        <?php endforeach; ?>
      </select>
      <p style="font-size:11px;color:var(--muted);margin-top:6px">
        Pick a <strong>Tricks</strong> practice set. After the article, a "Take Practice Test" button opens it — the user gets a result, full solution and a Hindi/English toggle.
        <a href="<?= $adminUrl ?>/sets/index.php?category=tricks" style="color:var(--cyan)">Manage Tricks sets →</a>
      </p>
    </div>
  </div>

  <div style="display:flex;gap:12px;flex-wrap:wrap">
    <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> <?= $isEdit ? 'Update Trick' : 'Save Trick' ?></button>
    <a href="<?= $adminUrl ?>/tricks/index.php" class="btn btn-secondary"><i class="fas fa-times"></i> Cancel</a>
  </div>
</form>
</div>

<style>
@media (max-width: 820px){ #rtGrid{ grid-template-columns:1fr !important; } }
#rtEditor:focus{ outline:none;border-color:var(--cyan) }
#rtEditor img, .rt-render img{ max-width:100%;border-radius:10px;margin:8px 0;display:block }
#rtEditor h2, .rt-render h2{ color:#fff;font-size:18px;font-weight:700;margin:14px 0 8px }
#rtEditor h3, .rt-render h3{ color:#fff;font-size:15px;font-weight:700;margin:12px 0 6px }
#rtEditor p, .rt-render p{ color:#9fb3c8;font-size:14px;line-height:1.7;margin:0 0 10px }
#rtEditor ul, #rtEditor ol, .rt-render ul, .rt-render ol{ color:#9fb3c8;font-size:14px;line-height:1.7;margin:0 0 10px;padding-left:22px }
.rt-render:empty:before{ content:'Preview will appear here…';color:#5b6b7c;font-size:12px }
#rtEditor .tunnl-video{ background:rgba(239,68,68,0.1);border:1px dashed rgba(239,68,68,0.5);border-radius:10px;padding:12px;margin:8px 0;color:#FCA5A5;font-size:13px;word-break:break-all }
#rtEditor .tunnl-video small{ color:#9fb3c8 }
</style>

<script>
function ytId(url){ if(!url) return ''; var m=url.match(/(?:youtu\.be\/|v=|\/embed\/|\/shorts\/)([A-Za-z0-9_-]{11})/); return m?m[1]:''; }
function renderVideoPreview(){
  var el=document.getElementById('videoUrl'); if(!el) return;
  var url=el.value.trim(); var id=ytId(url); var box=document.getElementById('videoPreview'); if(!box) return;
  box.innerHTML = id
    ? '<iframe width="100%" height="220" style="border-radius:12px;border:1px solid var(--border)" src="https://www.youtube.com/embed/'+id+'" frameborder="0" allowfullscreen></iframe>'
    : (url ? '<div style="color:var(--warning);font-size:12px"><i class="fas fa-exclamation-triangle"></i> Could not detect a YouTube id (a direct .mp4 still works in the app).</div>' : '');
}
function previewTrickImage(input){
  var box=document.getElementById('trickImagePreview'); if(!box) return;
  var file=input.files&&input.files[0]; if(!file) return;
  var r=new FileReader(); r.onload=function(e){ box.innerHTML='<img src="'+e.target.result+'" alt="trick" style="max-width:220px;max-height:140px;border-radius:12px;border:1px solid var(--border)">'; }; r.readAsDataURL(file);
}

// ── WYSIWYG rich editor ────────────────────────────────────────────────────
var RT_UPLOAD = '<?= $adminUrl ?>/tricks/upload_media.php';
function rtSync(){
  var ed=document.getElementById('rtEditor');
  document.getElementById('rtHtml').value = ed.innerHTML;
  document.getElementById('rtBlocks').value = JSON.stringify(rtBuildBlocks(ed));
  rtRenderPreview();
}
function rtRenderPreview(){
  var ed=document.getElementById('rtEditor');
  var prev=document.getElementById('rtPreview');
  prev.innerHTML = ed.innerHTML;
  // Turn video markers into real players in the preview.
  prev.querySelectorAll('.tunnl-video').forEach(function(node){
    var url=node.getAttribute('data-url')||'';
    var m=url.match(/(?:youtu\.be\/|v=|\/embed\/|\/shorts\/)([A-Za-z0-9_-]{11})/);
    var html = m
      ? '<iframe width="100%" height="200" style="border-radius:10px;border:1px solid var(--border)" src="https://www.youtube.com/embed/'+m[1]+'" frameborder="0" allowfullscreen></iframe>'
      : '<video src="'+url+'" controls style="max-width:100%;border-radius:10px"></video>';
    var wrap=document.createElement('div'); wrap.innerHTML=html; node.replaceWith(wrap);
  });
}
// Walk the editor DOM → ordered content blocks the APP renders
// (heading / text / image / video) — no extra app package needed.
function rtBuildBlocks(ed){
  var blocks=[];
  function pushText(t){ t=(t||'').replace(/\u00a0/g,' ').trim(); if(t) blocks.push({type:'text',text:t}); }
  function pushHeading(t){ t=(t||'').trim(); if(t) blocks.push({type:'heading',text:t}); }
  Array.prototype.forEach.call(ed.childNodes, function(node){
    if(node.nodeType===3){ pushText(node.textContent); return; }
    if(node.nodeType!==1) return;
    if(node.classList && node.classList.contains('tunnl-video')){
      var u=node.getAttribute('data-url')||''; if(u) blocks.push({type:'video',url:u}); return;
    }
    var tag=node.tagName.toLowerCase();
    if(tag==='h2'||tag==='h3'){ pushHeading(node.textContent); return; }
    if(tag==='img'){ var s=node.getAttribute('src'); if(s) blocks.push({type:'image',url:s}); return; }
    if(tag==='ul'||tag==='ol'){
      var items=[]; Array.prototype.forEach.call(node.querySelectorAll('li'), function(li){ var x=li.textContent.trim(); if(x) items.push('• '+x); });
      pushText(items.join('\n')); return;
    }
    // p / div / other: pull inline images out as their own blocks, keep text.
    var imgs=node.querySelectorAll ? node.querySelectorAll('img') : [];
    if(imgs && imgs.length){
      var txt=node.textContent.trim(); if(txt) pushText(txt);
      Array.prototype.forEach.call(imgs, function(im){ var s=im.getAttribute('src'); if(s) blocks.push({type:'image',url:s}); });
    } else {
      pushText(node.textContent);
    }
  });
  return blocks;
}
function rtCmd(cmd, val){
  document.getElementById('rtEditor').focus();
  try { document.execCommand(cmd, false, val || null); } catch(e){}
  rtSync();
}
function rtImage(){ document.getElementById('rtImageInput').click(); }
function rtVideoUpload(){ document.getElementById('rtVideoInput').click(); }
function rtVideoUrl(){
  var u=prompt('Paste a YouTube or .mp4 video URL:');
  if(u && u.trim()) rtInsertVideo(u.trim());
}
function rtInsertVideo(url){
  document.getElementById('rtEditor').focus();
  var safe=url.replace(/"/g,'&quot;');
  var html='<div class="tunnl-video" data-url="'+safe+'" contenteditable="false">▶ Video — <small>'+safe+'</small></div><p><br></p>';
  try { document.execCommand('insertHTML', false, html); } catch(e){}
  rtSync();
}
function rtVideoFile(input){
  var file=input.files&&input.files[0]; if(!file) return;
  var st=document.getElementById('rtStatus'); if(st) st.textContent='Uploading video…';
  var fd=new FormData(); fd.append('file', file);
  fetch(RT_UPLOAD,{method:'POST',body:fd}).then(function(r){return r.json();}).then(function(d){
    if(d&&d.success&&d.url){ rtInsertVideo(d.url); if(st) st.textContent='Video added ✓'; }
    else { if(st) st.textContent=(d&&d.message)?d.message:'Upload failed'; }
    input.value='';
  }).catch(function(){ if(st) st.textContent='Upload error'; input.value=''; });
}
function rtImageUpload(input){
  var file=input.files&&input.files[0]; if(!file) return;
  var st=document.getElementById('rtStatus'); if(st) st.textContent='Uploading image…';
  var fd=new FormData(); fd.append('file', file);
  fetch(RT_UPLOAD,{method:'POST',body:fd}).then(function(r){return r.json();}).then(function(d){
    if(d&&d.success&&d.url){
      document.getElementById('rtEditor').focus();
      try { document.execCommand('insertHTML', false, '<img src="'+d.url+'">'); } catch(e){}
      rtSync();
      if(st) st.textContent='Image added ✓';
    } else { if(st) st.textContent=(d&&d.message)?d.message:'Upload failed'; }
    input.value='';
  }).catch(function(){ if(st) st.textContent='Upload error'; input.value=''; });
}
document.addEventListener('DOMContentLoaded', function(){
  renderVideoPreview();
  // Seed the editor from saved HTML (or wrap legacy plain text in paragraphs).
  var saved = document.getElementById('rtHtml').value || '';
  if (saved.trim() === '') {
    var legacy = <?= json_encode((string)($t['article_content'] ?? '')) ?>;
    if (legacy && legacy.trim() !== '') {
      saved = legacy.split(/\n{2,}/).map(function(p){
        return '<p>'+p.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/\n/g,'<br>')+'</p>';
      }).join('');
    }
  }
  document.getElementById('rtEditor').innerHTML = saved;
  rtSync();
});
</script>

<?php } ?>
