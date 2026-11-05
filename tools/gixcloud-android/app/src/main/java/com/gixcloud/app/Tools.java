package com.gixcloud.app;

import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Base64;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.LogCommand;
import org.eclipse.jgit.lib.Constants;
import org.eclipse.jgit.lib.FileMode;
import org.eclipse.jgit.lib.ObjectId;
import org.eclipse.jgit.lib.Ref;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.revwalk.RevCommit;
import org.eclipse.jgit.revwalk.RevObject;
import org.eclipse.jgit.revwalk.RevTag;
import org.eclipse.jgit.revwalk.RevWalk;
import org.eclipse.jgit.treewalk.TreeWalk;
import org.eclipse.jgit.treewalk.filter.PathFilter;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Les outils exposés aux IA par MCP (et utilisés par l'interface de l'application). */
public final class Tools {

    /** Erreur « métier » renvoyée telle quelle à l'IA. */
    public static final class Err extends RuntimeException {
        public Err(String m) { super(m); }
    }

    interface Handler { Object run(JSONObject a) throws Exception; }

    static final class Tool {
        final String name, description; final JSONObject schema; final Handler h; final boolean readOnly, destructive, admin;
        Tool(String n, String d, JSONObject s, Handler h, boolean ro, boolean de, boolean ad) { name = n; description = d; schema = s; this.h = h; readOnly = ro; destructive = de; admin = ad; }
    }

    final Gix gix;
    final GitStore st;
    final Map<String, Tool> tools = new LinkedHashMap<>();

    Tools(Gix gix) {
        this.gix = gix;
        this.st = gix.store;
        registerRepos();
        registerFiles();
        registerHistory();
        registerIssues();
        registerPulls();
        registerReleases();
        registerApk();
        new ToolsMore(this);
    }

    // ---------- Infrastructure ----------

    static final String[] REPO = {"repo", "s", "Nom du dépôt, ou « propriétaire/dépôt ».", "1"};
    static final String[] OWNER = {"owner", "s", "Propriétaire (facultatif)."};

    void def(String name, String desc, String flags, String[][] params, Handler h) {
        JSONObject props = new JSONObject();
        JSONArray req = new JSONArray();
        try {
            for (String[] p : params) {
                JSONObject s = new JSONObject();
                switch (p[1]) {
                    case "i": s.put("type", "integer"); break;
                    case "b": s.put("type", "boolean"); break;
                    case "as": s.put("type", "array").put("items", new JSONObject().put("type", "string")); break;
                    case "af": s.put("type", "array").put("items", new JSONObject().put("type", "object")
                            .put("properties", new JSONObject()
                                    .put("path", new JSONObject().put("type", "string"))
                                    .put("content", new JSONObject().put("type", "string"))
                                    .put("encoding", new JSONObject().put("type", "string").put("enum", new JSONArray().put("utf-8").put("base64"))))
                            .put("required", new JSONArray().put("path").put("content"))); break;
                    case "ac": s.put("type", "array").put("items", new JSONObject().put("type", "object")
                            .put("properties", new JSONObject()
                                    .put("path", new JSONObject().put("type", "string"))
                                    .put("line", new JSONObject().put("type", "integer"))
                                    .put("body", new JSONObject().put("type", "string")))
                            .put("required", new JSONArray().put("path").put("body"))); break;
                    default:
                        s.put("type", "string");
                        if (p[1].startsWith("e:")) {
                            JSONArray en = new JSONArray();
                            for (String v : p[1].substring(2).split("\\|")) en.put(v);
                            s.put("enum", en);
                        }
                }
                s.put("description", p[2]);
                props.put(p[0], s);
                if (p.length > 3) req.put(p[0]);
            }
            JSONObject schema = new JSONObject().put("type", "object").put("properties", props).put("required", req);
            tools.put(name, new Tool(name, desc, schema, h, flags.contains("r"), flags.contains("d"), flags.contains("a")));
        } catch (Exception e) { throw new RuntimeException(e); }
    }

    public JSONArray list() throws Exception {
        JSONArray out = new JSONArray();
        for (Tool t : tools.values()) {
            JSONObject o = new JSONObject().put("name", t.name).put("description", t.description).put("inputSchema", t.schema);
            if (t.readOnly || t.destructive) {
                JSONObject an = new JSONObject();
                if (t.readOnly) an.put("readOnlyHint", true);
                if (t.destructive) an.put("destructiveHint", true);
                o.put("annotations", an);
            }
            out.put(o);
        }
        return out;
    }

    public Object call(String name, JSONObject args) throws Exception {
        Tool t = tools.get(name);
        if (t == null) throw new Err("Outil inconnu : " + name);
        Auth.User u = Auth.current(gix);
        String need = t.admin ? "admin" : t.readOnly ? "read" : "write";
        if (!u.can(need)) throw new Err("Permission refusée : « " + name + " » demande un jeton " + need + " (le vôtre : " + u.perm + ").");
        JSONObject a = args == null ? new JSONObject() : args;
        Object res = t.h.run(a);
        if (!t.readOnly && !name.equals("delete_repository") && !name.endsWith("_token")) recordEvent(name, a, res);
        return res;
    }

    /** Chaque écriture apparaît dans le fil d'activité du dépôt (et déclenche ses webhooks). */
    private void recordEvent(String name, JSONObject a, Object res) {
        try {
            String repo = s(a, "repo") != null ? s(a, "repo") : name.equals("create_repository") ? s(a, "name") : null;
            if (repo == null || name.contains("gist") || name.contains("wiki") && false) return;
            GitStore.Id id = st.id(s(a, "owner"), repo);
            if (!st.exists(id)) return;
            JSONObject p = new JSONObject();
            for (String k : new String[]{"number", "branch", "base", "head", "title", "tag", "path", "event", "name", "sha", "merge_method", "state"}) if (a.has(k)) p.put(k, a.get(k));
            if (res instanceof JSONObject) for (String k : new String[]{"number", "commit", "merged"}) if (((JSONObject) res).has(k)) p.put("result_" + k, ((JSONObject) res).get(k));
            gix.events.emit(id, name, p);
        } catch (Exception ignored) { }
    }

    static String s(JSONObject a, String k) { return a.has(k) && !a.isNull(k) ? a.optString(k, null) : null; }
    static String s(JSONObject a, String k, String def) { String v = s(a, k); return v == null || v.isEmpty() ? def : v; }
    static int i(JSONObject a, String k, int def) { return a.has(k) ? a.optInt(k, def) : def; }
    static boolean b(JSONObject a, String k) { return a.optBoolean(k, false); }
    static List<String> strs(JSONObject a, String k) {
        List<String> out = new ArrayList<>();
        JSONArray arr = a.optJSONArray(k);
        if (arr != null) for (int x = 0; x < arr.length(); x++) out.add(arr.optString(x));
        return out;
    }
    static JSONArray jarr(List<String> l) { JSONArray a = new JSONArray(); for (String x : l) a.put(x); return a; }

    GitStore.Id id(JSONObject a) { return st.id(s(a, "owner"), s(a, "repo")); }

    interface RepoFn { Object run(Repository r, GitStore.Id id) throws Exception; }

    Object withRepo(JSONObject a, RepoFn fn) throws Exception {
        GitStore.Id id = id(a);
        try (Repository r = st.open(id)) { return fn.run(r, id); }
    }

    static String refOr(Repository r, JSONObject a, String key) { return s(a, key, GitStore.defaultBranch(r)); }

    // ---------- Dépôts ----------

    JSONObject repoInfo(Repository r, GitStore.Id id) throws Exception {
        JSONObject m = st.readMeta(id);
        String branch = GitStore.defaultBranch(r);
        ObjectId head = GitStore.branchHead(r, branch);
        JSONObject o = new JSONObject();
        o.put("full_name", id.full()).put("owner", id.owner).put("name", id.repo);
        o.put("description", m.optString("description"));
        o.put("default_branch", branch);
        o.put("branches", r.getRefDatabase().getRefsByPrefix(Constants.R_HEADS).size());
        if (head != null) try (RevWalk rw = new RevWalk(r)) { o.put("last_commit", GitStore.commitJson(rw.parseCommit(head))); }
        o.put("open_issues", countOpen(m.getJSONArray("issues")));
        o.put("open_pulls", countOpen(m.getJSONArray("pulls")));
        o.put("releases", m.getJSONArray("releases").length());
        if (m.has("fork_of")) o.put("fork_of", m.getString("fork_of"));
        o.put("created_at", m.optString("created_at"));
        o.put("updated_at", m.optString("updated_at"));
        return o;
    }

    static int countOpen(JSONArray arr) {
        int n = 0;
        for (int x = 0; x < arr.length(); x++) if ("open".equals(arr.optJSONObject(x).optString("state"))) n++;
        return n;
    }

    private void registerRepos() {
        def("create_repository", "Crée un dépôt git sur le téléphone (comme sur GitHub). auto_init ajoute un README.", "", new String[][]{
                {"name", "s", "Nom du dépôt.", "1"}, OWNER, {"description", "s", "Description."},
                {"auto_init", "b", "Premier commit avec README.md (défaut : vrai)."}, {"default_branch", "s", "Branche par défaut (défaut : main)."}}, a -> {
            GitStore.Id id = st.id(s(a, "owner"), s(a, "name"));
            String branch = s(a, "default_branch", "main");
            st.init(id, branch);
            JSONObject m = st.readMeta(id);
            m.put("description", s(a, "description", ""));
            st.writeMeta(id, m);
            try (Repository r = st.open(id)) {
                if (!a.has("auto_init") || a.optBoolean("auto_init")) {
                    List<GitStore.Change> ch = new ArrayList<>();
                    ch.add(new GitStore.Change("README.md", ("# " + id.repo + "\n\n" + s(a, "description", "") + "\n").getBytes(StandardCharsets.UTF_8), false));
                    st.commit(r, branch, ch, "Initial commit", null);
                }
                return repoInfo(r, id);
            }
        });

        def("list_repositories", "Liste les dépôts du téléphone.", "r", new String[][]{{"query", "s", "Filtrer par nom ou description."}}, a -> {
            String q = s(a, "query", "").toLowerCase(Locale.ROOT);
            JSONArray out = new JSONArray();
            for (GitStore.Id id : st.list()) {
                JSONObject m = st.readMeta(id);
                String d = m.optString("description");
                if (!q.isEmpty() && !id.full().toLowerCase(Locale.ROOT).contains(q) && !d.toLowerCase(Locale.ROOT).contains(q)) continue;
                out.put(new JSONObject().put("full_name", id.full()).put("description", d).put("updated_at", m.optString("updated_at", m.optString("created_at"))));
            }
            return out;
        });

        def("get_repository", "Détails d'un dépôt : branche par défaut, dernier commit, compteurs.", "r", new String[][]{REPO, OWNER}, a -> withRepo(a, this::repoInfo));

        def("update_repository", "Modifie la description ou la branche par défaut.", "", new String[][]{REPO, OWNER,
                {"description", "s", "Nouvelle description."}, {"default_branch", "s", "Nouvelle branche par défaut."}}, a -> withRepo(a, (r, id) -> {
            String db = s(a, "default_branch");
            if (db != null) {
                GitStore.need(r, Constants.R_HEADS + db);
                r.updateRef(Constants.HEAD).link(Constants.R_HEADS + db);
            }
            if (a.has("description")) st.updateMeta(id, m -> m.put("description", s(a, "description", "")));
            return repoInfo(r, id);
        }));

        def("delete_repository", "Supprime définitivement un dépôt. Exige confirm = « propriétaire/dépôt ».", "ad", new String[][]{REPO, OWNER,
                {"confirm", "s", "Nom complet « propriétaire/dépôt » pour confirmer.", "1"}}, a -> {
            GitStore.Id id = id(a);
            if (!st.exists(id)) throw new Err("Dépôt introuvable : " + id.full());
            if (!id.full().equals(s(a, "confirm"))) throw new Err("Confirmation incorrecte : tapez exactement « " + id.full() + " ».");
            st.deleteAll(id);
            return new JSONObject().put("deleted", id.full());
        });

        def("fork_repository", "Copie (fork) un dépôt sous un autre nom ou propriétaire.", "", new String[][]{REPO, OWNER,
                {"new_owner", "s", "Propriétaire du fork."}, {"new_name", "s", "Nom du fork."}}, a -> {
            GitStore.Id src = id(a);
            if (!st.exists(src)) throw new Err("Dépôt introuvable : " + src.full());
            GitStore.Id dst = st.id(s(a, "new_owner", gix.owner()), s(a, "new_name", src.repo));
            if (dst.full().equals(src.full())) throw new Err("Donnez un autre propriétaire ou un autre nom au fork.");
            if (st.exists(dst)) throw new Err(dst.full() + " existe déjà.");
            GitStore.copyDir(st.gitDir(src), st.gitDir(dst));
            JSONObject m = st.readMeta(dst);
            m.put("description", st.readMeta(src).optString("description")).put("fork_of", src.full());
            st.writeMeta(dst, m);
            try (Repository r = st.open(dst)) { return repoInfo(r, dst); }
        });
    }

    // ---------- Fichiers ----------

    static JSONObject content(byte[] data) throws Exception {
        boolean bin = false;
        for (int x = 0; x < Math.min(data.length, 8000); x++) if (data[x] == 0) { bin = true; break; }
        JSONObject o = new JSONObject();
        if (bin) o.put("encoding", "base64").put("content", Base64.encodeToString(data, Base64.NO_WRAP));
        else o.put("encoding", "utf-8").put("content", new String(data, StandardCharsets.UTF_8));
        return o;
    }

    static byte[] bytes(JSONObject f) {
        String c = f.optString("content", null);
        if (c == null) throw new Err("Contenu requis.");
        return "base64".equals(f.optString("encoding")) ? Base64.decode(c, Base64.DEFAULT) : c.getBytes(StandardCharsets.UTF_8);
    }

    private void registerFiles() {
        def("get_file_contents", "Lit un fichier (texte, ou base64 si binaire) ou liste un dossier, sur une branche, un tag ou un commit.", "r", new String[][]{REPO, OWNER,
                {"path", "s", "Chemin (vide = racine)."}, {"ref", "s", "Branche, tag ou SHA."}}, a -> withRepo(a, (r, id) -> {
            String ref = refOr(r, a, "ref");
            ObjectId c = GitStore.need(r, ref);
            String p = s(a, "path", "");
            JSONObject o = new JSONObject().put("ref", ref);
            TreeWalk dirWalk;
            if (p.isEmpty()) {
                dirWalk = GitStore.walk(r, c, false);
                o.put("path", "/");
            } else {
                p = GitStore.normPath(p);
                TreeWalk tw;
                try (RevWalk rw = new RevWalk(r)) { tw = TreeWalk.forPath(r, p, rw.parseCommit(c).getTree()); }
                if (tw == null) throw new Err("Introuvable : " + p + " sur " + ref);
                if (!tw.isSubtree()) {
                    byte[] data = GitStore.readBlob(r, tw.getObjectId(0));
                    JSONObject f = content(data);
                    return f.put("type", "file").put("path", p).put("ref", ref).put("size", data.length).put("sha", tw.getObjectId(0).getName());
                }
                dirWalk = new TreeWalk(r);
                dirWalk.addTree(tw.getObjectId(0));
                dirWalk.setRecursive(false);
                o.put("path", p);
            }
            JSONArray entries = new JSONArray();
            while (dirWalk.next()) {
                boolean dir = dirWalk.isSubtree();
                JSONObject e = new JSONObject().put("name", dirWalk.getNameString())
                        .put("path", p.isEmpty() ? dirWalk.getNameString() : p + "/" + dirWalk.getNameString())
                        .put("type", dir ? "dir" : "file").put("sha", dirWalk.getObjectId(0).getName());
                if (!dir) e.put("size", r.open(dirWalk.getObjectId(0)).getSize());
                entries.put(e);
            }
            return o.put("type", "dir").put("entries", entries);
        }));

        def("get_tree", "Liste récursive de tous les fichiers d'une branche.", "r", new String[][]{REPO, OWNER, {"ref", "s", "Branche, tag ou SHA."}, {"path", "s", "Sous-dossier."}}, a -> withRepo(a, (r, id) -> {
            ObjectId c = GitStore.need(r, refOr(r, a, "ref"));
            TreeWalk tw = GitStore.walk(r, c, true);
            String p = s(a, "path");
            if (p != null && !p.isEmpty()) tw.setFilter(PathFilter.create(GitStore.normPath(p)));
            JSONArray files = new JSONArray();
            while (tw.next()) files.put(tw.getPathString());
            return new JSONObject().put("commit", c.getName()).put("count", files.length()).put("files", files);
        }));

        def("create_or_update_file", "Crée ou modifie un fichier et fait un commit.", "", new String[][]{REPO, OWNER,
                {"path", "s", "Chemin du fichier.", "1"}, {"content", "s", "Contenu (texte, ou base64 si encoding = base64).", "1"},
                {"encoding", "e:utf-8|base64", "Encodage."}, {"message", "s", "Message de commit."},
                {"branch", "s", "Branche (créée depuis la branche par défaut si besoin)."},
                {"sha", "s", "SHA actuel du fichier, pour éviter d'écraser une modification concurrente."}}, a -> withRepo(a, (r, id) -> {
            String branch = refOr(r, a, "branch");
            String p = GitStore.normPath(s(a, "path"));
            String sha = s(a, "sha");
            if (sha != null) {
                ObjectId head = GitStore.branchHead(r, branch);
                String cur = null;
                if (head != null) try (RevWalk rw = new RevWalk(r)) {
                    TreeWalk tw = TreeWalk.forPath(r, p, rw.parseCommit(head).getTree());
                    if (tw != null) cur = tw.getObjectId(0).getName();
                }
                if (!sha.equals(cur)) throw new Err("Le fichier a changé (sha actuel " + cur + "). Relisez-le avant de le modifier.");
            }
            List<GitStore.Change> ch = new ArrayList<>();
            ch.add(new GitStore.Change(p, bytes(a), false));
            ObjectId c = st.commit(r, branch, ch, s(a, "message", "Mise à jour de " + p), GitStore.defaultBranch(r));
            return new JSONObject().put("branch", branch).put("path", p).put("commit", c.getName());
        }));

        def("push_files", "Écrit plusieurs fichiers et en supprime d'autres en un seul commit.", "", new String[][]{REPO, OWNER,
                {"message", "s", "Message de commit.", "1"}, {"branch", "s", "Branche."},
                {"files", "af", "Fichiers à écrire : {path, content, encoding?}."}, {"delete", "as", "Chemins à supprimer."}}, a -> withRepo(a, (r, id) -> {
            String branch = refOr(r, a, "branch");
            List<GitStore.Change> ch = new ArrayList<>();
            JSONArray files = a.optJSONArray("files");
            if (files != null) for (int x = 0; x < files.length(); x++) {
                JSONObject f = files.getJSONObject(x);
                ch.add(new GitStore.Change(f.getString("path"), bytes(f), false));
            }
            for (String d : strs(a, "delete")) ch.add(new GitStore.Change(d, null, false));
            if (ch.isEmpty()) throw new Err("Rien à envoyer.");
            ObjectId c = st.commit(r, branch, ch, s(a, "message"), GitStore.defaultBranch(r));
            return new JSONObject().put("branch", branch).put("commit", c.getName()).put("files_changed", ch.size());
        }));

        def("delete_file", "Supprime un fichier ou un dossier avec un commit.", "d", new String[][]{REPO, OWNER,
                {"path", "s", "Chemin.", "1"}, {"message", "s", "Message de commit."}, {"branch", "s", "Branche."}}, a -> withRepo(a, (r, id) -> {
            String branch = refOr(r, a, "branch");
            String p = GitStore.normPath(s(a, "path"));
            TreeWalk tw = GitStore.walk(r, GitStore.need(r, Constants.R_HEADS + branch), true);
            tw.setFilter(PathFilter.create(p));
            List<GitStore.Change> ch = new ArrayList<>();
            JSONArray del = new JSONArray();
            while (tw.next()) { ch.add(new GitStore.Change(tw.getPathString(), null, false)); del.put(tw.getPathString()); }
            if (ch.isEmpty()) throw new Err("Introuvable : " + p);
            ObjectId c = st.commit(r, branch, ch, s(a, "message", "Suppression de " + p), null);
            return new JSONObject().put("branch", branch).put("deleted", del).put("commit", c.getName());
        }));

        def("search_code", "Recherche un texte dans le code d'un dépôt, ou de tous les dépôts si repo est omis.", "r", new String[][]{
                {"query", "s", "Texte recherché.", "1"}, {"repo", "s", "Dépôt (facultatif)."}, OWNER, {"ref", "s", "Branche."},
                {"ignore_case", "b", "Ignorer la casse."}, {"limit", "i", "Maximum (défaut 100)."}}, a -> {
            List<GitStore.Id> ids = new ArrayList<>();
            if (s(a, "repo") != null) ids.add(id(a)); else ids.addAll(st.list());
            boolean ic = b(a, "ignore_case");
            String q = ic ? s(a, "query").toLowerCase(Locale.ROOT) : s(a, "query");
            int limit = i(a, "limit", 100);
            JSONArray out = new JSONArray();
            for (GitStore.Id rid : ids) {
                try (Repository r = st.open(rid)) {
                    ObjectId c = GitStore.resolve(r, s(a, "repo") != null ? refOr(r, a, "ref") : GitStore.defaultBranch(r));
                    if (c == null) continue;
                    TreeWalk tw = GitStore.walk(r, c, true);
                    while (tw.next()) {
                        if (r.open(tw.getObjectId(0)).getSize() > 2_000_000) continue;
                        byte[] data = GitStore.readBlob(r, tw.getObjectId(0));
                        boolean bin = false;
                        for (int x = 0; x < Math.min(data.length, 8000); x++) if (data[x] == 0) { bin = true; break; }
                        if (bin) continue;
                        String[] lines = new String(data, StandardCharsets.UTF_8).split("\n", -1);
                        for (int n = 0; n < lines.length; n++) {
                            String l = ic ? lines[n].toLowerCase(Locale.ROOT) : lines[n];
                            if (l.contains(q)) {
                                out.put(new JSONObject().put("repo", rid.full()).put("path", tw.getPathString()).put("line", n + 1)
                                        .put("text", lines[n].length() > 300 ? lines[n].substring(0, 300) : lines[n]));
                                if (out.length() >= limit) return out;
                            }
                        }
                    }
                }
            }
            return out;
        });
    }

    // ---------- Branches, commits, tags ----------

    private void registerHistory() {
        def("list_branches", "Liste les branches avec leur dernier commit.", "r", new String[][]{REPO, OWNER}, a -> withRepo(a, (r, id) -> {
            String def = GitStore.defaultBranch(r);
            JSONArray out = new JSONArray();
            try (RevWalk rw = new RevWalk(r)) {
                for (Ref ref : r.getRefDatabase().getRefsByPrefix(Constants.R_HEADS)) {
                    RevCommit c = rw.parseCommit(ref.getObjectId());
                    String n = Repository.shortenRefName(ref.getName());
                    out.put(new JSONObject().put("name", n).put("sha", c.getName()).put("message", c.getShortMessage())
                            .put("date", GitStore.iso(c.getAuthorIdent().getWhen())).put("default", n.equals(def)));
                }
            }
            return out;
        }));

        def("create_branch", "Crée une branche depuis une autre branche, un tag ou un commit.", "", new String[][]{REPO, OWNER,
                {"branch", "s", "Nouvelle branche.", "1"}, {"from", "s", "Point de départ (défaut : branche par défaut)."}}, a -> withRepo(a, (r, id) -> {
            String br = s(a, "branch");
            if (!Repository.isValidRefName(Constants.R_HEADS + br)) throw new Err("Nom de branche invalide : " + br);
            if (GitStore.branchHead(r, br) != null) throw new Err("La branche " + br + " existe déjà.");
            ObjectId c = GitStore.need(r, refOr(r, a, "from"));
            GitStore.setRef(r, Constants.R_HEADS + br, c, null, false);
            return new JSONObject().put("branch", br).put("sha", c.getName());
        }));

        def("delete_branch", "Supprime une branche (sauf la branche par défaut).", "d", new String[][]{REPO, OWNER, {"branch", "s", "Branche.", "1"}}, a -> withRepo(a, (r, id) -> {
            String br = s(a, "branch");
            if (br.equals(GitStore.defaultBranch(r))) throw new Err("Impossible de supprimer la branche par défaut.");
            GitStore.need(r, Constants.R_HEADS + br);
            GitStore.deleteRef(r, Constants.R_HEADS + br);
            return new JSONObject().put("deleted", br);
        }));

        def("list_commits", "Historique des commits (filtrable par chemin et auteur).", "r", new String[][]{REPO, OWNER,
                {"ref", "s", "Branche, tag ou SHA."}, {"path", "s", "Seulement les commits touchant ce chemin."},
                {"author", "s", "Filtrer par auteur."}, {"limit", "i", "Maximum (défaut 30)."}, {"skip", "i", "Pagination."}}, a -> withRepo(a, (r, id) -> {
            ObjectId c = GitStore.resolve(r, refOr(r, a, "ref"));
            JSONArray out = new JSONArray();
            if (c == null) return out;
            try (Git g = new Git(r)) {
                LogCommand lc = g.log().add(c).setSkip(i(a, "skip", 0)).setMaxCount(s(a, "author") != null ? 5000 : i(a, "limit", 30));
                if (s(a, "path") != null) lc.addPath(GitStore.normPath(s(a, "path")));
                String au = s(a, "author") == null ? null : s(a, "author").toLowerCase(Locale.ROOT);
                for (RevCommit rc : lc.call()) {
                    if (au != null && !(rc.getAuthorIdent().getName() + " " + rc.getAuthorIdent().getEmailAddress()).toLowerCase(Locale.ROOT).contains(au)) continue;
                    out.put(GitStore.commitJson(rc));
                    if (out.length() >= i(a, "limit", 30)) break;
                }
            }
            return out;
        }));

        def("get_commit", "Détail d'un commit : fichiers modifiés et diff.", "r", new String[][]{REPO, OWNER,
                {"sha", "s", "SHA, branche ou tag.", "1"}, {"include_diff", "b", "Inclure le diff (défaut : vrai)."}}, a -> withRepo(a, (r, id) -> {
            try (RevWalk rw = new RevWalk(r)) {
                RevCommit c = rw.parseCommit(GitStore.need(r, s(a, "sha")));
                JSONObject o = GitStore.commitJson(c);
                JSONArray parents = new JSONArray();
                for (RevCommit p : c.getParents()) parents.put(p.getName());
                o.put("parents", parents);
                JSONObject d = GitStore.diff(r, c.getParentCount() > 0 ? c.getParent(0).getId() : null, c.getId(), !a.has("include_diff") || b(a, "include_diff"));
                o.put("files", d.get("files"));
                if (d.has("diff")) o.put("diff", d.get("diff"));
                return o;
            }
        }));

        def("compare", "Compare deux références (base...head) : commits d'avance, fichiers, diff.", "r", new String[][]{REPO, OWNER,
                {"base", "s", "Référence de base.", "1"}, {"head", "s", "Référence comparée.", "1"}, {"include_diff", "b", "Inclure le diff."}}, a -> withRepo(a, (r, id) ->
                compare(r, GitStore.need(r, s(a, "base")), GitStore.need(r, s(a, "head")), !a.has("include_diff") || b(a, "include_diff"))));

        def("list_tags", "Liste les tags.", "r", new String[][]{REPO, OWNER}, a -> withRepo(a, (r, id) -> {
            JSONArray out = new JSONArray();
            try (RevWalk rw = new RevWalk(r)) {
                for (Ref ref : r.getRefDatabase().getRefsByPrefix(Constants.R_TAGS)) {
                    RevObject obj = rw.parseAny(ref.getObjectId());
                    JSONObject t = new JSONObject().put("name", Repository.shortenRefName(ref.getName()));
                    if (obj instanceof RevTag) t.put("message", ((RevTag) obj).getShortMessage());
                    t.put("commit", rw.peel(obj).getName());
                    out.put(t);
                }
            }
            return out;
        }));

        def("create_tag", "Crée un tag (annoté si un message est donné).", "", new String[][]{REPO, OWNER,
                {"tag", "s", "Nom du tag (ex. v1.0.0).", "1"}, {"ref", "s", "Commit ou branche."}, {"message", "s", "Message."}}, a -> withRepo(a, (r, id) ->
                createTag(r, s(a, "tag"), refOr(r, a, "ref"), s(a, "message"))));
    }

    JSONObject compare(Repository r, ObjectId base, ObjectId head, boolean patch) throws Exception {
        ObjectId mb = GitStore.mergeBase(r, base, head);
        JSONArray commits = new JSONArray();
        for (RevCommit c : GitStore.range(r, base, head, 250)) commits.put(GitStore.commitJson(c));
        int behind = GitStore.range(r, head, base, 10000).size();
        JSONObject d = GitStore.diff(r, mb != null ? mb : base, head, patch);
        JSONObject o = new JSONObject().put("base", base.getName()).put("head", head.getName()).put("merge_base", mb == null ? JSONObject.NULL : mb.getName())
                .put("ahead_by", commits.length()).put("behind_by", behind).put("commits", commits).put("files", d.get("files"));
        if (d.has("diff")) o.put("diff", d.get("diff"));
        return o;
    }

    JSONObject createTag(Repository r, String tag, String ref, String message) throws Exception {
        if (!Repository.isValidRefName(Constants.R_TAGS + tag)) throw new Err("Nom de tag invalide : " + tag);
        if (r.exactRef(Constants.R_TAGS + tag) != null) throw new Err("Le tag " + tag + " existe déjà.");
        ObjectId c = GitStore.need(r, ref);
        try (Git g = new Git(r); RevWalk rw = new RevWalk(r)) {
            org.eclipse.jgit.api.TagCommand tc = g.tag().setName(tag).setObjectId(rw.parseCommit(c));
            if (message != null && !message.isEmpty()) tc.setMessage(message).setAnnotated(true).setTagger(st.person()); else tc.setAnnotated(false);
            tc.call();
        }
        return new JSONObject().put("tag", tag).put("commit", c.getName());
    }

    // ---------- Tickets ----------

    JSONObject find(JSONObject m, String kind, int number) throws Exception {
        JSONArray arr = m.getJSONArray(kind);
        for (int x = 0; x < arr.length(); x++) if (arr.getJSONObject(x).getInt("number") == number) return arr.getJSONObject(x);
        throw new Err((kind.equals("issues") ? "Ticket" : "Pull request") + " #" + number + " introuvable.");
    }

    static JSONObject summary(JSONObject it) throws Exception {
        JSONObject o = new JSONObject(it.toString());
        o.remove("body");
        o.put("comments", it.optJSONArray("comments") == null ? 0 : it.getJSONArray("comments").length());
        if (it.has("reviews")) o.put("reviews", it.getJSONArray("reviews").length());
        return o;
    }

    JSONObject comment(JSONObject it, String body) throws Exception {
        JSONArray cs = it.getJSONArray("comments");
        JSONObject c = new JSONObject().put("id", cs.length() + 1).put("author", Auth.current(gix).name).put("body", body).put("created_at", GitStore.now());
        cs.put(c);
        it.put("updated_at", c.get("created_at"));
        return c;
    }

    JSONArray filter(JSONArray arr, JSONObject a) throws Exception {
        String state = s(a, "state", "open");
        List<String> labels = strs(a, "labels");
        String q = s(a, "query", "").toLowerCase(Locale.ROOT);
        JSONArray out = new JSONArray();
        for (int x = arr.length() - 1; x >= 0; x--) {
            JSONObject it = arr.getJSONObject(x);
            if (!state.equals("all") && !state.equals(it.optString("state"))) continue;
            boolean ok = true;
            JSONArray il = it.optJSONArray("labels");
            for (String l : labels) { boolean has = false; if (il != null) for (int y = 0; y < il.length(); y++) if (l.equals(il.optString(y))) has = true; ok &= has; }
            if (!ok) continue;
            if (!q.isEmpty() && !(it.optString("title") + "\n" + it.optString("body")).toLowerCase(Locale.ROOT).contains(q)) continue;
            out.put(summary(it));
            if (out.length() >= i(a, "limit", 50)) break;
        }
        return out;
    }

    private static final String[] STATE = {"state", "e:open|closed|merged|all", "État (défaut : open)."};

    private void registerIssues() {
        def("create_issue", "Ouvre un ticket (bug, idée, tâche).", "", new String[][]{REPO, OWNER, {"title", "s", "Titre.", "1"},
                {"body", "s", "Description (Markdown)."}, {"labels", "as", "Étiquettes."}, {"assignees", "as", "Assignés."}, {"milestone", "s", "Jalon (titre)."}}, a -> {
            GitStore.Id id = id(a);
            if (!st.exists(id)) throw new Err("Dépôt introuvable : " + id.full());
            return st.updateMeta(id, m -> {
                int n = m.getInt("next_number");
                m.put("next_number", n + 1);
                JSONObject it = new JSONObject().put("number", n).put("title", s(a, "title")).put("body", s(a, "body", "")).put("state", "open")
                        .put("labels", jarr(strs(a, "labels"))).put("assignees", jarr(strs(a, "assignees"))).put("milestone", s(a, "milestone", "")).put("author", Auth.current(gix).name)
                        .put("created_at", GitStore.now()).put("updated_at", GitStore.now()).put("comments", new JSONArray());
                m.getJSONArray("issues").put(it);
                return summary(it);
            });
        });

        def("list_issues", "Liste les tickets.", "r", new String[][]{REPO, OWNER, STATE, {"labels", "as", "Étiquettes (toutes requises)."},
                {"query", "s", "Texte recherché."}, {"limit", "i", "Maximum."}}, a -> filter(st.readMeta(id(a)).getJSONArray("issues"), a));

        def("get_issue", "Lit un ticket et ses commentaires.", "r", new String[][]{REPO, OWNER, {"number", "i", "Numéro.", "1"}}, a ->
                find(st.readMeta(id(a)), "issues", a.getInt("number")));

        def("update_issue", "Modifie un ticket : titre, description, état, étiquettes, assignés.", "", new String[][]{REPO, OWNER,
                {"number", "i", "Numéro.", "1"}, {"title", "s", "Titre."}, {"body", "s", "Description."}, {"state", "e:open|closed", "État."},
                {"labels", "as", "Étiquettes."}, {"assignees", "as", "Assignés."}, {"milestone", "s", "Jalon (vide pour retirer)."},
                {"locked", "b", "Verrouiller la conversation."}}, a -> st.updateMeta(id(a), m -> {
            JSONObject it = find(m, "issues", a.getInt("number"));
            if (a.has("locked")) it.put("locked", a.getBoolean("locked"));
            for (String k : new String[]{"title", "body", "milestone"}) if (a.has(k)) it.put(k, a.getString(k));
            for (String k : new String[]{"labels", "assignees"}) if (a.has(k)) it.put(k, a.getJSONArray(k));
            if (a.has("state") && !a.getString("state").equals(it.optString("state"))) {
                it.put("state", a.getString("state"));
                it.put("closed_at", "closed".equals(a.getString("state")) ? GitStore.now() : JSONObject.NULL);
            }
            it.put("updated_at", GitStore.now());
            return summary(it);
        }));

        def("add_issue_comment", "Ajoute un commentaire à un ticket ou une pull request.", "", new String[][]{REPO, OWNER,
                {"number", "i", "Numéro.", "1"}, {"body", "s", "Commentaire.", "1"}}, a -> st.updateMeta(id(a), m -> {
            JSONObject it;
            try { it = find(m, "issues", a.getInt("number")); } catch (Err e) { it = find(m, "pulls", a.getInt("number")); }
            if (it.optBoolean("locked") && !Auth.current(gix).can("admin")) throw new Err("Conversation verrouillée.");
            return comment(it, s(a, "body"));
        }));
    }

    // ---------- Pull requests ----------

    ObjectId prHead(Repository r, GitStore.Id id, JSONObject pr) throws Exception {
        String headRepo = pr.optString("head_repo", id.full());
        String ref = "refs/pull/" + pr.getInt("number") + "/head";
        ObjectId sha;
        if (!headRepo.equals(id.full())) {
            GitStore.Id src = st.id(null, headRepo);
            sha = null;
            if (st.exists(src)) try (Repository sr = st.open(src)) {
                ObjectId h = GitStore.branchHead(sr, pr.getString("head"));
                if (h != null) {
                    try (Git g = new Git(r)) {
                        g.fetch().setRemote(st.gitDir(src).getAbsolutePath()).setRefSpecs("+" + Constants.R_HEADS + pr.getString("head") + ":" + ref).call();
                    }
                }
            }
            sha = GitStore.resolve(r, ref);
        } else {
            sha = GitStore.branchHead(r, pr.getString("head"));
            if (sha != null) GitStore.setRef(r, ref, sha, null, true);
            else sha = GitStore.resolve(r, ref);
        }
        if (sha == null) throw new Err("La branche source " + pr.getString("head") + " n'existe plus.");
        return sha;
    }

    private void registerPulls() {
        def("create_pull_request", "Ouvre une pull request d'une branche (ou « propriétaire/dépôt:branche » d'un fork) vers une autre.", "", new String[][]{REPO, OWNER,
                {"title", "s", "Titre.", "1"}, {"head", "s", "Branche source.", "1"}, {"base", "s", "Branche cible (défaut : branche par défaut)."},
                {"body", "s", "Description."}, {"draft", "b", "Brouillon."}}, a -> withRepo(a, (r, id) -> {
            String head = s(a, "head"), headRepo = id.full();
            if (head.contains(":")) { String[] p = head.split(":", 2); headRepo = st.id(null, p[0]).full(); head = p[1]; }
            String base = refOr(r, a, "base");
            ObjectId baseSha = GitStore.need(r, Constants.R_HEADS + base);
            final String fh = head, fhr = headRepo;
            return st.updateMeta(id, m -> {
                JSONArray pulls = m.getJSONArray("pulls");
                for (int x = 0; x < pulls.length(); x++) {
                    JSONObject p = pulls.getJSONObject(x);
                    if ("open".equals(p.optString("state")) && fh.equals(p.optString("head")) && fhr.equals(p.optString("head_repo")) && base.equals(p.optString("base")))
                        throw new Err("Une pull request ouverte existe déjà pour ces branches (#" + p.getInt("number") + ").");
                }
                int n = m.getInt("next_number");
                JSONObject pr = new JSONObject().put("number", n).put("title", s(a, "title")).put("body", s(a, "body", "")).put("state", "open")
                        .put("draft", b(a, "draft")).put("head", fh).put("head_repo", fhr).put("base", base).put("labels", new JSONArray())
                        .put("author", Auth.current(gix).name).put("created_at", GitStore.now()).put("updated_at", GitStore.now())
                        .put("comments", new JSONArray()).put("reviews", new JSONArray());
                ObjectId h = prHead(r, id, pr);
                if (GitStore.isAncestor(r, h, baseSha)) throw new Err("Aucun commit à fusionner : " + fh + " est déjà contenu dans " + base + ".");
                pr.put("head_sha", h.getName());
                m.put("next_number", n + 1);
                pulls.put(pr);
                JSONObject out = summary(pr);
                JSONObject mc = GitStore.mergeCheck(r, baseSha, h);
                mc.remove("tree");
                for (java.util.Iterator<String> it = mc.keys(); it.hasNext(); ) { String k = it.next(); out.put(k, mc.get(k)); }
                return out;
            });
        }));

        def("list_pull_requests", "Liste les pull requests.", "r", new String[][]{REPO, OWNER, STATE, {"query", "s", "Texte."}, {"limit", "i", "Maximum."}}, a ->
                filter(st.readMeta(id(a)).getJSONArray("pulls"), a));

        def("get_pull_request", "Détail d'une pull request : commits, fichiers, diff, conflits, revues, commentaires.", "r", new String[][]{REPO, OWNER,
                {"number", "i", "Numéro.", "1"}, {"include_diff", "b", "Inclure le diff (défaut : vrai)."}}, a -> withRepo(a, (r, id) -> {
            JSONObject pr = find(st.readMeta(id), "pulls", a.getInt("number"));
            if (!"open".equals(pr.optString("state"))) return pr;
            ObjectId h = prHead(r, id, pr);
            ObjectId base = GitStore.need(r, Constants.R_HEADS + pr.getString("base"));
            JSONObject cmp = compare(r, base, h, !a.has("include_diff") || b(a, "include_diff"));
            JSONObject mc = GitStore.mergeCheck(r, base, h);
            mc.remove("tree");
            pr.put("head_sha", h.getName());
            for (java.util.Iterator<String> it = mc.keys(); it.hasNext(); ) { String k = it.next(); pr.put(k, mc.get(k)); }
            pr.put("commits", cmp.get("commits")).put("files", cmp.get("files")).put("checks", ToolsMore.latestChecks(st.readMeta(id), h.getName()));
            if (cmp.has("diff")) pr.put("diff", cmp.get("diff"));
            return pr;
        }));

        def("update_pull_request", "Modifie une pull request : titre, description, cible, brouillon, fermer/rouvrir.", "", new String[][]{REPO, OWNER,
                {"number", "i", "Numéro.", "1"}, {"title", "s", "Titre."}, {"body", "s", "Description."}, {"base", "s", "Branche cible."},
                {"draft", "b", "Brouillon."}, {"state", "e:open|closed", "État."}}, a -> st.updateMeta(id(a), m -> {
            JSONObject pr = find(m, "pulls", a.getInt("number"));
            if ("merged".equals(pr.optString("state"))) throw new Err("Pull request déjà fusionnée.");
            for (String k : new String[]{"title", "body", "base", "state"}) if (a.has(k)) pr.put(k, a.getString(k));
            if (a.has("draft")) pr.put("draft", a.getBoolean("draft"));
            pr.put("updated_at", GitStore.now());
            return summary(pr);
        }));

        def("create_review", "Revue de pull request : approuver, demander des changements ou commenter.", "", new String[][]{REPO, OWNER,
                {"number", "i", "Numéro.", "1"}, {"event", "e:APPROVE|REQUEST_CHANGES|COMMENT", "Type.", "1"}, {"body", "s", "Commentaire."},
                {"comments", "ac", "Commentaires sur des lignes : {path, line?, body}."}}, a -> st.updateMeta(id(a), m -> {
            JSONObject pr = find(m, "pulls", a.getInt("number"));
            JSONArray rv = pr.getJSONArray("reviews");
            JSONObject x = new JSONObject().put("id", rv.length() + 1).put("author", Auth.current(gix).name).put("state", s(a, "event")).put("body", s(a, "body", ""))
                    .put("comments", a.optJSONArray("comments") == null ? new JSONArray() : a.getJSONArray("comments")).put("created_at", GitStore.now());
            rv.put(x);
            return x;
        }));

        def("merge_pull_request", "Fusionne une pull request (merge, squash, ou rebase en avance rapide). « Fixes #n » ferme le ticket n.", "", new String[][]{REPO, OWNER,
                {"number", "i", "Numéro.", "1"}, {"merge_method", "e:merge|squash|rebase", "Méthode (défaut : merge)."},
                {"commit_title", "s", "Titre du commit."}, {"delete_branch", "b", "Supprimer la branche source."}}, a -> withRepo(a, (r, id) -> st.updateMeta(id, m -> {
            JSONObject pr = find(m, "pulls", a.getInt("number"));
            if (!"open".equals(pr.optString("state"))) throw new Err("La pull request n'est pas ouverte (" + pr.optString("state") + ").");
            if (pr.optBoolean("draft")) throw new Err("Pull request en brouillon.");
            ObjectId h = prHead(r, id, pr);
            String baseRef = Constants.R_HEADS + pr.getString("base");
            ObjectId base = GitStore.need(r, baseRef);
            JSONObject mc = GitStore.mergeCheck(r, base, h);
            if (!mc.getBoolean("mergeable")) {
                if ("conflicts".equals(mc.getString("merge_state"))) throw new Err("Conflits dans : " + mc.getJSONArray("conflicts").join(", ").replace("\"", "") + ". Résolvez-les sur la branche " + pr.getString("head") + ".");
                throw new Err("Rien à fusionner.");
            }
            JSONObject prot = m.optJSONObject("protection") == null ? null : m.getJSONObject("protection").optJSONObject(pr.getString("base"));
            if (m.optBoolean("archived")) throw new Err("Dépôt archivé (lecture seule).");
            if (prot != null) {
                int need = prot.optInt("required_approvals", 0), got = 0;
                JSONArray rvs = pr.getJSONArray("reviews");
                java.util.Map<String, String> lastByAuthor = new java.util.HashMap<>();
                for (int x = 0; x < rvs.length(); x++) if (!"COMMENT".equals(rvs.getJSONObject(x).optString("state"))) lastByAuthor.put(rvs.getJSONObject(x).optString("author"), rvs.getJSONObject(x).optString("state"));
                for (String v : lastByAuthor.values()) if ("APPROVE".equals(v)) got++;
                if (lastByAuthor.containsValue("REQUEST_CHANGES")) throw new Err("Des changements ont été demandés dans une revue.");
                if (got < need) throw new Err("Branche protégée : " + need + " approbation(s) requise(s), " + got + " obtenue(s).");
                JSONArray req = prot.optJSONArray("required_checks");
                if (req != null && req.length() > 0) {
                    JSONArray runs = ToolsMore.latestChecks(m, h.getName());
                    for (int x = 0; x < req.length(); x++) {
                        String want = req.getString(x); String concl = null;
                        for (int y = 0; y < runs.length(); y++) if (want.equals(runs.getJSONObject(y).optString("name"))) concl = runs.getJSONObject(y).optString("conclusion");
                        if (!"success".equals(concl)) throw new Err("Vérification requise « " + want + " » : " + (concl == null ? "absente" : concl) + " sur " + h.getName().substring(0, 7) + ".");
                    }
                }
            }
            String method = s(a, "merge_method", "merge");
            int n = pr.getInt("number");
            ObjectId commit;
            if (method.equals("rebase")) {
                if (!"fast_forward".equals(mc.getString("merge_state"))) throw new Err("« rebase » impossible : la branche cible a avancé. Utilisez merge ou squash.");
                commit = h;
            } else {
                ObjectId tree = ObjectId.fromString(mc.getString("tree"));
                if (method.equals("squash")) {
                    StringBuilder msg = new StringBuilder(s(a, "commit_title", pr.getString("title") + " (#" + n + ")")).append("\n\n");
                    for (RevCommit c : GitStore.range(r, base, h, 200)) msg.append("* ").append(c.getShortMessage()).append("\n");
                    commit = st.writeCommit(r, tree, msg.toString(), base);
                } else {
                    String src = pr.getString("head_repo").equals(id.full()) ? pr.getString("head") : pr.getString("head_repo") + ":" + pr.getString("head");
                    commit = st.writeCommit(r, tree, s(a, "commit_title", "Merge pull request #" + n + " from " + src) + "\n\n" + pr.getString("title"), base, h);
                }
            }
            GitStore.setRef(r, baseRef, commit, base, false);
            pr.put("state", "merged").put("merged_at", GitStore.now()).put("closed_at", GitStore.now()).put("merge_commit", commit.getName())
                    .put("merge_method", method).put("head_sha", h.getName()).put("updated_at", GitStore.now());
            if (b(a, "delete_branch") && pr.getString("head_repo").equals(id.full()) && !pr.getString("head").equals(GitStore.defaultBranch(r)))
                GitStore.deleteRef(r, Constants.R_HEADS + pr.getString("head"));
            JSONArray closed = new JSONArray();
            Matcher mm = Pattern.compile("(?i)\\b(?:fix(?:es|ed)?|close[sd]?|resolve[sd]?|corrige|ferme|résout)\\s+#(\\d+)").matcher(pr.getString("title") + "\n" + pr.optString("body"));
            while (mm.find()) {
                try {
                    JSONObject it = find(m, "issues", Integer.parseInt(mm.group(1)));
                    if ("open".equals(it.optString("state"))) {
                        it.put("state", "closed").put("closed_at", GitStore.now());
                        comment(it, "Fermé par la pull request #" + n + ".");
                        closed.put(it.getInt("number"));
                    }
                } catch (Err ignored) { }
            }
            return new JSONObject().put("merged", true).put("number", n).put("method", method).put("commit", commit.getName()).put("closed_issues", closed);
        })));
    }

    // ---------- Versions ----------

    JSONObject attach(GitStore.Id id, String tag, String name, byte[] data) throws Exception {
        File dir = st.releaseDir(id, tag);
        dir.mkdirs();
        File f = new File(dir, new File(name).getName());
        Files.write(f.toPath(), data);
        return new JSONObject().put("name", f.getName()).put("size", f.length()).put("uploaded_at", GitStore.now())
                .put("download", "/download/release/" + id.owner + "/" + id.repo + "/" + dir.getName() + "/" + f.getName());
    }

    byte[] apkBytes(String name) throws Exception {
        File f = new File(st.apks, new File(name).getName());
        if (!f.isFile()) throw new Err("APK introuvable : " + name);
        return Files.readAllBytes(f.toPath());
    }

    private void registerReleases() {
        def("create_release", "Publie une version : crée le tag si besoin, notes générées depuis les commits, et joint des APK de la boîte du téléphone.", "", new String[][]{REPO, OWNER,
                {"tag", "s", "Tag (ex. v1.0.0).", "1"}, {"name", "s", "Nom."}, {"body", "s", "Notes (vide = générées)."},
                {"target", "s", "Branche ou commit si le tag n'existe pas."}, {"prerelease", "b", "Pré-version."},
                {"apks", "as", "Noms d'APK de la boîte (list_apks) à joindre."}}, a -> withRepo(a, (r, id) -> {
            String tag = s(a, "tag");
            if (r.exactRef(Constants.R_TAGS + tag) == null) createTag(r, tag, refOr(r, a, "target"), s(a, "name", tag));
            ObjectId c = GitStore.need(r, Constants.R_TAGS + tag);
            String body = s(a, "body");
            if (body == null || body.isEmpty()) {
                StringBuilder sb = new StringBuilder("## Changements\n\n");
                JSONArray rels = st.readMeta(id).getJSONArray("releases");
                ObjectId prev = rels.length() > 0 ? GitStore.resolve(r, Constants.R_TAGS + rels.getJSONObject(rels.length() - 1).getString("tag")) : null;
                for (RevCommit rc : GitStore.range(r, prev, c, 200)) if (rc.getParentCount() < 2) sb.append("- ").append(rc.getShortMessage()).append(" (").append(rc.getName(), 0, 7).append(")\n");
                body = sb.toString();
            }
            final String fb = body;
            return st.updateMeta(id, m -> {
                JSONArray rels = m.getJSONArray("releases");
                for (int x = 0; x < rels.length(); x++) if (tag.equals(rels.getJSONObject(x).getString("tag"))) throw new Err("Une version existe déjà pour " + tag + ".");
                JSONObject rel = new JSONObject().put("tag", tag).put("name", s(a, "name", tag)).put("body", fb).put("commit", c.getName())
                        .put("prerelease", b(a, "prerelease")).put("author", Auth.current(gix).name).put("created_at", GitStore.now());
                JSONArray assets = new JSONArray();
                for (String n : strs(a, "apks")) assets.put(attach(id, tag, n, apkBytes(n)));
                rel.put("assets", assets);
                rels.put(rel);
                return rel;
            });
        }));

        def("list_releases", "Liste les versions.", "r", new String[][]{REPO, OWNER}, a -> {
            JSONArray rels = st.readMeta(id(a)).getJSONArray("releases");
            JSONArray out = new JSONArray();
            for (int x = rels.length() - 1; x >= 0; x--) { JSONObject o = new JSONObject(rels.getJSONObject(x).toString()); o.remove("body"); out.put(o); }
            return out;
        });

        def("get_release", "Lit une version par tag (ou « latest »).", "r", new String[][]{REPO, OWNER, {"tag", "s", "Tag ou « latest ».", "1"}}, a -> {
            JSONArray rels = st.readMeta(id(a)).getJSONArray("releases");
            for (int x = rels.length() - 1; x >= 0; x--) {
                JSONObject rel = rels.getJSONObject(x);
                if ("latest".equals(s(a, "tag")) ? !rel.optBoolean("prerelease") : s(a, "tag").equals(rel.getString("tag"))) return rel;
            }
            throw new Err("Version introuvable.");
        });

        def("upload_release_asset", "Joint un fichier à une version : un APK de la boîte, ou un contenu base64.", "", new String[][]{REPO, OWNER,
                {"tag", "s", "Tag.", "1"}, {"apk", "s", "Nom d'un APK de la boîte."}, {"name", "s", "Nom du fichier (avec content_base64)."},
                {"content_base64", "s", "Contenu du fichier en base64."}}, a -> {
            GitStore.Id id = id(a);
            return st.updateMeta(id, m -> {
                JSONArray rels = m.getJSONArray("releases");
                for (int x = 0; x < rels.length(); x++) {
                    JSONObject rel = rels.getJSONObject(x);
                    if (!s(a, "tag").equals(rel.getString("tag"))) continue;
                    JSONObject asset = s(a, "apk") != null ? attach(id, s(a, "tag"), s(a, "apk"), apkBytes(s(a, "apk")))
                            : attach(id, s(a, "tag"), s(a, "name", "fichier"), Base64.decode(s(a, "content_base64", ""), Base64.DEFAULT));
                    rel.getJSONArray("assets").put(asset);
                    return asset;
                }
                throw new Err("Version introuvable.");
            });
        });

        def("delete_release", "Supprime une version et ses fichiers (le tag est gardé sauf delete_tag).", "d", new String[][]{REPO, OWNER,
                {"tag", "s", "Tag.", "1"}, {"delete_tag", "b", "Supprimer aussi le tag."}}, a -> withRepo(a, (r, id) -> {
            st.updateMeta(id, m -> {
                JSONArray rels = m.getJSONArray("releases"), keep = new JSONArray();
                for (int x = 0; x < rels.length(); x++) if (!s(a, "tag").equals(rels.getJSONObject(x).getString("tag"))) keep.put(rels.get(x));
                return m.put("releases", keep);
            });
            GitStore.rm(st.releaseDir(id, s(a, "tag")));
            if (b(a, "delete_tag") && r.exactRef(Constants.R_TAGS + s(a, "tag")) != null) GitStore.deleteRef(r, Constants.R_TAGS + s(a, "tag"));
            return new JSONObject().put("deleted", s(a, "tag"));
        }));
    }

    // ---------- APK et téléphone ----------

    JSONObject apkInfo(File f) throws Exception {
        PackageManager pm = gix.app.getPackageManager();
        PackageInfo pi = pm.getPackageArchiveInfo(f.getAbsolutePath(), PackageManager.GET_PERMISSIONS);
        JSONObject o = new JSONObject().put("name", f.getName()).put("size", f.length()).put("modified", GitStore.iso(new java.util.Date(f.lastModified())));
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] dig = md.digest(Files.readAllBytes(f.toPath()));
        StringBuilder sb = new StringBuilder();
        for (byte x : dig) sb.append(String.format("%02x", x));
        o.put("sha256", sb.toString());
        if (pi == null) return o.put("valid", false);
        o.put("valid", true).put("package", pi.packageName).put("versionName", pi.versionName)
                .put("versionCode", Build.VERSION.SDK_INT >= 28 ? pi.getLongVersionCode() : pi.versionCode);
        if (pi.applicationInfo != null) {
            pi.applicationInfo.sourceDir = f.getAbsolutePath();
            pi.applicationInfo.publicSourceDir = f.getAbsolutePath();
            o.put("label", String.valueOf(pi.applicationInfo.loadLabel(pm)));
            o.put("minSdk", Build.VERSION.SDK_INT >= 24 ? pi.applicationInfo.minSdkVersion : JSONObject.NULL);
            o.put("targetSdk", pi.applicationInfo.targetSdkVersion);
        }
        o.put("permissions", pi.requestedPermissions == null ? new JSONArray() : new JSONArray(pi.requestedPermissions));
        try {
            PackageInfo inst = pm.getPackageInfo(pi.packageName, 0);
            o.put("installed_version", inst.versionName);
        } catch (PackageManager.NameNotFoundException e) { o.put("installed_version", JSONObject.NULL); }
        return o;
    }

    File apkFile(JSONObject a) {
        String n = s(a, "apk");
        if (n == null) {
            File newest = null;
            File[] fs = st.apks.listFiles((d, x) -> x.endsWith(".apk"));
            if (fs != null) for (File f : fs) if (newest == null || f.lastModified() > newest.lastModified()) newest = f;
            if (newest == null) throw new Err("Aucun APK sur le téléphone : envoyez-en un avec upload_apk.");
            return newest;
        }
        File f = new File(st.apks, new File(n).getName());
        if (!f.isFile()) throw new Err("APK introuvable : " + n);
        return f;
    }

    private void registerApk() {
        def("device_info", "Informations sur le téléphone et sur GIXCLOUD (version d'Android, adresses, espace libre).", "r", new String[][]{}, a ->
                new JSONObject().put("app", "GIXCLOUD " + Gix.VERSION).put("model", Build.MANUFACTURER + " " + Build.MODEL)
                        .put("android", Build.VERSION.RELEASE).put("sdk", Build.VERSION.SDK_INT).put("abis", new JSONArray(Build.SUPPORTED_ABIS))
                        .put("ips", jarr(Gix.localIps())).put("port", gix.port()).put("free_mb", gix.root.getFreeSpace() / 1048576)
                        .put("repositories", st.list().size()));

        def("list_apks", "Liste les APK stockés dans GIXCLOUD sur le téléphone.", "r", new String[][]{}, a -> {
            JSONArray out = new JSONArray();
            File[] fs = st.apks.listFiles((d, x) -> x.endsWith(".apk"));
            if (fs != null) {
                java.util.Arrays.sort(fs, (x, y) -> Long.compare(y.lastModified(), x.lastModified()));
                for (File f : fs) out.put(new JSONObject().put("name", f.getName()).put("size", f.length()).put("modified", GitStore.iso(new java.util.Date(f.lastModified()))));
            }
            return out;
        });

        def("upload_apk", "Envoie un APK au téléphone (contenu base64). Pour les gros fichiers, utilisez plutôt HTTP PUT /upload/<nom>.apk.", "", new String[][]{
                {"name", "s", "Nom du fichier (ex. monappli-1.0.apk).", "1"}, {"content_base64", "s", "Contenu de l'APK en base64.", "1"},
                {"install", "b", "Proposer l'installation tout de suite."}}, a -> {
            String n = new File(s(a, "name")).getName();
            if (!n.endsWith(".apk")) n += ".apk";
            File f = new File(st.apks, n);
            Files.write(f.toPath(), Base64.decode(s(a, "content_base64"), Base64.DEFAULT));
            JSONObject o = apkInfo(f);
            if (b(a, "install")) o.put("install", Installer.install(gix.app, f));
            return o;
        });

        def("apk_info", "Analyse un APK : paquet, version, SDK, permissions, SHA-256, version déjà installée.", "r", new String[][]{
                {"apk", "s", "Nom de l'APK (défaut : le plus récent)."}}, a -> apkInfo(apkFile(a)));

        def("install_apk", "Installe un APK sur le téléphone : Android affiche la fenêtre de confirmation à l'utilisateur.", "", new String[][]{
                {"apk", "s", "Nom de l'APK (défaut : le plus récent)."}}, a -> {
            File f = apkFile(a);
            return new JSONObject().put("apk", f.getName()).put("result", Installer.install(gix.app, f));
        });

        def("save_apk_to_downloads", "Copie un APK dans le dossier Téléchargements du téléphone (visible dans le gestionnaire de fichiers).", "", new String[][]{
                {"apk", "s", "Nom de l'APK (défaut : le plus récent)."}}, a -> new JSONObject().put("saved", Installer.toDownloads(gix.app, apkFile(a))));

        def("delete_apk", "Supprime un APK de GIXCLOUD.", "d", new String[][]{{"apk", "s", "Nom de l'APK.", "1"}}, a -> {
            File f = apkFile(a);
            if (!f.delete()) throw new Err("Suppression impossible.");
            return new JSONObject().put("deleted", f.getName());
        });

        def("list_installed_apps", "Liste les applications installées par l'utilisateur (paquet, nom, version).", "r", new String[][]{{"query", "s", "Filtrer par nom ou paquet."}}, a -> {
            PackageManager pm = gix.app.getPackageManager();
            String q = s(a, "query", "").toLowerCase(Locale.ROOT);
            JSONArray out = new JSONArray();
            for (PackageInfo pi : pm.getInstalledPackages(0)) {
                if (pi.applicationInfo == null || (pi.applicationInfo.flags & ApplicationInfo.FLAG_SYSTEM) != 0) continue;
                String label = String.valueOf(pi.applicationInfo.loadLabel(pm));
                if (!q.isEmpty() && !label.toLowerCase(Locale.ROOT).contains(q) && !pi.packageName.contains(q)) continue;
                out.put(new JSONObject().put("package", pi.packageName).put("label", label).put("version", pi.versionName));
            }
            return out;
        });

        def("launch_app", "Ouvre une application installée.", "", new String[][]{{"package", "s", "Identifiant (ex. com.moi.appli).", "1"}}, a -> {
            Intent it = gix.app.getPackageManager().getLaunchIntentForPackage(s(a, "package"));
            if (it == null) throw new Err("Application introuvable ou sans écran de lancement.");
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            gix.app.startActivity(it);
            return new JSONObject().put("launched", s(a, "package"));
        });

        def("uninstall_app", "Demande la désinstallation d'une application (l'utilisateur confirme).", "d", new String[][]{{"package", "s", "Identifiant.", "1"}}, a -> {
            Intent it = new Intent(Intent.ACTION_DELETE, android.net.Uri.parse("package:" + s(a, "package")));
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            gix.app.startActivity(it);
            return new JSONObject().put("requested", s(a, "package"));
        });
    }

    static boolean isExec(FileMode m) { return m == FileMode.EXECUTABLE_FILE; }
}
