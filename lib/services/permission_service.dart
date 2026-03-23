import 'dart:developer' as developer;
import 'package:permission_handler/permission_handler.dart';

/// Manages Android permissions for BARQ X
/// Handles camera, notification policy, and system alert window
class PermissionService {
  /// Request all critical permissions
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.notification,
      Permission.systemAlertWindow,
    ];

    final statuses = await permissions.request();
    return statuses;
  }

  /// Request specific permission
  static Future<PermissionStatus> requestPermission(Permission permission) async {
    return await permission.request();
  }

  /// Check if all critical permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    final permissions = [
      Permission.camera,
      Permission.notification,
      Permission.systemAlertWindow,
    ];

    final statuses = await Future.wait(
      permissions.map((p) => p.status),
    );

    return statuses.every((status) => status.isGranted);
  }

  /// Check individual permission status
  static Future<PermissionStatus> checkPermissionStatus(
    Permission permission,
  ) async {
    return await permission.status;
  }

  /// Open app settings page
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      developer.log('Error opening app settings: $e', name: 'PermissionService');
    }
  }

  /// Check and request permissions, returning true if all granted
  static Future<bool> checkAndRequestPermissions() async {
    try {
      final allGranted = await areAllPermissionsGranted();
      if (allGranted) {
        return true;
      }

      // Request permissions
      final statuses = await requestAllPermissions();

      // Check if all granted after request
      return statuses.values.every((status) => status.isGranted);
    } catch (e) {
      developer.log('Error requesting permissions: $e', name: 'PermissionService');
      return false;
    }
  }
}
