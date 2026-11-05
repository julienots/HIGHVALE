// Dépôts, fichiers, branches, commits, tags, recherche.

import fs from 'node:fs';
import path from 'node:path';
import { ToolError } from '../mcp.js';
import { git, revParse, resolveRef, defaultBranch, commitChanges, normPath, objectType, parseLog, LOG_FORMAT, isAncestor } from '../git.js';
import { ident, gitDirOf, requireRepo, readMeta, updateMeta, writeMeta, deleteMeta, listRepoIds, ensureDir, now, HOME, DEFAULT_OWNER } from '../store.js';
import { S, REPO, tool, RO, DESTRUCTIVE, clip } from './util.js';

function repoInfo(id) {
  const gitDir = gitDirOf(id);
  const meta = readMeta(id);
  const branch = defaultBranch(gitDir);
  const head = revParse(gitDir, `refs/heads/${branch}`);
  const branches = git(gitDir, ['for-each-ref', '--format=%(refname:short)', 'refs/heads']).split('\n').filter(Boolean);
  return {
    full_name: id.full,
    owner: id.owner,
    name: id.repo,
    description: meta.description,
    topics: meta.topics,
    private: meta.private,
    default_branch: branch,
    branches: branches.length,
    last_commit: head ? parseLog(git(gitDir, ['log', '-1', LOG_FORMAT, head]))[0] : null,
    open_issues: meta.issues.filter((i) => i.state === 'open').length,
    open_pulls: meta.pulls.filter((p) => p.state === 'open').length,
    releases: meta.releases.length,
    stars: meta.stars,
    fork_of: meta.fork_of || null,
    clone_path: gitDir,
    clone_command: `git clone "${gitDir}"`,
    created_at: meta.created_at,
    updated_at: meta.updated_at,
  };
}

function textOrB64(buf) {
  const binary = buf.subarray(0, 8000).includes(0);
  return binary ? { encoding: 'base64', content: buf.toString('base64') } : { encoding: 'utf-8', content: buf.toString('utf8') };
}

function toBuffer(content, encoding) {
  if (content === undefined || content === null) throw new ToolError('Contenu requis.');
  return encoding === 'base64' ? Buffer.from(content, 'base64') : Buffer.from(String(content), 'utf8');
}

function refOf(gitDir, ref) {
  return ref || defaultBranch(gitDir);
}

export const repoTools = [
  tool('create_repository', 'Crée un dépôt local (comme sur GitHub). auto_init ajoute un README initial.', {
    name: S.str('Nom du dépôt.'),
    owner: S.str('Propriétaire (facultatif).'),
    description: S.str('Description.'),
    private: S.bool('Privé (indicatif, tout reste local).'),
    auto_init: S.bool('Créer un premier commit avec README.md (défaut : vrai).'),
    gitignore: S.enum(['none', 'android', 'node', 'python', 'godot'], 'Modèle .gitignore.'),
    default_branch: S.str('Branche par défaut (défaut : main).'),
  }, ['name'], (a) => {
    const id = ident({ owner: a.owner, repo: a.name });
    const gitDir = gitDirOf(id);
    if (fs.existsSync(gitDir)) throw new ToolError(`Le dépôt ${id.full} existe déjà.`);
    ensureDir(path.dirname(gitDir));
    const branch = a.default_branch || 'main';
    git(null, ['init', '--bare', '--quiet', `--initial-branch=${branch}`, gitDir]);
    git(gitDir, ['config', 'receive.denyNonFastForwards', 'false']);
    fs.writeFileSync(path.join(gitDir, 'description'), a.description || id.repo);
    const meta = readMeta(id);
    meta.description = a.description || '';
    meta.private = a.private !== false;
    writeMeta(id, meta);
    if (a.auto_init !== false) {
      const files = [{ path: 'README.md', content: `# ${id.repo}\n\n${a.description || ''}\n` }];
      const gi = GITIGNORES[a.gitignore || 'none'];
      if (gi) files.push({ path: '.gitignore', content: gi });
      commitChanges(gitDir, branch, files, 'Initial commit');
    }
    return repoInfo(id);
  }),

  tool('list_repositories', 'Liste les dépôts locaux.', {
    owner: S.str('Filtrer par propriétaire.'),
    query: S.str('Filtrer par nom ou description.'),
  }, [], (a) => {
    const q = (a.query || '').toLowerCase();
    return listRepoIds()
      .filter((id) => !a.owner || id.owner === a.owner)
      .map((id) => {
        const m = readMeta(id);
        return { full_name: id.full, description: m.description, topics: m.topics, updated_at: m.updated_at || m.created_at };
      })
      .filter((r) => !q || r.full_name.toLowerCase().includes(q) || (r.description || '').toLowerCase().includes(q) || r.topics.some((t) => t.includes(q)));
  }, RO),

  tool('get_repository', 'Détails d’un dépôt : branche par défaut, dernier commit, compteurs, chemin de clonage.', REPO, ['repo'], (a) => {
    const r = requireRepo(a);
    return repoInfo(r);
  }, RO),

  tool('update_repository', 'Modifie la description, les sujets, la branche par défaut, ou renomme le dépôt.', {
    ...REPO,
    description: S.str('Nouvelle description.'),
    topics: S.arr({ type: 'string' }, 'Sujets (tags).'),
    default_branch: S.str('Nouvelle branche par défaut.'),
    new_name: S.str('Nouveau nom.'),
    private: S.bool('Privé.'),
  }, ['repo'], (a) => {
    let r = requireRepo(a);
    if (a.default_branch) {
      resolveRef(r.gitDir, `refs/heads/${a.default_branch}`);
      git(r.gitDir, ['symbolic-ref', 'HEAD', `refs/heads/${a.default_branch}`]);
    }
    updateMeta(r, (m) => {
      if (a.description !== undefined) m.description = a.description;
      if (a.topics) m.topics = a.topics.map((t) => t.toLowerCase());
      if (a.private !== undefined) m.private = a.private;
    });
    if (a.new_name) {
      const nid = ident({ owner: r.owner, repo: a.new_name });
      const ndir = gitDirOf(nid);
      if (fs.existsSync(ndir)) throw new ToolError(`${nid.full} existe déjà.`);
      fs.renameSync(r.gitDir, ndir);
      const meta = readMeta(r);
      writeMeta(nid, meta);
      for (const sub of ['releases', 'builds']) {
        const src = path.join(HOME, sub, r.owner, r.repo);
        if (fs.existsSync(src)) fs.renameSync(src, path.join(HOME, sub, nid.owner, nid.repo));
      }
      deleteMeta(r);
      r = { ...nid, gitDir: ndir };
    }
    return repoInfo(r);
  }),

  tool('delete_repository', 'Supprime définitivement un dépôt et toutes ses données locales. Exige confirm = « propriétaire/dépôt ».', {
    ...REPO,
    confirm: S.str('Retaper le nom complet « propriétaire/dépôt » pour confirmer.'),
  }, ['repo', 'confirm'], (a) => {
    const r = requireRepo(a);
    if (a.confirm !== r.full) throw new ToolError(`Confirmation incorrecte : tapez exactement « ${r.full} ».`);
    fs.rmSync(r.gitDir, { recursive: true, force: true });
    deleteMeta(r);
    return { deleted: r.full };
  }, DESTRUCTIVE),

  tool('fork_repository', 'Crée une copie (fork) d’un dépôt sous un autre nom ou propriétaire.', {
    ...REPO,
    new_owner: S.str('Propriétaire du fork.'),
    new_name: S.str('Nom du fork (défaut : même nom).'),
  }, ['repo'], (a) => {
    const r = requireRepo(a);
    const nid = ident({ owner: a.new_owner || DEFAULT_OWNER, repo: a.new_name || r.repo });
    if (nid.full === r.full) throw new ToolError('Donnez un autre propriétaire ou un autre nom au fork.');
    const ndir = gitDirOf(nid);
    if (fs.existsSync(ndir)) throw new ToolError(`${nid.full} existe déjà.`);
    ensureDir(path.dirname(ndir));
    git(null, ['clone', '--bare', '--quiet', r.gitDir, ndir]);
    const m = readMeta(r);
    writeMeta(nid, { ...readMeta(nid), description: m.description, topics: m.topics, fork_of: r.full });
    return repoInfo(nid);
  }),

  tool('import_repository', 'Importe un dépôt existant (dossier local, fichier .bundle ou URL git) dans LocalHub.', {
    source: S.str('Chemin d’un dépôt/dossier git local, d’un .bundle, ou URL git.'),
    name: S.str('Nom du dépôt créé (défaut : déduit de la source).'),
    owner: S.str('Propriétaire.'),
    description: S.str('Description.'),
  }, ['source'], (a) => {
    const base = path.basename(a.source.replace(/[\\/]+$/, '')).replace(/\.(git|bundle)$/, '');
    const id = ident({ owner: a.owner, repo: a.name || base });
    const gitDir = gitDirOf(id);
    if (fs.existsSync(gitDir)) throw new ToolError(`${id.full} existe déjà.`);
    ensureDir(path.dirname(gitDir));
    git(null, ['clone', '--bare', '--quiet', a.source, gitDir]);
    git(gitDir, ['remote', 'remove', 'origin'], { allowFail: true });
    const meta = readMeta(id);
    meta.description = a.description || '';
    meta.imported_from = a.source;
    writeMeta(id, meta);
    return repoInfo(id);
  }),

  tool('export_repository', 'Exporte un dépôt en un seul fichier .bundle (sauvegarde, transfert sur clé USB ou téléphone).', {
    ...REPO,
    destination: S.str('Dossier ou fichier de destination (défaut : ~/LocalHub/exports).'),
  }, ['repo'], (a) => {
    const r = requireRepo(a);
    let dest = a.destination || path.join(HOME, 'exports');
    if (!dest.endsWith('.bundle')) dest = path.join(ensureDir(dest), `${r.owner}-${r.repo}-${now().slice(0, 10)}.bundle`);
    git(r.gitDir, ['bundle', 'create', path.resolve(dest), '--all']);
    return { bundle: path.resolve(dest), size: fs.statSync(dest).size, restore: `git clone "${path.resolve(dest)}" ${r.repo}` };
  }),

  tool('star_repository', 'Ajoute ou retire une étoile (favori) à un dépôt.', { ...REPO, unstar: S.bool('Retirer l’étoile.') }, ['repo'], (a) => {
    const r = requireRepo(a);
    return updateMeta(r, (m) => ({ stars: (m.stars = a.unstar ? 0 : 1) }));
  }),

  // ---- Fichiers ----
  tool('get_file_contents', 'Lit un fichier (texte ou base64 si binaire) ou liste un dossier, sur une branche, un tag ou un commit.', {
    ...REPO,
    path: S.str('Chemin du fichier ou du dossier (vide = racine).'),
    ref: S.str('Branche, tag ou SHA (défaut : branche par défaut).'),
  }, ['repo'], (a) => {
    const r = requireRepo(a);
    const ref = refOf(r.gitDir, a.ref);
    const sha = resolveRef(r.gitDir, ref);
    const p = a.path ? normPath(a.path) : '';
    const spec = p ? `${sha}:${p}` : `${sha}^{tree}`;
    const type = objectType(r.gitDir, spec);
    if (!type) throw new ToolError(`Introuvable : ${p || '/'} sur ${ref}`);
    if (type === 'tree') {
      const out = git(r.gitDir, ['ls-tree', '-l', '-z', spec], { raw: true }).toString('utf8');
      return {
        type: 'dir', path: p || '/', ref,
        entries: out.split('\0').filter(Boolean).map((l) => {
          const [meta, name] = l.split('\t');
          const [mode, t, oid, size] = meta.split(/\s+/);
          return { name, path: p ? `${p}/${name}` : name, type: t === 'tree' ? 'dir' : t === 'commit' ? 'submodule' : 'file', size: size === '-' ? undefined : Number(size), sha: oid, mode };
        }),
      };
    }
    const buf = git(r.gitDir, ['cat-file', 'blob', spec], { raw: true });
    const blobSha = git(r.gitDir, ['rev-parse', spec]).trim();
    if (buf.length > 20 * 1024 * 1024) return { type: 'file', path: p, ref, size: buf.length, sha: blobSha, note: 'Fichier trop gros pour être renvoyé (>20 Mo).' };
    return { type: 'file', path: p, ref, size: buf.length, sha: blobSha, ...textOrB64(buf) };
  }, RO),

  tool('get_tree', 'Arborescence complète (récursive) d’une branche ou d’un dossier.', {
    ...REPO,
    ref: S.str('Branche, tag ou SHA.'),
    path: S.str('Sous-dossier (facultatif).'),
  }, ['repo'], (a) => {
    const r = requireRepo(a);
    const sha = resolveRef(r.gitDir, refOf(r.gitDir, a.ref));
    const args = ['ls-tree', '-r', '-l', '--full-tree', sha];
    if (a.path) args.push('--', normPath(a.path));
    const lines = git(r.gitDir, args).split('\n').filter(Boolean);
    return {
      commit: sha,
      count: lines.length,
      files: lines.map((l) => {
        const [meta, p] = l.split('\t');
        const size = meta.split(/\s+/)[3];
        return `${p}${size !== '-' ? ` (${size} o)` : ''}`;
      }),
    };
  }, RO),

  tool('create_or_update_file', 'Crée ou modifie un fichier et fait un commit (comme l’éditeur web de GitHub).', {
    ...REPO,
    path: S.str('Chemin du fichier.'),
    content: S.str('Contenu (texte, ou base64 si encoding = base64).'),
    encoding: S.enum(['utf-8', 'base64'], 'Encodage du contenu.'),
    message: S.str('Message de commit.'),
    branch: S.str('Branche (créée depuis la branche par défaut si elle n’existe pas).'),
    sha: S.str('SHA actuel du fichier, pour éviter d’écraser une modification concurrente (facultatif).'),
    executable: S.bool('Fichier exécutable (mode 755).'),
  }, ['repo', 'path', 'content'], (a) => {
    const r = requireRepo(a);
    const branch = a.branch || defaultBranch(r.gitDir);
    const p = normPath(a.path);
    if (a.sha) {
      const cur = git(r.gitDir, ['rev-parse', `refs/heads/${branch}:${p}`], { allowFail: true }).stdout.trim();
      if (cur !== a.sha) throw new ToolError(`Le fichier a changé (sha actuel ${cur || 'aucun'}). Relisez-le avant de le modifier.`);
    }
    const res = commitChanges(r.gitDir, branch, [{ path: p, content: toBuffer(a.content, a.encoding), mode: a.executable ? '100755' : undefined }], a.message || `Mise à jour de ${p}`, { from: defaultBranch(r.gitDir) });
    return { branch, path: p, commit: res.commit };
  }),

  tool('push_files', 'Écrit plusieurs fichiers (et supprime des fichiers) en un seul commit.', {
    ...REPO,
    branch: S.str('Branche (créée depuis la branche par défaut si besoin).'),
    message: S.str('Message de commit.'),
    files: S.arr({
      type: 'object',
      properties: { path: { type: 'string' }, content: { type: 'string' }, encoding: { type: 'string', enum: ['utf-8', 'base64'] }, executable: { type: 'boolean' } },
      required: ['path', 'content'],
    }, 'Fichiers à écrire.'),
    delete: S.arr({ type: 'string' }, 'Chemins à supprimer.'),
    local_paths: S.arr({
      type: 'object',
      properties: { from: { type: 'string', description: 'Fichier ou dossier sur le disque.' }, to: { type: 'string', description: 'Chemin dans le dépôt.' } },
      required: ['from'],
    }, 'Copier des fichiers/dossiers du disque local dans le dépôt (images, APK, assets…).'),
  }, ['repo', 'message'], (a) => {
    const r = requireRepo(a);
    const branch = a.branch || defaultBranch(r.gitDir);
    const changes = (a.files || []).map((f) => ({ path: f.path, content: toBuffer(f.content, f.encoding), mode: f.executable ? '100755' : undefined }));
    for (const lp of a.local_paths || []) {
      const src = path.resolve(lp.from);
      if (!fs.existsSync(src)) throw new ToolError(`Introuvable sur le disque : ${src}`);
      const target = lp.to || path.basename(src);
      for (const f of walk(src)) {
        const rel = path.relative(src, f).split(path.sep).join('/');
        changes.push({ path: rel ? `${target}/${rel}` : target, content: fs.readFileSync(f), mode: fs.statSync(f).mode & 0o111 ? '100755' : undefined });
      }
    }
    for (const d of a.delete || []) changes.push({ path: d, content: null });
    if (!changes.length) throw new ToolError('Rien à envoyer.');
    const res = commitChanges(r.gitDir, branch, changes, a.message, { from: defaultBranch(r.gitDir) });
    return { branch, commit: res.commit, files_changed: changes.length };
  }),

  tool('delete_file', 'Supprime un fichier (ou un dossier entier) avec un commit.', {
    ...REPO,
    path: S.str('Chemin du fichier ou dossier.'),
    message: S.str('Message de commit.'),
    branch: S.str('Branche.'),
  }, ['repo', 'path'], (a) => {
    const r = requireRepo(a);
    const branch = a.branch || defaultBranch(r.gitDir);
    const p = normPath(a.path);
    const files = git(r.gitDir, ['ls-tree', '-r', '--name-only', resolveRef(r.gitDir, `refs/heads/${branch}`), '--', p]).split('\n').filter(Boolean);
    if (!files.length) throw new ToolError(`Introuvable : ${p}`);
    const res = commitChanges(r.gitDir, branch, files.map((f) => ({ path: f, content: null })), a.message || `Suppression de ${p}`);
    return { branch, deleted: files, commit: res.commit };
  }, DESTRUCTIVE),

  tool('checkout_to_folder', 'Extrait le contenu d’une branche/tag dans un dossier local (pour ouvrir dans un éditeur, Android Studio, Godot…).', {
    ...REPO,
    ref: S.str('Branche, tag ou SHA.'),
    destination: S.str('Dossier de destination (doit être vide ou inexistant).'),
    as_clone: S.bool('Faire un vrai clone git (relié au dépôt, pour git pull/push) plutôt qu’une simple copie.'),
  }, ['repo', 'destination'], (a) => {
    const r = requireRepo(a);
    const dest = path.resolve(a.destination);
    if (fs.existsSync(dest) && fs.readdirSync(dest).length) throw new ToolError(`Le dossier n’est pas vide : ${dest}`);
    const ref = refOf(r.gitDir, a.ref);
    if (a.as_clone) {
      git(null, ['clone', '--quiet', '--branch', ref, r.gitDir, dest]);
    } else {
      ensureDir(dest);
      extractTree(r.gitDir, resolveRef(r.gitDir, ref), dest);
    }
    return { destination: dest, ref, mode: a.as_clone ? 'clone' : 'copie' };
  }),

  // ---- Branches ----
  tool('list_branches', 'Liste les branches avec leur dernier commit.', REPO, ['repo'], (a) => {
    const r = requireRepo(a);
    const def = defaultBranch(r.gitDir);
    return git(r.gitDir, ['for-each-ref', '--sort=-committerdate', '--format=%(refname:short)\x1f%(objectname)\x1f%(committerdate:iso-strict)\x1f%(subject)', 'refs/heads'])
      .split('\n').filter(Boolean).map((l) => {
        const [name, sha, date, subject] = l.split('\x1f');
        return { name, sha, date, message: subject, default: name === def };
      });
  }, RO),

  tool('create_branch', 'Crée une branche à partir d’une autre branche, d’un tag ou d’un commit.', {
    ...REPO,
    branch: S.str('Nom de la nouvelle branche.'),
    from: S.str('Point de départ (défaut : branche par défaut).'),
  }, ['repo', 'branch'], (a) => {
    const r = requireRepo(a);
    git(null, ['check-ref-format', '--branch', a.branch]);
    if (revParse(r.gitDir, `refs/heads/${a.branch}`)) throw new ToolError(`La branche ${a.branch} existe déjà.`);
    const sha = resolveRef(r.gitDir, a.from || defaultBranch(r.gitDir));
    git(r.gitDir, ['update-ref', `refs/heads/${a.branch}`, sha, '']);
    return { branch: a.branch, sha };
  }),

  tool('delete_branch', 'Supprime une branche (sauf la branche par défaut).', { ...REPO, branch: S.str('Branche à supprimer.') }, ['repo', 'branch'], (a) => {
    const r = requireRepo(a);
    if (a.branch === defaultBranch(r.gitDir)) throw new ToolError('Impossible de supprimer la branche par défaut.');
    const sha = resolveRef(r.gitDir, `refs/heads/${a.branch}`);
    git(r.gitDir, ['update-ref', '-d', `refs/heads/${a.branch}`, sha]);
    return { deleted: a.branch, was: sha };
  }, DESTRUCTIVE),

  // ---- Commits ----
  tool('list_commits', 'Historique des commits (filtrable par chemin, auteur, texte, dates).', {
    ...REPO,
    ref: S.str('Branche, tag ou SHA.'),
    path: S.str('Seulement les commits touchant ce chemin.'),
    author: S.str('Filtrer par auteur.'),
    grep: S.str('Filtrer par texte du message.'),
    since: S.str('Depuis (ex. 2026-01-01 ou « 2 weeks ago »).'),
    until: S.str('Jusqu’à.'),
    limit: S.int('Nombre maximum (défaut 30).'),
    skip: S.int('Pagination : commits à sauter.'),
  }, ['repo'], (a) => {
    const r = requireRepo(a);
    const ref = refOf(r.gitDir, a.ref);
    if (!revParse(r.gitDir, ref)) return [];
    const args = ['log', LOG_FORMAT, `-n${a.limit || 30}`];
    if (a.skip) args.push(`--skip=${a.skip}`);
    if (a.author) args.push(`--author=${a.author}`);
    if (a.grep) args.push(`--grep=${a.grep}`, '-i');
    if (a.since) args.push(`--since=${a.since}`);
    if (a.until) args.push(`--until=${a.until}`);
    args.push(ref);
    if (a.path) args.push('--', normPath(a.path));
    return parseLog(git(r.gitDir, args));
  }, RO),

  tool('get_commit', 'Détail d’un commit : auteur, fichiers modifiés, diff.', {
    ...REPO,
    sha: S.str('SHA, branche ou tag.'),
    include_diff: S.bool('Inclure le diff complet (défaut : vrai).'),
  }, ['repo', 'sha'], (a) => {
    const r = requireRepo(a);
    const sha = resolveRef(r.gitDir, a.sha);
    const info = parseLog(git(r.gitDir, ['log', '-1', LOG_FORMAT, sha]))[0];
    const parents = git(r.gitDir, ['rev-list', '--parents', '-n1', sha]).trim().split(' ').slice(1);
    const files = git(r.gitDir, ['diff-tree', '--root', '-r', '--no-commit-id', '--numstat', '-M', sha]).split('\n').filter(Boolean).map((l) => {
      const [add, del, file] = l.split('\t');
      return { file, additions: add === '-' ? null : Number(add), deletions: del === '-' ? null : Number(del) };
    });
    const out = { ...info, parents, files };
    if (a.include_diff !== false) out.diff = clip(git(r.gitDir, ['show', '--format=', '-M', '--root', sha]));
    return out;
  }, RO),

  tool('compare', 'Compare deux références (base...head) : commits d’avance/retard, fichiers, diff.', {
    ...REPO,
    base: S.str('Référence de base.'),
    head: S.str('Référence comparée.'),
    include_diff: S.bool('Inclure le diff (défaut : vrai).'),
  }, ['repo', 'base', 'head'], (a) => {
    const r = requireRepo(a);
    return compareRefs(r.gitDir, resolveRef(r.gitDir, a.base), resolveRef(r.gitDir, a.head), a.include_diff !== false);
  }, RO),

  tool('blame', 'Qui a modifié chaque ligne d’un fichier (git blame).', {
    ...REPO,
    path: S.str('Fichier.'),
    ref: S.str('Branche, tag ou SHA.'),
    start: S.int('Première ligne.'),
    end: S.int('Dernière ligne.'),
  }, ['repo', 'path'], (a) => {
    const r = requireRepo(a);
    const args = ['blame', '--date=short', '-c'];
    if (a.start || a.end) args.push('-L', `${a.start || 1},${a.end || ''}`);
    args.push(resolveRef(r.gitDir, refOf(r.gitDir, a.ref)), '--', normPath(a.path));
    return clip(git(r.gitDir, args));
  }, RO),

  tool('revert_commit', 'Annule un commit en créant un commit inverse sur une branche.', {
    ...REPO,
    sha: S.str('Commit à annuler.'),
    branch: S.str('Branche (défaut : branche par défaut).'),
  }, ['repo', 'sha'], (a) => {
    const r = requireRepo(a);
    const branch = a.branch || defaultBranch(r.gitDir);
    const head = resolveRef(r.gitDir, `refs/heads/${branch}`);
    const target = resolveRef(r.gitDir, a.sha);
    const parent = revParse(r.gitDir, `${target}^`);
    if (!parent) throw new ToolError('Impossible d’annuler le tout premier commit.');
    // fusion à trois voies : base = commit annulé, « ours » = tête, « theirs » = parent du commit
    const res = git(r.gitDir, ['merge-tree', '--write-tree', `--merge-base=${target}`, head, parent], { allowFail: true });
    if (res.status !== 0) throw new ToolError(`Conflit : l’annulation ne s’applique pas proprement.\n${res.stdout}`);
    const tree = res.stdout.split('\n')[0].trim();
    const subject = git(r.gitDir, ['log', '-1', '--format=%s', target]).trim();
    const commit = git(r.gitDir, ['commit-tree', tree, '-p', head, '-F', '-'], { input: `Revert "${subject}"\n\nThis reverts commit ${target}.\n` }).trim();
    git(r.gitDir, ['update-ref', `refs/heads/${branch}`, commit, head]);
    return { branch, commit, reverted: target };
  }),

  // ---- Tags ----
  tool('list_tags', 'Liste les tags.', REPO, ['repo'], (a) => {
    const r = requireRepo(a);
    return git(r.gitDir, ['for-each-ref', '--sort=-creatordate', '--format=%(refname:short)\x1f%(objectname)\x1f%(*objectname)\x1f%(creatordate:iso-strict)\x1f%(contents:subject)', 'refs/tags'])
      .split('\n').filter(Boolean).map((l) => {
        const [name, obj, peeled, date, msg] = l.split('\x1f');
        return { name, commit: peeled || obj, date, message: msg || undefined };
      });
  }, RO),

  tool('create_tag', 'Crée un tag (annoté si un message est donné).', {
    ...REPO,
    tag: S.str('Nom du tag (ex. v1.0.0).'),
    ref: S.str('Commit ou branche à marquer.'),
    message: S.str('Message (tag annoté).'),
  }, ['repo', 'tag'], (a) => {
    const r = requireRepo(a);
    return createTag(r.gitDir, a.tag, a.ref, a.message);
  }),

  tool('delete_tag', 'Supprime un tag.', { ...REPO, tag: S.str('Tag.') }, ['repo', 'tag'], (a) => {
    const r = requireRepo(a);
    git(r.gitDir, ['tag', '-d', a.tag]);
    return { deleted: a.tag };
  }, DESTRUCTIVE),

  // ---- Recherche & statistiques ----
  tool('search_code', 'Recherche dans le code (git grep) d’un dépôt, ou de tous les dépôts si repo est omis.', {
    ...REPO,
    query: S.str('Texte ou expression régulière.'),
    ref: S.str('Branche, tag ou SHA.'),
    path: S.str('Limiter à un chemin ou motif (ex. *.kt).'),
    ignore_case: S.bool('Ignorer la casse.'),
    regex: S.bool('Interpréter query comme une expression régulière.'),
    limit: S.int('Résultats maximum (défaut 100).'),
  }, ['query'], (a) => {
    const ids = a.repo ? [requireRepo(a)] : listRepoIds().map((id) => ({ ...id, gitDir: gitDirOf(id) }));
    const results = [];
    const limit = a.limit || 100;
    for (const r of ids) {
      const ref = a.repo ? refOf(r.gitDir, a.ref) : defaultBranch(r.gitDir);
      const sha = revParse(r.gitDir, ref);
      if (!sha) continue;
      const args = ['grep', '-n', '-I', a.regex ? '-E' : '-F'];
      if (a.ignore_case) args.push('-i');
      args.push('-e', a.query, sha);
      if (a.path) args.push('--', a.path);
      const res = git(r.gitDir, args, { allowFail: true });
      for (const line of res.stdout.split('\n').filter(Boolean)) {
        const m = line.slice(sha.length + 1).match(/^(.*?):(\d+):(.*)$/);
        if (m) results.push({ repo: r.full, path: m[1], line: Number(m[2]), text: m[3].slice(0, 300) });
        if (results.length >= limit) return results;
      }
    }
    return results;
  }, RO),

  tool('repository_stats', 'Statistiques : langages (par extension), contributeurs, nombre de commits et de fichiers, taille.', { ...REPO, ref: S.str('Référence.') }, ['repo'], (a) => {
    const r = requireRepo(a);
    const sha = revParse(r.gitDir, refOf(r.gitDir, a.ref));
    if (!sha) return { commits: 0 };
    const langs = {};
    let files = 0;
    let bytes = 0;
    for (const l of git(r.gitDir, ['ls-tree', '-r', '-l', sha]).split('\n').filter(Boolean)) {
      const [meta, p] = l.split('\t');
      const size = Number(meta.split(/\s+/)[3]) || 0;
      const ext = path.extname(p).slice(1).toLowerCase() || '(sans extension)';
      langs[ext] = (langs[ext] || 0) + size;
      files++;
      bytes += size;
    }
    const contributors = git(r.gitDir, ['shortlog', '-sne', sha]).split('\n').filter(Boolean).map((l) => {
      const m = l.trim().match(/^(\d+)\s+(.*)$/);
      return { commits: Number(m[1]), author: m[2] };
    });
    const languages = Object.entries(langs).sort((x, y) => y[1] - x[1]).slice(0, 15).map(([ext, b]) => ({ ext, bytes: b, percent: Math.round((b / bytes) * 1000) / 10 }));
    return { commits: Number(git(r.gitDir, ['rev-list', '--count', sha]).trim()), files, bytes, languages, contributors };
  }, RO),
];

export function compareRefs(gitDir, base, head, includeDiff = true) {
  const mb = git(gitDir, ['merge-base', base, head], { allowFail: true }).stdout.trim();
  const ahead = parseLog(git(gitDir, ['log', LOG_FORMAT, `${base}..${head}`]));
  const behind = Number(git(gitDir, ['rev-list', '--count', `${head}..${base}`]).trim());
  const from = mb || base;
  const files = git(gitDir, ['diff', '--numstat', '-M', from, head]).split('\n').filter(Boolean).map((l) => {
    const [add, del, file] = l.split('\t');
    return { file, additions: add === '-' ? null : Number(add), deletions: del === '-' ? null : Number(del) };
  });
  const out = { base, head, merge_base: mb || null, ahead_by: ahead.length, behind_by: behind, status: ahead.length && behind ? 'diverged' : ahead.length ? 'ahead' : behind ? 'behind' : 'identical', commits: ahead, files };
  if (includeDiff) out.diff = clip(git(gitDir, ['diff', '-M', from, head]));
  return out;
}

export function createTag(gitDir, tag, ref, message) {
  git(null, ['check-ref-format', `refs/tags/${tag}`]);
  if (revParse(gitDir, `refs/tags/${tag}`)) throw new ToolError(`Le tag ${tag} existe déjà.`);
  const sha = resolveRef(gitDir, ref || defaultBranch(gitDir));
  if (message) git(gitDir, ['tag', '-a', tag, sha, '-F', '-'], { input: message });
  else git(gitDir, ['tag', tag, sha]);
  return { tag, commit: sha };
}

/** Écrit l’arbre d’un commit dans un dossier (sans .git). */
export function extractTree(gitDir, sha, dest) {
  const tar = git(gitDir, ['archive', '--format=tar', sha], { raw: true });
  extractTar(tar, dest);
}

function extractTar(buf, dest) {
  let off = 0;
  let longName = null;
  while (off + 512 <= buf.length) {
    const h = buf.subarray(off, off + 512);
    if (h.every((b) => b === 0)) break;
    const str = (s, l) => h.subarray(s, s + l).toString('utf8').replace(/\0.*$/s, '');
    let name = str(0, 100);
    const prefix = str(345, 155);
    if (prefix) name = `${prefix}/${name}`;
    const mode = parseInt(str(100, 8), 8) || 0o644;
    const size = parseInt(str(124, 12).trim() || '0', 8);
    const type = String.fromCharCode(h[156] || 48);
    const data = buf.subarray(off + 512, off + 512 + size);
    off += 512 + Math.ceil(size / 512) * 512;
    if (type === 'x' || type === 'g') {
      const m = data.toString('utf8').match(/\d+ path=([^\n]*)\n/);
      if (m && type === 'x') longName = m[1];
      continue;
    }
    if (longName) { name = longName; longName = null; }
    const target = path.join(dest, name);
    if (!path.resolve(target).startsWith(path.resolve(dest))) continue;
    if (type === '5') ensureDir(target);
    else if (type === '2') {
      ensureDir(path.dirname(target));
      try { fs.symlinkSync(str(157, 100), target); } catch { /* lien ignoré (Windows/Android) */ }
    } else if (type === '0' || type === '\0' || type === '7') {
      ensureDir(path.dirname(target));
      fs.writeFileSync(target, data, { mode });
    }
  }
}

function* walk(p) {
  const st = fs.statSync(p);
  if (st.isFile()) { yield p; return; }
  for (const e of fs.readdirSync(p)) {
    if (e === '.git') continue;
    yield* walk(path.join(p, e));
  }
}

export { isAncestor };

const GITIGNORES = {
  none: '',
  android: '*.iml\n.gradle/\n/local.properties\n.idea/\n.DS_Store\n/build/\n/app/build/\n/captures\n.externalNativeBuild\n.cxx\n*.apk\n*.aab\n*.keystore\n*.jks\n',
  node: 'node_modules/\ndist/\n.env\nnpm-debug.log*\n',
  python: '__pycache__/\n*.pyc\n.venv/\ndist/\nbuild/\n*.egg-info/\n',
  godot: '.godot/\n/android/\n/build/\n*.apk\n*.aab\nexport_credentials.cfg\n',
};
