package com.gixcloud.app;

import org.eclipse.jgit.lib.Constants;
import org.eclipse.jgit.lib.ObjectId;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.revwalk.RevCommit;
import org.eclipse.jgit.revwalk.RevWalk;
import org.eclipse.jgit.transport.PacketLineOut;
import org.eclipse.jgit.transport.ReceiveCommand;
import org.eclipse.jgit.transport.ReceivePack;
import org.eclipse.jgit.transport.RefAdvertiser;
import org.eclipse.jgit.transport.UploadPack;
import org.eclipse.jgit.treewalk.TreeWalk;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.FilterInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.Map;
import java.util.zip.GZIPInputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

/**
 * Accès git par le réseau, comme github.com :
 *   git clone http://IP:8765/git/<propriétaire>/<dépôt>.git   (identifiant : n'importe quoi, mot de passe : le jeton)
 * plus fichiers bruts (/raw), archives ZIP (/archive) et sites statiques (/pages, comme GitHub Pages).
 */
final class GitHttp {
    private final Gix gix;

    GitHttp(Gix gix) { this.gix = gix; }

    static boolean handles(String path) {
        return path.startsWith("/git/") || path.startsWith("/raw/") || path.startsWith("/archive/") || path.startsWith("/pages/");
    }

    static boolean isPublic(String path) { return path.startsWith("/pages/"); }

    /** Le corps de requête peut être « chunked » et/ou compressé gzip (git le fait pour les gros envois). */
    static InputStream body(InputStream in, Map<String, String> h) throws IOException {
        InputStream b;
        if ("chunked".equalsIgnoreCase(h.getOrDefault("transfer-encoding", ""))) b = new Chunked(in);
        else b = new Limited(in, Long.parseLong(h.getOrDefault("content-length", "0")));
        if ("gzip".equalsIgnoreCase(h.getOrDefault("content-encoding", ""))) b = new GZIPInputStream(b);
        return b;
    }

    static void head(OutputStream out, int code, String type) throws IOException {
        String s = "HTTP/1.1 " + code + (code == 200 ? " OK" : code == 404 ? " Not Found" : code == 403 ? " Forbidden" : " Error")
                + "\r\nContent-Type: " + type + "\r\nCache-Control: no-cache\r\nConnection: close\r\n\r\n";
        out.write(s.getBytes(StandardCharsets.UTF_8));
    }

    static void text(OutputStream out, int code, String msg) throws IOException {
        head(out, code, "text/plain; charset=utf-8");
        out.write((msg + "\n").getBytes(StandardCharsets.UTF_8));
        out.flush();
    }

    void handle(String method, String path, String query, Map<String, String> h, InputStream in, OutputStream out, Auth.User user) throws Exception {
        String[] seg = path.substring(1).split("/");
        for (int i = 0; i < seg.length; i++) seg[i] = URLDecoder.decode(seg[i], "UTF-8");
        if (seg.length < 3) { text(out, 404, "Introuvable"); return; }
        String kind = seg[0];
        GitStore.Id id;
        try { id = gix.store.id(seg[1], seg[2].replaceAll("\\.git$", "")); } catch (Tools.Err e) { text(out, 404, e.getMessage()); return; }
        if (!gix.store.exists(id)) { text(out, 404, "Dépôt introuvable : " + id.full()); return; }
        StringBuilder rest = new StringBuilder();
        for (int i = 3; i < seg.length; i++) rest.append(i > 3 ? "/" : "").append(seg[i]);
        try (Repository r = gix.store.open(id)) {
            switch (kind) {
                case "git": git(method, rest.toString(), query, h, in, out, user, r, id); break;
                case "raw": raw(rest.toString(), out, r); break;
                case "archive": archive(rest.toString(), out, r, id); break;
                case "pages": pages(rest.toString(), out, r, id); break;
                default: text(out, 404, "Introuvable");
            }
        }
    }

    // ---------- Protocole git « smart HTTP » ----------

    private void git(String method, String rest, String query, Map<String, String> h, InputStream in, OutputStream out, Auth.User user, Repository r, GitStore.Id id) throws Exception {
        String service = null;
        if (rest.equals("info/refs")) {
            for (String kv : query.split("&")) if (kv.startsWith("service=")) service = kv.substring(8);
            if (!"git-upload-pack".equals(service) && !"git-receive-pack".equals(service)) {
                text(out, 403, "Protocole git « dumb » non pris en charge : mettez git à jour.");
                return;
            }
            if (service.equals("git-receive-pack") && !user.can("write")) { text(out, 403, "Ce jeton est en lecture seule."); return; }
            head(out, 200, "application/x-" + service + "-advertisement");
            PacketLineOut pl = new PacketLineOut(out);
            pl.writeString("# service=" + service + "\n");
            pl.end();
            RefAdvertiser.PacketLineOutRefAdvertiser adv = new RefAdvertiser.PacketLineOutRefAdvertiser(pl);
            if (service.equals("git-upload-pack")) {
                UploadPack up = new UploadPack(r);
                up.setBiDirectionalPipe(false);
                up.sendAdvertisedRefs(adv);
            } else {
                receivePack(r, id).sendAdvertisedRefs(adv);
            }
            out.flush();
            return;
        }
        if (method.equals("POST") && rest.equals("git-upload-pack")) {
            head(out, 200, "application/x-git-upload-pack-result");
            UploadPack up = new UploadPack(r);
            up.setBiDirectionalPipe(false);
            up.upload(body(in, h), out, null);
            out.flush();
            return;
        }
        if (method.equals("POST") && rest.equals("git-receive-pack")) {
            if (!user.can("write")) { text(out, 403, "Ce jeton est en lecture seule."); return; }
            head(out, 200, "application/x-git-receive-pack-result");
            ReceivePack rp = receivePack(r, id);
            rp.receive(body(in, h), out, null);
            out.flush();
            return;
        }
        text(out, 404, "Introuvable");
    }

    private ReceivePack receivePack(Repository r, GitStore.Id id) {
        ReceivePack rp = new ReceivePack(r);
        rp.setBiDirectionalPipe(false);
        rp.setAllowCreates(true);
        rp.setAllowDeletes(true);
        rp.setAllowNonFastForwards(true);
        rp.setRefLogIdent(gix.store.person());
        rp.setPreReceiveHook((pack, cmds) -> {
            JSONObject m = gix.store.readMeta(id);
            JSONObject prot = m.optJSONObject("protection");
            String def = GitStore.defaultBranch(r);
            for (ReceiveCommand c : cmds) {
                String ref = c.getRefName();
                if (m.optBoolean("archived")) { c.setResult(ReceiveCommand.Result.REJECTED_OTHER_REASON, "dépôt archivé (lecture seule)"); continue; }
                if (ref.startsWith("refs/pull/")) { c.setResult(ReceiveCommand.Result.REJECTED_OTHER_REASON, "refs/pull est réservé aux pull requests"); continue; }
                if (!ref.startsWith(Constants.R_HEADS)) continue;
                String br = ref.substring(Constants.R_HEADS.length());
                if (c.getType() == ReceiveCommand.Type.DELETE && br.equals(def)) { c.setResult(ReceiveCommand.Result.REJECTED_NODELETE, "branche par défaut"); continue; }
                JSONObject p = prot == null ? null : prot.optJSONObject(br);
                if (p == null) continue;
                if (p.optBoolean("require_pull_request")) { c.setResult(ReceiveCommand.Result.REJECTED_OTHER_REASON, "branche protégée : passez par une pull request"); continue; }
                if (c.getType() == ReceiveCommand.Type.UPDATE_NONFASTFORWARD && !p.optBoolean("allow_force_push")) { c.setResult(ReceiveCommand.Result.REJECTED_NONFASTFORWARD, "branche protégée : push forcé interdit"); continue; }
                if (c.getType() == ReceiveCommand.Type.DELETE && !p.optBoolean("allow_deletion")) c.setResult(ReceiveCommand.Result.REJECTED_NODELETE, "branche protégée");
            }
        });
        rp.setPostReceiveHook((pack, cmds) -> {
            for (ReceiveCommand c : cmds) {
                if (c.getResult() != ReceiveCommand.Result.OK) continue;
                try {
                    JSONObject p = new JSONObject().put("ref", c.getRefName()).put("before", c.getOldId().getName()).put("after", c.getNewId().getName())
                            .put("type", c.getType().name().toLowerCase(Locale.ROOT));
                    if (c.getType() != ReceiveCommand.Type.DELETE) {
                        JSONArray commits = new JSONArray();
                        for (RevCommit rc : GitStore.range(r, c.getOldId().equals(ObjectId.zeroId()) ? null : c.getOldId(), c.getNewId(), 20))
                            commits.put(new JSONObject().put("sha", rc.getName()).put("message", rc.getShortMessage()).put("author", rc.getAuthorIdent().getName()));
                        p.put("commits", commits);
                    }
                    gix.events.emit(id, "push", p);
                } catch (Exception ignored) { }
            }
        });
        return rp;
    }

    // ---------- Fichiers bruts, archives, Pages ----------

    /** rest = <ref>/<chemin> ; la référence peut contenir des « / » (feature/x) : on essaie la plus longue. */
    private static Object[] refAndPath(Repository r, String rest) {
        String[] p = rest.split("/");
        for (int k = p.length - 1; k >= 1; k--) {
            String ref = String.join("/", java.util.Arrays.copyOfRange(p, 0, k));
            ObjectId c = GitStore.resolve(r, ref);
            if (c != null) return new Object[]{c, String.join("/", java.util.Arrays.copyOfRange(p, k, p.length))};
        }
        return null;
    }

    private static byte[] file(Repository r, ObjectId commit, String path) throws Exception {
        try (RevWalk rw = new RevWalk(r)) {
            TreeWalk tw = TreeWalk.forPath(r, path, rw.parseCommit(commit).getTree());
            if (tw == null || tw.isSubtree()) return null;
            return GitStore.readBlob(r, tw.getObjectId(0));
        }
    }

    private void raw(String rest, OutputStream out, Repository r) throws Exception {
        Object[] rp = refAndPath(r, rest);
        byte[] data = rp == null ? null : file(r, (ObjectId) rp[0], (String) rp[1]);
        if (data == null) { text(out, 404, "Fichier introuvable"); return; }
        head(out, 200, mime((String) rp[1], true));
        out.write(data);
        out.flush();
    }

    private void archive(String rest, OutputStream out, Repository r, GitStore.Id id) throws Exception {
        String ref = rest.replaceAll("\\.zip$", "");
        if (ref.isEmpty()) ref = GitStore.defaultBranch(r);
        ObjectId c = GitStore.resolve(r, ref);
        if (c == null) { text(out, 404, "Référence introuvable : " + ref); return; }
        String prefix = id.repo + "-" + ref.replace('/', '-') + "/";
        head(out, 200, "application/zip");
        try (ZipOutputStream z = new ZipOutputStream(out)) {
            TreeWalk tw = GitStore.walk(r, c, true);
            while (tw.next()) {
                z.putNextEntry(new ZipEntry(prefix + tw.getPathString()));
                z.write(GitStore.readBlob(r, tw.getObjectId(0)));
                z.closeEntry();
            }
        }
    }

    private void pages(String rest, OutputStream out, Repository r, GitStore.Id id) throws Exception {
        JSONObject p = gix.store.readMeta(id).optJSONObject("pages");
        if (p == null || !p.optBoolean("enabled")) { text(out, 404, "GIXCLOUD Pages n'est pas activé pour ce dépôt (enable_pages)."); return; }
        ObjectId c = GitStore.resolve(r, p.optString("branch", GitStore.defaultBranch(r)));
        if (c == null) { text(out, 404, "Branche de Pages introuvable"); return; }
        String folder = p.optString("folder", "").replaceAll("^/+|/+$", "");
        String base = folder.isEmpty() ? "" : folder + "/";
        String path = base + rest;
        byte[] data = rest.isEmpty() || rest.endsWith("/") ? null : file(r, c, path);
        if (data == null) {
            path = path.isEmpty() || path.endsWith("/") ? path + "index.html" : path + "/index.html";
            data = file(r, c, path);
        }
        if (data == null) { byte[] nf = file(r, c, base + "404.html"); head(out, 404, "text/html; charset=utf-8"); out.write(nf != null ? nf : "Page introuvable".getBytes(StandardCharsets.UTF_8)); out.flush(); return; }
        head(out, 200, mime(path, false));
        out.write(data);
        out.flush();
    }

    static String mime(String p, boolean raw) {
        String e = p.contains(".") ? p.substring(p.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT) : "";
        switch (e) {
            case "html": case "htm": return raw ? "text/plain; charset=utf-8" : "text/html; charset=utf-8";
            case "css": return "text/css; charset=utf-8";
            case "js": case "mjs": return raw ? "text/plain; charset=utf-8" : "application/javascript; charset=utf-8";
            case "json": return "application/json; charset=utf-8";
            case "svg": return "image/svg+xml";
            case "png": return "image/png";
            case "jpg": case "jpeg": return "image/jpeg";
            case "gif": return "image/gif";
            case "webp": return "image/webp";
            case "ico": return "image/x-icon";
            case "pdf": return "application/pdf";
            case "apk": return "application/vnd.android.package-archive";
            case "zip": return "application/zip";
            case "wasm": return "application/wasm";
            case "mp3": return "audio/mpeg";
            case "mp4": return "video/mp4";
            case "woff2": return "font/woff2";
            default: return "text/plain; charset=utf-8";
        }
    }

    // ---------- Flux d'entrée ----------

    static final class Limited extends FilterInputStream {
        long left;
        Limited(InputStream in, long n) { super(in); left = n; }
        @Override public int read() throws IOException { if (left <= 0) return -1; int c = super.read(); if (c >= 0) left--; return c; }
        @Override public int read(byte[] b, int off, int len) throws IOException {
            if (left <= 0) return -1;
            int n = super.read(b, off, (int) Math.min(len, left));
            if (n > 0) left -= n;
            return n;
        }
        @Override public void close() { }
    }

    static final class Chunked extends InputStream {
        private final InputStream in;
        private long left = 0;
        private boolean done = false;
        Chunked(InputStream in) { this.in = in; }

        private String line() throws IOException {
            StringBuilder sb = new StringBuilder();
            int c;
            while ((c = in.read()) != -1 && c != '\n') if (c != '\r') sb.append((char) c);
            return sb.toString();
        }

        private boolean next() throws IOException {
            if (done) return false;
            if (left == 0) {
                String l = line();
                if (l.isEmpty()) l = line();
                int semi = l.indexOf(';');
                left = Long.parseLong((semi >= 0 ? l.substring(0, semi) : l).trim(), 16);
                if (left == 0) { done = true; String t; while (!(t = line()).isEmpty()) { if (t == null) break; } return false; }
            }
            return true;
        }

        @Override public int read() throws IOException {
            byte[] b = new byte[1];
            int n = read(b, 0, 1);
            return n <= 0 ? -1 : b[0] & 0xff;
        }

        @Override public int read(byte[] b, int off, int len) throws IOException {
            if (!next()) return -1;
            int n = in.read(b, off, (int) Math.min(len, left));
            if (n > 0) left -= n;
            return n;
        }

        @Override public void close() { }
    }
}
