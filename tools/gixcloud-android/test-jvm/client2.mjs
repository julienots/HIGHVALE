import http from 'node:http';
import { execSync } from 'node:child_process';
const BASE = 'http://127.0.0.1:18765';
let id = 1;
async function call(name, args = {}, token = 'testtoken') {
  const r = await fetch(BASE + '/mcp', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ jsonrpc: '2.0', id: id++, method: 'tools/call', params: { name, arguments: args } }) });
  const j = await r.json();
  const t = j.result.content[0].text;
  if (j.result.isError) throw new Error(t);
  try { return JSON.parse(t); } catch { return t; }
}
const ok = (c, m) => { if (!c) throw new Error('ÉCHEC : ' + m); console.log('✓', m); };
const fails = async (p, re, m) => { try { await p; } catch (e) { ok(re.test(e.message), m + ' → ' + e.message.slice(0, 90)); return; } throw new Error('ÉCHEC (aurait dû échouer) : ' + m); };

// webhook receiver
const hooks = [];
const srv = http.createServer((req, res) => { let b = ''; req.on('data', (c) => b += c).on('end', () => { hooks.push({ sig: req.headers['x-hub-signature-256'], ev: JSON.parse(b) }); res.end('ok'); }); }).listen(18799);

// jetons
const ro = await call('create_token', { name: 'Lecteur', permission: 'read' });
const cl = await call('create_token', { name: 'Claude', permission: 'write' });
ok(ro.token.startsWith('gix_') && cl.token, 'create_token (read + write)');
ok((await call('whoami', {}, cl.token)).name === 'Claude', 'whoami avec le jeton Claude');
await fails(call('create_repository', { name: 'x' }, ro.token), /Permission refusée/, 'jeton read ne peut pas écrire');
await fails(call('create_token', { name: 'z' }, cl.token), /admin/, 'jeton write ne peut pas créer de jeton');
ok((await call('list_tokens')).length === 3, 'list_tokens');

await call('create_webhook', { repo: 'demo', url: 'http://127.0.0.1:18799/h', secret: 's3' });
const issue = await call('create_issue', { repo: 'demo', title: 'Écrit par Claude', milestone: 'v2' }, cl.token);
ok(issue.author === 'Claude' && issue.milestone === 'v2', 'auteur = nom du jeton, jalon sur ticket');
await call('create_or_update_file', { repo: 'demo', path: 'claude.txt', content: 'c\n' }, cl.token);
ok((await call('list_commits', { repo: 'demo', limit: 1 }))[0].author === 'Claude', 'commit signé du nom du jeton');

// étiquettes / jalons
await call('create_label', { repo: 'demo', name: 'bug', color: '#d73a4a' });
await call('create_milestone', { repo: 'demo', title: 'v2' });
await call('update_issue', { repo: 'demo', number: issue.number, labels: ['bug'], state: 'closed' });
const ms = await call('list_milestones', { repo: 'demo' });
ok(ms[0].closed_issues === 1 && ms[0].progress === 100, 'jalons avec avancement');
ok((await call('list_labels', { repo: 'demo' })).find((l) => l.name === 'bug').count >= 1, 'étiquettes avec compteur');

// protection + approbations + CI
await call('set_branch_protection', { repo: 'demo', branch: 'main', require_pull_request: true, required_approvals: 1, required_checks: ['tests'] });
await fails(call('create_or_update_file', { repo: 'demo', path: 'p.txt', content: 'p' }), /protégée/, 'commit direct refusé sur branche protégée');
let pushRefused = false; try { execSync('cd work/demo && echo z>z && git add z && git -c user.name=a -c user.email=a@a commit -qm z && git push -q origin main 2>&1', { stdio: 'pipe' }); } catch (e) { pushRefused = /protégée|rejected|declined/.test(String(e.stdout) + String(e.stderr)); }
ok(pushRefused, 'git push refusé sur branche protégée');
await call('create_branch', { repo: 'demo', branch: 'pr1' });
await call('create_or_update_file', { repo: 'demo', branch: 'pr1', path: 'p.txt', content: 'p\n' }, cl.token);
const pr = await call('create_pull_request', { repo: 'demo', title: 'PR protégée', head: 'pr1' }, cl.token);
await fails(call('merge_pull_request', { repo: 'demo', number: pr.number }), /approbation/, 'fusion bloquée sans approbation');
await call('create_review', { repo: 'demo', number: pr.number, event: 'APPROVE' });
await fails(call('merge_pull_request', { repo: 'demo', number: pr.number }), /tests/, 'fusion bloquée sans CI');
await call('create_check_run', { repo: 'demo', sha: `pull/${pr.number}`, name: 'tests', conclusion: 'failure' }, cl.token);
await fails(call('merge_pull_request', { repo: 'demo', number: pr.number }), /failure/, 'fusion bloquée si CI en échec');
await call('create_check_run', { repo: 'demo', sha: `pull/${pr.number}`, name: 'tests', conclusion: 'success', summary: '12 tests OK' }, cl.token);
ok((await call('get_pull_request', { repo: 'demo', number: pr.number })).checks[0].conclusion === 'success', 'checks visibles dans la PR');
ok((await call('merge_pull_request', { repo: 'demo', number: pr.number })).merged, 'fusion OK avec approbation + CI verte');
await call('remove_branch_protection', { repo: 'demo', branch: 'main' });

// git ops
const log = await call('list_commits', { repo: 'demo', limit: 5 });
const bl = await call('blame', { repo: 'demo', path: 'claude.txt' });
ok(/Claude/.test(bl), 'blame');
const c0 = (await call('list_commits', { repo: 'demo', path: 'claude.txt' }))[0];
await call('revert_commit', { repo: 'demo', sha: c0.sha });
await fails(call('get_file_contents', { repo: 'demo', path: 'claude.txt' }), /Introuvable/, 'revert_commit');
await call('create_branch', { repo: 'demo', branch: 'cp' });
await call('create_or_update_file', { repo: 'demo', branch: 'cp', path: 'cp.txt', content: 'cp\n', message: 'Pour cherry-pick' });
const cpc = (await call('list_commits', { repo: 'demo', ref: 'cp', limit: 1 }))[0];
await call('cherry_pick', { repo: 'demo', sha: cpc.sha, branch: 'main' });
ok((await call('get_file_contents', { repo: 'demo', path: 'cp.txt' })).content === 'cp\n', 'cherry_pick');
await call('create_branch', { repo: 'demo', branch: 'old', from: log[3].sha });
await call('create_or_update_file', { repo: 'demo', branch: 'old', path: 'old.txt', content: 'o\n' });
const opr = await call('create_pull_request', { repo: 'demo', title: 'Ancienne', head: 'old' });
ok((await call('update_pull_request_branch', { repo: 'demo', number: opr.number })).updated, 'update_pull_request_branch');
await call('rename_branch', { repo: 'demo', branch: 'old', new_name: 'ancienne' });
ok((await call('get_pull_request', { repo: 'demo', number: opr.number })).head === 'ancienne', 'rename_branch met à jour la PR');
ok((await call('merge_branches', { repo: 'demo', base: 'main', head: 'ancienne' })).commit, 'merge_branches');
await call('create_tag', { repo: 'demo', tag: 'v9' }); await call('delete_tag', { repo: 'demo', tag: 'v9' }); ok(!(await call('list_tags', { repo: 'demo' })).some((t) => t.name === 'v9'), 'delete_tag');

// wiki, gists, pages, discussions, projets
await call('write_wiki_page', { repo: 'demo', title: 'Accueil', content: '# Bienvenue' });
ok((await call('get_wiki_page', { repo: 'demo', title: 'Accueil' })).content === '# Bienvenue', 'wiki');
ok(!(await call('list_repositories')).some((r) => r.full_name.endsWith('.wiki')), 'le wiki n’apparaît pas comme dépôt');
const g = await call('create_gist', { description: 'snippet', files: [{ path: 'a.py', content: 'print(1)' }] });
await call('update_gist', { id: g.id, files: [{ path: 'b.py', content: 'print(2)' }] });
ok((await call('get_gist', { id: g.id })).files.length === 2 && (await call('list_gists')).length === 1, 'gists');
await call('push_files', { repo: 'demo', message: 'site', files: [{ path: 'docs/index.html', content: '<h1>Mon site</h1>' }, { path: 'docs/style.css', content: 'h1{}' }] });
const pg = await call('enable_pages', { repo: 'demo', folder: 'docs' });
const page = await fetch(BASE + '/pages/moi/demo/');
ok(page.status === 200 && (await page.text()).includes('Mon site') && page.headers.get('content-type').includes('text/html'), 'GIXCLOUD Pages (sans jeton)');
ok((await fetch(BASE + '/pages/moi/demo/style.css')).headers.get('content-type').includes('css'), 'Pages : type MIME');
const raw = await fetch(BASE + '/raw/moi/demo/main/docs/index.html', { headers: { Authorization: 'Bearer testtoken' } });
ok((await raw.text()) === '<h1>Mon site</h1>', 'fichier brut /raw');
ok((await fetch(BASE + '/raw/moi/demo/main/docs/index.html')).status === 401, '/raw exige le jeton');
const zip = Buffer.from(await (await fetch(BASE + '/archive/moi/demo/main.zip', { headers: { Authorization: 'Bearer testtoken' } })).arrayBuffer());
ok(zip.subarray(0, 2).toString() === 'PK' && zip.includes(Buffer.from('demo-main/docs/index.html')), 'archive ZIP');
const d = await call('create_discussion', { repo: 'demo', title: 'Question ?', category: 'q-a' });
await call('add_discussion_comment', { repo: 'demo', number: d.number, body: 'Réponse', mark_as_answer: true });
ok((await call('get_discussion', { repo: 'demo', number: d.number })).answer === 1, 'discussions + réponse acceptée');
const pj = await call('create_project', { repo: 'demo', name: 'Feuille de route' });
const card = await call('add_project_card', { repo: 'demo', project: pj.number, issue: issue.number });
await call('move_project_card', { repo: 'demo', project: pj.number, card: card.id, column: 'En cours' });
ok((await call('get_project', { repo: 'demo', number: pj.number })).board['En cours'][0].title === 'Écrit par Claude', 'projets kanban');

// réglages
await call('star_repository', { repo: 'demo' });
ok((await call('list_starred'))[0] === 'moi/demo', 'étoiles');
ok((await call('repository_stats', { repo: 'demo' })).contributors.length >= 2, 'repository_stats');
ok((await call('get_clone_urls', { repo: 'demo' })).clone_command.includes('/git/moi/demo.git'), 'get_clone_urls');
ok((await call('search_issues', { query: 'claude' })).length >= 1, 'search_issues');
ok((await call('search_repositories', { query: 'dém' })).length === 1, 'search_repositories');
await call('set_repository_settings', { repo: 'demo', archived: true });
await fails(call('create_or_update_file', { repo: 'demo', path: 'q', content: 'q' }), /archivé/, 'dépôt archivé en lecture seule');
await call('set_repository_settings', { repo: 'demo', archived: false });

// synchro distante : import par HTTP depuis le serveur lui-même (comme depuis GitHub), push/pull vers un distant
const imp = await call('import_repository', { url: BASE + '/git/moi/demo.git', name: 'copie', token: 'testtoken', username: 'gix' });
ok(imp.full_name === 'moi/copie' && imp.last_commit, 'import_repository via HTTPS/HTTP avec jeton');
execSync(`rm -rf ${process.cwd()}/remote.git && git init -q --bare -b main ${process.cwd()}/remote.git`);
await call('add_remote', { repo: 'demo', name: 'github', url: process.cwd() + '/remote.git' });
const pu = await call('push_to_remote', { repo: 'demo', remote: 'github', tags: true });
ok(pu.updates.every((u) => u.status === 'ok'), 'push_to_remote');
execSync(`cd work && rm -rf rc && git clone -q ${process.cwd()}/remote.git rc && cd rc && echo r>r.txt && git add r.txt && git -c user.name=r -c user.email=r@r commit -qm "Depuis le distant" && git push -q origin main`);
const pl = await call('pull_from_remote', { repo: 'demo', remote: 'github' });
ok(pl.updated.includes('main') && (await call('list_commits', { repo: 'demo', limit: 1 }))[0].message === 'Depuis le distant', 'pull_from_remote (avance rapide)');

// activité, notifications, webhooks
execSync('cd work/demo && git checkout -qb evt && echo e>e.txt && git add e.txt && git -c user.name=a -c user.email=a@a commit -qm evt && git push -q origin evt 2>/dev/null');
const evs = await call('list_events', { repo: 'demo', limit: 200 });
console.log('  types :', [...new Set(evs.map((e) => e.type))].join(', '));
ok(evs.some((e) => e.type === 'push') && evs.some((e) => e.type === 'merge_pull_request' && e.actor === 'GIXCLOUD'), 'fil d’activité (push git + fusions)');
ok((await call('list_notifications')).unread > 0, 'notifications');
await new Promise((r) => setTimeout(r, 800));
ok(hooks.length > 5 && hooks.every((h) => /^sha256=/.test(h.sig)), `webhooks reçus et signés (${hooks.length})`);
await call('revoke_token', { name: 'Claude' });
await fails(call('whoami', {}, cl.token), /./, 'jeton révoqué');
srv.close();
console.log('TOUT EST OK');
