import 'dart:developer' as developer;
import 'package:android_intent_plus/android_intent.dart';
import '../models/gesture_event.dart';
import '../models/gesture_settings.dart';
import '../constants/app_config.dart';
import 'haptic_service.dart';

/// Action handler for gesture-triggered intents
/// Maps gesture types to Android actions (camera, DND, WhatsApp, etc.)
class ActionHandler {
  /// Execute action based on gesture type and settings
  static Future<void> handleGesture(
    GestureEvent gesture,
    GestureSettings settings,
  ) async {
    try {
      switch (gesture.type) {
        case GestureType.shake:
          // Torch - Launch camera flashlight
          await _toggleTorch();
          await HapticService.playGestureHaptic(GestureType.shake);
          break;

        case GestureType.twist:
          // Camera - Launch camera app
          await _launchCamera();
          await HapticService.playGestureHaptic(GestureType.twist);
          break;

        case GestureType.flip:
          // DND - Enable Do Not Disturb (INTERRUPTION_FILTER_ALARMS)
          await _enableDnd();
          await HapticService.playGestureHaptic(GestureType.flip);
          break;

        case GestureType.backTap:
          // Back-Tap - Custom action (default: WhatsApp)
          await _executeCustomAction(settings.backTapCustomAction);
          await HapticService.playGestureHaptic(GestureType.backTap);
          break;

        case GestureType.pocketShield:
          // Pocket Shield - No action, silent mode
          break;
      }

      await HapticService.playSuccess();
    } catch (e) {
      developer.log('Error handling gesture: $e', name: 'ActionHandler');
      await HapticService.playError();
    }
  }

  /// Toggle flashlight (torch)
  static Future<void> _toggleTorch() async {
    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.android.systemui',
        componentName: 'com.android.systemui.flashlight.FlashlightActivity',
      );
      await intent.launch();
    } catch (e) {
      developer.log('Error toggling torch: $e', name: 'ActionHandler');
    }
  }

  /// Launch camera app
  static Future<void> _launchCamera() async {
    try {
      const AndroidIntent intent = AndroidIntent(
        action: AppConfig.cameraIntentAction,
      );
      await intent.launch();
    } catch (e) {
      developer.log('Error launching camera: $e', name: 'ActionHandler');
    }
  }

  /// Enable Do Not Disturb mode
  /// Sets interrupt filter to INTERRUPTION_FILTER_ALARMS (only alarms ring)
  static Future<void> _enableDnd() async {
    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.android.settings',
        componentName: 'com.android.settings.Settings\$ZenModeSettingsActivity',
      );
      await intent.launch();
    } catch (e) {
      developer.log('Error enabling DND: $e', name: 'ActionHandler');
    }
  }

  /// Execute custom action based on selection
  static Future<void> _executeCustomAction(String actionType) async {
    switch (actionType) {
      case 'whatsapp':
        await _launchWhatsApp();
        break;
      case 'assistant':
        await _launchAssistant();
        break;
      case 'media_player':
        await _launchMediaPlayer();
        break;
      default:
        await _launchWhatsApp(); // Default to WhatsApp
    }
  }

  /// Launch WhatsApp
  static Future<void> _launchWhatsApp() async {
    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: AppConfig.whatsAppPackage,
      );
      await intent.launch();
    } catch (e) {
      developer.log('Error launching WhatsApp: $e', name: 'ActionHandler');
    }
  }

  /// Launch Google Assistant
  static Future<void> _launchAssistant() async {
    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: AppConfig.assistantPackage,
      );
      await intent.launch();
    } catch (e) {
      developer.log('Error launching Assistant: $e', name: 'ActionHandler');
    }
  }

  /// Launch media player
  static Future<void> _launchMediaPlayer() async {
    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.APP_MUSIC',
      );
      await intent.launch();
    } catch (e) {
      developer.log('Error launching media player: $e', name: 'ActionHandler');
    }
  }
}
