const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 400, height: 860 }, deviceScaleFactor: 2 });
  const errors = [];
  p.on('pageerror', (e) => errors.push(e.message));
  p.on('dialog', (d) => { errors.push('dialog: ' + d.message()); d.accept(); });
  await p.addInitScript(() => {
    window.GX = {
      call(n, a) {
        const x = new XMLHttpRequest();
        x.open('POST', 'http://127.0.0.1:18765/mcp', false);
        x.setRequestHeader('Content-Type', 'application/json');
        x.setRequestHeader('Authorization', 'Bearer testtoken');
        x.send(JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: n, arguments: JSON.parse(a) } }));
        const r = JSON.parse(x.responseText).result; const t = r.content[0].text;
        if (r.isError) return JSON.stringify({ ok: false, error: t });
        let v; try { v = JSON.parse(t); } catch { v = t; }
        return JSON.stringify({ ok: true, result: v });
      },
      status() { return JSON.stringify({ running: true, port: 8765, lan: true, token: 'gix_0123456789abcdef', ips: ['192.168.1.20'], error: '', version: '2.0.0', owner: 'moi', author: 'GIXCLOUD', tools: 108, requests: 12, last_client: '192.168.1.10' }); },
      copy() {}, setServer() {}, settings() {}, pickApk() {},
    };
  });
  await p.goto('file://' + require('path').resolve(__dirname, '../app/src/main/assets/ui/index.html') + '');
  const shot = async (n) => { await p.waitForTimeout(150); await p.screenshot({ path: require('path').join(require('os').tmpdir(), `gixcloud-ui-${n}.png`) }); };
  await shot('1-ia');
  await p.click('nav button[data-tab=repos]'); await shot('2-repos');
  await p.click('text=moi/demo'); await shot('3-repo');
  for (const v of ['Tickets', 'Pull requests', 'Commits', 'Branches', 'Versions', 'Wiki', 'Activité']) {
    await p.click(`main button:has-text("${v}")`); await p.waitForTimeout(100);
    const txt = await p.textContent('main');
    if (/Erreur|undefined/.test(txt)) errors.push(v + ' : ' + txt.slice(0, 200));
    if (v === 'Pull requests') { await p.click('main .list > div >> nth=0'); await shot('4-pr'); await p.evaluate(() => back()); }
    await p.evaluate(() => back());
  }
  await p.click('main button:has-text("Tickets")'); await p.click('text=Nouveau ticket');
  await p.fill('#it', 'Depuis l’interface'); await p.fill('#ib', 'Test'); await p.click('text=Créer'); await shot('5-issue');
  await p.click('nav button[data-tab=activite]'); await shot('6-activite');
  await p.click('nav button[data-tab=reglages]'); await p.fill('#tn', 'Tablette'); await p.click('text=Créer le jeton'); await p.waitForTimeout(200); await shot('7-reglages');
  await p.click('nav button[data-tab=apk]'); await shot('8-apk');
  console.log('erreurs :', errors.length ? errors : 'aucune');
  await b.close();
})();
