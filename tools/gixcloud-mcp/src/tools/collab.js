// Tickets (issues), pull requests, revues, versions (releases), étiquettes, jalons.

import fs from 'node:fs';
import path from 'node:path';
import { ToolError } from '../mcp.js';
import { git, revParse, resolveRef, defaultBranch, isAncestor, identity, LOG_FORMAT, parseLog } from '../git.js';
import { requireRepo, readMeta, updateMeta, now, releaseDir, ensureDir, ident, gitDirOf } from '../store.js';
import { compareRefs, createTag } from './repos.js';
import { S, REPO, tool, RO, DESTRUCTIVE } from './util.js';

const me = () => identity().name;

function findItem(meta, kind, number) {
  const it = meta[kind].find((x) => x.number === Number(number));
  if (!it) throw new ToolError(`${kind === 'issues' ? 'Ticket' : 'Pull request'} #${number} introuvable.`);
  return it;
}

function summary(it) {
  const { comments, reviews, body, ...rest } = it;
  return { ...rest, comments: comments?.length || 0, ...(reviews ? { reviews: reviews.length } : {}) };
}

function addComment(it, body) {
  const c = { id: (it.comments.at(-1)?.id || 0) + 1, author: me(), body, created_at: now() };
  it.comments.push(c);
  it.updated_at = c.created_at;
  return c;
}

function matches(it, a) {
  if (a.state && a.state !== 'all' && it.state !== a.state) return false;
  if (a.labels?.length && !a.labels.every((l) => it.labels.includes(l))) return false;
  if (a.assignee && !it.assignees.includes(a.assignee)) return false;
  if (a.milestone && it.milestone !== a.milestone) return false;
  if (a.query) {
    const q = a.query.toLowerCase();
    const hay = [it.title, it.body, ...(it.comments || []).map((c) => c.body)].join('\n').toLowerCase();
    if (!hay.includes(q)) return false;
  }
  return true;
}

const FILTERS = {
  state: S.enum(['open', 'closed', 'merged', 'all'], 'État (défaut : open).'),
  labels: S.arr({ type: 'string' }, 'Étiquettes (toutes requises).'),
  assignee: S.str('Assigné à.'),
  milestone: S.str('Jalon.'),
  query: S.str('Texte recherché dans le titre, la description et les commentaires.'),
};

/** Tête actuelle d’une PR (branche du dépôt, ou d’un fork rapatriée dans refs/pull/N/head). */
function refreshHead(r, pr) {
  let sha;
  if (pr.head_repo && pr.head_repo !== r.full) {
    const src = ident({ repo: pr.head_repo });
    const dir = gitDirOf(src);
    if (fs.existsSync(dir)) {
      git(r.gitDir, ['fetch', '--quiet', '--no-tags', dir, `+refs/heads/${pr.head}:refs/pull/${pr.number}/head`], { allowFail: true });
    }
    sha = revParse(r.gitDir, `refs/pull/${pr.number}/head`);
  } else {
    sha = revParse(r.gitDir, `refs/heads/${pr.head}`);
    if (sha) git(r.gitDir, ['update-ref', `refs/pull/${pr.number}/head`, sha]);
    else sha = revParse(r.gitDir, `refs/pull/${pr.number}/head`);
  }
  if (!sha) throw new ToolError(`La branche source ${pr.head} n’existe plus.`);
  return sha;
}

function mergeCheck(gitDir, base, head) {
  if (isAncestor(gitDir, head, base)) return { mergeable: false, state: 'already_merged' };
  const res = git(gitDir, ['merge-tree', '--write-tree', '--name-only', base, head], { allowFail: true });
  if (res.status === 0) return { mergeable: true, state: isAncestor(gitDir, base, head) ? 'fast_forward' : 'clean', tree: res.stdout.split('\n')[0].trim() };
  const lines = res.stdout.split('\n');
  const conflicts = [];
  for (const l of lines.slice(1)) { if (!l.trim()) break; conflicts.push(l.trim()); }
  return { mergeable: false, state: 'conflicts', conflicts, details: lines.slice(conflicts.length + 2).filter(Boolean).slice(0, 50) };
}

export const collabTools = [
  // ---- Tickets ----
  tool('create_issue', 'Ouvre un ticket (bug, idée, tâche).', {
    ...REPO,
    title: S.str('Titre.'),
    body: S.str('Description (Markdown).'),
    labels: S.arr({ type: 'string' }, 'Étiquettes (bug, enhancement…).'),
    assignees: S.arr({ type: 'string' }, 'Personnes assignées.'),
    milestone: S.str('Jalon (ex. v1.0).'),
  }, ['repo', 'title'], (a) => {
    const r = requireRepo(a);
    return updateMeta(r, (m) => {
      const it = { number: m.next_number++, title: a.title, body: a.body || '', state: 'open', labels: a.labels || [], assignees: a.assignees || [], milestone: a.milestone || null, author: me(), created_at: now(), updated_at: now(), closed_at: null, comments: [] };
      m.issues.push(it);
      return summary(it);
    });
  }),

  tool('list_issues', 'Liste les tickets avec filtres.', { ...REPO, ...FILTERS, limit: S.int('Maximum (défaut 50).') }, ['repo'], (a) => {
    const r = requireRepo(a);
    const st = a.state || 'open';
    return readMeta(r).issues.filter((i) => matches(i, { ...a, state: st })).sort((x, y) => y.number - x.number).slice(0, a.limit || 50).map(summary);
  }, RO),

  tool('get_issue', 'Lit un ticket avec ses commentaires.', { ...REPO, number: S.int('Numéro.') }, ['repo', 'number'], (a) => {
    const r = requireRepo(a);
    return findItem(readMeta(r), 'issues', a.number);
  }, RO),

  tool('update_issue', 'Modifie un ticket : titre, description, état (fermer/rouvrir), étiquettes, assignés, jalon.', {
    ...REPO,
    number: S.int('Numéro.'),
    title: S.str('Titre.'),
    body: S.str('Description.'),
    state: S.enum(['open', 'closed'], 'État.'),
    state_reason: S.enum(['completed', 'not_planned', 'duplicate'], 'Raison de fermeture.'),
    labels: S.arr({ type: 'string' }, 'Remplace les étiquettes.'),
    assignees: S.arr({ type: 'string' }, 'Remplace les assignés.'),
    milestone: S.str('Jalon (vide pour retirer).'),
  }, ['repo', 'number'], (a) => {
    const r = requireRepo(a);
    return updateMeta(r, (m) => {
      const it = findItem(m, 'issues', a.number);
      for (const k of ['title', 'body', 'labels', 'assignees']) if (a[k] !== undefined) it[k] = a[k];
      if (a.milestone !== undefined) it.milestone = a.milestone || null;
      if (a.state && a.state !== it.state) {
        it.state = a.state;
        it.closed_at = a.state === 'closed' ? now() : null;
        it.state_reason = a.state === 'closed' ? a.state_reason || 'completed' : null;
      }
      it.updated_at = now();
      return summary(it);
    });
  }),

  tool('add_issue_comment', 'Ajoute un commentaire à un ticket ou à une pull request.', {
    ...REPO,
    number: S.int('Numéro du ticket ou de la PR.'),
    body: S.str('Commentaire (Markdown).'),
  }, ['repo', 'number', 'body'], (a) => {
    const r = requireRepo(a);
    return updateMeta(r, (m) => {
      const it = m.issues.find((x) => x.number === a.number) || findItem(m, 'pulls', a.number);
      return addComment(it, a.body);
    });
  }),

  tool('list_labels', 'Liste les étiquettes et jalons utilisés dans le dépôt, avec leur nombre.', REPO, ['repo'], (a) => {
    const r = requireRepo(a);
    const m = readMeta(r);
    const labels = {};
    const milestones = {};
    for (const it of [...m.issues, ...m.pulls]) {
      for (const l of it.labels) labels[l] = (labels[l] || 0) + 1;
      if (it.milestone) {
        const ms = (milestones[it.milestone] ||= { open: 0, closed: 0 });
        ms[it.state === 'open' ? 'open' : 'closed']++;
      }
    }
    return { labels, milestones };
  }, RO),

  // ---- Pull requests ----
  tool('create_pull_request', 'Ouvre une pull request d’une branche (ou d’une branche d’un fork « propriétaire/dépôt:branche ») vers une autre.', {
    ...REPO,
    title: S.str('Titre.'),
    head: S.str('Branche source, ou « propriétaire/dépôt:branche » pour un fork.'),
    base: S.str('Branche cible (défaut : branche par défaut).'),
    body: S.str('Description.'),
    draft: S.bool('Brouillon.'),
    labels: S.arr({ type: 'string' }, 'Étiquettes.'),
  }, ['repo', 'title', 'head'], (a) => {
    const r = requireRepo(a);
    let headRepo = r.full;
    let head = a.head;
    if (head.includes(':')) [headRepo, head] = head.split(':', 2);
    const base = a.base || defaultBranch(r.gitDir);
    resolveRef(r.gitDir, `refs/heads/${base}`);
    return updateMeta(r, (m) => {
      if (m.pulls.some((p) => p.state === 'open' && p.head === head && p.head_repo === headRepo && p.base === base)) throw new ToolError('Une pull request ouverte existe déjà pour ces branches.');
      const pr = { number: m.next_number++, title: a.title, body: a.body || '', state: 'open', draft: !!a.draft, head, head_repo: headRepo, base, labels: a.labels || [], assignees: [], milestone: null, author: me(), created_at: now(), updated_at: now(), closed_at: null, merged_at: null, merge_commit: null, comments: [], reviews: [] };
      const headSha = refreshHead(r, pr);
      const baseSha = resolveRef(r.gitDir, `refs/heads/${base}`);
      if (isAncestor(r.gitDir, headSha, baseSha)) throw new ToolError(`Aucun commit à fusionner : ${head} est déjà contenu dans ${base}.`);
      pr.head_sha = headSha;
      m.pulls.push(pr);
      return { ...summary(pr), ...mergeCheck(r.gitDir, baseSha, headSha), tree: undefined };
    });
  }),

  tool('list_pull_requests', 'Liste les pull requests.', { ...REPO, ...FILTERS, base: S.str('Branche cible.'), head: S.str('Branche source.'), limit: S.int('Maximum.') }, ['repo'], (a) => {
    const r = requireRepo(a);
    const st = a.state || 'open';
    return readMeta(r).pulls
      .filter((p) => matches(p, { ...a, state: st }) && (!a.base || p.base === a.base) && (!a.head || p.head === a.head))
      .sort((x, y) => y.number - x.number).slice(0, a.limit || 50).map(summary);
  }, RO),

  tool('get_pull_request', 'Détail d’une pull request : commits, fichiers, diff, fusion possible ou conflits, revues, commentaires.', {
    ...REPO,
    number: S.int('Numéro.'),
    include_diff: S.bool('Inclure le diff (défaut : vrai).'),
  }, ['repo', 'number'], (a) => {
    const r = requireRepo(a);
    const pr = findItem(readMeta(r), 'pulls', a.number);
    if (pr.state !== 'open') return pr;
    const headSha = refreshHead(r, pr);
    const baseSha = resolveRef(r.gitDir, `refs/heads/${pr.base}`);
    const cmp = compareRefs(r.gitDir, baseSha, headSha, a.include_diff !== false);
    const mc = mergeCheck(r.gitDir, baseSha, headSha);
    delete mc.tree;
    return { ...pr, head_sha: headSha, ...mc, commits: cmp.commits, files: cmp.files, diff: cmp.diff };
  }, RO),

  tool('update_pull_request', 'Modifie une pull request : titre, description, branche cible, brouillon, fermer/rouvrir.', {
    ...REPO,
    number: S.int('Numéro.'),
    title: S.str('Titre.'),
    body: S.str('Description.'),
    base: S.str('Nouvelle branche cible.'),
    draft: S.bool('Brouillon.'),
    state: S.enum(['open', 'closed'], 'État.'),
    labels: S.arr({ type: 'string' }, 'Étiquettes.'),
    assignees: S.arr({ type: 'string' }, 'Assignés.'),
  }, ['repo', 'number'], (a) => {
    const r = requireRepo(a);
    return updateMeta(r, (m) => {
      const pr = findItem(m, 'pulls', a.number);
      if (pr.state === 'merged') throw new ToolError('Pull request déjà fusionnée.');
      if (a.base) resolveRef(r.gitDir, `refs/heads/${a.base}`);
      for (const k of ['title', 'body', 'base', 'draft', 'labels', 'assignees']) if (a[k] !== undefined) pr[k] = a[k];
      if (a.state) { pr.state = a.state; pr.closed_at = a.state === 'closed' ? now() : null; }
      pr.updated_at = now();
      return summary(pr);
    });
  }),

  tool('create_review', 'Publie une revue de pull request : approuver, demander des changements ou commenter, avec commentaires sur des lignes.', {
    ...REPO,
    number: S.int('Numéro de la PR.'),
    event: S.enum(['APPROVE', 'REQUEST_CHANGES', 'COMMENT'], 'Type de revue.'),
    body: S.str('Commentaire général.'),
    comments: S.arr({
      type: 'object',
      properties: { path: { type: 'string' }, line: { type: 'integer' }, body: { type: 'string' } },
      required: ['path', 'body'],
    }, 'Commentaires sur des fichiers/lignes.'),
  }, ['repo', 'number', 'event'], (a) => {
    const r = requireRepo(a);
    return updateMeta(r, (m) => {
      const pr = findItem(m, 'pulls', a.number);
      const rv = { id: pr.reviews.length + 1, author: me(), state: a.event, body: a.body || '', comments: a.comments || [], commit: pr.head_sha, created_at: now() };
      pr.reviews.push(rv);
      pr.updated_at = rv.created_at;
      return rv;
    });
  }),

  tool('merge_pull_request', 'Fusionne une pull request (merge commit, squash, ou avance rapide « rebase »).', {
    ...REPO,
    number: S.int('Numéro.'),
    merge_method: S.enum(['merge', 'squash', 'rebase'], 'Méthode (défaut : merge). « rebase » n’est possible qu’en avance rapide.'),
    commit_title: S.str('Titre du commit de fusion.'),
    commit_message: S.str('Détail du commit de fusion.'),
    delete_branch: S.bool('Supprimer la branche source après fusion.'),
  }, ['repo', 'number'], (a) => {
    const r = requireRepo(a);
    return updateMeta(r, (m) => {
      const pr = findItem(m, 'pulls', a.number);
      if (pr.state !== 'open') throw new ToolError(`La pull request est ${pr.state === 'merged' ? 'déjà fusionnée' : 'fermée'}.`);
      if (pr.draft) throw new ToolError('Pull request en brouillon : passez draft à false avant de fusionner.');
      const headSha = refreshHead(r, pr);
      const baseRef = `refs/heads/${pr.base}`;
      const baseSha = resolveRef(r.gitDir, baseRef);
      const mc = mergeCheck(r.gitDir, baseSha, headSha);
      if (!mc.mergeable) throw new ToolError(mc.state === 'conflicts' ? `Conflits dans : ${mc.conflicts.join(', ')}. Résolvez-les sur la branche ${pr.head}.` : 'Rien à fusionner.');
      const method = a.merge_method || 'merge';
      const title = a.commit_title || (method === 'squash' ? `${pr.title} (#${pr.number})` : `Merge pull request #${pr.number} from ${pr.head_repo === r.full ? '' : pr.head_repo + ':'}${pr.head}`);
      const msg = `${title}\n\n${a.commit_message ?? (method === 'squash' ? parseLog(git(r.gitDir, ['log', LOG_FORMAT, `${baseSha}..${headSha}`])).map((c) => `* ${c.message}`).join('\n') : pr.title)}\n`;
      let commit;
      if (method === 'rebase') {
        if (mc.state !== 'fast_forward') throw new ToolError('« rebase » impossible : la branche cible a avancé. Utilisez merge ou squash.');
        commit = headSha;
      } else {
        const parents = method === 'squash' ? ['-p', baseSha] : ['-p', baseSha, '-p', headSha];
        commit = git(r.gitDir, ['commit-tree', mc.tree, ...parents, '-F', '-'], { input: msg }).trim();
      }
      git(r.gitDir, ['update-ref', baseRef, commit, baseSha]);
      Object.assign(pr, { state: 'merged', merged_at: now(), closed_at: now(), updated_at: now(), merge_commit: commit, merge_method: method, merged_by: me(), head_sha: headSha });
      if (a.delete_branch && pr.head_repo === r.full && pr.head !== defaultBranch(r.gitDir)) {
        git(r.gitDir, ['update-ref', '-d', `refs/heads/${pr.head}`], { allowFail: true });
      }
      // « Fixes #12 » / « Closes #12 » / « Corrige #12 » ferment les tickets liés.
      const closed = [];
      for (const mm of `${pr.title}\n${pr.body}`.matchAll(/\b(?:fix(?:es|ed)?|close[sd]?|resolve[sd]?|corrige|ferme|résout)\s+#(\d+)/gi)) {
        const it = m.issues.find((i) => i.number === Number(mm[1]) && i.state === 'open');
        if (it) { it.state = 'closed'; it.closed_at = now(); it.state_reason = 'completed'; addComment(it, `Fermé par la pull request #${pr.number}.`); closed.push(it.number); }
      }
      return { merged: true, number: pr.number, method, commit, base: pr.base, closed_issues: closed };
    });
  }),

  // ---- Versions (releases) ----
  tool('create_release', 'Publie une version : crée le tag si besoin et joint des fichiers locaux (APK, AAB, ZIP…).', {
    ...REPO,
    tag: S.str('Tag (ex. v1.0.0).'),
    name: S.str('Nom de la version.'),
    body: S.str('Notes de version (Markdown). Vide = générées depuis les commits.'),
    target: S.str('Branche ou commit à marquer si le tag n’existe pas.'),
    prerelease: S.bool('Pré-version.'),
    draft: S.bool('Brouillon.'),
    assets: S.arr({ type: 'string' }, 'Chemins de fichiers locaux à joindre (ex. un APK).'),
  }, ['repo', 'tag'], (a) => {
    const r = requireRepo(a);
    if (!revParse(r.gitDir, `refs/tags/${a.tag}`)) createTag(r.gitDir, a.tag, a.target, a.name || a.tag);
    const sha = resolveRef(r.gitDir, `refs/tags/${a.tag}`);
    let body = a.body;
    if (!body) {
      const prev = readMeta(r).releases.filter((x) => x.tag !== a.tag).sort((x, y) => y.created_at.localeCompare(x.created_at))[0];
      const range = prev && revParse(r.gitDir, `refs/tags/${prev.tag}`) ? `${prev.tag}..${sha}` : sha;
      body = '## Changements\n\n' + parseLog(git(r.gitDir, ['log', LOG_FORMAT, '-n200', '--no-merges', range])).map((c) => `- ${c.message} (${c.short})`).join('\n');
    }
    return updateMeta(r, (m) => {
      if (m.releases.some((x) => x.tag === a.tag)) throw new ToolError(`Une version existe déjà pour ${a.tag}.`);
      const rel = { id: (m.releases.reduce((mx, x) => Math.max(mx, x.id), 0) || 0) + 1, tag: a.tag, name: a.name || a.tag, body, commit: sha, prerelease: !!a.prerelease, draft: !!a.draft, author: me(), created_at: now(), assets: [] };
      for (const f of a.assets || []) rel.assets.push(copyAsset(r, a.tag, f));
      m.releases.push(rel);
      return rel;
    });
  }),

  tool('list_releases', 'Liste les versions publiées.', REPO, ['repo'], (a) => {
    const r = requireRepo(a);
    return readMeta(r).releases.sort((x, y) => y.created_at.localeCompare(x.created_at)).map(({ body, ...x }) => x);
  }, RO),

  tool('get_release', 'Lit une version par tag (ou la plus récente si tag = « latest »).', { ...REPO, tag: S.str('Tag, ou « latest ».') }, ['repo', 'tag'], (a) => {
    const r = requireRepo(a);
    const rels = readMeta(r).releases.filter((x) => !x.draft).sort((x, y) => y.created_at.localeCompare(x.created_at));
    const rel = a.tag === 'latest' ? rels.find((x) => !x.prerelease) || rels[0] : readMeta(r).releases.find((x) => x.tag === a.tag);
    if (!rel) throw new ToolError('Version introuvable.');
    return rel;
  }, RO),

  tool('upload_release_asset', 'Joint un fichier local (APK…) à une version existante.', { ...REPO, tag: S.str('Tag de la version.'), file: S.str('Chemin du fichier.'), name: S.str('Nom affiché (facultatif).') }, ['repo', 'tag', 'file'], (a) => {
    const r = requireRepo(a);
    return updateMeta(r, (m) => {
      const rel = m.releases.find((x) => x.tag === a.tag);
      if (!rel) throw new ToolError('Version introuvable.');
      const asset = copyAsset(r, a.tag, a.file, a.name);
      rel.assets = rel.assets.filter((x) => x.name !== asset.name).concat(asset);
      return asset;
    });
  }),

  tool('delete_release', 'Supprime une version (et ses fichiers joints ; le tag est conservé sauf delete_tag).', { ...REPO, tag: S.str('Tag.'), delete_tag: S.bool('Supprimer aussi le tag.') }, ['repo', 'tag'], (a) => {
    const r = requireRepo(a);
    updateMeta(r, (m) => { m.releases = m.releases.filter((x) => x.tag !== a.tag); });
    fs.rmSync(releaseDir(r, a.tag), { recursive: true, force: true });
    if (a.delete_tag) git(r.gitDir, ['tag', '-d', a.tag], { allowFail: true });
    return { deleted: a.tag };
  }, DESTRUCTIVE),
];

export function copyAsset(r, tag, file, name) {
  const src = path.resolve(file);
  if (!fs.existsSync(src) || !fs.statSync(src).isFile()) throw new ToolError(`Fichier introuvable : ${src}`);
  const dir = ensureDir(releaseDir(r, tag));
  const dest = path.join(dir, path.basename(name || src));
  fs.copyFileSync(src, dest);
  return { name: path.basename(dest), path: dest, size: fs.statSync(dest).size, uploaded_at: now() };
}
