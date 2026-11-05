package com.gixcloud.app;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.IBinder;
import android.os.PowerManager;

/** Service de premier plan : garde le serveur MCP actif, même application fermée. */
public final class GixService extends Service {
    static final String CHANNEL = "gixcloud";
    static McpHttpServer server;
    static String lastError = "";
    private PowerManager.WakeLock wake;
    private WifiManager.WifiLock wifi;

    static void ensureChannel(Context ctx) {
        NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm.getNotificationChannel(CHANNEL) == null) {
            nm.createNotificationChannel(new NotificationChannel(CHANNEL, "GIXCLOUD", NotificationManager.IMPORTANCE_LOW));
        }
    }

    public static void start(Context ctx) { ctx.startForegroundService(new Intent(ctx, GixService.class)); }

    public static void stop(Context ctx) { ctx.stopService(new Intent(ctx, GixService.class)); }

    public static boolean running() { return server != null && server.isRunning(); }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Gix gix = Gix.get(this);
        ensureChannel(this);
        String addr = (gix.lan() && !Gix.localIps().isEmpty() ? Gix.localIps().get(0) : "127.0.0.1") + ":" + gix.port();
        Notification n = new Notification.Builder(this, CHANNEL).setSmallIcon(R.drawable.ic_stat)
                .setContentTitle("GIXCLOUD — MCP actif")
                .setContentText("Les IA peuvent se connecter sur http://" + addr + "/mcp")
                .setOngoing(true)
                .setContentIntent(PendingIntent.getActivity(this, 0, new Intent(this, MainActivity.class), PendingIntent.FLAG_IMMUTABLE))
                .build();
        if (Build.VERSION.SDK_INT >= 29) startForeground(1, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC);
        else startForeground(1, n);
        try {
            if (server == null || !server.isRunning()) {
                server = new McpHttpServer(gix);
                server.start();
            }
            lastError = "";
        } catch (Exception e) {
            lastError = "Démarrage impossible (port " + gix.port() + " occupé ?) : " + e.getMessage();
            stopSelf();
            return START_NOT_STICKY;
        }
        if (wake == null) {
            wake = ((PowerManager) getSystemService(POWER_SERVICE)).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "gixcloud:mcp");
            wake.acquire();
            WifiManager wm = (WifiManager) getApplicationContext().getSystemService(WIFI_SERVICE);
            if (wm != null) { wifi = wm.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "gixcloud:mcp"); wifi.acquire(); }
        }
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        if (server != null) server.stop();
        server = null;
        if (wake != null && wake.isHeld()) wake.release();
        if (wifi != null && wifi.isHeld()) wifi.release();
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }
}
