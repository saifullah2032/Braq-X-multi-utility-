import 'dart:developer' as developer;
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:torch_light/torch_light.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/gesture_event.dart';
import '../models/gesture_settings.dart';
import 'haptic_service.dart';
import 'gesture_auditor.dart';

/// Action handler for gesture-triggered intents
/// Maps gesture types to hardware actions (torch, camera, DND, etc.)
/// Includes comprehensive logging for debugging
class ActionHandler {
  // Track torch state
  static bool _isTorchOn = false;
  
  // MethodChannel for native operations (DND, Media control)
  static const _methodChannel = MethodChannel('com.barq.x/background');
  
  // DND mode constants (matching Android NotificationManager)
  static const int _dndModeAll = 1;      // Normal mode - all notifications
  static const int _dndModePriority = 2; // Priority mode - only starred contacts
  
  /// Execute action based on gesture type and settings
  /// Returns a map with action details for logging
  static Future<Map<String, dynamic>> handleGestureWithLogging(
    GestureEvent gesture,
    GestureSettings settings,
  ) async {
    String actionName = '';
    String actionDetails = '';
    bool success = true;
    
    // Debug print for terminal visibility
    print('========================================');
    print('[ACTION_HANDLER] Executing action for: ${gesture.type}');
    print('========================================');
    
    try {
      switch (gesture.type) {
        case GestureType.shake:
          actionName = 'TOGGLE TORCH (FLASHLIGHT)';
          final torchResult = await _toggleTorchWithLogging();
          actionDetails = torchResult;
          await HapticService.playGestureHaptic(GestureType.shake);
          break;

        case GestureType.twist:
          actionName = 'LAUNCH CAMERA';
          final cameraResult = await _launchCameraWithLogging();
          actionDetails = cameraResult;
          await HapticService.playGestureHaptic(GestureType.twist);
          break;

        case GestureType.flip:
          // Check metadata for explicit action (ENABLE_DND or DISABLE_DND)
          final action = gesture.sensorData['action'] as String?;
          String dndResult;
          
          if (action == 'ENABLE_DND') {
            actionName = 'ENABLE DND (DO NOT DISTURB)';
            dndResult = await _setDndStateWithLogging(true);
          } else if (action == 'DISABLE_DND') {
            actionName = 'DISABLE DND (DO NOT DISTURB)';
            dndResult = await _setDndStateWithLogging(false);
          } else {
            // Fallback to toggle for backward compatibility
            actionName = 'TOGGLE DND (DO NOT DISTURB)';
            dndResult = await _toggleDndWithLogging();
          }
          
          actionDetails = dndResult;
          await HapticService.playGestureHaptic(GestureType.flip);
          break;

        case GestureType.backTap:
          // Check if heavy haptic was requested (indicates successful strike detection)
          final requestHeavyHaptic = gesture.sensorData['requestHeavyHaptic'] as bool? ?? false;
          
          // Play heavy impact haptic IMMEDIATELY on second tap detection
          if (requestHeavyHaptic) {
            await HapticService.playHeavyImpact();
          }
          
          // Get the user's selected action (default to 'assistant' if not set)
          final selectedAction = settings.backTapCustomAction.isEmpty 
              ? 'assistant' 
              : settings.backTapCustomAction;
          
          actionName = 'EXECUTE SECRET STRIKE: ${selectedAction.toUpperCase()}';
          final customResult = await _executeCustomActionWithLogging(selectedAction);
          actionDetails = customResult;
          // Don't play additional haptic - heavy impact already played
          break;

        case GestureType.pocketShield:
          actionName = 'POCKET SHIELD ACTIVATED';
          actionDetails = 'Phone detected in pocket/bag - gestures temporarily disabled';
          break;
      }

      await HapticService.playSuccess();
      
      // Log successful action result
      GestureAuditor.logActionResult(
        gestureType: gesture.type,
        actionName: actionName,
        success: true,
        actionDetails: {
          'result': actionDetails,
          'hapticFeedback': 'SUCCESS',
        },
      );
      
    } catch (e) {
      success = false;
      actionDetails = 'ERROR: $e';
      developer.log('Error handling gesture: $e', name: 'ActionHandler');
      await HapticService.playError();
      
      // Log failed action result
      GestureAuditor.logActionResult(
        gestureType: gesture.type,
        actionName: actionName.isEmpty ? 'UNKNOWN' : actionName,
        success: false,
        errorMessage: e.toString(),
      );
    }
    
    return {
      'actionName': actionName,
      'details': actionDetails,
      'success': success,
    };
  }
  
  /// Legacy method for backward compatibility
  static Future<void> handleGesture(
    GestureEvent gesture,
    GestureSettings settings,
  ) async {
    await handleGestureWithLogging(gesture, settings);
  }

  /// Toggle flashlight (torch) with logging
  static Future<String> _toggleTorchWithLogging() async {
    final previousState = _isTorchOn ? 'ON' : 'OFF';
    
    try {
      if (_isTorchOn) {
        // Log action execution before attempting
        GestureAuditor.logActionExecution(
          action: 'TORCH',
          method: 'torch_light package: TorchLight.disableTorch()',
          previousState: 'ON',
          newState: 'OFF',
        );
        
        await TorchLight.disableTorch();
        _isTorchOn = false;
        developer.log(
          '🔦 TORCH: OFF - Flashlight disabled via shake gesture',
          name: 'ActionHandler',
        );
        return 'Torch DISABLED (was ON)';
      } else {
        // Log action execution before attempting
        GestureAuditor.logActionExecution(
          action: 'TORCH',
          method: 'torch_light package: TorchLight.enableTorch()',
          previousState: 'OFF',
          newState: 'ON',
        );
        
        await TorchLight.enableTorch();
        _isTorchOn = true;
        developer.log(
          '🔦 TORCH: ON - Flashlight enabled via shake gesture',
          name: 'ActionHandler',
        );
        return 'Torch ENABLED (was OFF)';
      }
    } catch (e) {
      developer.log('Error toggling torch: $e', name: 'ActionHandler');
      
      GestureAuditor.logPermissionIssue(
        feature: 'TORCH (FLASHLIGHT)',
        issue: 'Failed to toggle torch: $e',
        resolution: 'Attempting fallback initialization',
      );
      
      // Fallback: Try to initialize torch if not available
      try {
        final isTorchAvailable = await TorchLight.isTorchAvailable();
        if (isTorchAvailable) {
          GestureAuditor.logActionExecution(
            action: 'TORCH',
            method: 'torch_light package (fallback): TorchLight.enableTorch()',
            previousState: previousState,
            newState: 'ON',
          );
          
          await TorchLight.enableTorch();
          _isTorchOn = true;
          return 'Torch ENABLED (fallback)';
        }
        return 'Torch NOT AVAILABLE on this device';
      } catch (e2) {
        developer.log('Torch not available: $e2', name: 'ActionHandler');
        return 'Torch ERROR: $e2';
      }
    }
  }

  /// Launch camera app with logging
  static Future<String> _launchCameraWithLogging() async {
    try {
      // Log intent launch before attempting
      GestureAuditor.logIntentLaunch(
        action: 'CAMERA',
        intentAction: 'android.media.action.STILL_IMAGE_CAMERA',
        success: true, // Will be updated on failure
        packageName: null, // System default camera
      );
      
      const AndroidIntent intent = AndroidIntent(
        action: 'android.media.action.STILL_IMAGE_CAMERA',
      );
      await intent.launch();
      developer.log(
        '📷 CAMERA: Launched via twist gesture (STILL_IMAGE_CAMERA intent)',
        name: 'ActionHandler',
      );
      return 'Camera launched successfully (STILL_IMAGE_CAMERA)';
    } catch (e) {
      developer.log('Primary camera launch failed: $e', name: 'ActionHandler');
      
      GestureAuditor.logIntentLaunch(
        action: 'CAMERA',
        intentAction: 'android.media.action.STILL_IMAGE_CAMERA',
        success: false,
        packageName: null,
      );
      
      // Fallback to IMAGE_CAPTURE
      try {
        GestureAuditor.logIntentLaunch(
          action: 'CAMERA (fallback)',
          intentAction: 'android.media.action.IMAGE_CAPTURE',
          success: true,
          packageName: null,
        );
        
        const AndroidIntent fallbackIntent = AndroidIntent(
          action: 'android.media.action.IMAGE_CAPTURE',
        );
        await fallbackIntent.launch();
        developer.log(
          '📷 CAMERA: Launched via fallback (IMAGE_CAPTURE intent)',
          name: 'ActionHandler',
        );
        return 'Camera launched (fallback: IMAGE_CAPTURE)';
      } catch (e2) {
        developer.log('Camera fallback failed: $e2', name: 'ActionHandler');
        
        GestureAuditor.logIntentLaunch(
          action: 'CAMERA (fallback)',
          intentAction: 'android.media.action.IMAGE_CAPTURE',
          success: false,
          packageName: null,
        );
        
        return 'Camera launch FAILED: $e2';
      }
    }
  }

  /// Set Do Not Disturb mode with logging (explicit state control)
  /// Only changes DND state if it differs from target state
  static Future<String> _setDndStateWithLogging(bool enable) async {
    try {
      // Check permission first
      final bool hasAccess = await _methodChannel.invokeMethod<bool>('checkDndAccess') ?? false;
      
      if (!hasAccess) {
        developer.log(
          '🔕 DND: Permission NOT granted - opening settings',
          name: 'ActionHandler',
        );
        
        GestureAuditor.logPermissionIssue(
          feature: 'DND (DO NOT DISTURB)',
          issue: 'NOTIFICATION_POLICY_ACCESS permission not granted',
          resolution: 'Opening system settings for user to grant permission',
        );
        
        await _methodChannel.invokeMethod('requestDndAccess');
        return 'DND permission required - opened settings';
      }

      // Get current DND mode
      final int currentMode = await _methodChannel.invokeMethod<int>('getCurrentDndMode') ?? _dndModeAll;
      final bool currentlyEnabled = (currentMode != _dndModeAll);
      final String previousState = currentlyEnabled ? 'ENABLED (PRIORITY)' : 'DISABLED (ALL)';
      
      developer.log(
        '🔕 DND: Current mode = $currentMode (${currentlyEnabled ? "ENABLED" : "DISABLED"})',
        name: 'ActionHandler',
      );
      
      // Check if state change is needed
      if (enable == currentlyEnabled) {
        final result = enable 
            ? 'DND already ENABLED - no action needed' 
            : 'DND already DISABLED - no action needed';
        developer.log('🔕 $result', name: 'ActionHandler');
        
        GestureAuditor.logActionExecution(
          action: 'DND',
          method: 'MethodChannel: checkDndAccess/getCurrentDndMode',
          previousState: previousState,
          newState: previousState + ' (NO CHANGE)',
        );
        
        return result;
      }

      // State change needed - apply new mode
      final int targetMode = enable ? _dndModePriority : _dndModeAll;
      final String newState = enable ? 'ENABLED (PRIORITY)' : 'DISABLED (ALL)';
      
      // Log action execution before attempting
      GestureAuditor.logActionExecution(
        action: 'DND',
        method: 'MethodChannel: setDndMode({mode: $targetMode})',
        previousState: previousState,
        newState: newState,
      );
      
      final bool success = await _methodChannel.invokeMethod<bool>(
        'setDndMode',
        {'mode': targetMode},
      ) ?? false;
      
      if (success) {
        final result = enable 
            ? 'DND ENABLED (PRIORITY mode) - Was: OFF' 
            : 'DND DISABLED (ALL mode) - Was: ON';
        developer.log('🔕 $result', name: 'ActionHandler');
        return result;
      } else {
        return 'DND state change FAILED';
      }
    } catch (e) {
      developer.log('Error setting DND state: $e', name: 'ActionHandler');
      return 'DND ERROR: $e';
    }
  }

  /// Toggle Do Not Disturb mode with logging
  static Future<String> _toggleDndWithLogging() async {
    try {
      final bool hasAccess = await _methodChannel.invokeMethod<bool>('checkDndAccess') ?? false;
      
      if (!hasAccess) {
        developer.log(
          '🔕 DND: Permission NOT granted - opening settings',
          name: 'ActionHandler',
        );
        await _methodChannel.invokeMethod('requestDndAccess');
        return 'DND permission required - opened settings';
      }

      final int currentFilter = await _methodChannel.invokeMethod<int>('getCurrentDndMode') ?? _dndModeAll;
      
      developer.log(
        '🔕 DND: Current filter mode = $currentFilter',
        name: 'ActionHandler',
      );

      if (currentFilter == _dndModeAll) {
        final bool success = await _methodChannel.invokeMethod<bool>(
          'setDndMode',
          {'mode': _dndModePriority},
        ) ?? false;
        
        if (success) {
          developer.log('🔕 DND: ENABLED (was OFF → PRIORITY mode)', name: 'ActionHandler');
          return 'DND ENABLED (PRIORITY mode) - Was: OFF';
        }
        return 'DND enable FAILED';
      } else {
        final bool success = await _methodChannel.invokeMethod<bool>(
          'setDndMode',
          {'mode': _dndModeAll},
        ) ?? false;
        
        if (success) {
          developer.log('🔕 DND: DISABLED (was ON → ALL mode)', name: 'ActionHandler');
          return 'DND DISABLED (ALL mode) - Was: ON';
        }
        return 'DND disable FAILED';
      }
    } catch (e) {
      developer.log('Error toggling DND: $e', name: 'ActionHandler');
      return 'DND toggle ERROR: $e';
    }
  }

  /// Execute custom action with logging
  /// Handles three "Top-Notch" triggers: WhatsApp, Media Pause/Play, Google Assistant
  static Future<String> _executeCustomActionWithLogging(String actionType) async {
    switch (actionType.toLowerCase()) {
      case 'whatsapp':
        return await _launchWhatsAppWithLogging();
      case 'assistant':
        return await _launchAssistantWithLogging();
      case 'media':
      case 'media_player':
      case 'media_pause':
        return await _toggleMediaPlayPauseWithLogging();
      default:
        developer.log(
          '⚡ CUSTOM: Unknown action "$actionType" - defaulting to Google Assistant',
          name: 'ActionHandler',
        );
        return await _launchAssistantWithLogging();
    }
  }

   /// Launch WhatsApp with logging
   /// Uses url_launcher with whatsapp://send URL scheme to avoid permission denial errors
   /// This method doesn't require explicit Android intents or hardcoded package names
   static Future<String> _launchWhatsAppWithLogging() async {
     try {
       // Primary: Use url_launcher with WhatsApp URL scheme
       final whatsappUrl = Uri.parse('whatsapp://send');
       
       GestureAuditor.logIntentLaunch(
         action: 'WHATSAPP',
         intentAction: 'whatsapp://send',
         success: true,
         packageName: null,
       );
       
       if (await canLaunchUrl(whatsappUrl)) {
         await launchUrl(whatsappUrl);
         developer.log(
           '💬 WHATSAPP: Launched via back-tap gesture (url_launcher whatsapp:// scheme)',
           name: 'ActionHandler',
         );
         return 'WhatsApp launched successfully via URL scheme';
       } else {
         throw 'WhatsApp URL scheme not available';
       }
     } catch (e) {
       developer.log('Primary WhatsApp URL scheme failed: $e', name: 'ActionHandler');
       
       GestureAuditor.logIntentLaunch(
         action: 'WHATSAPP',
         intentAction: 'whatsapp://send',
         success: false,
         packageName: null,
       );
       
       try {
         // Fallback: Use generic SEND intent (no package restriction)
         // This lets Android resolve which messaging app to use
         GestureAuditor.logIntentLaunch(
           action: 'WHATSAPP (fallback - generic SEND)',
           intentAction: 'android.intent.action.SEND',
           success: true,
           packageName: null,
         );
         
         const AndroidIntent fallbackIntent = AndroidIntent(
           action: 'android.intent.action.SEND',
           type: 'text/plain',
           flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
         );
         await fallbackIntent.launch();
         developer.log('💬 WHATSAPP: Fallback to generic SEND intent', name: 'ActionHandler');
         return 'Messaging app launched via generic intent (fallback)';
       } catch (e2) {
         developer.log('WhatsApp fallback failed: $e2', name: 'ActionHandler');
         
         GestureAuditor.logIntentLaunch(
           action: 'WHATSAPP (fallback)',
           intentAction: 'android.intent.action.SEND',
           success: false,
           packageName: null,
          );
          
          return 'WhatsApp launch FAILED: $e2';
        }
      }
    }

    /// Launch Google Assistant with logging
  /// Uses generic VOICE_COMMAND without hardcoded package to avoid permission denial
  static Future<String> _launchAssistantWithLogging() async {
    try {
      // Primary: Use VOICE_COMMAND action without package restriction
      GestureAuditor.logIntentLaunch(
        action: 'GOOGLE ASSISTANT',
        intentAction: 'android.intent.action.VOICE_COMMAND',
        success: true,
        packageName: null, // No hardcoded package - let system resolve
      );
      
      const AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.VOICE_COMMAND',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      developer.log(
        '🎤 ASSISTANT: Launched via generic VOICE_COMMAND intent',
        name: 'ActionHandler',
      );
      return 'Google Assistant launched (VOICE_COMMAND)';
    } catch (e) {
      developer.log('VOICE_COMMAND failed: $e', name: 'ActionHandler');
      
      GestureAuditor.logIntentLaunch(
        action: 'GOOGLE ASSISTANT',
        intentAction: 'android.intent.action.VOICE_COMMAND',
        success: false,
        packageName: null,
      );
      
      try {
        // Fallback 1: VOICE_ASSIST action (more generic, system-wide)
        GestureAuditor.logIntentLaunch(
          action: 'GOOGLE ASSISTANT (fallback 1)',
          intentAction: 'android.intent.action.VOICE_ASSIST',
          success: true,
          packageName: null,
        );
        
        const AndroidIntent fallbackIntent = AndroidIntent(
          action: 'android.intent.action.VOICE_ASSIST',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await fallbackIntent.launch();
        developer.log('🎤 ASSISTANT: Launched via VOICE_ASSIST', name: 'ActionHandler');
        return 'Google Assistant launched (VOICE_ASSIST fallback)';
      } catch (e2) {
        developer.log('VOICE_ASSIST fallback failed: $e2', name: 'ActionHandler');
        
        GestureAuditor.logIntentLaunch(
          action: 'GOOGLE ASSISTANT (fallback 1)',
          intentAction: 'android.intent.action.VOICE_ASSIST',
          success: false,
          packageName: null,
        );
        
        return 'Assistant launch FAILED: $e2';
      }
    }
  }

  /// Toggle Media Play/Pause with logging
  /// Uses MethodChannel to trigger native KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
  /// Works with Spotify, YouTube, and system players without opening an app
  static Future<String> _toggleMediaPlayPauseWithLogging() async {
    try {
      // Log action execution before attempting
      GestureAuditor.logActionExecution(
        action: 'MEDIA PLAY/PAUSE',
        method: 'MethodChannel: sendMediaPlayPause() -> KEYCODE_MEDIA_PLAY_PAUSE',
        previousState: 'UNKNOWN',
        newState: 'TOGGLED',
      );
      
      final bool success = await _methodChannel.invokeMethod<bool>('sendMediaPlayPause') ?? false;
      
      if (success) {
        developer.log(
          '🎵 MEDIA: Play/Pause toggled via KEYCODE_MEDIA_PLAY_PAUSE',
          name: 'ActionHandler',
        );
        return 'Media Play/Pause toggled successfully';
      } else {
        developer.log(
          '🎵 MEDIA: Play/Pause command sent but no confirmation',
          name: 'ActionHandler',
        );
        return 'Media Play/Pause sent (no confirmation)';
      }
    } catch (e) {
      developer.log('Media Play/Pause failed: $e', name: 'ActionHandler');
      
      GestureAuditor.logPermissionIssue(
        feature: 'MEDIA PLAY/PAUSE',
        issue: 'MethodChannel sendMediaPlayPause failed: $e',
        resolution: 'Attempting to launch default music app',
      );
      
      // Fallback: Try to launch default music app
      try {
        GestureAuditor.logIntentLaunch(
          action: 'MUSIC APP (fallback)',
          intentAction: 'android.intent.action.MAIN',
          success: true,
          packageName: 'android.intent.category.APP_MUSIC',
        );
        
        const AndroidIntent fallbackIntent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_MUSIC',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await fallbackIntent.launch();
        developer.log('🎵 MEDIA: Fallback - opened music app', name: 'ActionHandler');
        return 'Media app launched (Play/Pause unavailable)';
      } catch (e2) {
        developer.log('Media fallback failed: $e2', name: 'ActionHandler');
        return 'Media control FAILED: $e2';
      }
    }
  }

  /// Launch media player with logging (legacy method)
  static Future<String> _launchMediaPlayerWithLogging() async {
    return await _toggleMediaPlayPauseWithLogging();
  }
  
  // ============================================================
  // LEGACY METHODS (for backward compatibility)
  // ============================================================
  
  static Future<void> _toggleTorch() async {
    await _toggleTorchWithLogging();
  }

  static Future<void> _launchCamera() async {
    await _launchCameraWithLogging();
  }

  static Future<void> _setDndState(bool isOn) async {
    await _setDndStateWithLogging(isOn);
  }

  static Future<void> _toggleDnd() async {
    await _toggleDndWithLogging();
  }

  static Future<void> _executeCustomAction(String actionType) async {
    await _executeCustomActionWithLogging(actionType);
  }

  static Future<void> _launchWhatsApp() async {
    await _launchWhatsAppWithLogging();
  }

  static Future<void> _launchAssistant() async {
    await _launchAssistantWithLogging();
  }

  static Future<void> _launchMediaPlayer() async {
    await _launchMediaPlayerWithLogging();
  }
}
