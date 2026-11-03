(() => {
  const $ = (s) => document.querySelector(s);
  // Pont natif Android (simulé hors de l'app pour les aperçus)
  const VS = window.VS || {
    state: () => JSON.stringify({ mcpUrl: 'https://exemple.supabase.co/functions/v1/video-studio/mcp/xxxxxxxx', connected: true, relayState: 'online', version: 'dev' }),
    items: () => '[]', jobs: () => '[]', pick() {}, update() {}, remove() {}, setConnected() {}, copy() {}, resetToken() {}, openExternal() {}, share() {},
  };

  let items = [];
  let filter = '';
  let current = null;

  const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const icon = (t) => ({ video: '🎞️', image: '🖼️', audio: '🎵' }[t] || '📄');
  const fmtDur = (s) => {
    if (s == null) return '';
    s = Math.round(s);
    return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
  };
  function toast(msg) {
    const t = $('#toast');
    t.textContent = msg;
    t.classList.remove('hidden');
    clearTimeout(toast.t);
    toast.t = setTimeout(() => t.classList.add('hidden'), 2600);
  }

  function card(it) {
    const thumb = it.hasThumb ? `style="background-image:url('/thumb/${it.id}')"` : '';
    return `<div class="item" data-id="${it.id}">
      <div class="thumb" ${thumb}>${it.hasThumb ? '' : `<span class="ic">${icon(it.type)}</span>`}</div>
      <span class="type">${icon(it.type)}</span>
      ${it.duration ? `<span class="badge">${fmtDur(it.duration)}</span>` : ''}
      <div class="label">${esc(it.name)}<small>${it.notes ? esc(it.notes) : new Date(it.createdAt).toLocaleDateString('fr-FR')}</small></div>
    </div>`;
  }

  function renderState() {
    const s = JSON.parse(VS.state());
    $('#mcpUrl').textContent = s.mcpUrl;
    $('#version').textContent = 'Version ' + s.version;
    $('#connectToggle').checked = s.connected;
    const st = s.connected ? s.relayState : 'off';
    $('#dot').className = 'dot ' + st;
    const txt = {
      off: 'Désactivé : Claude ne peut pas accéder à tes fichiers',
      connecting: 'Connexion…',
      online: s.lastCommand ? `En ligne · dernière action : ${s.lastCommand}` : 'En ligne : Claude peut accéder à tes fichiers',
      error: 'Pas de réseau, nouvel essai… ' + (s.relayMessage || ''),
    }[st];
    $('#statusTxt').textContent = txt;
    $('#claudePill').textContent = st === 'online' ? '🟢 Claude connecté' : st === 'off' ? 'Claude : déconnecté' : '🟠 Claude : connexion…';
  }

  function renderJobs() {
    const jobs = JSON.parse(VS.jobs());
    const visible = jobs.filter((j) => j.status === 'queued' || j.status === 'running' || j.status === 'error').slice(0, 3);
    $('#jobs').innerHTML = visible.map((j) => j.status === 'error'
      ? `<div class="job error">❌ ${esc(j.name)} : ${esc(j.error || 'échec')}</div>`
      : `<div class="job">⏳ Claude monte « ${esc(j.name)} »… ${j.progress}%<div class="bar"><div style="width:${j.progress}%"></div></div></div>`).join('');
    return jobs.some((j) => j.status === 'queued' || j.status === 'running');
  }

  function render() {
    items = JSON.parse(VS.items());
    const uploads = items.filter((i) => i.kind !== 'montage' && (!filter || i.type === filter));
    const montages = items.filter((i) => i.kind === 'montage');
    $('#grid').innerHTML = uploads.map(card).join('');
    $('#montageGrid').innerHTML = montages.map(card).join('');
    $('#empty').classList.toggle('hidden', uploads.length > 0);
    $('#emptyMontages').classList.toggle('hidden', montages.length > 0);
    renderState();
    renderJobs();
  }

  // Rafraîchissement : appelé par l'app native à chaque changement + toutes les 2 s pendant un rendu
  window.vsRefresh = () => render();
  window.vsBusy = (n) => {
    $('#busy').classList.toggle('hidden', !n);
    $('#busy').textContent = n ? `Ajout de ${n} fichier(s)…` : '';
  };
  setInterval(() => {
    if (renderJobs()) render();
    else renderState();
  }, 2000);

  // ----- fiche détail -----
  function openSheet(id) {
    const it = items.find((i) => i.id === id);
    if (!it) return;
    current = it;
    const src = `/media/${it.id}`;
    $('#player').innerHTML = it.type === 'video'
      ? `<video src="${src}" controls playsinline preload="metadata" ${it.hasThumb ? `poster="/thumb/${it.id}"` : ''}></video>`
      : it.type === 'image' ? `<img src="${src}" alt="">` : `<audio src="${src}" controls></audio>`;
    const v = $('#player video');
    if (v) v.onerror = () => { $('#player').innerHTML = `<button class="btn" style="width:100%" id="extPlay">▶️ Ouvrir dans le lecteur</button>`; $('#extPlay').onclick = () => VS.openExternal(it.id); };
    $('#mName').value = it.name;
    $('#mNotes').value = it.notes || '';
    $('#mMeta').textContent = [icon(it.type), it.duration ? fmtDur(it.duration) : '', it.width ? `${it.width}×${it.height}` : '', `${it.sizeMB} Mo`, `ID ${it.id}`].filter(Boolean).join(' · ');
    $('#delMedia').textContent = it.kind === 'montage' ? 'Supprimer' : 'Retirer';
    $('#sheet').classList.remove('hidden');
  }
  function closeSheet() {
    $('#sheet').classList.add('hidden');
    $('#player').innerHTML = '';
    current = null;
  }
  window.vsBack = () => {
    if (!$('#sheet').classList.contains('hidden')) { closeSheet(); return true; }
    return false;
  };

  // ----- événements -----
  document.querySelectorAll('.tabs button').forEach((b) => (b.onclick = () => {
    document.querySelectorAll('.tabs button').forEach((x) => x.classList.toggle('active', x === b));
    document.querySelectorAll('.tab').forEach((t) => t.classList.toggle('hidden', t.id !== 'tab-' + b.dataset.tab));
    $('#fab').classList.toggle('hidden', b.dataset.tab === 'claude');
    render();
  }));
  document.querySelectorAll('.filters .chip').forEach((c) => (c.onclick = () => {
    filter = c.dataset.filter;
    document.querySelectorAll('.filters .chip').forEach((x) => x.classList.toggle('active', x === c));
    render();
  }));
  $('#fab').onclick = () => VS.pick();
  document.addEventListener('click', (e) => {
    const el = e.target.closest('.item');
    if (el) openSheet(el.dataset.id);
  });
  $('#closeSheet').onclick = closeSheet;
  $('#sheet').onclick = (e) => { if (e.target.id === 'sheet') closeSheet(); };
  $('#saveMedia').onclick = () => {
    if (!current) return;
    VS.update(current.id, $('#mName').value.trim() || current.name, $('#mNotes').value);
    toast('Enregistré');
    closeSheet();
    render();
  };
  $('#shareMedia').onclick = () => current && VS.share(current.id);
  $('#delMedia').onclick = () => {
    if (!current) return;
    const msg = current.kind === 'montage'
      ? `Supprimer le montage « ${current.name} » (aussi de la galerie) ?`
      : `Retirer « ${current.name} » de l'app ? (le fichier original reste dans ta galerie)`;
    if (!confirm(msg)) return;
    VS.remove(current.id);
    closeSheet();
    render();
  };
  $('#connectToggle').onchange = (e) => VS.setConnected(e.target.checked);
  $('#copyMcp').onclick = () => VS.copy($('#mcpUrl').textContent);
  $('#resetToken').onclick = () => {
    if (confirm("Créer une nouvelle adresse ? L'ancienne ne marchera plus : il faudra mettre à jour le connecteur dans Claude.")) VS.resetToken();
  };

  render();
})();
