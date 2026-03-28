import 'dart:developer' as developer;
import 'package:flutter/services.dart';

/// Manages the Foreground Service for BARQ X Gesture Engine
/// Implements the "Background Motor" - keeps sensors alive when app is minimized
/// Mandatory for Android 12+ battery compliance and continuous gesture detection
/// 
/// Uses native Android BackgroundGestureService with method channel
class ForegroundServiceManager {
  static final ForegroundServiceManager _instance = ForegroundServiceManager._internal();
  static const platform = MethodChannel('com.barq.x/background');

  ForegroundServiceManager._internal();

  factory ForegroundServiceManager() {
    return _instance;
  }

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  /// Initialize the foreground service
  /// Call once during app startup
  Future<void> initialize() async {
    try {
      // Check if service is already running
      _isRunning = false;
      
      developer.log(
        '✓ Foreground service manager initialized',
        name: 'ForegroundServiceManager',
      );
    } catch (e) {
      developer.log(
        '✗ Error initializing foreground service: $e',
        name: 'ForegroundServiceManager',
        error: e,
      );
    }
  }

  /// Start the foreground service via native Android
  /// Shows persistent notification with Disarm button
  Future<void> start() async {
    try {
      if (_isRunning) {
        developer.log('Service already running', name: 'ForegroundServiceManager');
        return;
      }

      await platform.invokeMethod('startBackgroundService');
      _isRunning = true;

      developer.log(
        '✓ Foreground service started (native)',
        name: 'ForegroundServiceManager',
      );
    } catch (e) {
      developer.log(
        '✗ Error starting foreground service: $e',
        name: 'ForegroundServiceManager',
        error: e,
      );
    }
  }

  /// Stop the foreground service
  Future<void> stop() async {
    try {
      await platform.invokeMethod('stopBackgroundService');
      _isRunning = false;

      developer.log(
        '✓ Foreground service stopped (native)',
        name: 'ForegroundServiceManager',
      );
    } catch (e) {
      developer.log(
        '✗ Error stopping foreground service: $e',
        name: 'ForegroundServiceManager',
        error: e,
      );
    }
  }
  
  /// Check if service is running
  Future<bool> checkIsRunning() async {
    try {
      // You can implement a native method to check service state
      return _isRunning;
    } catch (e) {
      return false;
    }
  }
}

