package com.x10think.wave

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/** A user-visible, ongoing audio/Bluetooth foreground service, not an invisible background task. */
class MeshForegroundService : Service() {
    companion object {
        const val ACTION_STOP = "com.x10think.wave.STOP_MESH"
        private const val CHANNEL = "wave_mesh_live"
        private const val NOTIFICATION_ID = 4902
        @Volatile var instance: MeshForegroundService? = null
            private set
    }
    private var projectionEnabled = false
    private var sessionHost = false
    private var microphoneEnabled = false
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(NotificationChannel(
            CHANNEL, "WAVE live audio sharing", NotificationManager.IMPORTANCE_LOW))
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            MeshRuntime.get(this).stop()
            LanRuntime.get(this).stop()
            // Notification Stop must also stop imported movie audio/video.
            startService(Intent(this, WaveMediaService::class.java).setAction(WaveMediaService.STOP))
            getSharedPreferences("wave_active_session", Context.MODE_PRIVATE).edit().clear().apply()
            stopSelf()
            return START_NOT_STICKY
        }
        sessionHost = intent?.getBooleanExtra("host", false) == true
        promoteForeground()
        return START_NOT_STICKY // Never recreate empty session after process death without user action.
    }

    /** A Receiver promoted by LAN quorum must be foregrounded by the user before
     * requesting mic permission and upgrading FGS type. This cannot bypass OS rules. */
    @Synchronized fun enableHostMicrophone() {
        check(checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED) {
            "Open WAVE and grant microphone permission before speaking"
        }
        sessionHost=true
        microphoneEnabled=true
        promoteForeground()
    }

    /** Called on UI thread after MediaProjection consent and BEFORE getMediaProjection(). */
    @Synchronized fun enableMediaProjection() {
        sessionHost = (LanRuntime.get(this).state()["host"]==true && LanRuntime.get(this).isRunning()) || (MeshRuntime.get(this).state()["host"]==true && MeshRuntime.get(this).isRunning())
        check(sessionHost) { "Only the Host may begin media capture" }
        projectionEnabled = true
        promoteForeground()
    }

    @Synchronized private fun promoteForeground() {
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE or
                (if (microphoneEnabled && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE else 0) or
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK or
                (if (projectionEnabled) ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION else 0)
        } else 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification(), flags)
        } else startForeground(NOTIFICATION_ID, notification())
    }

    private fun notification(): Notification {
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val stop = PendingIntent.getService(this, 1, Intent(this, MeshForegroundService::class.java)
            .setAction(ACTION_STOP), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return Notification.Builder(this, CHANNEL)
            .setSmallIcon(android.R.drawable.stat_sys_upload)
            .setContentTitle("WAVE — session running")
            .setContentText("Room open. Tap to check playback and listeners.")
            .setContentIntent(open)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(Notification.Action.Builder(null, "Stop session", stop).build())
            .build()
    }

    /** User explicitly removed WAVE's task from Recents. This is not
     * screen-off/Home/minimize: end the session and stop all media and relays.
     * OEMs may kill the process without delivering this callback; verify on devices.
     */
    override fun onTaskRemoved(rootIntent:Intent?) {
        MeshRuntime.get(this).stop()
        LanRuntime.get(this).stop()
        startService(Intent(this,WaveMediaService::class.java).setAction(WaveMediaService.STOP))
        getSharedPreferences("wave_active_session",Context.MODE_PRIVATE).edit().clear().apply()
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        MeshRuntime.get(this).stop()
        LanRuntime.get(this).stop()
        getSharedPreferences("wave_active_session", Context.MODE_PRIVATE).edit().clear().apply()
        projectionEnabled = false
        microphoneEnabled = false
        instance = null
        super.onDestroy()
    }
}
