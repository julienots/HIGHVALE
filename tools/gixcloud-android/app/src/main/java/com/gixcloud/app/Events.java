package com.gixcloud.app;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** Fil d'activité (push, tickets, PR, versions…) et webhooks sortants, comme sur GitHub. */
public final class Events {
    private static final ExecutorService HOOKS = Executors.newSingleThreadExecutor();
    private final Gix gix;

    Events(Gix gix) { this.gix = gix; }

    /** Enregistre un évènement dans le dépôt et déclenche ses webhooks. Ne lève jamais d'erreur. */
    public void emit(GitStore.Id id, String type, JSONObject payload) {
        try {
            final JSONObject ev = new JSONObject().put("type", type).put("repo", id.full())
                    .put("actor", Auth.current(gix).name).put("created_at", GitStore.now()).put("payload", payload == null ? new JSONObject() : payload);
            final JSONArray[] hooks = new JSONArray[1];
            gix.store.updateMeta(id, m -> {
                JSONArray evs = m.optJSONArray("events");
                if (evs == null) { evs = new JSONArray(); m.put("events", evs); }
                ev.put("id", m.optInt("next_event", 1));
                m.put("next_event", ev.getInt("id") + 1);
                evs.put(ev);
                while (evs.length() > 500) evs.remove(0);
                hooks[0] = m.optJSONArray("webhooks");
                return null;
            });
            if (hooks[0] != null) for (int i = 0; i < hooks[0].length(); i++) {
                JSONObject h = hooks[0].getJSONObject(i);
                if (!h.optBoolean("active", true)) continue;
                JSONArray want = h.optJSONArray("events");
                boolean match = want == null || want.length() == 0;
                if (want != null) for (int j = 0; j < want.length(); j++) if ("*".equals(want.optString(j)) || type.equals(want.optString(j))) match = true;
                if (match) fire(h.getString("url"), h.optString("secret"), ev);
            }
        } catch (Exception ignored) { }
    }

    private static void fire(String url, String secret, JSONObject ev) {
        HOOKS.execute(() -> {
            try {
                byte[] body = ev.toString().getBytes(StandardCharsets.UTF_8);
                HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
                c.setConnectTimeout(5000);
                c.setReadTimeout(10000);
                c.setRequestMethod("POST");
                c.setDoOutput(true);
                c.setRequestProperty("Content-Type", "application/json");
                c.setRequestProperty("X-GIXCLOUD-Event", ev.optString("type"));
                if (secret != null && !secret.isEmpty()) {
                    javax.crypto.Mac mac = javax.crypto.Mac.getInstance("HmacSHA256");
                    mac.init(new javax.crypto.spec.SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
                    StringBuilder sb = new StringBuilder("sha256=");
                    for (byte b : mac.doFinal(body)) sb.append(String.format("%02x", b));
                    c.setRequestProperty("X-Hub-Signature-256", sb.toString());
                }
                try (OutputStream o = c.getOutputStream()) { o.write(body); }
                c.getResponseCode();
                c.disconnect();
            } catch (Exception ignored) { }
        });
    }
}
