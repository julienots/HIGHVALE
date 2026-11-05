// Tests de bout en bout : on lance le serveur MCP et on l’utilise comme Claude le ferait.
// APK réel : GIXCLOUD_TEST_APK=1 ANDROID_HOME=… npm test

import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import readline from 'node:readline';
import { fileURLToPath } from 'node:url';

const SERVER = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'src', 'server.js');
const home = fs.mkdtempSync(path.join(os.tmpdir(), 'gixcloud-test-'));
let proc;
let nextId = 1;
const pending = new Map();

function rpc(method, params) {
  const id = nextId++;
  proc.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n');
  return new Promise((ok) => pending.set(id, ok));
}

async function call(name, args = {}) {
  const res = await rpc('tools/call', { name, arguments: args });
  const text = res.result.content[0].text;
  if (res.result.isError) throw new Error(text);
  try { return JSON.parse(text); } catch { return text; }
}

before(async () => {
  proc = spawn(process.execPath, [SERVER], { env: { ...process.env, GIXCLOUD_HOME: home, GIXCLOUD_OWNER: 'moi' }, stdio: ['pipe', 'pipe', 'inherit'] });
  readline.createInterface({ input: proc.stdout }).on('line', (l) => {
    const m = JSON.parse(l);
    pending.get(m.id)?.(m);
    pending.delete(m.id);
  });
  const init = await rpc('initialize', { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'test', version: '0' } });
  assert.equal(init.result.serverInfo.name, 'gixcloud');
});

after(() => {
  proc.stdin.end();
  if (process.env.GIXCLOUD_KEEP) return console.error('données gardées :', home);
  fs.rmSync(home, { recursive: true, force: true });
});

test('dépôts, fichiers, branches, PR, fusion, tickets, versions', async () => {
  const repo = await call('create_repository', { name: 'demo', description: 'Démo', gitignore: 'node' });
  assert.equal(repo.full_name, 'moi/demo');
  assert.equal(repo.default_branch, 'main');

  await call('push_files', { repo: 'demo', message: 'Code', files: [{ path: 'src/a.js', content: 'console.log(1)\n' }, { path: 'img.bin', content: Buffer.from([0, 1, 2]).toString('base64'), encoding: 'base64' }] });
  const dir = await call('get_file_contents', { repo: 'demo', path: 'src' });
  assert.equal(dir.entries[0].name, 'a.js');
  const bin = await call('get_file_contents', { repo: 'demo', path: 'img.bin' });
  assert.equal(bin.encoding, 'base64');

  const issue = await call('create_issue', { repo: 'demo', title: 'Afficher 2', labels: ['bug'] });
  assert.equal(issue.number, 1);

  await call('create_branch', { repo: 'demo', branch: 'fix' });
  const f = await call('get_file_contents', { repo: 'demo', path: 'src/a.js', ref: 'fix' });
  await call('create_or_update_file', { repo: 'demo', branch: 'fix', path: 'src/a.js', content: 'console.log(2)\n', sha: f.sha, message: 'Affiche 2' });
  await assert.rejects(call('create_or_update_file', { repo: 'demo', branch: 'fix', path: 'src/a.js', content: 'x', sha: f.sha }), /a changé/);

  // la branche main avance aussi (fusion à 3 voies sans conflit)
  await call('create_or_update_file', { repo: 'demo', path: 'NOTES.md', content: 'notes\n' });

  const pr = await call('create_pull_request', { repo: 'demo', title: 'Correction', head: 'fix', body: 'Fixes #1' });
  assert.equal(pr.number, 2);
  assert.equal(pr.mergeable, true);
  const prd = await call('get_pull_request', { repo: 'demo', number: 2 });
  assert.equal(prd.files[0].file, 'src/a.js');
  assert.match(prd.diff, /\+console\.log\(2\)/);
  await call('create_review', { repo: 'demo', number: 2, event: 'APPROVE', body: 'OK' });

  const wf = await call('run_workflow', { repo: 'demo', pr: 2, command: 'grep -q "2" src/a.js' });
  assert.equal(wf.status, 'success');

  const merged = await call('merge_pull_request', { repo: 'demo', number: 2, delete_branch: true });
  assert.equal(merged.merged, true);
  assert.deepEqual(merged.closed_issues, [1]);
  assert.equal((await call('get_issue', { repo: 'demo', number: 1 })).state, 'closed');
  const main = await call('get_file_contents', { repo: 'demo', path: 'src/a.js' });
  assert.equal(main.content, 'console.log(2)\n');
  assert.ok((await call('get_file_contents', { repo: 'demo', path: 'NOTES.md' })).content);
  assert.equal((await call('list_branches', { repo: 'demo' })).length, 1);

  // conflit détecté
  await call('create_branch', { repo: 'demo', branch: 'c1' });
  await call('create_or_update_file', { repo: 'demo', branch: 'c1', path: 'NOTES.md', content: 'A\n' });
  await call('create_or_update_file', { repo: 'demo', path: 'NOTES.md', content: 'B\n' });
  const cpr = await call('create_pull_request', { repo: 'demo', title: 'Conflit', head: 'c1' });
  assert.equal(cpr.mergeable, false);
  assert.deepEqual(cpr.conflicts, ['NOTES.md']);
  await assert.rejects(call('merge_pull_request', { repo: 'demo', number: cpr.number }), /Conflits/);

  // annulation d'un commit
  const log = await call('list_commits', { repo: 'demo', path: 'NOTES.md' });
  const rv = await call('revert_commit', { repo: 'demo', sha: log[0].sha });
  assert.ok(rv.commit);
  assert.equal((await call('get_file_contents', { repo: 'demo', path: 'NOTES.md' })).content, 'notes\n');

  // recherche, stats, versions, tags
  const hits = await call('search_code', { query: 'console.log' });
  assert.equal(hits[0].repo, 'moi/demo');
  const stats = await call('repository_stats', { repo: 'demo' });
  assert.ok(stats.commits >= 5);
  const asset = path.join(home, 'notes.txt');
  fs.writeFileSync(asset, 'fichier joint');
  const rel = await call('create_release', { repo: 'demo', tag: 'v1.0.0', name: 'Première', assets: [asset] });
  assert.match(rel.body, /Affiche 2/);
  assert.equal(rel.assets[0].name, 'notes.txt');
  assert.equal((await call('get_release', { repo: 'demo', tag: 'latest' })).tag, 'v1.0.0');

  // clonable avec git normal, et push accepté
  const clone = path.join(home, 'clone');
  assert.equal(spawnSync('git', ['clone', '-q', repo.clone_path, clone]).status, 0);
  fs.writeFileSync(path.join(clone, 'local.txt'), 'depuis un clone\n');
  spawnSync('git', ['-C', clone, 'add', '.']);
  spawnSync('git', ['-C', clone, '-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-qm', 'Depuis le clone']);
  assert.equal(spawnSync('git', ['-C', clone, 'push', '-q', 'origin', 'main']).status, 0);
  assert.equal((await call('list_commits', { repo: 'demo', limit: 1 }))[0].message, 'Depuis le clone');

  // fork + PR depuis le fork
  await call('fork_repository', { repo: 'demo', new_owner: 'ami' });
  await call('create_or_update_file', { repo: 'ami/demo', path: 'fork.txt', content: 'du fork\n' });
  const fpr = await call('create_pull_request', { repo: 'demo', title: 'Du fork', head: 'ami/demo:main' });
  assert.equal(fpr.mergeable, true);
  await call('merge_pull_request', { repo: 'demo', number: fpr.number, merge_method: 'squash' });
  assert.equal((await call('get_file_contents', { repo: 'demo', path: 'fork.txt' })).content, 'du fork\n');

  // export / import / renommage / suppression
  const exp = await call('export_repository', { repo: 'demo' });
  const imp = await call('import_repository', { source: exp.bundle, name: 'demo-copie' });
  assert.equal(imp.full_name, 'moi/demo-copie');
  await call('update_repository', { repo: 'demo-copie', new_name: 'demo2' });
  await assert.rejects(call('delete_repository', { repo: 'demo2', confirm: 'non' }), /Confirmation/);
  await call('delete_repository', { repo: 'demo2', confirm: 'moi/demo2' });
  assert.equal((await call('list_repositories')).length, 2);
});

test('application Android : modèle, version, analyse APK', async () => {
  const app = await call('create_android_app', { name: 'mon-appli', app_name: "L'Appli", template: 'webview', package_name: 'com.moi.appli' });
  assert.ok(app.files.includes('gradlew'));
  assert.ok(app.files.includes('app/src/main/assets/www/index.html'));
  const tree = await call('get_file_contents', { repo: 'mon-appli', path: 'gradlew' });
  assert.equal(tree.content.startsWith('#!/bin/sh'), true);
  const v = await call('set_app_version', { repo: 'mon-appli', bump: 'minor' });
  assert.equal(v.version_name, '1.1.0');
  assert.equal(v.version_code, 2);
  const env = await call('android_environment');
  assert.ok(env.gixcloud_home);
});

test('build réel d’un APK (si SDK Android présent)', { skip: !process.env.GIXCLOUD_TEST_APK, timeout: 30 * 60000 }, async () => {
  const b = await call('build_apk', { repo: 'mon-appli', variant: 'debug', wait_seconds: 1700, send_to: path.join(home, 'envoi') });
  assert.equal(b.status, 'success', JSON.stringify(b, null, 2));
  const info = await call('apk_info', {});
  assert.equal(info.package, 'com.moi.appli');
  assert.equal(info.versionName, '1.1.0');
  assert.equal(info.versionCode, 2);
  assert.ok(info.signed.v2_plus || info.signed.v1_jar);
  assert.ok(info.permissions.includes('android.permission.INTERNET'));
  assert.ok(fs.readdirSync(path.join(home, 'envoi')).some((f) => f.endsWith('.apk')));
  const rel = await call('publish_apk_release', { repo: 'mon-appli', bump: 'patch', variant: 'release', send_to: path.join(home, 'envoi2') });
  assert.equal(rel.release, 'v1.1.1', JSON.stringify(rel, null, 2));
  const signed = await call('apk_info', { apk: rel.apks[0] });
  assert.ok(signed.signed.v2_plus);
  assert.equal(signed.versionName, '1.1.1');
});
