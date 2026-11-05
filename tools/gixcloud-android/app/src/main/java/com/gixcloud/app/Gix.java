package com.gixcloud.app;

import android.content.Context;
import android.content.SharedPreferences;

import org.eclipse.jgit.lib.Config;
import org.eclipse.jgit.storage.file.FileBasedConfig;
import org.eclipse.jgit.util.FS;
import org.eclipse.jgit.util.SystemReader;

import java.io.File;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.TimeZone;

/** État global de l'application : dossiers, réglages, moteur git, outils. */
public final class Gix {
    public static final String VERSION = "1.0.0";
    private static Gix instance;

    public final Context app;
    public final File root;
    public final SharedPreferences prefs;
    public final GitStore store;
    public final Tools tools;

    private Gix(Context ctx) {
        app = ctx.getApplicationContext();
        root = new File(app.getFilesDir(), "gixcloud");
        root.mkdirs();
        prefs = app.getSharedPreferences("gixcloud", Context.MODE_PRIVATE);
        installSystemReader(new File(root, "config"));
        if (!prefs.contains("token")) prefs.edit().putString("token", newToken()).apply();
        store = new GitStore(this);
        tools = new Tools(this);
    }

    public static synchronized Gix get(Context ctx) {
        if (instance == null) instance = new Gix(ctx);
        return instance;
    }

    public int port() { return prefs.getInt("port", 8765); }
    public boolean lan() { return prefs.getBoolean("lan", true); }
    public String token() { return prefs.getString("token", ""); }
    public String owner() { return prefs.getString("owner", "moi"); }
    public String authorName() { return prefs.getString("author_name", "GIXCLOUD"); }
    public String authorEmail() { return prefs.getString("author_email", "gixcloud@telephone.local"); }

    public static String newToken() {
        byte[] b = new byte[18];
        new SecureRandom().nextBytes(b);
        StringBuilder sb = new StringBuilder("gix_");
        for (byte x : b) sb.append(String.format("%02x", x));
        return sb.toString();
    }

    public static List<String> localIps() {
        List<String> out = new ArrayList<>();
        try {
            for (NetworkInterface ni : Collections.list(NetworkInterface.getNetworkInterfaces())) {
                if (!ni.isUp() || ni.isLoopback()) continue;
                for (InetAddress a : Collections.list(ni.getInetAddresses())) {
                    if (a instanceof Inet4Address) out.add(a.getHostAddress());
                }
            }
        } catch (Exception ignored) { }
        return out;
    }

    /** JGit lit normalement ~/.gitconfig et lance « git » : sur Android on lui donne des configs vides. */
    private static void installSystemReader(File configDir) {
        configDir.mkdirs();
        final File user = new File(configDir, "user.gitconfig");
        final File system = new File(configDir, "system.gitconfig");
        final File jgit = new File(configDir, "jgit.gitconfig");
        SystemReader.setInstance(new SystemReader() {
            @Override public String getHostname() { return "android"; }
            @Override public String getenv(String v) { return null; }
            @Override public String getProperty(String k) { return System.getProperty(k); }
            @Override public FileBasedConfig openUserConfig(Config parent, FS fs) { return new FileBasedConfig(parent, user, fs); }
            @Override public FileBasedConfig openSystemConfig(Config parent, FS fs) { return new FileBasedConfig(parent, system, fs); }
            @Override public FileBasedConfig openJGitConfig(Config parent, FS fs) { return new FileBasedConfig(parent, jgit, fs); }
            @Override public long getCurrentTime() { return System.currentTimeMillis(); }
            @Override public int getTimezone(long when) { return TimeZone.getDefault().getOffset(when) / 60000; }
        });
    }
}
