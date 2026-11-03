(() => {
  const $ = (s) => document.querySelector(s);
  const store = {
    get: (k) => { try { return localStorage.getItem(k); } catch { return null; } },
    set: (k, v) => { try { v == null ? localStorage.removeItem(k) : localStorage.setItem(k, v); } catch {} },
  };

  // Le jeton peut arriver dans l'URL (app Android) puis est retiré de la barre d'adresse
  const params = new URLSearchParams(location.search);
  if (params.get('token')) {
    store.set('vs_token', params.get('token'));
    history.replaceState(null, '', location.pathname);
  }
  let token = store.get('vs_token');
  let items = [];
  let filter = '';
  let current = null;
  let jobsTimer = null;

  const api = async (path, opts = {}) => {
    const res = await fetch(path, { ...opts, headers: { ...(opts.headers || {}), Authorization: 'Bearer ' + token } });
    if (res.status === 401) { showLogin('Jeton invalide.'); throw new Error('401'); }
    if (!res.ok) throw new Error((await res.json().catch(() => ({}))).error || res.statusText);
    return res.json();
  };
  const withToken = (u) => u + (u.includes('?') ? '&' : '?') + 'token=' + encodeURIComponent(token);

  function toast(msg) {
    const t = $('#toast');
    t.textContent = msg;
    t.classList.remove('hidden');
    clearTimeout(toast.t);
    toast.t = setTimeout(() => t.classList.add('hidden'), 2600);
  }
  const fmtDur = (s) => {
    if (s == null) return '';
    s = Math.round(s);
    const m = Math.floor(s / 60);
    return `${m}:${String(s % 60).padStart(2, '0')}`;
  };
  const icon = (t) => ({ video: '🎞️', image: '🖼️', audio: '🎵' }[t] || '📄');
  const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

  function showLogin(err) {
    $('#main').classList.add('hidden');
    $('#login').classList.remove('hidden');
    $('#loginErr').textContent = err || '';
  }

  async function start() {
    if (!token) return showLogin();
    try {
      const info = await api('/api/info');
      $('#login').classList.add('hidden');
      $('#main').classList.remove('hidden');
      $('#mcpUrl').textContent = info.mcpUrl;
      const host = location.hostname;
      if (/^(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)/.test(host) || location.protocol !== 'https:') {
        $('#localWarn').classList.remove('hidden');
      }
      await refresh();
      pollJobs();
    } catch (e) {
      if (e.message !== '401') showLogin('Serveur injoignable : ' + e.message);
    }
  }

  async function refresh() {
    items = await api('/api/media');
    render();
  }

  function card(it) {
    const thumb = it.type !== 'audio' ? `style="background-image:url('${withToken(`/api/media/${it.id}/thumb`)}')"` : '';
    return `<div class="item" data-id="${it.id}">
      <div class="thumb" ${thumb}>${it.type === 'audio' ? '🎵' : ''}</div>
      <span class="type">${icon(it.type)}</span>
      ${it.duration ? `<span class="badge">${fmtDur(it.duration)}</span>` : ''}
      <div class="label">${esc(it.name)}<small>${it.notes ? esc(it.notes) : new Date(it.createdAt).toLocaleDateString('fr-FR')}</small></div>
    </div>`;
  }

  function render() {
    const uploads = items.filter((i) => i.kind !== 'montage' && (!filter || i.type === filter));
    const montages = items.filter((i) => i.kind === 'montage');
    $('#grid').innerHTML = uploads.map(card).join('');
    $('#montageGrid').innerHTML = montages.map(card).join('');
    $('#empty').classList.toggle('hidden', uploads.length > 0);
    $('#emptyMontages').classList.toggle('hidden', montages.length > 0);
    $('#count').textContent = `${items.length} fichier${items.length > 1 ? 's' : ''}`;
  }

  async function pollJobs() {
    clearTimeout(jobsTimer);
    try {
      const jobs = await api('/api/jobs');
      const active = jobs.filter((j) => j.status === 'queued' || j.status === 'running');
      const recentErr = jobs.filter((j) => j.status === 'error').slice(0, 2);
      $('#jobs').innerHTML = [...active, ...recentErr].map((j) => j.status === 'error'
        ? `<div class="job error">❌ ${esc(j.name)} : échec du rendu</div>`
        : `<div class="job">⏳ Claude monte « ${esc(j.name)} »… ${j.progress}%<div class="bar"><div style="width:${j.progress}%"></div></div></div>`).join('');
      if (pollJobs.wasActive && !active.length) await refresh();
      pollJobs.wasActive = active.length > 0;
      jobsTimer = setTimeout(pollJobs, active.length ? 2000 : 10000);
    } catch {
      jobsTimer = setTimeout(pollJobs, 15000);
    }
  }

  // ----- Upload avec progression -----
  function uploadFiles(files) {
    for (const file of files) {
      const row = document.createElement('div');
      row.className = 'upload';
      row.innerHTML = `⬆️ ${esc(file.name)} <span class="pct">0%</span><div class="bar"><div></div></div>`;
      $('#uploads').appendChild(row);
      const fd = new FormData();
      fd.append('files', file, file.name);
      const xhr = new XMLHttpRequest();
      xhr.open('POST', '/api/upload');
      xhr.setRequestHeader('Authorization', 'Bearer ' + token);
      xhr.upload.onprogress = (e) => {
        if (!e.lengthComputable) return;
        const p = Math.round((e.loaded / e.total) * 100);
        row.querySelector('.bar div').style.width = p + '%';
        row.querySelector('.pct').textContent = p < 100 ? p + '%' : 'analyse…';
      };
      xhr.onload = () => {
        let r = {};
        try { r = JSON.parse(xhr.responseText); } catch {}
        if (xhr.status === 200 && r.added?.length) {
          row.remove();
          toast(`✅ ${file.name} ajouté`);
          refresh();
        } else {
          row.innerHTML = `❌ ${esc(file.name)} : ${esc(r.errors?.[0] || r.error || 'échec')}`;
          setTimeout(() => row.remove(), 8000);
        }
      };
      xhr.onerror = () => { row.innerHTML = `❌ ${esc(file.name)} : connexion perdue`; setTimeout(() => row.remove(), 8000); };
      xhr.send(fd);
    }
  }

  // ----- Fiche détail -----
  function openSheet(id) {
    const it = items.find((i) => i.id === id);
    if (!it) return;
    current = it;
    const src = withToken(`/api/media/${it.id}/file`);
    $('#player').innerHTML = it.type === 'video'
      ? `<video src="${src}" controls playsinline preload="metadata" poster="${withToken(`/api/media/${it.id}/thumb`)}"></video>`
      : it.type === 'image' ? `<img src="${src}" alt="">` : `<audio src="${src}" controls></audio>`;
    $('#mName').value = it.name;
    $('#mNotes').value = it.notes || '';
    const meta = [icon(it.type), it.duration ? fmtDur(it.duration) : '', it.width ? `${it.width}×${it.height}` : '', `${it.sizeMB} Mo`, `ID ${it.id}`];
    $('#mMeta').textContent = meta.filter(Boolean).join(' · ');
    $('#dlMedia').href = it.downloadUrl + '?dl=1';
    $('#sheet').classList.remove('hidden');
  }
  function closeSheet() {
    $('#sheet').classList.add('hidden');
    $('#player').innerHTML = '';
    current = null;
  }

  // ----- Événements -----
  $('#loginBtn').onclick = () => {
    token = $('#tokenInput').value.trim();
    store.set('vs_token', token);
    start();
  };
  $('#tokenInput').onkeydown = (e) => { if (e.key === 'Enter') $('#loginBtn').click(); };
  $('#logout').onclick = () => {
    store.set('vs_token', null);
    token = null;
    if (window.VideoStudioApp?.resetSettings) window.VideoStudioApp.resetSettings();
    else showLogin();
  };
  document.querySelectorAll('.tabs button').forEach((b) => (b.onclick = () => {
    document.querySelectorAll('.tabs button').forEach((x) => x.classList.toggle('active', x === b));
    document.querySelectorAll('.tab').forEach((t) => t.classList.toggle('hidden', t.id !== 'tab-' + b.dataset.tab));
    $('#fab').classList.toggle('hidden', b.dataset.tab === 'claude');
    if (b.dataset.tab !== 'claude') refresh();
  }));
  document.querySelectorAll('.filters .chip').forEach((c) => (c.onclick = () => {
    filter = c.dataset.filter;
    document.querySelectorAll('.filters .chip').forEach((x) => x.classList.toggle('active', x === c));
    render();
  }));
  $('#fab').onclick = () => $('#fileInput').click();
  $('#fileInput').onchange = (e) => { uploadFiles([...e.target.files]); e.target.value = ''; };
  document.addEventListener('click', (e) => {
    const el = e.target.closest('.item');
    if (el) openSheet(el.dataset.id);
  });
  $('#closeSheet').onclick = closeSheet;
  $('#sheet').onclick = (e) => { if (e.target.id === 'sheet') closeSheet(); };
  $('#saveMedia').onclick = async () => {
    if (!current) return;
    await api(`/api/media/${current.id}`, {
      method: 'PATCH', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: $('#mName').value.trim() || current.name, notes: $('#mNotes').value }),
    });
    toast('Enregistré');
    closeSheet();
    refresh();
  };
  $('#delMedia').onclick = async () => {
    if (!current || !confirm(`Supprimer « ${current.name} » ?`)) return;
    await api(`/api/media/${current.id}`, { method: 'DELETE' });
    toast('Supprimé');
    closeSheet();
    refresh();
  };
  $('#copyMcp').onclick = async () => {
    const txt = $('#mcpUrl').textContent;
    try { await navigator.clipboard.writeText(txt); }
    catch { window.VideoStudioApp?.copy?.(txt); }
    if (window.VideoStudioApp?.copy) window.VideoStudioApp.copy(txt);
    toast('Adresse copiée');
  };
  window.addEventListener('focus', () => token && refresh().catch(() => {}));
  // Appelé par l'app Android après un partage depuis la galerie
  window.vsRefresh = () => refresh().catch(() => {});

  start();
})();
