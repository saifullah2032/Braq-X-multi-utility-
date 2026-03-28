import 'dart:developer' as developer;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';

/// Manages runtime permissions required for BARQ X
/// Handles both dangerous and special permissions
class RuntimePermissionsService {
  static final RuntimePermissionsService _instance = RuntimePermissionsService._internal();

  RuntimePermissionsService._internal();

  factory RuntimePermissionsService() {
    return _instance;
  }

  /// Check and request POST_NOTIFICATIONS permission (Android 13+)
  Future<bool> checkPostNotifications() async {
    if (!Platform.isAndroid) return true;

    try {
      final status = await Permission.notification.request();
      
      developer.log(
        'POST_NOTIFICATIONS: ${status.isDenied ? 'DENIED' : status.isGranted ? 'GRANTED' : 'PROVISIONAL'}',
        name: 'RuntimePermissionsService',
      );
      
      return status.isGranted || status.isProvisional;
    } catch (e) {
      developer.log('Error checking POST_NOTIFICATIONS: $e', name: 'RuntimePermissionsService');
      return false;
    }
  }

  /// Check and request CAMERA permission
  Future<bool> checkCamera() async {
    if (!Platform.isAndroid) return true;

    try {
      final status = await Permission.camera.request();
      
      developer.log(
        'CAMERA: ${status.isDenied ? 'DENIED' : status.isGranted ? 'GRANTED' : 'UNKNOWN'}',
        name: 'RuntimePermissionsService',
      );
      
      return status.isGranted;
    } catch (e) {
      developer.log('Error checking CAMERA: $e', name: 'RuntimePermissionsService');
      return false;
    }
  }

  /// Check and request SYSTEM_ALERT_WINDOW permission
  Future<bool> checkSystemAlertWindow() async {
    if (!Platform.isAndroid) return true;

    try {
      final status = await Permission.systemAlertWindow.request();
      
      developer.log(
        'SYSTEM_ALERT_WINDOW: ${status.isDenied ? 'DENIED' : status.isGranted ? 'GRANTED' : 'UNKNOWN'}',
        name: 'RuntimePermissionsService',
      );
      
      return status.isGranted;
    } catch (e) {
      developer.log('Error checking SYSTEM_ALERT_WINDOW: $e', name: 'RuntimePermissionsService');
      return false;
    }
  }

  /// Request IGNORE_BATTERY_OPTIMIZATIONS permission
  /// This is a special permission that must be granted via system settings
  Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;

    try {
      const intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      );
      await intent.launch();

      developer.log(
        'Launched IGNORE_BATTERY_OPTIMIZATION settings',
        name: 'RuntimePermissionsService',
      );
    } catch (e) {
      developer.log(
        'Error launching IGNORE_BATTERY_OPTIMIZATION: $e',
        name: 'RuntimePermissionsService',
      );
    }
  }

  /// Request ACCESS_NOTIFICATION_POLICY (DND) permission
  /// This is a special permission that must be granted via system settings
  Future<void> requestNotificationPolicyAccess() async {
    if (!Platform.isAndroid) return;

    try {
      const intent = AndroidIntent(
        action: 'android.settings.NOTIFICATION_POLICY_ACCESS_SETTINGS',
      );
      await intent.launch();

      developer.log(
        'Launched NOTIFICATION_POLICY_ACCESS settings',
        name: 'RuntimePermissionsService',
      );
    } catch (e) {
      developer.log(
        'Error launching NOTIFICATION_POLICY_ACCESS: $e',
        name: 'RuntimePermissionsService',
      );
    }
  }

  /// Check all critical permissions
  /// Returns map of permission -> granted status
  Future<Map<String, bool>> checkAllPermissions() async {
    if (!Platform.isAndroid) {
      return {
        'POST_NOTIFICATIONS': true,
        'CAMERA': true,
        'SYSTEM_ALERT_WINDOW': true,
        'NOTIFICATION_POLICY_ACCESS': true,
      };
    }

    return {
      'POST_NOTIFICATIONS': await checkPostNotifications(),
      'CAMERA': await checkCamera(),
      'SYSTEM_ALERT_WINDOW': await checkSystemAlertWindow(),
    };
  }

  /// Request all critical permissions
  /// Returns map of permission -> granted status
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = await checkAllPermissions();
    
    developer.log(
      'Permission check results: $results',
      name: 'RuntimePermissionsService',
    );
    
    return results;
  }

  /// Show permission details for debugging
  void logAllPermissions() async {
    if (!Platform.isAndroid) return;

    final allPermissions = [
      Permission.camera,
      Permission.notification,
      Permission.systemAlertWindow,
    ];

    for (final permission in allPermissions) {
      final status = await permission.status;
      developer.log(
        '${permission.toString()}: $status',
        name: 'RuntimePermissionsService',
      );
    }
  }
}
