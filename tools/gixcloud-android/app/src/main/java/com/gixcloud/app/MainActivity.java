package com.gixcloud.app;

import android.Manifest;
import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;

/** Interface (HTML dans assets/ui) reliée aux mêmes outils que ceux exposés aux IA. */
public final class MainActivity extends Activity {
    private static final int PICK_APK = 7;
    private WebView web;
    private Gix gix;

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        gix = Gix.get(this);
        if (Build.VERSION.SDK_INT >= 33) requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 1);
        else if (Build.VERSION.SDK_INT < 29) requestPermissions(new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, 2);
        if (gix.prefs.getBoolean("autostart", true)) GixService.start(this);
        web = new WebView(this);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        web.addJavascriptInterface(new Bridge(), "GX");
        web.loadUrl("file:///android_asset/ui/index.html");
        setContentView(web);
        handleIncoming(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        handleIncoming(intent);
    }

    /** APK partagé ou ouvert depuis une autre appli : on le range dans GIXCLOUD. */
    private void handleIncoming(Intent it) {
        if (it == null) return;
        Uri uri = null;
        if (Intent.ACTION_VIEW.equals(it.getAction())) uri = it.getData();
        else if (Intent.ACTION_SEND.equals(it.getAction())) uri = it.getParcelableExtra(Intent.EXTRA_STREAM);
        if (uri != null) importApk(uri);
    }

    private void importApk(Uri uri) {
        try {
            String name = uri.getLastPathSegment() == null ? "importe.apk" : new File(uri.getLastPathSegment()).getName();
            if (!name.endsWith(".apk")) name = name.replaceAll("[^A-Za-z0-9._-]", "_") + ".apk";
            File f = new File(gix.store.apks, name);
            try (InputStream in = getContentResolver().openInputStream(uri)) { Files.copy(in, f.toPath(), StandardCopyOption.REPLACE_EXISTING); }
            Toast.makeText(this, "APK ajouté : " + name, Toast.LENGTH_SHORT).show();
            if (web != null) web.evaluateJavascript("window.refresh && refresh()", null);
        } catch (Exception e) {
            Toast.makeText(this, "Import impossible : " + e.getMessage(), Toast.LENGTH_LONG).show();
        }
    }

    @Override
    protected void onActivityResult(int req, int res, Intent data) {
        super.onActivityResult(req, res, data);
        if (req == PICK_APK && res == RESULT_OK && data != null && data.getData() != null) importApk(data.getData());
    }

    @Override
    public void onBackPressed() {
        web.evaluateJavascript("window.back ? back() : false", v -> { if (!"true".equals(v)) MainActivity.super.onBackPressed(); });
    }

    final class Bridge {
        @JavascriptInterface
        public String call(String name, String args) {
            try {
                Object v = gix.tools.call(name, new JSONObject(args == null || args.isEmpty() ? "{}" : args));
                return new JSONObject().put("ok", true).put("result", v).toString();
            } catch (Throwable e) {
                try { return new JSONObject().put("ok", false).put("error", String.valueOf(e.getMessage())).toString(); } catch (Exception x) { return "{\"ok\":false}"; }
            }
        }

        @JavascriptInterface
        public String status() {
            try {
                JSONArray ips = new JSONArray();
                for (String ip : Gix.localIps()) ips.put(ip);
                McpHttpServer srv = GixService.server;
                return new JSONObject().put("running", GixService.running()).put("port", gix.port()).put("lan", gix.lan()).put("token", gix.token())
                        .put("ips", ips).put("error", GixService.lastError).put("version", Gix.VERSION).put("owner", gix.owner())
                        .put("author", gix.authorName()).put("tools", gix.tools.tools.size())
                        .put("requests", srv == null ? 0 : srv.requests).put("last_client", srv == null ? "" : srv.lastClient).toString();
            } catch (Exception e) { return "{}"; }
        }

        @JavascriptInterface
        public void setServer(boolean on) {
            gix.prefs.edit().putBoolean("autostart", on).apply();
            if (on) GixService.start(MainActivity.this); else GixService.stop(MainActivity.this);
        }

        @JavascriptInterface
        public void settings(String json) {
            try {
                JSONObject o = new JSONObject(json);
                android.content.SharedPreferences.Editor e = gix.prefs.edit();
                if (o.has("port")) e.putInt("port", o.getInt("port"));
                if (o.has("lan")) e.putBoolean("lan", o.getBoolean("lan"));
                if (o.has("owner")) e.putString("owner", o.getString("owner"));
                if (o.has("author")) e.putString("author_name", o.getString("author"));
                if (o.optBoolean("new_token")) e.putString("token", Gix.newToken());
                e.apply();
                if (GixService.running()) {
                    new Handler(Looper.getMainLooper()).post(() -> {
                        GixService.stop(MainActivity.this);
                        new Handler(Looper.getMainLooper()).postDelayed(() -> GixService.start(MainActivity.this), 400);
                    });
                }
            } catch (Exception ignored) { }
        }

        @JavascriptInterface
        public void copy(String text) {
            ((ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE)).setPrimaryClip(ClipData.newPlainText("GIXCLOUD", text));
            runOnUiThread(() -> Toast.makeText(MainActivity.this, "Copié", Toast.LENGTH_SHORT).show());
        }

        @JavascriptInterface
        public void pickApk() {
            Intent it = new Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("application/vnd.android.package-archive");
            startActivityForResult(it, PICK_APK);
        }
    }
}
