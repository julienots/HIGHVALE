// Stockage local : dépôts git bare + métadonnées JSON (tickets, PR, versions, builds).
//
//   $GIXCLOUD_HOME/                    (défaut ~/GIXCLOUD)
//     repos/<owner>/<repo>.git          dépôt bare (clonable : git clone <chemin>)
//     meta/<owner>/<repo>.json          tickets, pull requests, versions, builds
//     releases/<owner>/<repo>/<tag>/    fichiers joints aux versions (APK…)
//     builds/<owner>/<repo>/            journaux de build et d'intégration
//     apk/                              boîte de sortie des APK (GIXCLOUD_APK_DIR)

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { ToolError } from './mcp.js';

export const HOME = path.resolve(process.env.GIXCLOUD_HOME || path.join(os.homedir(), 'GIXCLOUD'));
export const APK_DIR = path.resolve(process.env.GIXCLOUD_APK_DIR || path.join(HOME, 'apk'));
export const DEFAULT_OWNER = sanitize(process.env.GIXCLOUD_OWNER || os.userInfo().username || 'local');

const NAME_RE = /^[A-Za-z0-9._-]{1,100}$/;

export function sanitize(s) {
  return String(s).replace(/[^A-Za-z0-9._-]/g, '-') || 'local';
}

export function ensureDir(d) {
  fs.mkdirSync(d, { recursive: true });
  return d;
}

/** Résout {owner, repo} ; accepte repo = "owner/repo". */
export function ident(args) {
  let owner = args.owner;
  let repo = args.repo;
  if (!repo) throw new ToolError('Paramètre « repo » requis.');
  if (repo.includes('/')) [owner, repo] = repo.split('/', 2);
  owner = owner || DEFAULT_OWNER;
  repo = repo.replace(/\.git$/, '');
  for (const n of [owner, repo]) {
    if (!NAME_RE.test(n) || n.startsWith('.')) throw new ToolError(`Nom invalide : ${n}`);
  }
  return { owner, repo, full: `${owner}/${repo}` };
}

export function gitDirOf({ owner, repo }) {
  return path.join(HOME, 'repos', owner, `${repo}.git`);
}

export function requireRepo(args) {
  const id = ident(args);
  const dir = gitDirOf(id);
  if (!fs.existsSync(dir)) throw new ToolError(`Dépôt introuvable : ${id.full}`);
  return { ...id, gitDir: dir };
}

function metaFile({ owner, repo }) {
  return path.join(HOME, 'meta', owner, `${repo}.json`);
}

const EMPTY_META = () => ({ description: '', private: true, topics: [], next_number: 1, issues: [], pulls: [], releases: [], builds: [], runs: [], stars: 0, created_at: now() });

export function readMeta(id) {
  const f = metaFile(id);
  if (!fs.existsSync(f)) return EMPTY_META();
  return { ...EMPTY_META(), ...JSON.parse(fs.readFileSync(f, 'utf8')) };
}

export function writeMeta(id, meta) {
  const f = metaFile(id);
  ensureDir(path.dirname(f));
  const tmp = `${f}.${process.pid}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(meta, null, 2));
  fs.renameSync(tmp, f);
}

/** Lecture-modification-écriture des métadonnées. */
export function updateMeta(id, fn) {
  const meta = readMeta(id);
  const res = fn(meta);
  meta.updated_at = now();
  writeMeta(id, meta);
  return res;
}

export function deleteMeta(id) {
  fs.rmSync(metaFile(id), { force: true });
  for (const sub of ['releases', 'builds']) fs.rmSync(path.join(HOME, sub, id.owner, id.repo), { recursive: true, force: true });
}

export function releaseDir(id, tag) {
  return path.join(HOME, 'releases', id.owner, id.repo, sanitize(tag));
}

export function buildDir(id) {
  return ensureDir(path.join(HOME, 'builds', id.owner, id.repo));
}

export function listRepoIds() {
  const root = path.join(HOME, 'repos');
  if (!fs.existsSync(root)) return [];
  const out = [];
  for (const owner of fs.readdirSync(root)) {
    const od = path.join(root, owner);
    if (!fs.statSync(od).isDirectory()) continue;
    for (const r of fs.readdirSync(od)) if (r.endsWith('.git')) out.push({ owner, repo: r.slice(0, -4), full: `${owner}/${r.slice(0, -4)}` });
  }
  return out;
}

export function now() {
  return new Date().toISOString();
}

export function pick(obj, keys) {
  return Object.fromEntries(keys.filter((k) => obj[k] !== undefined).map((k) => [k, obj[k]]));
}
