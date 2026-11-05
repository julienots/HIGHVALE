package com.gixcloud.app;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.diff.DiffEntry;
import org.eclipse.jgit.diff.DiffFormatter;
import org.eclipse.jgit.diff.Edit;
import org.eclipse.jgit.dircache.DirCache;
import org.eclipse.jgit.dircache.DirCacheBuilder;
import org.eclipse.jgit.dircache.DirCacheEditor;
import org.eclipse.jgit.dircache.DirCacheEntry;
import org.eclipse.jgit.lib.CommitBuilder;
import org.eclipse.jgit.lib.Constants;
import org.eclipse.jgit.lib.FileMode;
import org.eclipse.jgit.lib.ObjectId;
import org.eclipse.jgit.lib.ObjectInserter;
import org.eclipse.jgit.lib.ObjectReader;
import org.eclipse.jgit.lib.PersonIdent;
import org.eclipse.jgit.lib.Ref;
import org.eclipse.jgit.lib.RefUpdate;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.merge.MergeStrategy;
import org.eclipse.jgit.merge.ResolveMerger;
import org.eclipse.jgit.revwalk.RevCommit;
import org.eclipse.jgit.revwalk.RevWalk;
import org.eclipse.jgit.revwalk.filter.RevFilter;
import org.eclipse.jgit.storage.file.FileRepositoryBuilder;
import org.eclipse.jgit.treewalk.AbstractTreeIterator;
import org.eclipse.jgit.treewalk.CanonicalTreeParser;
import org.eclipse.jgit.treewalk.EmptyTreeIterator;
import org.eclipse.jgit.treewalk.TreeWalk;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;
import java.util.regex.Pattern;

/** Dépôts git « bare » (JGit) + métadonnées JSON (tickets, pull requests, versions). */
public final class GitStore {
    private static final Pattern NAME = Pattern.compile("[A-Za-z0-9._-]{1,100}");
    final Gix gix;
    final File repos, meta, releases, apks;

    GitStore(Gix gix) {
        this.gix = gix;
        repos = new File(gix.root, "repos");
        meta = new File(gix.root, "meta");
        releases = new File(gix.root, "releases");
        apks = new File(gix.root, "apk");
        for (File f : new File[]{repos, meta, releases, apks}) f.mkdirs();
    }

    // ---------- Identifiants ----------

    public static final class Id {
        public final String owner, repo;
        Id(String o, String r) { owner = o; repo = r; }
        public String full() { return owner + "/" + repo; }
    }

    public Id id(String owner, String repo) {
        if (repo == null || repo.isEmpty()) throw new Tools.Err("Paramètre « repo » requis.");
        if (repo.contains("/")) { String[] p = repo.split("/", 2); owner = p[0]; repo = p[1]; }
        if (owner == null || owner.isEmpty()) owner = gix.owner();
        if (repo.endsWith(".git")) repo = repo.substring(0, repo.length() - 4);
        for (String n : new String[]{owner, repo}) {
            if (!NAME.matcher(n).matches() || n.startsWith(".")) throw new Tools.Err("Nom invalide : " + n);
        }
        return new Id(owner, repo);
    }

    public File gitDir(Id id) { return new File(new File(repos, id.owner), id.repo + ".git"); }

    public boolean exists(Id id) { return gitDir(id).isDirectory(); }

    public Repository open(Id id) {
        if (!exists(id)) throw new Tools.Err("Dépôt introuvable : " + id.full());
        try {
            return new FileRepositoryBuilder().setGitDir(gitDir(id)).setBare().build();
        } catch (Exception e) { throw new Tools.Err(e.getMessage()); }
    }

    public List<Id> list() {
        List<Id> out = new ArrayList<>();
        File[] owners = repos.listFiles();
        if (owners == null) return out;
        for (File o : owners) {
            File[] rs = o.listFiles();
            if (rs == null) continue;
            for (File r : rs) if (r.getName().endsWith(".git")) out.add(new Id(o.getName(), r.getName().substring(0, r.getName().length() - 4)));
        }
        return out;
    }

    public void init(Id id, String branch) throws Exception {
        File d = gitDir(id);
        if (d.exists()) throw new Tools.Err("Le dépôt " + id.full() + " existe déjà.");
        d.getParentFile().mkdirs();
        Git.init().setBare(true).setDirectory(d).setInitialBranch(branch).call().close();
    }

    // ---------- Références ----------

    public static String defaultBranch(Repository r) {
        try {
            Ref head = r.exactRef(Constants.HEAD);
            if (head != null && head.isSymbolic()) return Repository.shortenRefName(head.getTarget().getName());
        } catch (Exception ignored) { }
        return "main";
    }

    public static ObjectId resolve(Repository r, String ref) {
        try {
            return r.resolve(ref + "^{commit}");
        } catch (Exception e) { return null; }
    }

    public static ObjectId need(Repository r, String ref) {
        ObjectId id = resolve(r, ref);
        if (id == null) throw new Tools.Err("Référence introuvable : " + ref);
        return id;
    }

    public static ObjectId branchHead(Repository r, String branch) { return resolve(r, Constants.R_HEADS + branch); }

    public static void setRef(Repository r, String name, ObjectId newId, ObjectId expected, boolean force) throws Exception {
        RefUpdate ru = r.updateRef(name);
        ru.setNewObjectId(newId);
        if (!force) ru.setExpectedOldObjectId(expected == null ? ObjectId.zeroId() : expected);
        ru.setForceUpdate(force);
        ru.setRefLogMessage("gixcloud", false);
        RefUpdate.Result res = ru.update();
        switch (res) {
            case NEW: case FAST_FORWARD: case FORCED: case NO_CHANGE: return;
            default: throw new Tools.Err("Mise à jour de " + name + " refusée (" + res + ") : quelqu'un l'a modifiée entre-temps ?");
        }
    }

    public static void deleteRef(Repository r, String name) throws Exception {
        RefUpdate ru = r.updateRef(name);
        ru.setForceUpdate(true);
        RefUpdate.Result res = ru.delete();
        if (res != RefUpdate.Result.FORCED && res != RefUpdate.Result.NO_CHANGE) throw new Tools.Err("Suppression refusée : " + res);
    }

    public static boolean isAncestor(Repository r, ObjectId a, ObjectId b) throws Exception {
        try (RevWalk rw = new RevWalk(r)) {
            return rw.isMergedInto(rw.parseCommit(a), rw.parseCommit(b));
        }
    }

    public static ObjectId mergeBase(Repository r, ObjectId a, ObjectId b) throws Exception {
        try (RevWalk rw = new RevWalk(r)) {
            rw.setRevFilter(RevFilter.MERGE_BASE);
            rw.markStart(rw.parseCommit(a));
            rw.markStart(rw.parseCommit(b));
            RevCommit c = rw.next();
            return c == null ? null : c.getId();
        }
    }

    // ---------- Commit sans copie de travail ----------

    public static final class Change {
        final String path; final byte[] content; final boolean exec;
        Change(String p, byte[] c, boolean x) { path = p; content = c; exec = x; }
    }

    public static String normPath(String p) {
        String n = p == null ? "" : p.replace('\\', '/').replaceAll("^/+", "").replaceAll("/+$", "");
        if (n.isEmpty()) throw new Tools.Err("Chemin invalide : " + p);
        for (String s : n.split("/")) if (s.equals("..") || s.equals(".") || s.equals(".git") || s.isEmpty()) throw new Tools.Err("Chemin invalide : " + p);
        return n;
    }

    public PersonIdent person() { return new PersonIdent(gix.authorName(), gix.authorEmail()); }

    public ObjectId commit(Repository r, String branch, List<Change> changes, String message, String from) throws Exception {
        String ref = Constants.R_HEADS + branch;
        ObjectId current = resolve(r, ref);
        ObjectId parent = current != null ? current : (from != null ? resolve(r, from) : null);
        try (ObjectInserter ins = r.newObjectInserter(); ObjectReader reader = r.newObjectReader(); RevWalk rw = new RevWalk(r)) {
            DirCache dc = DirCache.newInCore();
            ObjectId parentTree = null;
            if (parent != null) {
                parentTree = rw.parseCommit(parent).getTree().getId();
                DirCacheBuilder b = dc.builder();
                b.addTree(new byte[0], 0, reader, parentTree);
                b.finish();
            }
            DirCacheEditor ed = dc.editor();
            for (Change c : changes) {
                final String p = normPath(c.path);
                if (c.content == null) {
                    ed.add(new DirCacheEditor.DeletePath(p));
                } else {
                    final ObjectId blob = ins.insert(Constants.OBJ_BLOB, c.content);
                    final boolean exec = c.exec;
                    ed.add(new DirCacheEditor.PathEdit(p) {
                        @Override public void apply(DirCacheEntry e) {
                            e.setFileMode(exec ? FileMode.EXECUTABLE_FILE : FileMode.REGULAR_FILE);
                            e.setObjectId(blob);
                        }
                    });
                }
            }
            ed.finish();
            ObjectId tree = dc.writeTree(ins);
            if (tree.equals(parentTree)) throw new Tools.Err("Aucun changement à enregistrer (contenu identique).");
            ObjectId cid = writeCommit(ins, tree, message, parent == null ? new ObjectId[0] : new ObjectId[]{parent});
            ins.flush();
            setRef(r, ref, cid, current, false);
            return cid;
        }
    }

    public ObjectId writeCommit(ObjectInserter ins, ObjectId tree, String message, ObjectId[] parents) throws Exception {
        CommitBuilder cb = new CommitBuilder();
        cb.setTreeId(tree);
        cb.setParentIds(parents);
        cb.setAuthor(person());
        cb.setCommitter(person());
        cb.setMessage(message.endsWith("\n") ? message : message + "\n");
        return ins.insert(cb);
    }

    public ObjectId writeCommit(Repository r, ObjectId tree, String message, ObjectId... parents) throws Exception {
        try (ObjectInserter ins = r.newObjectInserter()) {
            ObjectId id = writeCommit(ins, tree, message, parents);
            ins.flush();
            return id;
        }
    }

    // ---------- Lecture ----------

    public static JSONObject commitJson(RevCommit c) throws Exception {
        JSONObject o = new JSONObject();
        o.put("sha", c.getName());
        o.put("short", c.getName().substring(0, 7));
        o.put("author", c.getAuthorIdent().getName());
        o.put("email", c.getAuthorIdent().getEmailAddress());
        o.put("date", iso(c.getAuthorIdent().getWhen()));
        o.put("message", c.getShortMessage());
        String full = c.getFullMessage().trim();
        if (full.length() > c.getShortMessage().length()) o.put("body", full.substring(c.getShortMessage().length()).trim());
        return o;
    }

    public static AbstractTreeIterator treeIter(Repository r, ObjectId commit) throws Exception {
        if (commit == null) return new EmptyTreeIterator();
        try (RevWalk rw = new RevWalk(r); ObjectReader reader = r.newObjectReader()) {
            CanonicalTreeParser p = new CanonicalTreeParser();
            p.reset(reader, rw.parseCommit(commit).getTree().getId());
            return p;
        }
    }

    /** Fichiers modifiés (+/-) et diff entre deux commits (from peut être null). */
    public static JSONObject diff(Repository r, ObjectId from, ObjectId to, boolean withPatch) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        JSONArray files = new JSONArray();
        try (DiffFormatter df = new DiffFormatter(out)) {
            df.setRepository(r);
            df.setDetectRenames(true);
            List<DiffEntry> entries = df.scan(treeIter(r, from), treeIter(r, to));
            for (DiffEntry e : entries) {
                int add = 0, del = 0;
                for (Edit ed : df.toFileHeader(e).toEditList()) { add += ed.getLengthB(); del += ed.getLengthA(); }
                JSONObject f = new JSONObject();
                f.put("file", e.getChangeType() == DiffEntry.ChangeType.DELETE ? e.getOldPath() : e.getNewPath());
                f.put("status", e.getChangeType().name().toLowerCase(Locale.ROOT));
                if (e.getChangeType() == DiffEntry.ChangeType.RENAME) f.put("from", e.getOldPath());
                f.put("additions", add);
                f.put("deletions", del);
                files.put(f);
                if (withPatch && out.size() < 300_000) df.format(e);
            }
        }
        JSONObject o = new JSONObject();
        o.put("files", files);
        if (withPatch) {
            String d = out.toString("UTF-8");
            if (out.size() >= 300_000) d += "\n… (diff tronqué)";
            o.put("diff", d);
        }
        return o;
    }

    public static List<RevCommit> range(Repository r, ObjectId base, ObjectId head, int max) throws Exception {
        List<RevCommit> out = new ArrayList<>();
        try (RevWalk rw = new RevWalk(r)) {
            rw.markStart(rw.parseCommit(head));
            if (base != null) rw.markUninteresting(rw.parseCommit(base));
            for (RevCommit c : rw) { out.add(c); if (out.size() >= max) break; }
        }
        return out;
    }

    /** Fusion à trois voies en mémoire ; renvoie {mergeable, merge_state, tree?, conflicts?}. */
    public static JSONObject mergeCheck(Repository r, ObjectId base, ObjectId head) throws Exception {
        JSONObject o = new JSONObject();
        if (isAncestor(r, head, base)) return o.put("mergeable", false).put("merge_state", "already_merged");
        ResolveMerger m = (ResolveMerger) MergeStrategy.RECURSIVE.newMerger(r, true);
        if (m.merge(base, head)) {
            o.put("mergeable", true);
            o.put("merge_state", isAncestor(r, base, head) ? "fast_forward" : "clean");
            o.put("tree", m.getResultTreeId().getName());
        } else {
            JSONArray c = new JSONArray();
            if (m.getUnmergedPaths() != null) for (String p : m.getUnmergedPaths()) c.put(p);
            if (m.getFailingPaths() != null) for (String p : m.getFailingPaths().keySet()) c.put(p);
            o.put("mergeable", false).put("merge_state", "conflicts").put("conflicts", c);
        }
        return o;
    }

    public static byte[] readBlob(Repository r, ObjectId id) throws Exception {
        return r.open(id, Constants.OBJ_BLOB).getCachedBytes(50 * 1024 * 1024);
    }

    public static TreeWalk walk(Repository r, ObjectId commit, boolean recursive) throws Exception {
        TreeWalk tw = new TreeWalk(r);
        try (RevWalk rw = new RevWalk(r)) {
            tw.addTree(rw.parseCommit(commit).getTree());
        }
        tw.setRecursive(recursive);
        return tw;
    }

    // ---------- Métadonnées ----------

    private File metaFile(Id id) { return new File(new File(meta, id.owner), id.repo + ".json"); }

    public synchronized JSONObject readMeta(Id id) {
        try {
            File f = metaFile(id);
            JSONObject m = f.exists() ? new JSONObject(new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8)) : new JSONObject();
            if (!m.has("next_number")) m.put("next_number", 1);
            for (String k : new String[]{"issues", "pulls", "releases"}) if (!m.has(k)) m.put(k, new JSONArray());
            if (!m.has("description")) m.put("description", "");
            if (!m.has("created_at")) m.put("created_at", now());
            return m;
        } catch (Exception e) { throw new Tools.Err("Métadonnées illisibles : " + e.getMessage()); }
    }

    public synchronized void writeMeta(Id id, JSONObject m) {
        try {
            File f = metaFile(id);
            f.getParentFile().mkdirs();
            m.put("updated_at", now());
            File tmp = new File(f.getPath() + ".tmp");
            try (FileOutputStream o = new FileOutputStream(tmp)) { o.write(m.toString(2).getBytes(StandardCharsets.UTF_8)); }
            if (!tmp.renameTo(f)) throw new Exception("écriture impossible");
        } catch (Tools.Err e) { throw e; } catch (Exception e) { throw new Tools.Err(e.getMessage()); }
    }

    public interface MetaFn { Object apply(JSONObject m) throws Exception; }

    public synchronized Object updateMeta(Id id, MetaFn fn) throws Exception {
        JSONObject m = readMeta(id);
        Object res = fn.apply(m);
        writeMeta(id, m);
        return res;
    }

    public void deleteAll(Id id) {
        rm(gitDir(id));
        metaFile(id).delete();
        rm(new File(new File(releases, id.owner), id.repo));
    }

    public File releaseDir(Id id, String tag) {
        return new File(new File(new File(releases, id.owner), id.repo), tag.replaceAll("[^A-Za-z0-9._-]", "-"));
    }

    public static void rm(File f) {
        if (f == null || !f.exists()) return;
        File[] kids = f.listFiles();
        if (kids != null) for (File k : kids) rm(k);
        f.delete();
    }

    public static void copyDir(File src, File dst) throws Exception {
        if (src.isDirectory()) {
            dst.mkdirs();
            File[] kids = src.listFiles();
            if (kids != null) for (File k : kids) copyDir(k, new File(dst, k.getName()));
        } else {
            Files.copy(src.toPath(), dst.toPath());
        }
    }

    public static String now() { return iso(new Date()); }

    public static String iso(Date d) {
        SimpleDateFormat f = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.ROOT);
        f.setTimeZone(TimeZone.getTimeZone("UTC"));
        return f.format(d);
    }
}
