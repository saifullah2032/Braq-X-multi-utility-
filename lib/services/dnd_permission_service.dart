import 'dart:developer' as developer;
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';

/// Manages DND (Do Not Disturb) / Notification Policy Access permissions
class DndPermissionService {
  static final DndPermissionService _instance = DndPermissionService._internal();
  static const platform = MethodChannel('com.barq.x/background');

  DndPermissionService._internal();

  factory DndPermissionService() {
    return _instance;
  }

  /// Check if the app has Notification Policy Access permission
  /// Uses native platform channel to check NotificationManager.isNotificationPolicyAccessGranted
  Future<bool> hasNotificationPolicyAccess() async {
    try {
      final bool hasAccess = await platform.invokeMethod('checkDndAccess');
      developer.log(
        'DND Access: $hasAccess',
        name: 'DndPermissionService',
      );
      return hasAccess;
    } catch (e) {
      developer.log(
        'Error checking notification policy access: $e',
        name: 'DndPermissionService',
      );
      return false;
    }
  }

  /// Open the notification policy access settings
  /// User must manually grant permission in the settings
  Future<void> requestNotificationPolicyAccess() async {
    try {
      // Launch Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS
      const intent = AndroidIntent(
        action: 'android.settings.NOTIFICATION_POLICY_ACCESS_SETTINGS',
      );
      await intent.launch();

      developer.log(
        'Launched notification policy access settings',
        name: 'DndPermissionService',
      );
    } catch (e) {
      developer.log(
        'Error launching notification policy settings: $e',
        name: 'DndPermissionService',
      );
    }
  }

  /// Check and request permission if needed
  /// Returns true if permission is available, false otherwise
  Future<bool> checkAndRequest() async {
    final hasAccess = await hasNotificationPolicyAccess();
    if (!hasAccess) {
      await requestNotificationPolicyAccess();
      return false;
    }
    return true;
  }
}

