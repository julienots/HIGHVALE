// Accès à git par la ligne de commande (dépôts « bare » stockés en local).

import { spawnSync, spawn } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { ToolError } from './mcp.js';

export const ZERO = '0000000000000000000000000000000000000000';

export function identity() {
  const name = process.env.LOCALHUB_USER_NAME || readGlobal('user.name') || os.userInfo().username || 'localhub';
  const email = process.env.LOCALHUB_USER_EMAIL || readGlobal('user.email') || `${name}@localhub.local`;
  return { name, email };
}

function readGlobal(key) {
  const r = spawnSync('git', ['config', '--global', key], { encoding: 'utf8' });
  return r.status === 0 ? r.stdout.trim() : '';
}

/** Lance git sur un dépôt. Renvoie stdout (texte, ou Buffer si raw). */
export function git(gitDir, args, { input, env, cwd, raw = false, allowFail = false } = {}) {
  const id = identity();
  const full = gitDir ? [`--git-dir=${gitDir}`, ...args] : args;
  const r = spawnSync('git', full, {
    cwd: cwd || (gitDir && fs.existsSync(gitDir) ? gitDir : undefined),
    input,
    maxBuffer: 512 * 1024 * 1024,
    env: {
      ...process.env,
      GIT_AUTHOR_NAME: id.name,
      GIT_AUTHOR_EMAIL: id.email,
      GIT_COMMITTER_NAME: id.name,
      GIT_COMMITTER_EMAIL: id.email,
      GIT_TERMINAL_PROMPT: '0',
      ...env,
    },
  });
  if (r.error) throw new ToolError(`git introuvable ou en échec : ${r.error.message}`);
  const res = { status: r.status, stdout: raw ? r.stdout : r.stdout.toString('utf8'), stderr: r.stderr.toString('utf8') };
  if (allowFail) return res;
  if (r.status !== 0) throw new ToolError(`git ${args[0]} : ${res.stderr.trim() || 'échec'}`);
  return res.stdout;
}

export function revParse(gitDir, rev) {
  const r = git(gitDir, ['rev-parse', '--verify', '--quiet', `${rev}^{commit}`], { allowFail: true });
  return r.status === 0 ? r.stdout.trim() : null;
}

export function resolveRef(gitDir, ref) {
  const sha = revParse(gitDir, ref);
  if (!sha) throw new ToolError(`Référence introuvable : ${ref}`);
  return sha;
}

export function defaultBranch(gitDir) {
  const r = git(gitDir, ['symbolic-ref', '--short', 'HEAD'], { allowFail: true });
  return r.status === 0 ? r.stdout.trim() : 'main';
}

export function isAncestor(gitDir, a, b) {
  return git(gitDir, ['merge-base', '--is-ancestor', a, b], { allowFail: true }).status === 0;
}

export function objectType(gitDir, spec) {
  const r = git(gitDir, ['cat-file', '-t', spec], { allowFail: true });
  return r.status === 0 ? r.stdout.trim() : null;
}

/**
 * Écrit un commit sur une branche sans copie de travail (comme l'API GitHub).
 * changes : [{ path, content: Buffer|string|null (null = suppression), mode? }]
 */
export function commitChanges(gitDir, branch, changes, message, { from } = {}) {
  const ref = `refs/heads/${branch}`;
  let parent = revParse(gitDir, ref);
  if (!parent && from) parent = resolveRef(gitDir, from);
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'localhub-idx-'));
  const env = { GIT_INDEX_FILE: path.join(tmp, 'index') };
  try {
    if (parent) git(gitDir, ['read-tree', parent], { env });
    const lines = [];
    for (const c of changes) {
      const p = normPath(c.path);
      if (c.content === null || c.content === undefined) {
        lines.push(`0 ${ZERO}\t${p}`);
      } else {
        const blob = git(gitDir, ['hash-object', '-w', '--stdin'], { input: c.content }).trim();
        lines.push(`${c.mode || '100644'} ${blob}\t${p}`);
      }
    }
    git(gitDir, ['update-index', '--index-info'], { env, input: lines.join('\n') + '\n' });
    const tree = git(gitDir, ['write-tree'], { env }).trim();
    if (parent && tree === git(gitDir, ['rev-parse', `${parent}^{tree}`]).trim()) {
      throw new ToolError('Aucun changement à enregistrer (contenu identique).');
    }
    const args = ['commit-tree', tree, ...(parent ? ['-p', parent] : []), '-F', '-'];
    const commit = git(gitDir, args, { input: message }).trim();
    const current = revParse(gitDir, ref);
    git(gitDir, ['update-ref', ref, commit, current || ZERO]);
    return { commit, tree, parent };
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

export function normPath(p) {
  const n = String(p || '').replace(/\\/g, '/').replace(/^\/+/, '').replace(/\/+$/, '');
  if (!n || n.split('/').some((s) => s === '..' || s === '.git')) throw new ToolError(`Chemin invalide : ${p}`);
  return n;
}

export function parseLog(text) {
  return text
    .split('\x1e')
    .map((s) => s.replace(/^\n/, ''))
    .filter(Boolean)
    .map((rec) => {
      const [sha, author, email, date, subject, body] = rec.split('\x1f');
      return { sha, short: sha.slice(0, 7), author, email, date, message: subject, ...(body?.trim() ? { body: body.trim() } : {}) };
    });
}
export const LOG_FORMAT = '--format=%H%x1f%an%x1f%ae%x1f%aI%x1f%s%x1f%b%x1e';

/** Lance une commande longue (build) et enregistre son journal. */
export function runLogged(cmd, args, { cwd, env, logFile, timeoutMs = 60 * 60 * 1000 }) {
  return new Promise((resolve) => {
    const logStream = fs.createWriteStream(logFile, { flags: 'a' });
    logStream.write(`$ ${cmd} ${args.join(' ')}\n`);
    let child;
    try {
      child = spawn(cmd, args, { cwd, env: { ...process.env, ...env }, shell: process.platform === 'win32' });
    } catch (e) {
      logStream.end(`échec du lancement : ${e.message}\n`);
      return resolve({ code: -1, error: e.message });
    }
    const timer = setTimeout(() => child.kill('SIGKILL'), timeoutMs);
    child.stdout.pipe(logStream, { end: false });
    child.stderr.pipe(logStream, { end: false });
    child.on('error', (e) => {
      clearTimeout(timer);
      logStream.end(`\nerreur : ${e.message}\n`);
      resolve({ code: -1, error: e.message });
    });
    child.on('close', (code) => {
      clearTimeout(timer);
      logStream.end(`\n[code de sortie ${code}]\n`);
      resolve({ code });
    });
  });
}
