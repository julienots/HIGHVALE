package com.gixcloud.app;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInstaller;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;

/** Installation d'APK (PackageInstaller, sans FileProvider) et copie vers Téléchargements. */
public final class Installer extends BroadcastReceiver {
    static final String ACTION = "com.gixcloud.app.INSTALL_STATUS";

    public static String install(Context ctx, File apk) throws Exception {
        if (Build.VERSION.SDK_INT >= 26 && !ctx.getPackageManager().canRequestPackageInstalls()) {
            Intent s = new Intent(android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:" + ctx.getPackageName()));
            s.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            notifyIntent(ctx, 41, "Autoriser GIXCLOUD à installer des applis", "Touchez pour autoriser, puis relancez l'installation.", s);
            try { ctx.startActivity(s); } catch (Exception ignored) { }
            return "Autorisation requise : sur le téléphone, autorisez « Installer des applis inconnues » pour GIXCLOUD, puis réessayez.";
        }
        PackageInstaller pi = ctx.getPackageManager().getPackageInstaller();
        PackageInstaller.SessionParams params = new PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL);
        int sid = pi.createSession(params);
        try (PackageInstaller.Session session = pi.openSession(sid)) {
            try (InputStream in = new FileInputStream(apk); OutputStream out = session.openWrite("base.apk", 0, apk.length())) {
                byte[] buf = new byte[65536];
                int n;
                while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
                session.fsync(out);
            }
            Intent cb = new Intent(ctx, Installer.class).setAction(ACTION).putExtra("apk", apk.getName());
            int flags = PendingIntent.FLAG_UPDATE_CURRENT | (Build.VERSION.SDK_INT >= 31 ? PendingIntent.FLAG_MUTABLE : 0);
            session.commit(PendingIntent.getBroadcast(ctx, sid, cb, flags).getIntentSender());
        }
        return "Installation lancée : confirmez sur le téléphone (fenêtre ou notification « Installer »).";
    }

    @Override
    public void onReceive(Context ctx, Intent intent) {
        int status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE);
        String apk = intent.getStringExtra("apk");
        if (status == PackageInstaller.STATUS_PENDING_USER_ACTION) {
            Intent confirm = intent.getParcelableExtra(Intent.EXTRA_INTENT);
            if (confirm == null) return;
            confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            notifyIntent(ctx, 42, "Installer " + apk, "Touchez pour confirmer l'installation.", confirm);
            try { ctx.startActivity(confirm); } catch (Exception ignored) { }
        } else if (status == PackageInstaller.STATUS_SUCCESS) {
            notifyIntent(ctx, 42, "Installé : " + apk, "L'application est prête.", null);
        } else {
            notifyIntent(ctx, 42, "Échec de l'installation", apk + " : " + intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE), null);
        }
    }

    static void notifyIntent(Context ctx, int id, String title, String text, Intent target) {
        NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        GixService.ensureChannel(ctx);
        Notification.Builder b = new Notification.Builder(ctx, GixService.CHANNEL).setSmallIcon(R.drawable.ic_stat)
                .setContentTitle(title).setContentText(text).setAutoCancel(true);
        if (target != null) b.setContentIntent(PendingIntent.getActivity(ctx, id, target, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE));
        nm.notify(id, b.build());
    }

    public static String toDownloads(Context ctx, File apk) throws Exception {
        if (Build.VERSION.SDK_INT >= 29) {
            ContentValues v = new ContentValues();
            v.put(MediaStore.Downloads.DISPLAY_NAME, apk.getName());
            v.put(MediaStore.Downloads.MIME_TYPE, "application/vnd.android.package-archive");
            v.put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/GIXCLOUD");
            Uri uri = ctx.getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, v);
            if (uri == null) throw new Tools.Err("Impossible de créer le fichier dans Téléchargements.");
            try (OutputStream out = ctx.getContentResolver().openOutputStream(uri)) { Files.copy(apk.toPath(), out); }
            return "Téléchargements/GIXCLOUD/" + apk.getName();
        }
        File dir = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "GIXCLOUD");
        dir.mkdirs();
        File dst = new File(dir, apk.getName());
        Files.copy(apk.toPath(), dst.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
        return dst.getAbsolutePath();
    }
}
