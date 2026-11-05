package com.gixcloud.app;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.MessageDigest;

/**
 * Jetons d'accès (comme les « personal access tokens » de GitHub) : un par IA ou par personne,
 * avec un niveau read / write / admin. Le jeton principal (affiché dans l'appli) est admin.
 * Seule l'empreinte SHA-256 des jetons supplémentaires est conservée.
 */
public final class Auth {
    public static final class User {
        public final String name, perm;
        User(String n, String p) { name = n; perm = p; }
        public boolean can(String need) { return rank(perm) >= rank(need); }
        static int rank(String p) { return "admin".equals(p) ? 3 : "write".equals(p) ? 2 : "read".equals(p) ? 1 : 0; }
    }

    private static final ThreadLocal<User> CURRENT = new ThreadLocal<>();
    public static void set(User u) { CURRENT.set(u); }
    public static void clear() { CURRENT.remove(); }
    /** Utilisateur de la requête en cours (l'appli elle-même = propriétaire admin). */
    public static User current(Gix gix) { User u = CURRENT.get(); return u != null ? u : new User(gix.authorName(), "admin"); }

    private final Gix gix;
    private final File file;

    Auth(Gix gix) {
        this.gix = gix;
        file = new File(gix.root, "tokens.json");
    }

    static String sha(String s) {
        try {
            byte[] d = MessageDigest.getInstance("SHA-256").digest(s.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : d) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) { throw new RuntimeException(e); }
    }

    synchronized JSONArray load() {
        try {
            return file.exists() ? new JSONArray(new String(Files.readAllBytes(file.toPath()), StandardCharsets.UTF_8)) : new JSONArray();
        } catch (Exception e) { return new JSONArray(); }
    }

    synchronized void save(JSONArray a) {
        try (FileOutputStream o = new FileOutputStream(file)) { o.write(a.toString(2).getBytes(StandardCharsets.UTF_8)); } catch (Exception ignored) { }
    }

    /** Vérifie un jeton ; renvoie l'utilisateur ou null. */
    public User check(String token) {
        if (token == null || token.isEmpty()) return null;
        if (MessageDigest.isEqual(token.getBytes(StandardCharsets.UTF_8), gix.token().getBytes(StandardCharsets.UTF_8))) return new User(gix.authorName(), "admin");
        String h = sha(token);
        JSONArray a = load();
        for (int i = 0; i < a.length(); i++) {
            JSONObject t = a.optJSONObject(i);
            if (t != null && h.equals(t.optString("hash"))) {
                try { t.put("last_used", GitStore.now()); save(a); } catch (Exception ignored) { }
                return new User(t.optString("name"), t.optString("perm", "read"));
            }
        }
        return null;
    }

    public JSONObject create(String name, String perm) throws Exception {
        if (name == null || name.trim().isEmpty()) throw new Tools.Err("Nom requis (ex. Claude, Cursor, Julien).");
        if (User.rank(perm) == 0) throw new Tools.Err("Permission : read, write ou admin.");
        String tok = Gix.newToken();
        JSONArray a = load();
        for (int i = 0; i < a.length(); i++) if (name.equals(a.getJSONObject(i).optString("name"))) throw new Tools.Err("Un jeton porte déjà ce nom.");
        a.put(new JSONObject().put("name", name.trim()).put("perm", perm).put("hash", sha(tok)).put("prefix", tok.substring(0, 10)).put("created_at", GitStore.now()));
        save(a);
        return new JSONObject().put("name", name.trim()).put("perm", perm).put("token", tok)
                .put("note", "Copiez ce jeton maintenant : il ne sera plus jamais affiché.");
    }

    public JSONArray list() throws Exception {
        JSONArray a = load(), out = new JSONArray();
        out.put(new JSONObject().put("name", gix.authorName() + " (jeton principal)").put("perm", "admin").put("prefix", gix.token().substring(0, Math.min(10, gix.token().length()))));
        for (int i = 0; i < a.length(); i++) {
            JSONObject t = new JSONObject(a.getJSONObject(i).toString());
            t.remove("hash");
            out.put(t);
        }
        return out;
    }

    public boolean revoke(String name) {
        JSONArray a = load(), keep = new JSONArray();
        boolean found = false;
        for (int i = 0; i < a.length(); i++) {
            if (name.equals(a.optJSONObject(i).optString("name"))) found = true; else keep.put(a.opt(i));
        }
        save(keep);
        return found;
    }
}
