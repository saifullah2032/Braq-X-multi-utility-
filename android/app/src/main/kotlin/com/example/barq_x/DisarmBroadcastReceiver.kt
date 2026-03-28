package com.example.barq_x

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receives disarm broadcast from BackgroundGestureService
 * Communicates with Flutter app through method channel
 */
class DisarmBroadcastReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == "com.barq.x.DISARM") {
            Log.d("DisarmBroadcast", "Received disarm signal")
            
            // Send message to Flutter through MainActivity
            MainActivity.disarmApp()
        }
    }
}
