package com.gixcloud.app;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Serveur MCP « Streamable HTTP » intégré (JSON-RPC 2.0 sur POST /mcp), protégé par jeton.
 * Routes :
 *   POST /mcp                         protocole MCP
 *   PUT  /upload/<nom>.apk            dépôt d'un APK (corps brut)
 *   GET  /download/apk/<nom>          récupération d'un APK
 *   GET  /download/release/<o>/<r>/<tag>/<fichier>
 *   GET  /                            page d'état (sans secret)
 */
public final class McpHttpServer {
    private static final String[] PROTOCOLS = {"2025-06-18", "2025-03-26", "2024-11-05"};
    private final Gix gix;
    private ServerSocket server;
    private ExecutorService pool;
    private volatile boolean running;
    public volatile String lastClient = "";
    public volatile int requests = 0;

    private final GitHttp gitHttp;

    public McpHttpServer(Gix gix) { this.gix = gix; this.gitHttp = new GitHttp(gix); }

    public boolean isRunning() { return running; }

    public synchronized void start() throws Exception {
        if (running) return;
        server = new ServerSocket();
        server.setReuseAddress(true);
        InetAddress bind = gix.lan() ? null : InetAddress.getByName("127.0.0.1");
        server.bind(bind == null ? new InetSocketAddress(gix.port()) : new InetSocketAddress(bind, gix.port()));
        pool = Executors.newFixedThreadPool(8);
        running = true;
        Thread t = new Thread(() -> {
            while (running) {
                try {
                    Socket s = server.accept();
                    pool.execute(() -> handle(s));
                } catch (Exception e) {
                    if (!running) break;
                }
            }
        }, "gixcloud-http");
        t.setDaemon(true);
        t.start();
    }

    public synchronized void stop() {
        running = false;
        try { if (server != null) server.close(); } catch (Exception ignored) { }
        if (pool != null) pool.shutdownNow();
    }

    // ---------- HTTP minimal ----------

    private static String readLine(InputStream in) throws Exception {
        ByteArrayOutputStream b = new ByteArrayOutputStream();
        int c;
        while ((c = in.read()) != -1) {
            if (c == '\n') break;
            if (c != '\r') b.write(c);
            if (b.size() > 16384) throw new Exception("ligne trop longue");
        }
        if (c == -1 && b.size() == 0) return null;
        return b.toString("UTF-8");
    }

    private void handle(Socket s) {
        try (Socket sock = s) {
            sock.setSoTimeout(120_000);
            InputStream in = new BufferedInputStream(sock.getInputStream());
            OutputStream out = sock.getOutputStream();
            String line = readLine(in);
            if (line == null || line.isEmpty()) return;
            String[] rl = line.split(" ");
            if (rl.length < 2) { send(out, 400, "text/plain", "Requête invalide".getBytes(StandardCharsets.UTF_8), null); return; }
            String method = rl[0].toUpperCase(Locale.ROOT);
            String target = rl[1];
            Map<String, String> h = new HashMap<>();
            String hl;
            while ((hl = readLine(in)) != null && !hl.isEmpty()) {
                int i = hl.indexOf(':');
                if (i > 0) h.put(hl.substring(0, i).trim().toLowerCase(Locale.ROOT), hl.substring(i + 1).trim());
            }
            String path = target, query = "";
            int q = target.indexOf('?');
            if (q >= 0) { path = target.substring(0, q); query = target.substring(q + 1); }
            lastClient = sock.getInetAddress().getHostAddress();
            requests++;

            if (method.equals("OPTIONS")) { send(out, 204, "text/plain", new byte[0], null); return; }
            if (path.equals("/") && method.equals("GET")) {
                String body = "GIXCLOUD " + Gix.VERSION + " — serveur MCP actif.\nPoint d'accès : POST /mcp (en-tête Authorization: Bearer <jeton>)\nGit : git clone http://<IP>:" + gix.port() + "/git/<propriétaire>/<dépôt>.git (mot de passe = jeton)\n";
                send(out, 200, "text/plain; charset=utf-8", body.getBytes(StandardCharsets.UTF_8), null);
                return;
            }
            Auth.User user = authorized(h, query);
            if (GitHttp.handles(path)) {
                if (user == null && !GitHttp.isPublic(path)) {
                    drain(in, h);
                    send(out, 401, "text/plain; charset=utf-8", "Authentification requise : mot de passe = jeton GIXCLOUD\n".getBytes(StandardCharsets.UTF_8),
                            new String[]{"WWW-Authenticate", "Basic realm=\"GIXCLOUD\""});
                    return;
                }
                Auth.set(user != null ? user : new Auth.User("public", "read"));
                try { gitHttp.handle(method, path, query, h, in, out, user != null ? user : new Auth.User("public", "read")); } finally { Auth.clear(); }
                return;
            }
            if (user == null) {
                drain(in, h);
                send(out, 401, "application/json", "{\"error\":\"Jeton GIXCLOUD manquant ou invalide\"}".getBytes(StandardCharsets.UTF_8),
                        new String[]{"WWW-Authenticate", "Bearer realm=\"gixcloud\""});
                return;
            }
            Auth.set(user);

            if (path.equals("/mcp")) {
                if (method.equals("GET")) { send(out, 405, "text/plain", "Utilisez POST".getBytes(StandardCharsets.UTF_8), new String[]{"Allow", "POST"}); return; }
                if (method.equals("DELETE")) { send(out, 200, "text/plain", new byte[0], null); return; }
                if (!method.equals("POST")) { send(out, 405, "text/plain", new byte[0], null); return; }
                byte[] body = readBody(in, h, 64L * 1024 * 1024);
                String res = mcp(new String(body, StandardCharsets.UTF_8));
                String sid = h.containsKey("mcp-session-id") ? h.get("mcp-session-id") : UUID.randomUUID().toString();
                if (res == null) send(out, 202, "application/json", new byte[0], new String[]{"Mcp-Session-Id", sid});
                else send(out, 200, "application/json", res.getBytes(StandardCharsets.UTF_8), new String[]{"Mcp-Session-Id", sid});
                return;
            }
            if (path.startsWith("/upload/") && (method.equals("PUT") || method.equals("POST"))) {
                if (!user.can("write")) { drain(in, h); send(out, 403, "text/plain", "Jeton en lecture seule".getBytes(StandardCharsets.UTF_8), null); return; }
                String name = new File(URLDecoder.decode(path.substring(8), "UTF-8")).getName();
                if (!name.endsWith(".apk")) name += ".apk";
                File f = new File(gix.store.apks, name);
                long len = Long.parseLong(h.getOrDefault("content-length", "-1"));
                if (len < 0) { send(out, 411, "text/plain", "Content-Length requis".getBytes(StandardCharsets.UTF_8), null); return; }
                try (OutputStream fo = new FileOutputStream(f)) {
                    byte[] buf = new byte[65536];
                    long left = len;
                    while (left > 0) {
                        int n = in.read(buf, 0, (int) Math.min(buf.length, left));
                        if (n < 0) throw new Exception("connexion coupée");
                        fo.write(buf, 0, n);
                        left -= n;
                    }
                }
                JSONObject info;
                try { info = gix.tools.apkInfo(f); } catch (Throwable e) { info = new JSONObject().put("name", name).put("size", f.length()); }
                try {
                    if (query.contains("install=1")) info.put("install", Installer.install(gix.app, f));
                    Installer.notifyIntent(gix.app, 43, "APK reçu : " + name, "Ouvrez GIXCLOUD pour l'installer.",
                            new android.content.Intent(gix.app, MainActivity.class));
                } catch (Throwable e) { info.put("notice", String.valueOf(e.getMessage())); }
                send(out, 200, "application/json", info.toString(2).getBytes(StandardCharsets.UTF_8), null);
                return;
            }
            if (path.startsWith("/download/") && method.equals("GET")) {
                String rest = URLDecoder.decode(path.substring(10), "UTF-8");
                File base = rest.startsWith("apk/") ? gix.store.apks : rest.startsWith("release/") ? gix.store.releases : null;
                File f = base == null ? null : new File(base, rest.substring(rest.indexOf('/') + 1));
                if (f == null || !f.getCanonicalPath().startsWith(base.getCanonicalPath() + File.separator) || !f.isFile()) {
                    send(out, 404, "text/plain", "Introuvable".getBytes(StandardCharsets.UTF_8), null);
                    return;
                }
                String head = "HTTP/1.1 200 OK\r\nContent-Type: application/vnd.android.package-archive\r\nContent-Length: " + f.length()
                        + "\r\nContent-Disposition: attachment; filename=\"" + f.getName() + "\"\r\nConnection: close\r\n\r\n";
                out.write(head.getBytes(StandardCharsets.UTF_8));
                try (InputStream fi = new FileInputStream(f)) {
                    byte[] buf = new byte[65536];
                    int n;
                    while ((n = fi.read(buf)) > 0) out.write(buf, 0, n);
                }
                out.flush();
                return;
            }
            send(out, 404, "text/plain", "Introuvable".getBytes(StandardCharsets.UTF_8), null);
        } catch (Exception ignored) {
        } finally { Auth.clear(); }
    }

    private Auth.User authorized(Map<String, String> h, String query) {
        String tok = null;
        String auth = h.get("authorization");
        if (auth != null && auth.regionMatches(true, 0, "Bearer ", 0, 7)) tok = auth.substring(7).trim();
        if (auth != null && auth.regionMatches(true, 0, "Basic ", 0, 6)) {
            try {
                String dec = new String(java.util.Base64.getDecoder().decode(auth.substring(6).trim()), StandardCharsets.UTF_8);
                tok = dec.contains(":") ? dec.substring(dec.indexOf(':') + 1) : dec;
                if (tok.isEmpty()) tok = dec.substring(0, Math.max(0, dec.indexOf(':')));
            } catch (Exception ignored) { }
        }
        if (tok == null) tok = h.get("x-gixcloud-token");
        if (tok == null) for (String kv : query.split("&")) if (kv.startsWith("token=")) tok = kv.substring(6);
        return gix.auth.check(tok);
    }

    private static byte[] readBody(InputStream in, Map<String, String> h, long max) throws Exception {
        long len = Long.parseLong(h.getOrDefault("content-length", "0"));
        if (len > max) throw new Exception("corps trop gros");
        byte[] b = new byte[(int) len];
        int off = 0;
        while (off < len) {
            int n = in.read(b, off, (int) len - off);
            if (n < 0) break;
            off += n;
        }
        return b;
    }

    private static void drain(InputStream in, Map<String, String> h) {
        try {
            long len = Long.parseLong(h.getOrDefault("content-length", "0"));
            if (len < 1_000_000) readBody(in, h, len);
        } catch (Exception ignored) { }
    }

    private static void send(OutputStream out, int code, String type, byte[] body, String[] extra) throws Exception {
        StringBuilder sb = new StringBuilder("HTTP/1.1 ").append(code).append(' ').append(reason(code)).append("\r\n");
        sb.append("Content-Type: ").append(type).append("\r\nContent-Length: ").append(body.length).append("\r\nConnection: close\r\n");
        sb.append("Access-Control-Allow-Origin: *\r\nAccess-Control-Allow-Headers: Authorization, Content-Type, Mcp-Session-Id, Mcp-Protocol-Version\r\n");
        sb.append("Access-Control-Expose-Headers: Mcp-Session-Id\r\n");
        if (extra != null) for (int i = 0; i + 1 < extra.length; i += 2) sb.append(extra[i]).append(": ").append(extra[i + 1]).append("\r\n");
        sb.append("\r\n");
        out.write(sb.toString().getBytes(StandardCharsets.UTF_8));
        out.write(body);
        out.flush();
    }

    private static String reason(int c) {
        switch (c) {
            case 200: return "OK"; case 202: return "Accepted"; case 204: return "No Content"; case 400: return "Bad Request";
            case 401: return "Unauthorized"; case 404: return "Not Found"; case 405: return "Method Not Allowed"; case 411: return "Length Required";
            default: return "Error";
        }
    }

    // ---------- MCP (JSON-RPC) ----------

    /** Traite un message ou un lot ; renvoie null s'il n'y avait que des notifications. */
    public String mcp(String text) {
        try {
            Object parsed = new org.json.JSONTokener(text).nextValue();
            if (parsed instanceof JSONArray) {
                JSONArray in = (JSONArray) parsed, out = new JSONArray();
                for (int i = 0; i < in.length(); i++) { JSONObject r = one(in.getJSONObject(i)); if (r != null) out.put(r); }
                return out.length() == 0 ? null : out.toString();
            }
            JSONObject r = one((JSONObject) parsed);
            return r == null ? null : r.toString();
        } catch (Exception e) {
            return "{\"jsonrpc\":\"2.0\",\"id\":null,\"error\":{\"code\":-32700,\"message\":\"JSON invalide\"}}";
        }
    }

    private JSONObject one(JSONObject msg) throws Exception {
        Object id = msg.opt("id");
        boolean request = id != null && id != JSONObject.NULL;
        String method = msg.optString("method");
        JSONObject params = msg.optJSONObject("params");
        JSONObject res = new JSONObject().put("jsonrpc", "2.0").put("id", request ? id : JSONObject.NULL);
        try {
            JSONObject result;
            switch (method) {
                case "initialize": {
                    String asked = params == null ? "" : params.optString("protocolVersion");
                    String v = PROTOCOLS[0];
                    for (String p : PROTOCOLS) if (p.equals(asked)) v = p;
                    result = new JSONObject().put("protocolVersion", v)
                            .put("capabilities", new JSONObject().put("tools", new JSONObject().put("listChanged", false)))
                            .put("serverInfo", new JSONObject().put("name", "gixcloud").put("version", Gix.VERSION))
                            .put("instructions", "GIXCLOUD : forge git (équivalent de GitHub) qui tourne sur un téléphone Android, plus gestion des APK. "
                                    + "« repo » accepte « nom » ou « propriétaire/nom ». Pour envoyer un APK : upload_apk (base64) ou HTTP PUT /upload/<nom>.apk, "
                                    + "puis install_apk (l'utilisateur confirme sur le téléphone).");
                    break;
                }
                case "ping": result = new JSONObject(); break;
                case "tools/list": result = new JSONObject().put("tools", gix.tools.list()); break;
                case "tools/call": {
                    String name = params.getString("name");
                    JSONObject content = new JSONObject().put("type", "text");
                    result = new JSONObject();
                    try {
                        Object v = gix.tools.call(name, params.optJSONObject("arguments"));
                        String t = v instanceof JSONObject ? ((JSONObject) v).toString(2) : v instanceof JSONArray ? ((JSONArray) v).toString(2) : String.valueOf(v);
                        content.put("text", t);
                    } catch (Throwable e) {
                        String m = e.getMessage() == null ? e.getClass().getSimpleName() : e.getMessage();
                        content.put("text", "Erreur : " + m);
                        result.put("isError", true);
                    }
                    result.put("content", new JSONArray().put(content));
                    break;
                }
                case "resources/list": result = new JSONObject().put("resources", new JSONArray()); break;
                case "prompts/list": result = new JSONObject().put("prompts", new JSONArray()); break;
                default:
                    if (!request) return null;
                    return res.put("error", new JSONObject().put("code", -32601).put("message", "Méthode non prise en charge : " + method));
            }
            return request ? res.put("result", result) : null;
        } catch (Exception e) {
            return request ? res.put("error", new JSONObject().put("code", -32603).put("message", String.valueOf(e.getMessage()))) : null;
        }
    }
}
