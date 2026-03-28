package com.example.barq_x

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.Intent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import android.util.Log
import android.os.Build
import android.os.SystemClock
import android.app.NotificationManager
import android.provider.Settings
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraAccessException
import android.view.KeyEvent
import android.media.AudioManager

class MainActivity : FlutterActivity() {
    
    companion object {
        private const val CHANNEL = "com.barq.x/background"
        private const val EVENT_CHANNEL = "com.barq.x/disarm"
        private var channel: MethodChannel? = null
        private var eventChannel: EventChannel? = null
        
        fun disarmApp() {
            // Send disarm signal to Flutter
            channel?.invokeMethod("onDisarm", null)
        }
    }

    private var disarmReceiver: BroadcastReceiver? = null
    private var eventSink: EventChannel.EventSink? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize camera hardware handshake on startup
        initializeCameraHandshake()
        
        // Setup method channel for background service communication
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "startBackgroundService" -> {
                        startBackgroundService()
                        result.success(null)
                    }
                    "stopBackgroundService" -> {
                        stopBackgroundService()
                        result.success(null)
                    }
                    "checkDndAccess" -> {
                        val hasAccess = checkDndAccess()
                        result.success(hasAccess)
                    }
                    "requestDndAccess" -> {
                        requestDndAccess()
                        result.success(null)
                    }
                    "getCurrentDndMode" -> {
                        val mode = getCurrentDndMode()
                        result.success(mode)
                    }
                    "setDndMode" -> {
                        val mode = call.argument<Int>("mode") ?: NotificationManager.INTERRUPTION_FILTER_ALL
                        val success = setDndMode(mode)
                        result.success(success)
                    }
                    "sendMediaPlayPause" -> {
                        val success = sendMediaPlayPause()
                        result.success(success)
                    }
                    else -> result.notImplemented()
                }
            }
            
            channel = this
        }

        // Setup event channel for disarm broadcasts
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d("MainActivity", "Disarm event channel listener registered")
                    eventSink = events
                    setupDisarmBroadcastReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    Log.d("MainActivity", "Disarm event channel listener cancelled")
                    teardownDisarmBroadcastReceiver()
                    eventSink = null
                }
            }
        )
    }

    private fun setupDisarmBroadcastReceiver() {
        if (disarmReceiver == null) {
            disarmReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    if (intent?.action == "com.barq.x.DISARM") {
                        Log.d("MainActivity", "Received disarm broadcast, sending to Flutter")
                        eventSink?.success("disarm")
                    }
                }
            }
            
            val filter = IntentFilter("com.barq.x.DISARM")
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Context.RECEIVER_NOT_EXPORTED
            } else {
                0
            }
            
            registerReceiver(disarmReceiver, filter, flags)
        }
    }

    private fun teardownDisarmBroadcastReceiver() {
        if (disarmReceiver != null) {
            try {
                unregisterReceiver(disarmReceiver)
            } catch (e: Exception) {
                Log.e("MainActivity", "Error unregistering disarm receiver: ${e.message}")
            }
            disarmReceiver = null
        }
    }
    
    private fun startBackgroundService() {
        val intent = Intent(this, BackgroundGestureService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        Log.d("MainActivity", "Background service started")
    }
    
    private fun stopBackgroundService() {
        val intent = Intent(this, BackgroundGestureService::class.java)
        stopService(intent)
        Log.d("MainActivity", "Background service stopped")
    }

    /**
     * Check if app has DND (Notification Policy) Access
     */
    private fun checkDndAccess(): Boolean {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            notificationManager.isNotificationPolicyAccessGranted
        } else {
            true // Pre-Marshmallow doesn't require this permission
        }
    }

    /**
     * Open DND settings to request permission
     */
    private fun requestDndAccess() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            startActivity(intent)
            Log.d("MainActivity", "Opened DND permission settings")
        }
    }

    /**
     * Get current DND interruption filter mode
     * Returns: INTERRUPTION_FILTER_ALL (1), INTERRUPTION_FILTER_PRIORITY (2), 
     *          INTERRUPTION_FILTER_NONE (3), INTERRUPTION_FILTER_ALARMS (4)
     */
    private fun getCurrentDndMode(): Int {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            notificationManager.currentInterruptionFilter
        } else {
            NotificationManager.INTERRUPTION_FILTER_ALL
        }
    }

    /**
     * Set DND mode
     * @param mode - INTERRUPTION_FILTER constant (1=ALL, 2=PRIORITY, 3=NONE, 4=ALARMS)
     * @return true if successful, false otherwise
     */
    private fun setDndMode(mode: Int): Boolean {
        return try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (notificationManager.isNotificationPolicyAccessGranted) {
                    notificationManager.setInterruptionFilter(mode)
                    Log.d("MainActivity", "DND mode set to: $mode")
                    true
                } else {
                    Log.e("MainActivity", "DND permission not granted")
                    false
                }
            } else {
                Log.d("MainActivity", "DND not supported on this Android version")
                false
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error setting DND mode: ${e.message}")
            false
        }
    }

    /**
     * Send Media Play/Pause KeyEvent broadcast
     * This works with Spotify, YouTube, and system media players
     * Uses KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE to toggle playback
     * @return true if the event was dispatched successfully
     */
    private fun sendMediaPlayPause(): Boolean {
        return try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            
            // Get current time for the KeyEvent
            val eventTime = SystemClock.uptimeMillis()
            
            // Create and dispatch KEY_DOWN event
            val downEvent = KeyEvent(
                eventTime, 
                eventTime, 
                KeyEvent.ACTION_DOWN, 
                KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, 
                0
            )
            audioManager.dispatchMediaKeyEvent(downEvent)
            
            // Create and dispatch KEY_UP event
            val upEvent = KeyEvent(
                eventTime, 
                eventTime, 
                KeyEvent.ACTION_UP, 
                KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, 
                0
            )
            audioManager.dispatchMediaKeyEvent(upEvent)
            
            Log.d("MainActivity", "Media Play/Pause KeyEvent dispatched successfully")
            true
        } catch (e: Exception) {
            Log.e("MainActivity", "Error sending Media Play/Pause: ${e.message}")
            false
        }
    }

    /**
     * Initialize camera hardware handshake
     * Creates a brief connection to camera hardware to ensure access path is open
     * Resolves "Access denied finding property vendor.camera.aux.packagelist" on Nothing Phone
     */
    private fun initializeCameraHandshake() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
                val cameraIdList = cameraManager.cameraIdList
                
                if (cameraIdList.isNotEmpty()) {
                    Log.d("MainActivity", "Camera handshake: Found ${cameraIdList.size} camera(s)")
                    // Just enumerating cameras is enough to initialize the hardware path
                    for (cameraId in cameraIdList) {
                        try {
                            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                            Log.d("MainActivity", "Camera $cameraId characteristics loaded")
                        } catch (e: CameraAccessException) {
                            Log.w("MainActivity", "Camera $cameraId access exception (expected on some devices): ${e.message}")
                        }
                    }
                    Log.d("MainActivity", "Camera hardware handshake completed successfully")
                } else {
                    Log.w("MainActivity", "No cameras found on device")
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Camera handshake failed: ${e.message}")
            // Non-fatal - camera may still work via intent
        }
    }

    override fun onDestroy() {
        teardownDisarmBroadcastReceiver()
        super.onDestroy()
    }
}
