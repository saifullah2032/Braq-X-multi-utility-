package com.example.barq_x

import android.app.Service
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * BARQ X Background Gesture Detection Service
 * 
 * Runs continuously in foreground (with notification)
 * Keeps sensors active even when app is minimized
 * Shows non-dismissible notification with Disarm button
 */
class BackgroundGestureService : Service() {
    
    companion object {
        private const val CHANNEL_ID = "barq_x_gesture_engine"
        private const val NOTIFICATION_ID = 888
        private const val ACTION_DISARM = "com.example.barq_x.DISARM"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Handle disarm action from notification
        if (intent?.action == ACTION_DISARM) {
            // Stop service and notify Flutter app to disarm
            notifyFlutterDisarm()
            stopSelf()
            return START_NOT_STICKY
        }

        // Show persistent notification
        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /**
     * Create notification channel (Android 8+)
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "BARQ X Gesture Engine",
                NotificationManager.IMPORTANCE_LOW  // Low importance = no sound/vibration
            ).apply {
                description = "Monitors device gestures for quick actions"
                // Make it persistent and non-dismissible
                setShowBadge(true)
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    /**
     * Build non-dismissible notification with Disarm button
     */
    private fun buildNotification(): Notification {
        // Create Disarm intent
        val disarmIntent = Intent(this, BackgroundGestureService::class.java).apply {
            action = ACTION_DISARM
        }

        // Title: "BARQ X: Active"
        // Subtext: "Monitoring gestures..."
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("BARQ X: Active")
            .setContentText("Monitoring gestures...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)  // Default icon
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)  // Non-dismissible
            .setAutoCancel(false)  // Cannot swipe to dismiss
            
            // Add Disarm action button
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Disarm",
                disarmIntent.let { intent ->
                    android.app.PendingIntent.getService(
                        this,
                        0,
                        intent,
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or 
                        android.app.PendingIntent.FLAG_IMMUTABLE
                    )
                }
            )
            
            // Make notification persistent and non-dismissible
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            
            .build()

        // Ensure notification cannot be dismissed
        notification.flags = notification.flags or Notification.FLAG_NO_CLEAR

        return notification
    }

    /**
     * Notify Flutter app to disarm
     * This triggers the disarm through the method channel
     */
    private fun notifyFlutterDisarm() {
        // Send broadcast to notify Flutter app
        val intent = Intent("com.barq.x.DISARM")
        sendBroadcast(intent)
    }
}
