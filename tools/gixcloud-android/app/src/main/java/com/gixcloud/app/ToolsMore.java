package com.gixcloud.app;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.PushCommand;
import org.eclipse.jgit.blame.BlameResult;
import org.eclipse.jgit.lib.Constants;
import org.eclipse.jgit.lib.ObjectId;
import org.eclipse.jgit.lib.Ref;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.lib.StoredConfig;
import org.eclipse.jgit.merge.MergeStrategy;
import org.eclipse.jgit.merge.ResolveMerger;
import org.eclipse.jgit.revwalk.RevCommit;
import org.eclipse.jgit.revwalk.RevWalk;
import org.eclipse.jgit.transport.CredentialsProvider;
import org.eclipse.jgit.transport.FetchResult;
import org.eclipse.jgit.transport.PushResult;
import org.eclipse.jgit.transport.RefSpec;
import org.eclipse.jgit.transport.RemoteRefUpdate;
import org.eclipse.jgit.transport.UsernamePasswordCredentialsProvider;
import org.eclipse.jgit.treewalk.TreeWalk;
import org.json.JSONArray;
import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/** Le reste de GitHub : jetons, activité, webhooks, protections, étiquettes, jalons, wiki, gists,
 *  Pages, discussions, projets, statuts de CI, synchronisation avec un vrai GitHub, blame, revert, cherry-pick… */
final class ToolsMore {
    private final Tools t;
    private final Gix gix;
    private final GitStore st;
    private static final String[] REPO = Tools.REPO, OWNER = Tools.OWNER;

    ToolsMore(Tools t) {
        this.t = t;
        this.gix = t.gix;
        this.st = t.st;
        tokens();
        activity();
        settings();
        labels();
        gitOps();
        remotes();
        wiki();
        gists();
        pages();
        discussions();
        projects();
        checks();
        search();
    }

    private static String s(org.json.JSONObject a, String k) { return Tools.s(a, k); }
    private static String s(org.json.JSONObject a, String k, String d) { return Tools.s(a, k, d); }
    private static int i(org.json.JSONObject a, String k, int d) { return Tools.i(a, k, d); }
    private static boolean b(org.json.JSONObject a, String k) { return Tools.b(a, k); }

    JSONObject findIn(JSONObject m, String kind, String key, Object val, String what) throws Exception {
        JSONArray arr = m.optJSONArray(kind);
        if (arr != null) for (int x = 0; x < arr.length(); x++) if (String.valueOf(val).equals(String.valueOf(arr.getJSONObject(x).opt(key)))) return arr.getJSONObject(x);
        throw new Tools.Err(what + " introuvable : " + val);
    }

    static JSONArray arr(JSONObject m, String k) throws Exception {
        JSONArray a = m.optJSONArray(k);
        if (a == null) { a = new JSONArray(); m.put(k, a); }
        return a;
    }

    static int nextId(JSONArray a, String key) {
        int mx = 0;
        for (int x = 0; x < a.length(); x++) mx = Math.max(mx, a.optJSONObject(x).optInt(key));
        return mx + 1;
    }

    List<String> urls(String suffix) {
        List<String> out = new ArrayList<>();
        List<String> ips = gix.lan() ? Gix.localIps() : new ArrayList<>();
        if (ips.isEmpty()) ips.add("127.0.0.1");
        for (String ip : ips) out.add("http://" + ip + ":" + gix.port() + suffix);
        return out;
    }

    // ---------- Jetons ----------

    private void tokens() {
        t.def("create_token", "Crée un jeton d'accès (une IA, un ordinateur ou une personne) avec une permission read, write ou admin. Le jeton n'est affiché qu'une fois.", "a", new String[][]{
                {"name", "s", "Nom (ex. Claude, Cursor, PC-salon). Sert d'auteur pour ses commits.", "1"}, {"permission", "e:read|write|admin", "Permission (défaut : write)."}}, a ->
                gix.auth.create(s(a, "name"), s(a, "permission", "write")));
        t.def("list_tokens", "Liste les jetons d'accès (sans les secrets).", "a", new String[][]{}, a -> gix.auth.list());
        t.def("revoke_token", "Révoque un jeton d'accès par son nom.", "ad", new String[][]{{"name", "s", "Nom du jeton.", "1"}}, a -> {
            if (!gix.auth.revoke(s(a, "name"))) throw new Tools.Err("Jeton introuvable : " + s(a, "name"));
            return new JSONObject().put("revoked", s(a, "name"));
        });
        t.def("whoami", "Indique avec quel jeton (nom, permission) vous êtes connecté.", "r", new String[][]{}, a -> {
            Auth.User u = Auth.current(gix);
            return new JSONObject().put("name", u.name).put("permission", u.perm);
        });
    }

    // ---------- Activité, notifications, webhooks ----------

    private void activity() {
        t.def("list_events", "Fil d'activité (push, commits, tickets, PR, fusions, versions…) d'un dépôt, ou de tous si repo est omis.", "r", new String[][]{
                {"repo", "s", "Dépôt (facultatif)."}, OWNER, {"type", "s", "Filtrer par type (push, merge_pull_request, create_issue…)."}, {"limit", "i", "Maximum (défaut 50)."}}, a -> {
            List<GitStore.Id> ids = new ArrayList<>();
            if (s(a, "repo") != null) ids.add(t.id(a)); else ids.addAll(st.list());
            List<JSONObject> all = new ArrayList<>();
            for (GitStore.Id id : ids) {
                JSONArray ev = st.readMeta(id).optJSONArray("events");
                if (ev != null) for (int x = 0; x < ev.length(); x++) {
                    JSONObject e = ev.getJSONObject(x);
                    if (s(a, "type") == null || s(a, "type").equals(e.optString("type"))) all.add(e);
                }
            }
            all.sort((x, y) -> y.optString("created_at").compareTo(x.optString("created_at")));
            JSONArray out = new JSONArray();
            for (JSONObject e : all) { out.put(e); if (out.length() >= i(a, "limit", 50)) break; }
            return out;
        });

        t.def("list_notifications", "Notifications : activité de tous les dépôts depuis la dernière lecture (mark_notifications_read).", "r", new String[][]{{"limit", "i", "Maximum (défaut 50)."}}, a -> {
            String since = gix.prefs.getString("notif_read_" + Auth.current(gix).name, "");
            JSONArray out = new JSONArray();
            List<JSONObject> all = new ArrayList<>();
            for (GitStore.Id id : st.list()) {
                JSONArray ev = st.readMeta(id).optJSONArray("events");
                if (ev != null) for (int x = 0; x < ev.length(); x++) if (ev.getJSONObject(x).optString("created_at").compareTo(since) > 0) all.add(ev.getJSONObject(x));
            }
            all.sort((x, y) -> y.optString("created_at").compareTo(x.optString("created_at")));
            for (JSONObject e : all) { out.put(e); if (out.length() >= i(a, "limit", 50)) break; }
            return new JSONObject().put("unread", all.size()).put("notifications", out);
        });

        t.def("mark_notifications_read", "Marque toutes les notifications comme lues.", "r", new String[][]{}, a -> {
            gix.prefs.edit().putString("notif_read_" + Auth.current(gix).name, GitStore.now()).apply();
            return new JSONObject().put("read", true);
        });

        t.def("create_webhook", "Ajoute un webhook : à chaque évènement, GIXCLOUD envoie un POST JSON à l'URL (signé X-Hub-Signature-256 si secret).", "a", new String[][]{REPO, OWNER,
                {"url", "s", "URL à appeler (ex. http://192.168.1.10:9000/hook).", "1"}, {"events", "as", "Types d'évènements (vide ou « * » = tous)."}, {"secret", "s", "Secret de signature."}}, a ->
                st.updateMeta(t.id(a), m -> {
                    JSONArray h = arr(m, "webhooks");
                    JSONObject w = new JSONObject().put("id", nextId(h, "id")).put("url", s(a, "url")).put("events", Tools.jarr(Tools.strs(a, "events")))
                            .put("secret", s(a, "secret", "")).put("active", true).put("created_at", GitStore.now());
                    h.put(w);
                    return w;
                }));
        t.def("list_webhooks", "Liste les webhooks d'un dépôt.", "r", new String[][]{REPO, OWNER}, a -> {
            JSONArray h = st.readMeta(t.id(a)).optJSONArray("webhooks"), out = new JSONArray();
            if (h != null) for (int x = 0; x < h.length(); x++) { JSONObject w = new JSONObject(h.getJSONObject(x).toString()); if (!w.optString("secret").isEmpty()) w.put("secret", "••••"); out.put(w); }
            return out;
        });
        t.def("delete_webhook", "Supprime un webhook.", "ad", new String[][]{REPO, OWNER, {"id", "i", "Numéro du webhook.", "1"}}, a -> st.updateMeta(t.id(a), m -> {
            JSONArray h = arr(m, "webhooks"), keep = new JSONArray();
            for (int x = 0; x < h.length(); x++) if (h.getJSONObject(x).optInt("id") != a.getInt("id")) keep.put(h.get(x));
            m.put("webhooks", keep);
            return new JSONObject().put("deleted", a.getInt("id"));
        }));
    }

    // ---------- Réglages du dépôt, protections, étoiles, liens ----------

    private void settings() {
        t.def("set_repository_settings", "Réglages du dépôt : archivé (lecture seule), sujets, site web, visibilité indicative.", "a", new String[][]{REPO, OWNER,
                {"archived", "b", "Archiver (plus aucune écriture possible)."}, {"topics", "as", "Sujets."}, {"homepage", "s", "Site web."}, {"private", "b", "Privé."}}, a ->
                st.updateMeta(t.id(a), m -> {
                    if (a.has("archived")) m.put("archived", a.getBoolean("archived"));
                    if (a.has("topics")) m.put("topics", a.getJSONArray("topics"));
                    if (a.has("homepage")) m.put("homepage", s(a, "homepage"));
                    if (a.has("private")) m.put("private", a.getBoolean("private"));
                    return new JSONObject().put("archived", m.optBoolean("archived")).put("topics", m.optJSONArray("topics")).put("homepage", m.optString("homepage")).put("private", m.optBoolean("private", true));
                }));

        t.def("star_repository", "Ajoute ou retire une étoile (favori).", "", new String[][]{REPO, OWNER, {"unstar", "b", "Retirer l'étoile."}}, a -> st.updateMeta(t.id(a), m -> {
            JSONArray sg = arr(m, "stargazers");
            String me = Auth.current(gix).name;
            JSONArray keep = new JSONArray();
            for (int x = 0; x < sg.length(); x++) if (!me.equals(sg.optString(x))) keep.put(sg.optString(x));
            if (!b(a, "unstar")) keep.put(me);
            m.put("stargazers", keep);
            return new JSONObject().put("stars", keep.length()).put("starred", !b(a, "unstar"));
        }));

        t.def("list_starred", "Dépôts mis en favoris par le jeton courant.", "r", new String[][]{}, a -> {
            JSONArray out = new JSONArray();
            String me = Auth.current(gix).name;
            for (GitStore.Id id : st.list()) {
                JSONArray sg = st.readMeta(id).optJSONArray("stargazers");
                if (sg != null) for (int x = 0; x < sg.length(); x++) if (me.equals(sg.optString(x))) out.put(id.full());
            }
            return out;
        });

        t.def("get_clone_urls", "Adresses pour cloner/pousser avec git (git clone, git push) et télécharger le ZIP ou les fichiers bruts.", "r", new String[][]{REPO, OWNER, {"ref", "s", "Branche ou tag pour le ZIP."}}, a -> {
            GitStore.Id id = t.id(a);
            if (!st.exists(id)) throw new Tools.Err("Dépôt introuvable : " + id.full());
            String ref = s(a, "ref", "");
            return new JSONObject().put("git", Tools.jarr(urls("/git/" + id.owner + "/" + id.repo + ".git")))
                    .put("clone_command", "git clone " + urls("/git/" + id.owner + "/" + id.repo + ".git").get(0))
                    .put("credentials", "Identifiant : n'importe lequel (ex. gix) — mot de passe : votre jeton GIXCLOUD")
                    .put("zip", urls("/archive/" + id.owner + "/" + id.repo + "/" + (ref.isEmpty() ? "" : ref) + ".zip").get(0))
                    .put("raw", urls("/raw/" + id.owner + "/" + id.repo + "/<ref>/<chemin>").get(0));
        });

        t.def("set_branch_protection", "Protège une branche : PR obligatoire, nombre d'approbations, statuts de CI requis, push forcé et suppression interdits.", "a", new String[][]{REPO, OWNER,
                {"branch", "s", "Branche.", "1"}, {"require_pull_request", "b", "Interdire les commits directs (PR obligatoire)."},
                {"required_approvals", "i", "Approbations nécessaires pour fusionner."}, {"required_checks", "as", "Noms des statuts de CI devant réussir (create_check_run)."},
                {"allow_force_push", "b", "Autoriser le push forcé."}, {"allow_deletion", "b", "Autoriser la suppression."}}, a -> st.updateMeta(t.id(a), m -> {
            JSONObject prot = m.optJSONObject("protection");
            if (prot == null) { prot = new JSONObject(); m.put("protection", prot); }
            JSONObject p = new JSONObject().put("require_pull_request", b(a, "require_pull_request")).put("required_approvals", i(a, "required_approvals", 0))
                    .put("required_checks", Tools.jarr(Tools.strs(a, "required_checks"))).put("allow_force_push", b(a, "allow_force_push")).put("allow_deletion", b(a, "allow_deletion"));
            prot.put(s(a, "branch"), p);
            return new JSONObject().put("branch", s(a, "branch")).put("protection", p);
        }));
        t.def("get_branch_protection", "Règles de protection des branches.", "r", new String[][]{REPO, OWNER}, a -> {
            JSONObject p = st.readMeta(t.id(a)).optJSONObject("protection");
            return p == null ? new JSONObject() : p;
        });
        t.def("remove_branch_protection", "Retire la protection d'une branche.", "ad", new String[][]{REPO, OWNER, {"branch", "s", "Branche.", "1"}}, a -> st.updateMeta(t.id(a), m -> {
            JSONObject p = m.optJSONObject("protection");
            if (p != null) p.remove(s(a, "branch"));
            return new JSONObject().put("unprotected", s(a, "branch"));
        }));

        t.def("repository_stats", "Statistiques : langages (par extension), contributeurs, commits, fichiers, taille.", "r", new String[][]{REPO, OWNER, {"ref", "s", "Référence."}}, a -> t.withRepo(a, (r, id) -> {
            ObjectId c = GitStore.resolve(r, Tools.refOr(r, a, "ref"));
            if (c == null) return new JSONObject().put("commits", 0);
            java.util.Map<String, Long> langs = new java.util.HashMap<>();
            long bytes = 0; int files = 0;
            TreeWalk tw = GitStore.walk(r, c, true);
            while (tw.next()) {
                long sz = r.open(tw.getObjectId(0)).getSize();
                String p = tw.getPathString();
                String ext = p.contains(".") && p.lastIndexOf('.') > p.lastIndexOf('/') ? p.substring(p.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT) : "(sans extension)";
                langs.merge(ext, sz, Long::sum);
                bytes += sz; files++;
            }
            java.util.Map<String, Integer> authors = new java.util.HashMap<>();
            int commits = 0;
            try (RevWalk rw = new RevWalk(r)) {
                rw.markStart(rw.parseCommit(c));
                for (RevCommit rc : rw) { commits++; authors.merge(rc.getAuthorIdent().getName() + " <" + rc.getAuthorIdent().getEmailAddress() + ">", 1, Integer::sum); }
            }
            JSONArray lj = new JSONArray();
            final long total = Math.max(1, bytes);
            langs.entrySet().stream().sorted((x, y) -> Long.compare(y.getValue(), x.getValue())).limit(15)
                    .forEach(e -> { try { lj.put(new JSONObject().put("ext", e.getKey()).put("bytes", e.getValue()).put("percent", Math.round(e.getValue() * 1000.0 / total) / 10.0)); } catch (Exception ignored) { } });
            JSONArray cj = new JSONArray();
            authors.entrySet().stream().sorted((x, y) -> y.getValue() - x.getValue())
                    .forEach(e -> { try { cj.put(new JSONObject().put("author", e.getKey()).put("commits", e.getValue())); } catch (Exception ignored) { } });
            return new JSONObject().put("commits", commits).put("files", files).put("bytes", bytes).put("languages", lj).put("contributors", cj);
        }));
    }

    // ---------- Étiquettes et jalons ----------

    private void labels() {
        t.def("create_label", "Crée une étiquette (nom, couleur, description).", "", new String[][]{REPO, OWNER,
                {"name", "s", "Nom (ex. bug).", "1"}, {"color", "s", "Couleur hexadécimale (ex. d73a4a)."}, {"description", "s", "Description."}}, a -> st.updateMeta(t.id(a), m -> {
            JSONArray l = arr(m, "labels");
            for (int x = 0; x < l.length(); x++) if (s(a, "name").equals(l.getJSONObject(x).optString("name"))) throw new Tools.Err("L'étiquette existe déjà.");
            JSONObject o = new JSONObject().put("name", s(a, "name")).put("color", s(a, "color", "ededed").replace("#", "")).put("description", s(a, "description", ""));
            l.put(o);
            return o;
        }));
        t.def("list_labels", "Étiquettes du dépôt avec le nombre de tickets/PR qui les portent.", "r", new String[][]{REPO, OWNER}, a -> {
            JSONObject m = st.readMeta(t.id(a));
            java.util.Map<String, JSONObject> byName = new java.util.LinkedHashMap<>();
            JSONArray l = m.optJSONArray("labels");
            if (l != null) for (int x = 0; x < l.length(); x++) byName.put(l.getJSONObject(x).optString("name"), new JSONObject(l.getJSONObject(x).toString()).put("count", 0));
            for (String k : new String[]{"issues", "pulls"}) {
                JSONArray it = m.getJSONArray(k);
                for (int x = 0; x < it.length(); x++) {
                    JSONArray ls = it.getJSONObject(x).optJSONArray("labels");
                    if (ls != null) for (int y = 0; y < ls.length(); y++) {
                        JSONObject o = byName.computeIfAbsent(ls.optString(y), n -> { try { return new JSONObject().put("name", n).put("color", "ededed").put("count", 0); } catch (Exception e) { return new JSONObject(); } });
                        o.put("count", o.optInt("count") + 1);
                    }
                }
            }
            return new JSONArray(byName.values());
        });
        t.def("delete_label", "Supprime une étiquette (et la retire des tickets/PR).", "d", new String[][]{REPO, OWNER, {"name", "s", "Nom.", "1"}}, a -> st.updateMeta(t.id(a), m -> {
            JSONArray l = arr(m, "labels"), keep = new JSONArray();
            for (int x = 0; x < l.length(); x++) if (!s(a, "name").equals(l.getJSONObject(x).optString("name"))) keep.put(l.get(x));
            m.put("labels", keep);
            for (String k : new String[]{"issues", "pulls"}) {
                JSONArray it = m.getJSONArray(k);
                for (int x = 0; x < it.length(); x++) {
                    JSONArray ls = it.getJSONObject(x).optJSONArray("labels"), nl = new JSONArray();
                    if (ls == null) continue;
                    for (int y = 0; y < ls.length(); y++) if (!s(a, "name").equals(ls.optString(y))) nl.put(ls.optString(y));
                    it.getJSONObject(x).put("labels", nl);
                }
            }
            return new JSONObject().put("deleted", s(a, "name"));
        }));

        t.def("create_milestone", "Crée un jalon (ex. v1.0) avec date d'échéance.", "", new String[][]{REPO, OWNER,
                {"title", "s", "Titre.", "1"}, {"description", "s", "Description."}, {"due_on", "s", "Échéance (AAAA-MM-JJ)."}}, a -> st.updateMeta(t.id(a), m -> {
            JSONArray ms = arr(m, "milestones");
            JSONObject o = new JSONObject().put("number", nextId(ms, "number")).put("title", s(a, "title")).put("description", s(a, "description", ""))
                    .put("due_on", s(a, "due_on", "")).put("state", "open").put("created_at", GitStore.now());
            ms.put(o);
            return o;
        }));
        t.def("list_milestones", "Jalons avec leur avancement (tickets ouverts/fermés).", "r", new String[][]{REPO, OWNER}, a -> {
            JSONObject m = st.readMeta(t.id(a));
            JSONArray ms = m.optJSONArray("milestones"), out = new JSONArray();
            if (ms != null) for (int x = 0; x < ms.length(); x++) {
                JSONObject o = new JSONObject(ms.getJSONObject(x).toString());
                int open = 0, closed = 0;
                for (String k : new String[]{"issues", "pulls"}) {
                    JSONArray it = m.getJSONArray(k);
                    for (int y = 0; y < it.length(); y++) if (o.optString("title").equals(it.getJSONObject(y).optString("milestone"))) { if ("open".equals(it.getJSONObject(y).optString("state"))) open++; else closed++; }
                }
                out.put(o.put("open_issues", open).put("closed_issues", closed).put("progress", open + closed == 0 ? 0 : closed * 100 / (open + closed)));
            }
            return out;
        });
        t.def("update_milestone", "Modifie ou ferme un jalon.", "", new String[][]{REPO, OWNER, {"number", "i", "Numéro.", "1"},
                {"title", "s", "Titre."}, {"description", "s", "Description."}, {"due_on", "s", "Échéance."}, {"state", "e:open|closed", "État."}}, a -> st.updateMeta(t.id(a), m -> {
            JSONObject o = findIn(m, "milestones", "number", a.getInt("number"), "Jalon");
            for (String k : new String[]{"title", "description", "due_on", "state"}) if (a.has(k)) o.put(k, a.getString(k));
            return o;
        }));
    }

    // ---------- Opérations git ----------

    /** Applique (theirs − base) sur la tête d'une branche, en mémoire ; renvoie le nouveau commit. */
    private ObjectId threeWay(Repository r, String branch, ObjectId base, ObjectId theirs, String message) throws Exception {
        String ref = Constants.R_HEADS + branch;
        ObjectId head = GitStore.need(r, ref);
        st.guard(r, branch);
        ResolveMerger m = (ResolveMerger) MergeStrategy.RECURSIVE.newMerger(r, true);
        m.setBase(base);
        if (!m.merge(head, theirs)) {
            List<String> c = new ArrayList<>();
            if (m.getUnmergedPaths() != null) c.addAll(m.getUnmergedPaths());
            throw new Tools.Err("Conflit : ne s'applique pas proprement sur " + branch + " (" + String.join(", ", c) + ").");
        }
        ObjectId commit = st.writeCommit(r, m.getResultTreeId(), message, head);
        GitStore.setRef(r, ref, commit, head, false);
        return commit;
    }

    private void gitOps() {
        t.def("blame", "Qui a écrit chaque ligne d'un fichier (git blame).", "r", new String[][]{REPO, OWNER,
                {"path", "s", "Fichier.", "1"}, {"ref", "s", "Branche, tag ou SHA."}, {"start", "i", "Première ligne."}, {"end", "i", "Dernière ligne."}}, a -> t.withRepo(a, (r, id) -> {
            try (Git g = new Git(r)) {
                BlameResult br = g.blame().setFilePath(GitStore.normPath(s(a, "path"))).setStartCommit(GitStore.need(r, Tools.refOr(r, a, "ref"))).call();
                if (br == null) throw new Tools.Err("Fichier introuvable.");
                int n = br.getResultContents().size();
                int from = Math.max(1, i(a, "start", 1)), to = Math.min(n, i(a, "end", Math.min(n, from + 499)));
                StringBuilder sb = new StringBuilder();
                for (int l = from; l <= to; l++) {
                    RevCommit c = br.getSourceCommit(l - 1);
                    sb.append(c == null ? "???????" : c.getName().substring(0, 7)).append(' ')
                            .append(String.format("%-14.14s", c == null ? "" : c.getAuthorIdent().getName())).append(' ')
                            .append(c == null ? "" : GitStore.iso(c.getAuthorIdent().getWhen()).substring(0, 10)).append(' ')
                            .append(String.format("%4d", l)).append("| ").append(br.getResultContents().getString(l - 1)).append('\n');
                }
                return sb.toString();
            }
        }));

        t.def("revert_commit", "Annule un commit en créant un commit inverse.", "", new String[][]{REPO, OWNER,
                {"sha", "s", "Commit à annuler.", "1"}, {"branch", "s", "Branche (défaut : par défaut)."}}, a -> t.withRepo(a, (r, id) -> {
            try (RevWalk rw = new RevWalk(r)) {
                RevCommit c = rw.parseCommit(GitStore.need(r, s(a, "sha")));
                if (c.getParentCount() == 0) throw new Tools.Err("Impossible d'annuler le tout premier commit.");
                String br = Tools.refOr(r, a, "branch");
                ObjectId n = threeWay(r, br, c.getId(), c.getParent(0).getId(), "Revert \"" + c.getShortMessage() + "\"\n\nThis reverts commit " + c.getName() + ".");
                return new JSONObject().put("branch", br).put("commit", n.getName()).put("reverted", c.getName());
            }
        }));

        t.def("cherry_pick", "Applique un commit (d'une autre branche) sur une branche.", "", new String[][]{REPO, OWNER,
                {"sha", "s", "Commit à reprendre.", "1"}, {"branch", "s", "Branche cible.", "1"}}, a -> t.withRepo(a, (r, id) -> {
            try (RevWalk rw = new RevWalk(r)) {
                RevCommit c = rw.parseCommit(GitStore.need(r, s(a, "sha")));
                ObjectId base = c.getParentCount() > 0 ? c.getParent(0).getId() : null;
                if (base == null) throw new Tools.Err("Le premier commit ne peut pas être repris.");
                ObjectId n = threeWay(r, s(a, "branch"), base, c.getId(), c.getFullMessage().trim() + "\n\n(cherry picked from commit " + c.getName() + ")");
                return new JSONObject().put("branch", s(a, "branch")).put("commit", n.getName()).put("picked", c.getName());
            }
        }));

        t.def("merge_branches", "Fusionne une branche dans une autre directement (sans pull request).", "", new String[][]{REPO, OWNER,
                {"base", "s", "Branche qui reçoit.", "1"}, {"head", "s", "Branche à fusionner.", "1"}, {"message", "s", "Message du commit de fusion."}}, a -> t.withRepo(a, (r, id) -> {
            String base = s(a, "base");
            st.guard(r, base);
            ObjectId b = GitStore.need(r, Constants.R_HEADS + base), h = GitStore.need(r, s(a, "head"));
            JSONObject mc = GitStore.mergeCheck(r, b, h);
            if (!mc.getBoolean("mergeable")) throw new Tools.Err("already_merged".equals(mc.optString("merge_state")) ? "Déjà à jour." : "Conflits : " + mc.optJSONArray("conflicts"));
            ObjectId c = "fast_forward".equals(mc.getString("merge_state")) ? h
                    : st.writeCommit(r, ObjectId.fromString(mc.getString("tree")), s(a, "message", "Merge branch '" + s(a, "head") + "' into " + base), b, h);
            GitStore.setRef(r, Constants.R_HEADS + base, c, b, false);
            return new JSONObject().put("base", base).put("commit", c.getName()).put("fast_forward", c.equals(h));
        }));

        t.def("update_pull_request_branch", "Met à jour la branche d'une PR avec les derniers commits de sa branche cible (bouton « Update branch » de GitHub).", "", new String[][]{REPO, OWNER,
                {"number", "i", "Numéro de la PR.", "1"}}, a -> t.withRepo(a, (r, id) -> {
            JSONObject pr = t.find(st.readMeta(id), "pulls", a.getInt("number"));
            if (!pr.optString("head_repo", id.full()).equals(id.full())) throw new Tools.Err("PR depuis un fork : mettez à jour la branche dans le fork.");
            ObjectId h = GitStore.need(r, Constants.R_HEADS + pr.getString("head")), b = GitStore.need(r, Constants.R_HEADS + pr.getString("base"));
            JSONObject mc = GitStore.mergeCheck(r, h, b);
            if ("already_merged".equals(mc.optString("merge_state"))) return new JSONObject().put("updated", false).put("message", "Déjà à jour.");
            if (!mc.getBoolean("mergeable")) throw new Tools.Err("Conflits avec " + pr.getString("base") + " : " + mc.optJSONArray("conflicts"));
            ObjectId c = "fast_forward".equals(mc.getString("merge_state")) ? b
                    : st.writeCommit(r, ObjectId.fromString(mc.getString("tree")), "Merge branch '" + pr.getString("base") + "' into " + pr.getString("head"), h, b);
            GitStore.setRef(r, Constants.R_HEADS + pr.getString("head"), c, h, false);
            return new JSONObject().put("updated", true).put("commit", c.getName());
        }));

        t.def("delete_tag", "Supprime un tag.", "d", new String[][]{REPO, OWNER, {"tag", "s", "Tag.", "1"}}, a -> t.withRepo(a, (r, id) -> {
            if (r.exactRef(Constants.R_TAGS + s(a, "tag")) == null) throw new Tools.Err("Tag introuvable.");
            GitStore.deleteRef(r, Constants.R_TAGS + s(a, "tag"));
            return new JSONObject().put("deleted", s(a, "tag"));
        }));

        t.def("rename_branch", "Renomme une branche (et met à jour les PR ouvertes qui l'utilisent).", "", new String[][]{REPO, OWNER,
                {"branch", "s", "Nom actuel.", "1"}, {"new_name", "s", "Nouveau nom.", "1"}}, a -> t.withRepo(a, (r, id) -> {
            String o = s(a, "branch"), n = s(a, "new_name");
            if (!Repository.isValidRefName(Constants.R_HEADS + n)) throw new Tools.Err("Nom invalide : " + n);
            if (GitStore.branchHead(r, n) != null) throw new Tools.Err("La branche " + n + " existe déjà.");
            ObjectId c = GitStore.need(r, Constants.R_HEADS + o);
            GitStore.setRef(r, Constants.R_HEADS + n, c, null, false);
            if (o.equals(GitStore.defaultBranch(r))) r.updateRef(Constants.HEAD).link(Constants.R_HEADS + n);
            GitStore.deleteRef(r, Constants.R_HEADS + o);
            st.updateMeta(id, m -> {
                JSONArray p = m.getJSONArray("pulls");
                for (int x = 0; x < p.length(); x++) {
                    JSONObject pr = p.getJSONObject(x);
                    if (!"open".equals(pr.optString("state"))) continue;
                    if (o.equals(pr.optString("base"))) pr.put("base", n);
                    if (o.equals(pr.optString("head")) && id.full().equals(pr.optString("head_repo"))) pr.put("head", n);
                }
                return null;
            });
            return new JSONObject().put("renamed", o).put("to", n);
        }));
    }

    // ---------- Synchronisation avec un vrai GitHub (ou tout serveur git) ----------

    private CredentialsProvider creds(JSONObject m, String remote, JSONObject a) throws Exception {
        String tok = s(a, "token");
        String user = s(a, "username", "x-access-token");
        if (tok == null) {
            JSONObject rt = m.optJSONObject("remote_tokens");
            if (rt != null && rt.optJSONObject(remote) != null) { tok = rt.getJSONObject(remote).optString("token"); user = rt.getJSONObject(remote).optString("username", user); }
        }
        return tok == null || tok.isEmpty() ? null : new UsernamePasswordCredentialsProvider(user, tok);
    }

    private void remember(GitStore.Id id, String remote, JSONObject a) throws Exception {
        if (!b(a, "remember_token") || s(a, "token") == null) return;
        st.updateMeta(id, m -> {
            JSONObject rt = m.optJSONObject("remote_tokens");
            if (rt == null) { rt = new JSONObject(); m.put("remote_tokens", rt); }
            rt.put(remote, new JSONObject().put("token", s(a, "token")).put("username", s(a, "username", "x-access-token")));
            return null;
        });
    }

    private static final String[] TOKEN = {"token", "s", "Jeton d'accès du serveur distant (ex. jeton GitHub) si le dépôt est privé ou pour pousser."};
    private static final String[] USERNAME = {"username", "s", "Identifiant distant (défaut : x-access-token, qui convient à GitHub)."};
    private static final String[] REMEMBER = {"remember_token", "b", "Mémoriser le jeton dans l'appli pour les prochaines synchronisations."};

    private void remotes() {
        t.def("import_repository", "Importe (clone) un dépôt depuis une URL : GitHub, GitLab, un autre GIXCLOUD… Toutes les branches et tags.", "", new String[][]{
                {"url", "s", "URL git (ex. https://github.com/moi/projet.git).", "1"}, {"name", "s", "Nom local (défaut : tiré de l'URL)."}, OWNER, TOKEN, USERNAME, REMEMBER,
                {"description", "s", "Description."}}, a -> {
            String url = s(a, "url");
            String base = url.replaceAll("/+$", "").replaceAll("\\.git$", "");
            base = base.substring(base.lastIndexOf('/') + 1);
            GitStore.Id id = st.id(s(a, "owner"), s(a, "name", base));
            if (st.exists(id)) throw new Tools.Err(id.full() + " existe déjà.");
            java.io.File dir = st.gitDir(id);
            dir.getParentFile().mkdirs();
            try {
                org.eclipse.jgit.api.CloneCommand cc = Git.cloneRepository().setURI(url).setDirectory(dir).setBare(true).setCloneAllBranches(true).setTimeout(120);
                CredentialsProvider cp = creds(new JSONObject(), "origin", a);
                if (cp != null) cc.setCredentialsProvider(cp);
                cc.call().close();
            } catch (Exception e) {
                GitStore.rm(dir);
                throw new Tools.Err("Import impossible : " + e.getMessage());
            }
            JSONObject m = st.readMeta(id);
            m.put("description", s(a, "description", "Importé de " + url)).put("imported_from", url);
            st.writeMeta(id, m);
            remember(id, "origin", a);
            try (Repository r = st.open(id)) { return t.repoInfo(r, id); }
        });

        t.def("list_remotes", "Dépôts distants configurés (pour synchroniser avec GitHub…).", "r", new String[][]{REPO, OWNER}, a -> t.withRepo(a, (r, id) -> {
            JSONArray out = new JSONArray();
            StoredConfig c = r.getConfig();
            JSONObject rt = st.readMeta(id).optJSONObject("remote_tokens");
            for (String n : c.getSubsections("remote")) out.put(new JSONObject().put("name", n).put("url", c.getString("remote", n, "url")).put("token_saved", rt != null && rt.has(n)));
            return out;
        }));

        t.def("add_remote", "Ajoute un dépôt distant (ex. github → https://github.com/moi/projet.git).", "", new String[][]{REPO, OWNER,
                {"name", "s", "Nom du distant (ex. github).", "1"}, {"url", "s", "URL git.", "1"}, TOKEN, USERNAME, REMEMBER}, a -> t.withRepo(a, (r, id) -> {
            StoredConfig c = r.getConfig();
            if (c.getSubsections("remote").contains(s(a, "name"))) throw new Tools.Err("Ce distant existe déjà.");
            c.setString("remote", s(a, "name"), "url", s(a, "url"));
            c.setString("remote", s(a, "name"), "fetch", "+refs/heads/*:refs/remotes/" + s(a, "name") + "/*");
            c.save();
            remember(id, s(a, "name"), a.put("remember_token", a.has("remember_token") ? a.getBoolean("remember_token") : s(a, "token") != null));
            return new JSONObject().put("added", s(a, "name")).put("url", s(a, "url"));
        }));

        t.def("remove_remote", "Supprime un dépôt distant (et son jeton mémorisé).", "d", new String[][]{REPO, OWNER, {"name", "s", "Nom.", "1"}}, a -> t.withRepo(a, (r, id) -> {
            StoredConfig c = r.getConfig();
            c.unsetSection("remote", s(a, "name"));
            c.save();
            st.updateMeta(id, m -> { JSONObject rt = m.optJSONObject("remote_tokens"); if (rt != null) rt.remove(s(a, "name")); return null; });
            return new JSONObject().put("removed", s(a, "name"));
        }));

        t.def("push_to_remote", "Pousse des branches/tags vers un dépôt distant (ex. publier sur GitHub).", "", new String[][]{REPO, OWNER,
                {"remote", "s", "Nom du distant (défaut : origin).", ""}, {"branches", "as", "Branches (défaut : toutes)."}, {"tags", "b", "Pousser aussi les tags."},
                {"force", "b", "Push forcé."}, TOKEN, USERNAME, REMEMBER}, a -> t.withRepo(a, (r, id) -> {
            String remote = s(a, "remote", "origin");
            if (!r.getConfig().getSubsections("remote").contains(remote)) throw new Tools.Err("Distant inconnu : " + remote + " (add_remote).");
            try (Git g = new Git(r)) {
                PushCommand pc = g.push().setRemote(remote).setForce(b(a, "force")).setTimeout(120);
                List<String> brs = Tools.strs(a, "branches");
                if (brs.isEmpty()) pc.setPushAll(); else for (String br : brs) pc.add(Constants.R_HEADS + br);
                if (b(a, "tags")) pc.setPushTags();
                CredentialsProvider cp = creds(st.readMeta(id), remote, a);
                if (cp != null) pc.setCredentialsProvider(cp);
                JSONArray res = new JSONArray();
                for (PushResult pr : pc.call()) for (RemoteRefUpdate u : pr.getRemoteUpdates())
                    res.put(new JSONObject().put("ref", u.getRemoteName()).put("status", u.getStatus().name().toLowerCase(Locale.ROOT)).put("message", u.getMessage() == null ? "" : u.getMessage()));
                remember(id, remote, a);
                return new JSONObject().put("remote", remote).put("updates", res);
            } catch (org.eclipse.jgit.api.errors.TransportException e) {
                throw new Tools.Err("Échec de connexion au distant : " + e.getMessage() + " (jeton ? réseau ?)");
            }
        }));

        t.def("pull_from_remote", "Récupère un dépôt distant et met à jour les branches locales (avance rapide) ; signale les branches divergentes.", "", new String[][]{REPO, OWNER,
                {"remote", "s", "Nom du distant (défaut : origin)."}, {"create_missing", "b", "Créer localement les nouvelles branches distantes (défaut : vrai)."},
                {"tags", "b", "Récupérer les tags (défaut : vrai)."}, TOKEN, USERNAME, REMEMBER}, a -> t.withRepo(a, (r, id) -> {
            String remote = s(a, "remote", "origin");
            if (!r.getConfig().getSubsections("remote").contains(remote)) throw new Tools.Err("Distant inconnu : " + remote + " (add_remote).");
            try (Git g = new Git(r)) {
                org.eclipse.jgit.api.FetchCommand fc = g.fetch().setRemote(remote).setRefSpecs(new RefSpec("+refs/heads/*:refs/remotes/" + remote + "/*")).setTimeout(120);
                if (!a.has("tags") || b(a, "tags")) fc.setTagOpt(org.eclipse.jgit.transport.TagOpt.FETCH_TAGS);
                CredentialsProvider cp = creds(st.readMeta(id), remote, a);
                if (cp != null) fc.setCredentialsProvider(cp);
                FetchResult fr = fc.call();
                JSONArray updated = new JSONArray(), created = new JSONArray(), diverged = new JSONArray(), same = new JSONArray();
                for (Ref rr : r.getRefDatabase().getRefsByPrefix("refs/remotes/" + remote + "/")) {
                    String br = rr.getName().substring(("refs/remotes/" + remote + "/").length());
                    if (br.equals("HEAD")) continue;
                    ObjectId loc = GitStore.branchHead(r, br), rem = rr.getObjectId();
                    if (loc == null) {
                        if (!a.has("create_missing") || b(a, "create_missing")) { GitStore.setRef(r, Constants.R_HEADS + br, rem, null, false); created.put(br); }
                    } else if (loc.equals(rem) || GitStore.isAncestor(r, rem, loc)) same.put(br);
                    else if (GitStore.isAncestor(r, loc, rem)) { GitStore.setRef(r, Constants.R_HEADS + br, rem, loc, false); updated.put(br); }
                    else diverged.put(br);
                }
                remember(id, remote, a);
                return new JSONObject().put("remote", remote).put("updated", updated).put("created", created).put("up_to_date", same).put("diverged", diverged)
                        .put("note", diverged.length() > 0 ? "Branches divergentes : fusionnez avec merge_branches (base = branche, head = refs/remotes/" + remote + "/<branche>)." : "")
                        .put("fetched_refs", fr.getTrackingRefUpdates().size());
            } catch (org.eclipse.jgit.api.errors.TransportException e) {
                throw new Tools.Err("Échec de connexion au distant : " + e.getMessage() + " (jeton ? réseau ?)");
            }
        }));
    }

    // ---------- Wiki ----------

    private GitStore.Id wikiId(JSONObject a) {
        GitStore.Id id = t.id(a);
        if (!st.exists(id)) throw new Tools.Err("Dépôt introuvable : " + id.full());
        return st.id(id.owner, id.repo + ".wiki");
    }

    private Repository wikiRepo(GitStore.Id w, boolean create) throws Exception {
        if (!st.exists(w)) {
            if (!create) return null;
            st.init(w, "main");
        }
        return st.open(w);
    }

    static String slug(String title) {
        String s = title.trim().replaceAll("[\\\\/:*?\"<>|#]", "").replaceAll("\\s+", "-");
        if (s.isEmpty()) throw new Tools.Err("Titre de page invalide.");
        return s;
    }

    private void wiki() {
        t.def("list_wiki_pages", "Pages du wiki du dépôt.", "r", new String[][]{REPO, OWNER}, a -> {
            JSONArray out = new JSONArray();
            try (Repository r = wikiRepo(wikiId(a), false)) {
                if (r == null) return out;
                ObjectId c = GitStore.branchHead(r, "main");
                if (c == null) return out;
                TreeWalk tw = GitStore.walk(r, c, true);
                while (tw.next()) if (tw.getPathString().endsWith(".md")) out.put(tw.getPathString().replaceAll("\\.md$", "").replace('-', ' '));
            }
            return out;
        });
        t.def("get_wiki_page", "Lit une page du wiki (Markdown) et son historique.", "r", new String[][]{REPO, OWNER, {"title", "s", "Titre (ex. Home).", "1"}}, a -> {
            try (Repository r = wikiRepo(wikiId(a), false)) {
                if (r == null) throw new Tools.Err("Le wiki est vide.");
                String p = slug(s(a, "title")) + ".md";
                ObjectId c = GitStore.need(r, Constants.R_HEADS + "main");
                TreeWalk tw;
                try (RevWalk rw = new RevWalk(r)) { tw = TreeWalk.forPath(r, p, rw.parseCommit(c).getTree()); }
                if (tw == null) throw new Tools.Err("Page introuvable : " + s(a, "title"));
                JSONArray hist = new JSONArray();
                try (Git g = new Git(r)) { for (RevCommit rc : g.log().add(c).addPath(p).setMaxCount(20).call()) hist.put(GitStore.commitJson(rc)); }
                return new JSONObject().put("title", s(a, "title")).put("content", new String(GitStore.readBlob(r, tw.getObjectId(0)), StandardCharsets.UTF_8)).put("history", hist);
            }
        });
        t.def("write_wiki_page", "Crée ou modifie une page du wiki (Markdown).", "", new String[][]{REPO, OWNER,
                {"title", "s", "Titre.", "1"}, {"content", "s", "Contenu Markdown.", "1"}, {"message", "s", "Message de modification."}}, a -> {
            GitStore.Id w = wikiId(a);
            try (Repository r = wikiRepo(w, true)) {
                List<GitStore.Change> ch = new ArrayList<>();
                ch.add(new GitStore.Change(slug(s(a, "title")) + ".md", s(a, "content").getBytes(StandardCharsets.UTF_8), false));
                ObjectId c = st.commit(r, "main", ch, s(a, "message", "Page " + s(a, "title")), null);
                return new JSONObject().put("title", s(a, "title")).put("commit", c.getName());
            }
        });
        t.def("delete_wiki_page", "Supprime une page du wiki.", "d", new String[][]{REPO, OWNER, {"title", "s", "Titre.", "1"}}, a -> {
            try (Repository r = wikiRepo(wikiId(a), false)) {
                if (r == null) throw new Tools.Err("Le wiki est vide.");
                List<GitStore.Change> ch = new ArrayList<>();
                ch.add(new GitStore.Change(slug(s(a, "title")) + ".md", null, false));
                st.commit(r, "main", ch, "Suppression de " + s(a, "title"), null);
                return new JSONObject().put("deleted", s(a, "title"));
            }
        });
    }

    // ---------- Gists ----------

    private void gists() {
        t.def("create_gist", "Crée un gist (extrait de code partageable, versionné) avec un ou plusieurs fichiers.", "", new String[][]{
                {"description", "s", "Description."}, {"files", "af", "Fichiers : {path (nom), content}.", "1"}, {"public", "b", "Public (indicatif)."}}, a -> {
            byte[] rnd = new byte[8];
            new SecureRandom().nextBytes(rnd);
            StringBuilder hex = new StringBuilder();
            for (byte x : rnd) hex.append(String.format("%02x", x));
            GitStore.Id id = st.id("gist", hex.toString());
            st.init(id, "main");
            JSONObject m = st.readMeta(id);
            m.put("description", s(a, "description", "")).put("public", b(a, "public")).put("gist_owner", Auth.current(gix).name);
            st.writeMeta(id, m);
            try (Repository r = st.open(id)) {
                List<GitStore.Change> ch = new ArrayList<>();
                JSONArray fs = a.getJSONArray("files");
                for (int x = 0; x < fs.length(); x++) ch.add(new GitStore.Change(fs.getJSONObject(x).getString("path"), Tools.bytes(fs.getJSONObject(x)), false));
                st.commit(r, "main", ch, "Gist", null);
            }
            return new JSONObject().put("id", hex.toString()).put("repo", id.full()).put("git", urls("/git/gist/" + hex + ".git").get(0));
        });
        t.def("list_gists", "Liste les gists.", "r", new String[][]{}, a -> {
            JSONArray out = new JSONArray();
            for (GitStore.Id id : st.listAll()) if (id.owner.equals("gist")) {
                JSONObject m = st.readMeta(id);
                out.put(new JSONObject().put("id", id.repo).put("description", m.optString("description")).put("owner", m.optString("gist_owner")).put("updated_at", m.optString("updated_at")));
            }
            return out;
        });
        t.def("get_gist", "Lit un gist (tous ses fichiers).", "r", new String[][]{{"id", "s", "Identifiant du gist.", "1"}}, a -> {
            GitStore.Id id = st.id("gist", s(a, "id"));
            try (Repository r = st.open(id)) {
                JSONArray files = new JSONArray();
                TreeWalk tw = GitStore.walk(r, GitStore.need(r, "refs/heads/main"), true);
                while (tw.next()) files.put(Tools.content(GitStore.readBlob(r, tw.getObjectId(0))).put("name", tw.getPathString()));
                return new JSONObject().put("id", s(a, "id")).put("description", st.readMeta(id).optString("description")).put("files", files);
            }
        });
        t.def("update_gist", "Modifie les fichiers ou la description d'un gist (nouvelle révision).", "", new String[][]{{"id", "s", "Identifiant.", "1"},
                {"description", "s", "Description."}, {"files", "af", "Fichiers à écrire."}, {"delete", "as", "Fichiers à supprimer."}}, a -> {
            GitStore.Id id = st.id("gist", s(a, "id"));
            if (a.has("description")) st.updateMeta(id, m -> m.put("description", s(a, "description")));
            List<GitStore.Change> ch = new ArrayList<>();
            JSONArray fs = a.optJSONArray("files");
            if (fs != null) for (int x = 0; x < fs.length(); x++) ch.add(new GitStore.Change(fs.getJSONObject(x).getString("path"), Tools.bytes(fs.getJSONObject(x)), false));
            for (String d : Tools.strs(a, "delete")) ch.add(new GitStore.Change(d, null, false));
            if (!ch.isEmpty()) try (Repository r = st.open(id)) { st.commit(r, "main", ch, "Révision", null); }
            return new JSONObject().put("id", s(a, "id")).put("updated", true);
        });
        t.def("delete_gist", "Supprime un gist.", "d", new String[][]{{"id", "s", "Identifiant.", "1"}}, a -> {
            GitStore.Id id = st.id("gist", s(a, "id"));
            if (!st.exists(id)) throw new Tools.Err("Gist introuvable.");
            st.deleteAll(id);
            return new JSONObject().put("deleted", s(a, "id"));
        });
    }

    // ---------- Pages ----------

    private void pages() {
        t.def("enable_pages", "Active GIXCLOUD Pages : publie le site statique (HTML) d'une branche/dossier sur le réseau local, comme GitHub Pages.", "a", new String[][]{REPO, OWNER,
                {"branch", "s", "Branche (défaut : par défaut)."}, {"folder", "s", "Dossier (ex. docs ; défaut : racine)."}}, a -> {
            GitStore.Id id = t.id(a);
            st.updateMeta(id, m -> m.put("pages", new JSONObject().put("enabled", true).put("branch", s(a, "branch", "")).put("folder", s(a, "folder", ""))));
            if (s(a, "branch") == null) st.updateMeta(id, m -> { m.getJSONObject("pages").remove("branch"); return null; });
            return new JSONObject().put("enabled", true).put("urls", Tools.jarr(urls("/pages/" + id.owner + "/" + id.repo + "/")))
                    .put("note", "Le site est visible sans jeton par les appareils du même réseau.");
        });
        t.def("disable_pages", "Désactive GIXCLOUD Pages.", "a", new String[][]{REPO, OWNER}, a -> st.updateMeta(t.id(a), m -> { m.remove("pages"); return new JSONObject().put("enabled", false); }));
        t.def("get_pages", "État et adresse du site GIXCLOUD Pages.", "r", new String[][]{REPO, OWNER}, a -> {
            GitStore.Id id = t.id(a);
            JSONObject p = st.readMeta(id).optJSONObject("pages");
            if (p == null) return new JSONObject().put("enabled", false);
            return new JSONObject(p.toString()).put("urls", Tools.jarr(urls("/pages/" + id.owner + "/" + id.repo + "/")));
        });
    }

    // ---------- Discussions ----------

    private void discussions() {
        t.def("create_discussion", "Ouvre une discussion (questions, idées, annonces).", "", new String[][]{REPO, OWNER,
                {"title", "s", "Titre.", "1"}, {"body", "s", "Message."}, {"category", "e:general|ideas|q-a|announcements|show-and-tell", "Catégorie (défaut general)."}}, a -> st.updateMeta(t.id(a), m -> {
            JSONArray d = arr(m, "discussions");
            JSONObject o = new JSONObject().put("number", nextId(d, "number")).put("title", s(a, "title")).put("body", s(a, "body", "")).put("category", s(a, "category", "general"))
                    .put("author", Auth.current(gix).name).put("created_at", GitStore.now()).put("comments", new JSONArray()).put("answer", JSONObject.NULL).put("state", "open");
            d.put(o);
            return o;
        }));
        t.def("list_discussions", "Liste les discussions.", "r", new String[][]{REPO, OWNER, {"category", "s", "Catégorie."}}, a -> {
            JSONArray d = st.readMeta(t.id(a)).optJSONArray("discussions"), out = new JSONArray();
            if (d != null) for (int x = d.length() - 1; x >= 0; x--) {
                JSONObject o = d.getJSONObject(x);
                if (s(a, "category") != null && !s(a, "category").equals(o.optString("category"))) continue;
                JSONObject sm = new JSONObject(o.toString());
                sm.remove("body");
                out.put(sm.put("comments", o.getJSONArray("comments").length()));
            }
            return out;
        });
        t.def("get_discussion", "Lit une discussion et ses réponses.", "r", new String[][]{REPO, OWNER, {"number", "i", "Numéro.", "1"}}, a ->
                findIn(st.readMeta(t.id(a)), "discussions", "number", a.getInt("number"), "Discussion"));
        t.def("add_discussion_comment", "Répond dans une discussion ; mark_as_answer marque la réponse comme solution.", "", new String[][]{REPO, OWNER,
                {"number", "i", "Numéro.", "1"}, {"body", "s", "Réponse.", "1"}, {"mark_as_answer", "b", "Marquer comme réponse acceptée."}}, a -> st.updateMeta(t.id(a), m -> {
            JSONObject d = findIn(m, "discussions", "number", a.getInt("number"), "Discussion");
            JSONObject c = t.comment(d, s(a, "body"));
            if (b(a, "mark_as_answer")) d.put("answer", c.getInt("id"));
            return c;
        }));
    }

    // ---------- Projets (tableaux kanban) ----------

    private void projects() {
        t.def("create_project", "Crée un projet (tableau kanban) avec des colonnes.", "", new String[][]{REPO, OWNER,
                {"name", "s", "Nom.", "1"}, {"columns", "as", "Colonnes (défaut : À faire, En cours, Terminé)."}}, a -> st.updateMeta(t.id(a), m -> {
            JSONArray p = arr(m, "projects");
            List<String> cols = Tools.strs(a, "columns");
            if (cols.isEmpty()) { cols.add("À faire"); cols.add("En cours"); cols.add("Terminé"); }
            JSONObject o = new JSONObject().put("number", nextId(p, "number")).put("name", s(a, "name")).put("columns", Tools.jarr(cols)).put("cards", new JSONArray()).put("created_at", GitStore.now());
            p.put(o);
            return o;
        }));
        t.def("list_projects", "Liste les projets.", "r", new String[][]{REPO, OWNER}, a -> {
            JSONArray p = st.readMeta(t.id(a)).optJSONArray("projects"), out = new JSONArray();
            if (p != null) for (int x = 0; x < p.length(); x++) out.put(new JSONObject().put("number", p.getJSONObject(x).getInt("number")).put("name", p.getJSONObject(x).getString("name")).put("cards", p.getJSONObject(x).getJSONArray("cards").length()));
            return out;
        });
        t.def("get_project", "Tableau d'un projet : cartes par colonne (avec titre et état des tickets liés).", "r", new String[][]{REPO, OWNER, {"number", "i", "Numéro du projet.", "1"}}, a -> {
            JSONObject m = st.readMeta(t.id(a));
            JSONObject p = findIn(m, "projects", "number", a.getInt("number"), "Projet");
            JSONObject board = new JSONObject();
            JSONArray cols = p.getJSONArray("columns");
            for (int x = 0; x < cols.length(); x++) board.put(cols.getString(x), new JSONArray());
            JSONArray cards = p.getJSONArray("cards");
            for (int x = 0; x < cards.length(); x++) {
                JSONObject c = new JSONObject(cards.getJSONObject(x).toString());
                if (c.has("issue")) {
                    for (String k : new String[]{"issues", "pulls"}) {
                        JSONArray it = m.getJSONArray(k);
                        for (int y = 0; y < it.length(); y++) if (it.getJSONObject(y).getInt("number") == c.getInt("issue")) c.put("title", it.getJSONObject(y).optString("title")).put("state", it.getJSONObject(y).optString("state"));
                    }
                }
                JSONArray col = board.optJSONArray(c.optString("column"));
                if (col != null) col.put(c);
            }
            return new JSONObject().put("number", p.getInt("number")).put("name", p.getString("name")).put("board", board);
        });
        t.def("add_project_card", "Ajoute une carte (ticket/PR ou simple note) dans une colonne d'un projet.", "", new String[][]{REPO, OWNER,
                {"project", "i", "Numéro du projet.", "1"}, {"column", "s", "Colonne (défaut : la première)."}, {"issue", "i", "Numéro de ticket ou PR."}, {"note", "s", "Note libre."}}, a -> st.updateMeta(t.id(a), m -> {
            JSONObject p = findIn(m, "projects", "number", a.getInt("project"), "Projet");
            String col = s(a, "column", p.getJSONArray("columns").getString(0));
            if (!p.getJSONArray("columns").toString().contains("\"" + col + "\"")) throw new Tools.Err("Colonne inconnue : " + col);
            JSONArray cards = p.getJSONArray("cards");
            JSONObject c = new JSONObject().put("id", nextId(cards, "id")).put("column", col).put("created_at", GitStore.now());
            if (a.has("issue")) c.put("issue", a.getInt("issue"));
            if (s(a, "note") != null) c.put("note", s(a, "note"));
            if (!c.has("issue") && !c.has("note")) throw new Tools.Err("Donnez issue ou note.");
            cards.put(c);
            return c;
        }));
        t.def("move_project_card", "Déplace une carte vers une autre colonne (ou la supprime avec remove).", "", new String[][]{REPO, OWNER,
                {"project", "i", "Numéro du projet.", "1"}, {"card", "i", "Numéro de la carte.", "1"}, {"column", "s", "Nouvelle colonne."}, {"remove", "b", "Supprimer la carte."}}, a -> st.updateMeta(t.id(a), m -> {
            JSONObject p = findIn(m, "projects", "number", a.getInt("project"), "Projet");
            JSONArray cards = p.getJSONArray("cards"), keep = new JSONArray();
            JSONObject moved = null;
            for (int x = 0; x < cards.length(); x++) {
                JSONObject c = cards.getJSONObject(x);
                if (c.getInt("id") == a.getInt("card")) {
                    moved = c;
                    if (b(a, "remove")) continue;
                    if (s(a, "column") != null) {
                        if (!p.getJSONArray("columns").toString().contains("\"" + s(a, "column") + "\"")) throw new Tools.Err("Colonne inconnue.");
                        c.put("column", s(a, "column"));
                    }
                }
                keep.put(c);
            }
            if (moved == null) throw new Tools.Err("Carte introuvable.");
            p.put("cards", keep);
            return moved;
        }));
    }

    // ---------- Statuts de CI (check runs) ----------

    private void checks() {
        t.def("create_check_run", "Publie le résultat d'une vérification (tests, build, lint) sur un commit : c'est ce que fait la CI de GitHub. Les branches protégées peuvent l'exiger.", "", new String[][]{REPO, OWNER,
                {"sha", "s", "Commit, branche ou « pull/N » (tête d'une PR).", "1"}, {"name", "s", "Nom de la vérification (ex. tests, build-apk).", "1"},
                {"status", "e:queued|in_progress|completed", "État (défaut completed)."}, {"conclusion", "e:success|failure|neutral|cancelled|skipped", "Résultat."},
                {"summary", "s", "Résumé / journal court."}, {"details_url", "s", "Lien vers les détails."}}, a -> t.withRepo(a, (r, id) -> {
            String ref = s(a, "sha");
            if (ref.startsWith("pull/")) {
                JSONObject pr = t.find(st.readMeta(id), "pulls", Integer.parseInt(ref.substring(5)));
                ref = t.prHead(r, id, pr).getName();
            }
            String sha = GitStore.need(r, ref).getName();
            return st.updateMeta(id, m -> {
                JSONArray cr = arr(m, "check_runs");
                JSONObject o = new JSONObject().put("id", nextId(cr, "id")).put("sha", sha).put("name", s(a, "name")).put("status", s(a, "status", "completed"))
                        .put("conclusion", s(a, "conclusion", "success")).put("summary", s(a, "summary", "")).put("details_url", s(a, "details_url", ""))
                        .put("by", Auth.current(gix).name).put("created_at", GitStore.now());
                cr.put(o);
                while (cr.length() > 1000) cr.remove(0);
                return o;
            });
        }));
        t.def("list_check_runs", "Résultats de vérification d'un commit (ou « pull/N ») ; le plus récent par nom.", "r", new String[][]{REPO, OWNER, {"sha", "s", "Commit, branche ou pull/N.", "1"}}, a -> t.withRepo(a, (r, id) -> {
            String ref = s(a, "sha");
            if (ref.startsWith("pull/")) ref = t.prHead(r, id, t.find(st.readMeta(id), "pulls", Integer.parseInt(ref.substring(5)))).getName();
            return latestChecks(st.readMeta(id), GitStore.need(r, ref).getName());
        }));
    }

    static JSONArray latestChecks(JSONObject m, String sha) throws Exception {
        java.util.Map<String, JSONObject> last = new java.util.LinkedHashMap<>();
        JSONArray cr = m.optJSONArray("check_runs");
        if (cr != null) for (int x = 0; x < cr.length(); x++) if (sha.equals(cr.getJSONObject(x).optString("sha"))) last.put(cr.getJSONObject(x).getString("name"), cr.getJSONObject(x));
        return new JSONArray(last.values());
    }

    // ---------- Recherche globale ----------

    private void search() {
        t.def("search_issues", "Recherche dans les tickets et pull requests de tous les dépôts.", "r", new String[][]{
                {"query", "s", "Texte (titre, description, commentaires).", "1"}, {"type", "e:issue|pr|all", "Type (défaut all)."}, {"state", "e:open|closed|merged|all", "État (défaut all)."}, {"limit", "i", "Maximum."}}, a -> {
            String q = s(a, "query").toLowerCase(Locale.ROOT), type = s(a, "type", "all"), state = s(a, "state", "all");
            JSONArray out = new JSONArray();
            for (GitStore.Id id : st.list()) {
                JSONObject m = st.readMeta(id);
                for (String k : new String[]{"issues", "pulls"}) {
                    if (type.equals("issue") && k.equals("pulls") || type.equals("pr") && k.equals("issues")) continue;
                    JSONArray it = m.getJSONArray(k);
                    for (int x = 0; x < it.length(); x++) {
                        JSONObject o = it.getJSONObject(x);
                        if (!state.equals("all") && !state.equals(o.optString("state"))) continue;
                        StringBuilder hay = new StringBuilder(o.optString("title")).append('\n').append(o.optString("body"));
                        JSONArray cs = o.optJSONArray("comments");
                        if (cs != null) for (int y = 0; y < cs.length(); y++) hay.append('\n').append(cs.getJSONObject(y).optString("body"));
                        if (!hay.toString().toLowerCase(Locale.ROOT).contains(q)) continue;
                        out.put(new JSONObject().put("repo", id.full()).put("type", k.equals("issues") ? "issue" : "pr").put("number", o.getInt("number"))
                                .put("title", o.optString("title")).put("state", o.optString("state")).put("updated_at", o.optString("updated_at")));
                        if (out.length() >= i(a, "limit", 50)) return out;
                    }
                }
            }
            return out;
        });
        t.def("search_repositories", "Recherche des dépôts par nom, description ou sujet.", "r", new String[][]{{"query", "s", "Texte.", "1"}}, a -> {
            String q = s(a, "query").toLowerCase(Locale.ROOT);
            JSONArray out = new JSONArray();
            for (GitStore.Id id : st.list()) {
                JSONObject m = st.readMeta(id);
                String hay = (id.full() + " " + m.optString("description") + " " + m.optJSONArray("topics")).toLowerCase(Locale.ROOT);
                if (hay.contains(q)) out.put(new JSONObject().put("full_name", id.full()).put("description", m.optString("description"))
                        .put("stars", m.optJSONArray("stargazers") == null ? 0 : m.getJSONArray("stargazers").length()));
            }
            return out;
        });
    }
}
