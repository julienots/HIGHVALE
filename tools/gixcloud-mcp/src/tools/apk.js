// Fonctions en plus de GitHub : créer des applis Android, construire, signer,
// analyser, installer et envoyer des APK — tout en local.

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { ToolError } from '../mcp.js';
import { git, revParse, resolveRef, defaultBranch, commitChanges, runLogged } from '../git.js';
import { requireRepo, ident, gitDirOf, readMeta, updateMeta, writeMeta, ensureDir, now, HOME, APK_DIR, buildDir } from '../store.js';
import { readZip } from '../apk/zip.js';
import { manifestSummary } from '../apk/axml.js';
import { androidTemplate } from '../templates/android.js';
import { copyAsset, collabTools } from './collab.js';
import { S, REPO, tool, RO, DESTRUCTIVE, clip } from './util.js';

const IS_WIN = process.platform === 'win32';
const EXE = IS_WIN ? '.exe' : '';

// ---------- Outils Android du système ----------

export function androidSdk() {
  const candidates = [
    process.env.GIXCLOUD_ANDROID_SDK,
    process.env.ANDROID_HOME,
    process.env.ANDROID_SDK_ROOT,
    path.join(os.homedir(), 'Android', 'Sdk'),
    path.join(os.homedir(), 'Library', 'Android', 'sdk'),
    process.env.LOCALAPPDATA && path.join(process.env.LOCALAPPDATA, 'Android', 'Sdk'),
    '/opt/android-sdk',
    process.env.PREFIX && path.join(process.env.PREFIX, 'share', 'android-sdk'), // Termux
  ].filter(Boolean);
  return candidates.find((d) => fs.existsSync(path.join(d, 'platforms')) || fs.existsSync(path.join(d, 'build-tools'))) || null;
}

function which(cmd) {
  const r = spawnSync(IS_WIN ? 'where' : 'which', [cmd], { encoding: 'utf8' });
  return r.status === 0 ? r.stdout.split(/\r?\n/)[0].trim() : null;
}

function buildTool(name) {
  const sdk = androidSdk();
  if (sdk) {
    const bt = path.join(sdk, 'build-tools');
    if (fs.existsSync(bt)) {
      const versions = fs.readdirSync(bt).sort((a, b) => b.localeCompare(a, undefined, { numeric: true }));
      for (const v of versions) {
        for (const ext of IS_WIN ? ['.bat', '.exe'] : ['']) {
          const p = path.join(bt, v, name + ext);
          if (fs.existsSync(p)) return p;
        }
      }
    }
  }
  return which(name);
}

function adbPath() {
  const sdk = androidSdk();
  const p = sdk && path.join(sdk, 'platform-tools', `adb${EXE}`);
  return p && fs.existsSync(p) ? p : which('adb');
}

function run(cmd, args, opts = {}) {
  const r = spawnSync(cmd, args, { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, shell: IS_WIN && /\.(bat|cmd)$/i.test(cmd), ...opts });
  if (r.error) throw new ToolError(`${path.basename(cmd)} : ${r.error.message}`);
  return r;
}

function adb(args, serial) {
  const a = adbPath();
  if (!a) throw new ToolError('adb introuvable : installez « Android SDK Platform-Tools » ou définissez ANDROID_HOME.');
  return run(a, [...(serial ? ['-s', serial] : []), ...args]);
}

// ---------- Analyse d’APK ----------

export function apkInfo(file) {
  const z = readZip(file);
  const manifest = z.get('AndroidManifest.xml');
  if (!manifest) throw new ToolError('Pas d’AndroidManifest.xml : ce n’est pas un APK.');
  const info = manifestSummary(manifest);
  const names = z.entries.map((e) => e.name);
  const abis = [...new Set(names.filter((n) => n.startsWith('lib/')).map((n) => n.split('/')[1]))];
  const sha256 = crypto.createHash('sha256').update(z.buf).digest('hex');
  return {
    file: path.resolve(file),
    size: z.buf.length,
    size_mb: Math.round((z.buf.length / 1048576) * 100) / 100,
    sha256,
    ...info,
    abis: abis.length ? abis : ['(toutes : pas de code natif)'],
    dex_files: names.filter((n) => /^classes\d*\.dex$/.test(n)).length,
    signed: { v1_jar: names.some((n) => /^META-INF\/.*\.(RSA|DSA|EC)$/i.test(n)), v2_plus: z.hasV2Signature },
    entries: z.entries.length,
  };
}

// ---------- Détection et construction ----------

function readTreeFile(gitDir, sha, p) {
  const r = git(gitDir, ['cat-file', 'blob', `${sha}:${p}`], { allowFail: true });
  return r.status === 0 ? r.stdout : null;
}

function detectProject(gitDir, sha) {
  const files = git(gitDir, ['ls-tree', '-r', '--name-only', sha]).split('\n').filter(Boolean);
  const set = new Set(files);
  let cfg = {};
  const lh = readTreeFile(gitDir, sha, 'gixcloud.json');
  if (lh) { try { cfg = JSON.parse(lh).build || {}; } catch { throw new ToolError('gixcloud.json invalide.'); } }
  if (cfg.type) return { ...cfg, files };
  if (set.has('pubspec.yaml') && /flutter:/.test(readTreeFile(gitDir, sha, 'pubspec.yaml') || '')) return { type: 'flutter', files };
  if (set.has('project.godot')) {
    const presets = readTreeFile(gitDir, sha, 'export_presets.cfg') || '';
    const m = [...presets.matchAll(/\[preset\.\d+\][^[]*?name="([^"]+)"[^[]*?platform="Android"/g)];
    return { type: 'godot', preset: m[0]?.[1] || 'Android', export_path: (presets.match(/export_path="([^"]+\.apk)"/) || [])[1], files };
  }
  const gradleApp = files.filter((f) => /(^|\/)build\.gradle(\.kts)?$/.test(f)).some((f) => /com\.android\.application|android\s*\{/.test(readTreeFile(gitDir, sha, f) || ''));
  if (gradleApp) return { type: 'gradle', files };
  if (set.has('capacitor.config.json') || set.has('capacitor.config.ts')) return { type: 'capacitor', files };
  return { type: 'unknown', files };
}

/** Copie de travail persistante (garde les caches Gradle d’un build à l’autre). */
function prepareWorkspace(r, sha) {
  const ws = path.join(HOME, 'workspaces', r.owner, r.repo);
  if (!fs.existsSync(path.join(ws, '.git'))) {
    fs.rmSync(ws, { recursive: true, force: true });
    ensureDir(path.dirname(ws));
    git(null, ['clone', '--quiet', '--no-checkout', r.gitDir, ws]);
  }
  const wd = { cwd: ws };
  git(null, ['-C', ws, 'fetch', '--quiet', '--force', '--tags', 'origin', '+refs/heads/*:refs/remotes/origin/*', '+refs/pull/*:refs/remotes/pull/*'], wd);
  git(null, ['-C', ws, 'fetch', '--quiet', 'origin', sha], { ...wd, allowFail: true });
  git(null, ['-C', ws, 'checkout', '--quiet', '--force', '--detach', sha], wd);
  git(null, ['-C', ws, 'clean', '-fdq'], wd); // garde les fichiers ignorés (build/, .gradle/) pour aller plus vite
  return ws;
}

function findApks(dir, since) {
  const out = [];
  const walk = (d, depth) => {
    if (depth > 12) return;
    let entries;
    try { entries = fs.readdirSync(d, { withFileTypes: true }); } catch { return; }
    for (const e of entries) {
      if (e.name === '.git' || e.name === 'node_modules' || e.name === '.gradle' || e.name === 'intermediates') continue;
      const p = path.join(d, e.name);
      if (e.isDirectory()) walk(p, depth + 1);
      else if (e.name.endsWith('.apk') && fs.statSync(p).mtimeMs >= since) out.push(p);
    }
  };
  walk(dir, 0);
  return out;
}

function buildCommand(proj, variant, ws, a) {
  const release = variant === 'release';
  switch (proj.type) {
    case 'gradle': {
      const task = a.task || (release ? proj.release_task || 'assembleRelease' : proj.debug_task || 'assembleDebug');
      const wrapper = path.join(ws, IS_WIN ? 'gradlew.bat' : 'gradlew');
      if (fs.existsSync(wrapper)) {
        if (!IS_WIN) fs.chmodSync(wrapper, 0o755);
        return { cmd: wrapper, args: [task, '--console=plain', '--no-daemon'] };
      }
      const g = which('gradle');
      if (!g) throw new ToolError('Ni gradlew dans le dépôt, ni gradle installé.');
      return { cmd: g, args: [task, '--console=plain'] };
    }
    case 'flutter':
      return { cmd: which('flutter') || 'flutter', args: ['build', 'apk', release ? '--release' : '--debug'] };
    case 'godot': {
      const godot = process.env.GIXCLOUD_GODOT || which('godot') || which('godot4');
      if (!godot) throw new ToolError('Godot introuvable : définissez GIXCLOUD_GODOT (chemin de l’exécutable Godot 4).');
      const out = path.join(ws, 'build', `${a.repo}-${variant}.apk`);
      ensureDir(path.dirname(out));
      return { cmd: godot, args: ['--headless', `--export-${release ? 'release' : 'debug'}`, proj.preset, out], pre: [{ cmd: godot, args: ['--headless', '--import'] }] };
    }
    case 'capacitor':
      return { cmd: IS_WIN ? 'npx.cmd' : 'npx', args: ['cap', 'build', 'android'], pre: [{ cmd: IS_WIN ? 'npm.cmd' : 'npm', args: ['install'] }, { cmd: IS_WIN ? 'npx.cmd' : 'npx', args: ['cap', 'sync', 'android'] }] };
    case 'custom':
      if (!proj.command) throw new ToolError('gixcloud.json : « build.command » manquant.');
      return { cmd: IS_WIN ? 'cmd' : 'sh', args: IS_WIN ? ['/c', proj.command] : ['-c', proj.command] };
    default:
      throw new ToolError('Type de projet non reconnu. Ajoutez un gixcloud.json : {"build":{"type":"custom","command":"…"}} ou utilisez create_android_app.');
  }
}

const active = new Map(); // id -> promise

async function executeBuild(r, b, a) {
  const logFile = b.log;
  const env = {};
  const sdk = androidSdk();
  if (sdk) { env.ANDROID_HOME = sdk; env.ANDROID_SDK_ROOT = sdk; }
  const finish = (patch) => updateMeta(r, (m) => {
    const x = m.builds.find((y) => y.id === b.id);
    Object.assign(x, patch, { finished_at: now(), duration_s: Math.round((Date.now() - Date.parse(x.started_at)) / 1000) });
    return x;
  });
  try {
    const ws = prepareWorkspace(r, b.commit);
    const proj = detectProject(r.gitDir, b.commit);
    if (proj.type === 'gradle' && sdk && !fs.existsSync(path.join(ws, 'local.properties'))) {
      fs.writeFileSync(path.join(ws, 'local.properties'), `sdk.dir=${sdk.replace(/\\/g, '\\\\')}\n`);
    }
    const c = buildCommand(proj, b.variant, ws, a);
    fs.appendFileSync(logFile, `Projet ${proj.type}, variante ${b.variant}, commit ${b.commit}\nSDK Android : ${sdk || 'non trouvé'}\n`);
    // On retire les APK des builds précédents : seul le résultat de ce build sera récupéré.
    for (const old of findApks(ws, 0)) {
      const tracked = git(null, ['-C', ws, 'ls-files', '--error-unmatch', old], { cwd: ws, allowFail: true }).status === 0;
      if (!tracked) fs.rmSync(old, { force: true });
    }
    const started = Date.now() - 2000;
    for (const p of c.pre || []) await runLogged(p.cmd, p.args, { cwd: ws, env, logFile });
    const res = await runLogged(c.cmd, c.args, { cwd: ws, env, logFile, timeoutMs: (a.timeout_minutes || 60) * 60000 });
    if (res.code !== 0) return finish({ status: 'failed', error: res.error || `code ${res.code}` });
    let apks = findApks(ws, started);
    if (proj.apk_glob) {
      const re = new RegExp(proj.apk_glob.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*\*/g, '§').replace(/\*/g, '[^/]*').replace(/§/g, '.*'));
      apks = apks.filter((p) => re.test(path.relative(ws, p).split(path.sep).join('/')));
    }
    if (!apks.length) return finish({ status: 'failed', error: 'Build réussi mais aucun APK produit.' });
    ensureDir(APK_DIR);
    const outputs = [];
    for (const src of apks) {
      let info = {};
      try { info = apkInfo(src); } catch { /* APK illisible : copié quand même */ }
      const suffix = path.basename(src, '.apk').replace(/^app-?/, '') || b.variant;
      const name = `${r.repo}-${info.versionName || b.ref.replace(/[^\w.-]/g, '_')}-${b.commit.slice(0, 7)}-${suffix}.apk`;
      const dest = path.join(APK_DIR, name);
      fs.copyFileSync(src, dest);
      outputs.push({ path: dest, size: fs.statSync(dest).size, package: info.package, versionName: info.versionName, versionCode: info.versionCode, signed: info.signed });
    }
    const after = [];
    if (a.release_tag) {
      updateMeta(r, (m) => {
        const rel = m.releases.find((x) => x.tag === a.release_tag);
        if (!rel) { after.push(`version ${a.release_tag} introuvable : APK non joint`); return; }
        for (const o of outputs) {
          const asset = copyAsset(r, a.release_tag, o.path);
          rel.assets = rel.assets.filter((x) => x.name !== asset.name).concat(asset);
        }
        after.push(`joint à la version ${a.release_tag}`);
      });
    }
    if (a.send_to) for (const o of outputs) after.push(...sendFile(o.path, a.send_to));
    if (a.install) for (const o of outputs.slice(0, 1)) after.push(installApk(o.path, a.device));
    return finish({ status: 'success', outputs, after });
  } catch (e) {
    fs.appendFileSync(logFile, `\nErreur : ${e.message}\n`);
    return finish({ status: 'failed', error: e.message });
  }
}

function startJob(r, kind, a, runner) {
  const ref = a.ref || defaultBranch(r.gitDir);
  const commit = resolveRef(r.gitDir, a.pr ? `refs/pull/${a.pr}/head` : ref);
  const dir = buildDir(r);
  const rec = updateMeta(r, (m) => {
    const list = m[kind];
    const id = (list.reduce((mx, x) => Math.max(mx, x.id), 0) || 0) + 1;
    const x = { id, status: 'running', ref: a.pr ? `pull/${a.pr}` : ref, commit, started_at: now(), log: path.join(dir, `${kind === 'builds' ? 'build' : 'run'}-${id}.log`) };
    if (kind === 'builds') x.variant = a.variant || 'debug';
    if (kind === 'runs') x.command = a.command;
    list.push(x);
    if (list.length > 200) list.splice(0, list.length - 200);
    return x;
  });
  fs.writeFileSync(rec.log, `[${rec.started_at}] ${kind === 'builds' ? 'Build' : 'Exécution'} #${rec.id} de ${r.full}@${rec.ref}\n`);
  const p = runner(rec).finally(() => active.delete(`${r.full}#${kind}#${rec.id}`));
  active.set(`${r.full}#${kind}#${rec.id}`, p);
  return { rec, p };
}

async function waitFor(p, rec, seconds, r, kind) {
  const limit = (seconds ?? 600) * 1000;
  const res = await Promise.race([p, new Promise((ok) => setTimeout(() => ok(null), limit))]);
  if (res) return res;
  return { ...rec, status: 'running', note: `Toujours en cours : suivez avec ${kind === 'builds' ? 'get_build' : 'get_run'} id=${rec.id}.` };
}

/** Un travail « running » dont le processus n’existe plus (serveur redémarré) est marqué interrompu. */
function liveStatus(r, kind, x) {
  if (x.status === 'running' && !active.has(`${r.full}#${kind}#${x.id}`)) return { ...x, status: 'interrupted' };
  return x;
}

function tail(file, lines = 80) {
  if (!fs.existsSync(file)) return '';
  const t = fs.readFileSync(file, 'utf8').split('\n');
  return t.slice(-lines).join('\n');
}

// ---------- Envoi / installation ----------

function sendFile(file, dest) {
  const msgs = [];
  if (dest === 'device' || dest.startsWith('device:')) {
    const serial = dest.split(':')[1];
    const remote = `/sdcard/Download/${path.basename(file)}`;
    const r = adb(['push', file, remote], serial);
    if (r.status !== 0) throw new ToolError(`adb push : ${r.stderr || r.stdout}`);
    msgs.push(`copié sur le téléphone : ${remote}`);
  } else {
    const d = path.resolve(dest.replace(/^~(?=$|[\\/])/, os.homedir()));
    ensureDir(d);
    const target = path.join(d, path.basename(file));
    fs.copyFileSync(file, target);
    msgs.push(`copié dans ${target}`);
  }
  return msgs;
}

function installApk(file, serial) {
  const r = adb(['install', '-r', '-d', file], serial);
  const out = `${r.stdout}${r.stderr}`.trim();
  if (r.status !== 0 || !/Success/.test(out)) throw new ToolError(`Installation échouée : ${out}`);
  return `installé sur ${serial || 'l’appareil connecté'}`;
}

function resolveApk(a) {
  if (a.apk) {
    const p = path.resolve(a.apk);
    if (fs.existsSync(p)) return p;
    const inBox = path.join(APK_DIR, a.apk);
    if (fs.existsSync(inBox)) return inBox;
    throw new ToolError(`APK introuvable : ${a.apk}`);
  }
  const all = listApks();
  if (!all.length) throw new ToolError('Aucun APK dans la boîte de sortie.');
  return all[0].path;
}

function listApks() {
  if (!fs.existsSync(APK_DIR)) return [];
  return fs.readdirSync(APK_DIR).filter((f) => f.endsWith('.apk')).map((f) => {
    const p = path.join(APK_DIR, f);
    const st = fs.statSync(p);
    return { name: f, path: p, size: st.size, modified: st.mtime.toISOString() };
  }).sort((x, y) => y.modified.localeCompare(x.modified));
}

// ---------- Signature ----------

function keysDir() { return ensureDir(path.join(HOME, 'keys')); }

function debugKeystore() {
  const ks = path.join(os.homedir(), '.android', 'debug.keystore');
  if (!fs.existsSync(ks)) {
    ensureDir(path.dirname(ks));
    const r = run(which('keytool') || 'keytool', ['-genkeypair', '-v', '-keystore', ks, '-storepass', 'android', '-alias', 'androiddebugkey', '-keypass', 'android', '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000', '-dname', 'CN=Android Debug,O=Android,C=US']);
    if (r.status !== 0) throw new ToolError(`keytool : ${r.stderr}`);
  }
  return { file: ks, alias: 'androiddebugkey', password: 'android' };
}

function loadKey(name, password) {
  if (!name || name === 'debug') return debugKeystore();
  const cfgFile = path.join(keysDir(), `${name}.json`);
  if (!fs.existsSync(cfgFile)) throw new ToolError(`Clé « ${name} » introuvable (create_keystore).`);
  const cfg = JSON.parse(fs.readFileSync(cfgFile, 'utf8'));
  const pw = password || cfg.password || process.env.GIXCLOUD_KEYSTORE_PASSWORD;
  if (!pw) throw new ToolError('Mot de passe du keystore requis (paramètre password ou variable GIXCLOUD_KEYSTORE_PASSWORD).');
  return { file: cfg.file, alias: cfg.alias, password: pw };
}

// ---------- Version de l’application ----------

function bumpVersion(text, kind, a) {
  let code; let name;
  if (kind === 'gradle') {
    text = text.replace(/(versionCode\s*=?\s*)(\d+)/, (_, p, v) => p + (code = a.version_code ?? Number(v) + 1));
    text = text.replace(/(versionName\s*=?\s*)(["'])([^"']*)\2/, (_, p, q, v) => p + q + (name = a.version_name ?? nextName(v, a.bump)) + q);
  } else {
    text = text.replace(/(version\/code=)(\d+)/, (_, p, v) => p + (code = a.version_code ?? Number(v) + 1));
    text = text.replace(/(version\/name=")([^"]*)"/, (_, p, v) => `${p}${(name = a.version_name ?? nextName(v, a.bump))}"`);
  }
  return { text, code, name };
}

function nextName(v, bump = 'patch') {
  const m = String(v).match(/^(\d+)\.(\d+)(?:\.(\d+))?(.*)$/);
  if (!m) return v;
  let [maj, min, pat] = [Number(m[1]), Number(m[2]), Number(m[3] || 0)];
  if (bump === 'major') { maj++; min = 0; pat = 0; } else if (bump === 'minor') { min++; pat = 0; } else pat++;
  return `${maj}.${min}.${pat}`;
}

// ---------- Outils ----------

export const apkTools = [
  tool('android_environment', 'Vérifie les outils disponibles pour construire des APK : SDK Android, Java, Gradle, adb, apksigner, Godot, Flutter.', {}, [], () => {
    const ver = (cmd, args) => { const p = which(cmd); if (!p) return null; const r = spawnSync(p, args, { encoding: 'utf8', shell: IS_WIN }); return `${p} — ${(r.stdout + r.stderr).split('\n').find((l) => l.trim() && !/JAVA_TOOL_OPTIONS/.test(l))?.trim() || 'ok'}`; };
    const sdk = androidSdk();
    return {
      gixcloud_home: HOME,
      apk_outbox: APK_DIR,
      android_sdk: sdk,
      build_tools: sdk && fs.existsSync(path.join(sdk, 'build-tools')) ? fs.readdirSync(path.join(sdk, 'build-tools')) : [],
      platforms: sdk && fs.existsSync(path.join(sdk, 'platforms')) ? fs.readdirSync(path.join(sdk, 'platforms')) : [],
      java: ver('java', ['-version']),
      gradle: ver('gradle', ['--version']),
      adb: adbPath(),
      apksigner: buildTool('apksigner'),
      zipalign: buildTool('zipalign'),
      godot: process.env.GIXCLOUD_GODOT || which('godot') || which('godot4'),
      flutter: which('flutter'),
      conseils: sdk ? [] : ['SDK Android non trouvé : installez Android Studio (ou les « command line tools ») et définissez ANDROID_HOME.'],
    };
  }, RO),

  tool('create_android_app', 'Crée un dépôt contenant une application Android prête à compiler en APK (native Java ou WebView HTML/JS).', {
    name: S.str('Nom du dépôt.'),
    owner: S.str('Propriétaire.'),
    app_name: S.str('Nom affiché de l’application.'),
    package_name: S.str('Identifiant Android (ex. com.moi.monappli).'),
    template: S.enum(['blank', 'webview'], 'blank = appli native Java ; webview = appli faite en HTML/CSS/JS (assets/www).'),
    html: S.str('Pour webview : contenu de index.html (facultatif).'),
    min_sdk: S.int('Android minimum (défaut 24 = Android 7).'),
    description: S.str('Description du dépôt.'),
  }, ['name'], (a) => {
    const id = ident({ owner: a.owner, repo: a.name });
    const gitDir = gitDirOf(id);
    if (fs.existsSync(gitDir)) throw new ToolError(`${id.full} existe déjà.`);
    const pkg = a.package_name || `com.${id.owner.toLowerCase().replace(/[^a-z0-9]/g, '') || 'local'}.${id.repo.toLowerCase().replace(/[^a-z0-9]/g, '') || 'app'}`;
    if (!/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/.test(pkg)) throw new ToolError(`Identifiant Android invalide : ${pkg}`);
    ensureDir(path.dirname(gitDir));
    git(null, ['init', '--bare', '--quiet', '--initial-branch=main', gitDir]);
    const meta = readMeta(id);
    meta.description = a.description || `Application Android ${a.app_name || id.repo}`;
    meta.topics = ['android', 'apk'];
    writeMeta(id, meta);
    const files = androidTemplate({ appName: a.app_name || id.repo, packageName: pkg, template: a.template || 'blank', html: a.html, minSdk: a.min_sdk });
    const res = commitChanges(gitDir, 'main', files, `Création de l’application Android ${a.app_name || id.repo}`);
    return { repo: id.full, package: pkg, template: a.template || 'blank', commit: res.commit, files: files.map((f) => f.path), next: 'build_apk pour produire l’APK.' };
  }),

  tool('build_apk', 'Construit l’APK d’un dépôt (Gradle/Android Studio, Godot, Flutter, Capacitor ou commande perso), le dépose dans la boîte de sortie locale, et peut le joindre à une version, le copier dans un dossier ou l’installer sur un téléphone.', {
    ...REPO,
    ref: S.str('Branche, tag ou commit (défaut : branche par défaut).'),
    pr: S.int('Construire la pull request n° (au lieu de ref).'),
    variant: S.enum(['debug', 'release'], 'debug (signé automatiquement, installable) ou release.'),
    task: S.str('Tâche Gradle personnalisée (ex. assembleFreeRelease).'),
    release_tag: S.str('Joindre l’APK à cette version (release) existante.'),
    send_to: S.str('Copier l’APK : un dossier local (ex. ~/Téléchargements, clé USB, dossier synchronisé) ou « device » pour /sdcard/Download du téléphone (adb).'),
    install: S.bool('Installer sur le téléphone connecté (adb).'),
    device: S.str('Numéro de série adb de l’appareil.'),
    wait_seconds: S.int('Attente maximale avant de rendre la main (défaut 600) ; le build continue en arrière-plan.'),
    timeout_minutes: S.int('Durée maximale du build (défaut 60).'),
  }, ['repo'], async (a) => {
    const r = requireRepo(a);
    const { rec, p } = startJob(r, 'builds', a, (b) => executeBuild(r, b, { ...a, repo: r.repo }));
    const res = await waitFor(p, rec, a.wait_seconds, r, 'builds');
    return { ...res, log_tail: res.status === 'success' ? undefined : tail(rec.log, 60) };
  }),

  tool('list_builds', 'Historique des builds d’APK d’un dépôt.', { ...REPO, limit: S.int('Maximum (défaut 20).') }, ['repo'], (a) => {
    const r = requireRepo(a);
    return readMeta(r).builds.slice(-(a.limit || 20)).reverse().map((x) => liveStatus(r, 'builds', x));
  }, RO),

  tool('get_build', 'État d’un build et fin de son journal.', { ...REPO, id: S.int('Numéro du build.'), log_lines: S.int('Lignes de journal (défaut 120, 0 = tout).') }, ['repo', 'id'], (a) => {
    const r = requireRepo(a);
    const b = readMeta(r).builds.find((x) => x.id === a.id);
    if (!b) throw new ToolError('Build introuvable.');
    return { ...liveStatus(r, 'builds', b), log: a.log_lines === 0 ? clip(fs.readFileSync(b.log, 'utf8')) : tail(b.log, a.log_lines || 120) };
  }, RO),

  tool('list_apks', 'Liste les APK de la boîte de sortie locale (les plus récents d’abord).', {}, [], () => ({ outbox: APK_DIR, apks: listApks() }), RO),

  tool('apk_info', 'Analyse un APK : paquet, version, SDK min/cible, permissions, architectures, signature, empreinte SHA-256.', {
    apk: S.str('Chemin de l’APK ou nom dans la boîte de sortie (défaut : le plus récent).'),
  }, [], (a) => apkInfo(resolveApk(a)), RO),

  tool('send_apk', 'Envoie un APK en local : copie dans un dossier (Téléchargements, clé USB, dossier partagé…) et/ou sur le téléphone par câble/Wi-Fi (adb), sans aucun serveur.', {
    apk: S.str('Chemin ou nom de l’APK (défaut : le plus récent).'),
    to: S.str('Dossier de destination, « device » (dossier Download du téléphone) ou « device:SERIE ».'),
  }, ['to'], (a) => ({ apk: resolveApk(a), result: sendFile(resolveApk(a), a.to) })),

  tool('delete_apk', 'Supprime un APK de la boîte de sortie.', { apk: S.str('Nom du fichier.') }, ['apk'], (a) => {
    const p = path.join(APK_DIR, path.basename(a.apk));
    if (!fs.existsSync(p)) throw new ToolError('APK introuvable.');
    fs.rmSync(p);
    return { deleted: p };
  }, DESTRUCTIVE),

  tool('list_devices', 'Liste les téléphones/tablettes Android connectés (USB ou Wi-Fi) via adb.', {}, [], () => {
    const r = adb(['devices', '-l']);
    return r.stdout.split('\n').slice(1).filter((l) => l.trim()).map((l) => {
      const [serial, state, ...rest] = l.trim().split(/\s+/);
      return { serial, state, ...Object.fromEntries(rest.map((x) => x.split(':'))) };
    });
  }, RO),

  tool('connect_device', 'Connecte un téléphone en Wi-Fi (débogage sans fil) : appairage avec code puis connexion.', {
    address: S.str('IP:port affiché par le téléphone (Options développeur → Débogage sans fil).'),
    pairing_code: S.str('Code d’appairage à 6 chiffres (première fois seulement, avec l’adresse d’appairage).'),
  }, ['address'], (a) => {
    if (a.pairing_code) {
      const p = adb(['pair', a.address, a.pairing_code]);
      return { pair: (p.stdout + p.stderr).trim(), next: 'Relancez connect_device avec l’adresse de connexion (sans code).' };
    }
    const r = adb(['connect', a.address]);
    return { result: (r.stdout + r.stderr).trim() };
  }),

  tool('install_apk', 'Installe un APK sur le téléphone connecté (adb install), et le lance si demandé.', {
    apk: S.str('Chemin ou nom de l’APK (défaut : le plus récent).'),
    device: S.str('Numéro de série adb.'),
    launch: S.bool('Lancer l’application après installation.'),
  }, [], (a) => {
    const file = resolveApk(a);
    const msg = installApk(file, a.device);
    let launched;
    if (a.launch) {
      const info = apkInfo(file);
      const r = adb(['shell', 'monkey', '-p', info.package, '-c', 'android.intent.category.LAUNCHER', '1'], a.device);
      launched = r.status === 0 ? info.package : (r.stdout + r.stderr).trim();
    }
    return { apk: file, result: msg, launched };
  }),

  tool('uninstall_app', 'Désinstalle une application du téléphone.', { package: S.str('Identifiant (ex. com.moi.appli).'), device: S.str('Série adb.') }, ['package'], (a) => {
    const r = adb(['uninstall', a.package], a.device);
    return { result: (r.stdout + r.stderr).trim() };
  }, DESTRUCTIVE),

  tool('device_logs', 'Journal (logcat) du téléphone, filtré par application ou texte, pour déboguer un plantage.', {
    package: S.str('Ne garder que les lignes de ce paquet (s’il tourne).'),
    filter: S.str('Texte à chercher.'),
    lines: S.int('Nombre de lignes (défaut 300).'),
    crashes_only: S.bool('Seulement les plantages (AndroidRuntime, FATAL).'),
    device: S.str('Série adb.'),
  }, [], (a) => {
    const args = ['logcat', '-d', '-t', String(a.lines || 300)];
    if (a.crashes_only) args.push('-b', 'crash');
    if (a.package) {
      const pid = adb(['shell', 'pidof', a.package], a.device).stdout.trim();
      if (pid) args.push(`--pid=${pid.split(/\s+/)[0]}`);
    }
    let out = adb(args, a.device).stdout;
    if (a.filter) out = out.split('\n').filter((l) => l.toLowerCase().includes(a.filter.toLowerCase())).join('\n');
    return clip(out, 100_000);
  }, RO),

  tool('create_keystore', 'Crée une clé de signature (keystore) pour publier des APK release. Gardez-la précieusement : sans elle, impossible de mettre à jour l’appli.', {
    name: S.str('Nom de la clé (ex. moncompte).'),
    password: S.str('Mot de passe (6 caractères minimum).'),
    alias: S.str('Alias (défaut : name).'),
    dname: S.str('Identité, ex. « CN=Prénom Nom, O=Studio, C=FR ».'),
    remember_password: S.bool('Enregistrer le mot de passe en clair dans ~/GIXCLOUD/keys (pratique, moins sûr).'),
  }, ['name', 'password'], (a) => {
    if (a.password.length < 6) throw new ToolError('Mot de passe trop court (6 caractères minimum).');
    const name = a.name.replace(/[^\w.-]/g, '_');
    const file = path.join(keysDir(), `${name}.jks`);
    if (fs.existsSync(file)) throw new ToolError(`La clé ${name} existe déjà.`);
    const alias = a.alias || name;
    const r = run(which('keytool') || 'keytool', ['-genkeypair', '-keystore', file, '-storetype', 'PKCS12', '-storepass', a.password, '-keypass', a.password, '-alias', alias, '-keyalg', 'RSA', '-keysize', '4096', '-validity', '10000', '-dname', a.dname || `CN=${name}`]);
    if (r.status !== 0) throw new ToolError(`keytool : ${r.stderr || r.stdout}`);
    fs.writeFileSync(path.join(keysDir(), `${name}.json`), JSON.stringify({ file, alias, ...(a.remember_password ? { password: a.password } : {}), created_at: now() }, null, 2), { mode: 0o600 });
    return { keystore: file, alias, password_saved: !!a.remember_password, conseil: 'Sauvegardez ce fichier .jks et son mot de passe hors de l’ordinateur.' };
  }),

  tool('sign_apk', 'Aligne (zipalign) et signe un APK (apksigner) avec une clé créée par create_keystore, ou la clé de débogage.', {
    apk: S.str('Chemin ou nom de l’APK (défaut : le plus récent).'),
    key: S.str('Nom de la clé (défaut : debug).'),
    password: S.str('Mot de passe du keystore (si non enregistré).'),
    output: S.str('Fichier de sortie (défaut : <nom>-signed.apk dans la boîte de sortie).'),
  }, [], (a) => {
    const src = resolveApk(a);
    const key = loadKey(a.key, a.password);
    const signer = buildTool('apksigner');
    if (!signer) throw new ToolError('apksigner introuvable (Android SDK build-tools).');
    ensureDir(APK_DIR);
    const out = path.resolve(a.output || path.join(APK_DIR, path.basename(src, '.apk').replace(/-unsigned$/, '') + '-signed.apk'));
    const aligner = buildTool('zipalign');
    let input = src;
    if (aligner) {
      const aligned = out + '.aligned';
      const z = run(aligner, ['-f', '-p', '4', src, aligned]);
      if (z.status !== 0) throw new ToolError(`zipalign : ${z.stderr}`);
      input = aligned;
    }
    const r = run(signer, ['sign', '--ks', key.file, '--ks-key-alias', key.alias, '--ks-pass', `pass:${key.password}`, '--key-pass', `pass:${key.password}`, '--out', out, input]);
    if (input !== src) fs.rmSync(input, { force: true });
    if (r.status !== 0) throw new ToolError(`apksigner : ${r.stderr || r.stdout}`);
    fs.rmSync(out + '.idsig', { force: true });
    const v = run(signer, ['verify', '--print-certs', out]);
    return { signed: out, key: a.key || 'debug', verify: (v.stdout || v.stderr).split('\n').slice(0, 4).join('\n') };
  }),

  tool('set_app_version', 'Change la version de l’application (versionCode / versionName) dans app/build.gradle(.kts) ou export_presets.cfg (Godot), avec un commit.', {
    ...REPO,
    branch: S.str('Branche.'),
    bump: S.enum(['patch', 'minor', 'major'], 'Incrément de versionName (défaut patch).'),
    version_name: S.str('versionName exact (sinon incrément).'),
    version_code: S.int('versionCode exact (sinon +1).'),
  }, ['repo'], (a) => {
    const r = requireRepo(a);
    const branch = a.branch || defaultBranch(r.gitDir);
    const sha = resolveRef(r.gitDir, `refs/heads/${branch}`);
    const files = git(r.gitDir, ['ls-tree', '-r', '--name-only', sha]).split('\n');
    const target = files.find((f) => /^app\/build\.gradle(\.kts)?$/.test(f)) || files.find((f) => f === 'export_presets.cfg') || files.find((f) => /build\.gradle(\.kts)?$/.test(f) && /versionCode/.test(readTreeFile(r.gitDir, sha, f) || ''));
    if (!target) throw new ToolError('Fichier de version introuvable (app/build.gradle ou export_presets.cfg).');
    const { text, code, name } = bumpVersion(readTreeFile(r.gitDir, sha, target), target.endsWith('.cfg') ? 'godot' : 'gradle', a);
    if (code === undefined && name === undefined) throw new ToolError(`Pas de versionCode/versionName dans ${target}.`);
    const res = commitChanges(r.gitDir, branch, [{ path: target, content: text }], `Version ${name ?? ''} (code ${code ?? '?'})`.trim());
    return { file: target, version_code: code, version_name: name, commit: res.commit };
  }),

  tool('publish_apk_release', 'Tout-en-un : (optionnel) monte la version, crée le tag et la version, construit l’APK et le joint, puis l’envoie dans un dossier ou sur le téléphone.', {
    ...REPO,
    bump: S.enum(['none', 'patch', 'minor', 'major'], 'Monter la version avant (défaut : patch).'),
    variant: S.enum(['debug', 'release'], 'Variante (défaut release si une clé est donnée, sinon debug).'),
    key: S.str('Clé de signature pour un APK release (create_keystore).'),
    password: S.str('Mot de passe de la clé.'),
    notes: S.str('Notes de version.'),
    send_to: S.str('Dossier local ou « device ».'),
    install: S.bool('Installer sur le téléphone.'),
  }, ['repo'], async (a) => {
    const r = requireRepo(a);
    const steps = [];
    let versionName;
    if ((a.bump || 'patch') !== 'none') {
      const v = apkTools.find((t) => t.name === 'set_app_version').handler({ owner: r.owner, repo: r.full, bump: a.bump || 'patch' });
      versionName = v.version_name;
      steps.push(`version ${v.version_name} (code ${v.version_code})`);
    }
    const branch = defaultBranch(r.gitDir);
    const tag = `v${versionName || now().slice(0, 10).replace(/-/g, '.')}`;
    const variant = a.variant || (a.key ? 'release' : 'debug');
    const build = await apkTools.find((t) => t.name === 'build_apk').handler({ repo: r.full, ref: branch, variant, wait_seconds: 3000 });
    if (build.status !== 'success') return { steps, build };
    const files = [];
    for (const o of build.outputs) {
      let f = o.path;
      if (variant === 'release' && (a.key || !(o.signed?.v1_jar || o.signed?.v2_plus))) {
        f = apkTools.find((t) => t.name === 'sign_apk').handler({ apk: o.path, key: a.key || 'debug', password: a.password }).signed;
      }
      files.push(f);
    }
    steps.push(`APK : ${files.map((f) => path.basename(f)).join(', ')}`);
    const rel = collabTools.find((t) => t.name === 'create_release').handler({ repo: r.full, tag: revParse(r.gitDir, `refs/tags/${tag}`) ? `${tag}-${Date.now()}` : tag, target: branch, body: a.notes, assets: files });
    steps.push(`version publiée ${rel.tag}`);
    if (a.send_to) for (const f of files) steps.push(...sendFile(f, a.send_to));
    if (a.install) steps.push(installApk(files[0], undefined));
    return { steps, release: rel.tag, apks: files };
  }),

  // ---- « Actions » locales : intégration continue ----
  tool('run_workflow', 'Lance une commande de vérification (tests, lint…) sur une branche ou une PR dans une copie de travail isolée, comme GitHub Actions mais en local. Par défaut : « ci » de gixcloud.json.', {
    ...REPO,
    ref: S.str('Branche, tag ou commit.'),
    pr: S.int('Pull request à vérifier.'),
    command: S.str('Commande shell (défaut : champ « ci » de gixcloud.json).'),
    wait_seconds: S.int('Attente maximale (défaut 600).'),
  }, ['repo'], async (a) => {
    const r = requireRepo(a);
    if (a.pr) {
      const pr = readMeta(r).pulls.find((x) => x.number === a.pr);
      if (!pr) throw new ToolError('Pull request introuvable.');
      if (pr.head_repo === r.full && revParse(r.gitDir, `refs/heads/${pr.head}`)) git(r.gitDir, ['update-ref', `refs/pull/${pr.number}/head`, `refs/heads/${pr.head}`]);
    }
    const { rec, p } = startJob(r, 'runs', a, async (run_) => {
      const finish = (patch) => updateMeta(r, (m) => {
        const x = m.runs.find((y) => y.id === run_.id);
        Object.assign(x, patch, { finished_at: now() });
        if (a.pr) {
          const pr = m.pulls.find((y) => y.number === a.pr);
          if (pr) pr.checks = { run: x.id, status: x.status, commit: x.commit };
        }
        return x;
      });
      try {
        let cmd = a.command;
        if (!cmd) {
          const lh = readTreeFile(r.gitDir, run_.commit, 'gixcloud.json');
          cmd = lh && JSON.parse(lh).ci;
        }
        if (!cmd) return finish({ status: 'failed', error: 'Aucune commande : donnez command ou ajoutez "ci" dans gixcloud.json.' });
        const ws = prepareWorkspace(r, run_.commit);
        const res = await runLogged(IS_WIN ? 'cmd' : 'sh', IS_WIN ? ['/c', cmd] : ['-c', cmd], { cwd: ws, logFile: run_.log, timeoutMs: 60 * 60000 });
        return finish({ status: res.code === 0 ? 'success' : 'failed', command: cmd, exit_code: res.code });
      } catch (e) {
        return finish({ status: 'failed', error: e.message });
      }
    });
    const res = await waitFor(p, rec, a.wait_seconds, r, 'runs');
    return { ...res, log_tail: tail(rec.log, 60) };
  }),

  tool('list_workflow_runs', 'Historique des exécutions de vérification.', { ...REPO, limit: S.int('Maximum.') }, ['repo'], (a) => {
    const r = requireRepo(a);
    return readMeta(r).runs.slice(-(a.limit || 20)).reverse().map((x) => liveStatus(r, 'runs', x));
  }, RO),

  tool('get_workflow_run', 'Détail et journal d’une exécution.', { ...REPO, id: S.int('Numéro.'), log_lines: S.int('Lignes (0 = tout).') }, ['repo', 'id'], (a) => {
    const r = requireRepo(a);
    const x = readMeta(r).runs.find((y) => y.id === a.id);
    if (!x) throw new ToolError('Exécution introuvable.');
    return { ...liveStatus(r, 'runs', x), log: a.log_lines === 0 ? clip(fs.readFileSync(x.log, 'utf8')) : tail(x.log, a.log_lines || 120) };
  }, RO),
];
