import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../models/gesture_event.dart';
import '../providers/armed_provider.dart';
import '../providers/pocket_shield_provider.dart';
import '../providers/settings_provider.dart';
import '../services/action_handler.dart';
import '../services/sensor_service.dart';
import '../services/gesture_auditor.dart';

/// Integrates gesture events with action execution
/// Listens to gesture stream, filters by state, and executes actions
/// Includes comprehensive logging for debugging triggers
class GestureIntegrationService {
  final Ref ref;

  GestureIntegrationService(this.ref);

  /// Initialize gesture event listener
  Future<void> initialize() async {
    final sensorService = ref.read(sensorServiceProvider);
    
    try {
      // Initialize sensor service
      await sensorService.initialize();

      // Listen to gesture events
      sensorService.gestureEvents.listen(
        (gesture) => _handleGestureEvent(gesture),
        onError: (error, stackTrace) {
          developer.log(
            'Gesture event error: $error',
            name: 'GestureIntegrationService',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );

      developer.log(
        'Gesture integration service initialized',
        name: 'GestureIntegrationService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing gesture service: $e',
        name: 'GestureIntegrationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle incoming gesture event with comprehensive logging
  Future<void> _handleGestureEvent(GestureEvent gesture) async {
    try {
      // Check if armed
      final isArmed = ref.read(armedProvider);
      if (!isArmed) {
        GestureAuditor.logBlocked(
          gesture: gesture.type.displayName,
          reason: 'BARQ X is DISARMED - All gestures are inactive',
          blockType: 'DISARMED',
          context: {
            'isArmed': false,
            'gesture': gesture.type.displayName,
            'timestamp': gesture.timestamp.toIso8601String(),
          },
        );
        return;
      }

      // Check if pocket shield active
      final isPocketShielded = ref.read(pocketShieldProvider);
      if (isPocketShielded) {
        GestureAuditor.logBlocked(
          gesture: gesture.type.displayName,
          reason: 'POCKET SHIELD is ACTIVE - Phone is in pocket/bag',
          blockType: 'SHIELD',
          context: {
            'isPocketShielded': true,
            'gesture': gesture.type.displayName,
            'lightLevel': gesture.sensorData['light'] ?? 'N/A',
            'proximityBlocked': gesture.sensorData['proximity'] ?? 'N/A',
          },
        );
        return;
      }

      // Get settings
      final settings = ref.read(settingsProvider);

      // Check if specific gesture enabled
      final isGestureEnabled = _isGestureEnabled(gesture.type, settings);
      if (!isGestureEnabled) {
        GestureAuditor.logBlocked(
          gesture: gesture.type.displayName,
          reason: 'Gesture is DISABLED in settings',
          blockType: 'DISABLED',
          context: {
            'gestureType': gesture.type.displayName,
            'enabledInSettings': false,
          },
        );
        return;
      }

      // Log detection before action execution
      GestureAuditor.logDetection(
        gestureType: gesture.type,
        detectionReason: _getDetectionReason(gesture),
        rawSensorValues: gesture.sensorData,
        thresholds: _getThresholdsForGesture(gesture.type),
      );

      // Execute action with result logging
      final actionResult = await ActionHandler.handleGestureWithLogging(
        gesture,
        settings,
      );

      // Log complete trigger event
      GestureAuditor.logTrigger(
        gestureType: gesture.type,
        triggerCause: _getDetectionReason(gesture),
        sensorData: gesture.sensorData,
        actionExecuted: actionResult['actionName'] ?? 'Unknown',
        additionalInfo: actionResult['details'],
      );

    } catch (e, stackTrace) {
      developer.log(
        'Error handling gesture: $e',
        name: 'GestureIntegrationService',
        error: e,
        stackTrace: stackTrace,
      );
      
      GestureAuditor.logActionResult(
        gestureType: gesture.type,
        actionName: 'GESTURE_HANDLER',
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get human-readable detection reason based on gesture type
  String _getDetectionReason(GestureEvent gesture) {
    switch (gesture.type) {
      case GestureType.shake:
        final magnitude = gesture.sensorData['magnitude'] ?? 'N/A';
        final threshold = gesture.sensorData['threshold'] ?? '15.0';
        return 'Accelerometer magnitude ($magnitude m/s²) exceeded shake threshold ($threshold m/s²)';
      
      case GestureType.twist:
        final gyroZ = gesture.sensorData['gyroZ'] ?? 'N/A';
        final threshold = gesture.sensorData['threshold'] ?? '5.0';
        return 'Gyroscope Z-axis rotation ($gyroZ rad/s) exceeded twist threshold ($threshold rad/s)';
      
      case GestureType.flip:
        final zAxis = gesture.sensorData['zAxis'] ?? 
                      gesture.sensorData['accelZ'] ?? 'N/A';
        final action = gesture.sensorData['action'] ?? 'TOGGLE';
        
        if (action == 'ENABLE_DND') {
          return 'Phone flipped face-down (Z-axis: $zAxis m/s²) - Enabling DND';
        } else if (action == 'DISABLE_DND') {
          return 'Phone flipped face-up (Z-axis: $zAxis m/s²) - Disabling DND';
        } else {
          return 'Phone flipped (Z-axis: $zAxis m/s²) - Toggling DND';
        }
      
      case GestureType.backTap:
        final tapCount = gesture.sensorData['tapCount'] ?? '2';
        final impactMagnitude = gesture.sensorData['impactMagnitude'] ?? 'N/A';
        return 'Back-tap detected ($tapCount taps, impact: $impactMagnitude)';
      
      case GestureType.pocketShield:
        final lightLevel = gesture.sensorData['light'] ?? 'N/A';
        final proximity = gesture.sensorData['proximity'] ?? 'N/A';
        return 'Pocket shield activated (light: $lightLevel lux, proximity: $proximity)';
    }
  }

  /// Get threshold values for each gesture type (for logging)
  Map<String, dynamic> _getThresholdsForGesture(GestureType type) {
    switch (type) {
      case GestureType.shake:
        return {
          'shakeThreshold': '15.0 m/s²',
          'minDuration': '100ms',
          'cooldown': '1000ms',
        };
      case GestureType.twist:
        return {
          'twistThreshold': '5.0 rad/s',
          'minRotation': '90°',
          'cooldown': '1500ms',
        };
      case GestureType.flip:
        return {
          'flipThreshold': '-9.0 m/s² (Z-axis)',
          'holdDuration': '500ms',
          'cooldown': '2000ms',
        };
      case GestureType.backTap:
        return {
          'tapThreshold': '20.0 m/s²',
          'doubleTapWindow': '400ms',
          'cooldown': '500ms',
        };
      case GestureType.pocketShield:
        return {
          'lightThreshold': '10 lux',
          'proximityThreshold': 'near',
          'activationDelay': '1000ms',
        };
    }
  }

  /// Check if gesture is enabled in settings
  bool _isGestureEnabled(GestureType type, dynamic settings) {
    switch (type) {
      case GestureType.shake:
        return settings.shakeEnabled;
      case GestureType.twist:
        return settings.twistEnabled;
      case GestureType.flip:
        return settings.flipEnabled;
      case GestureType.backTap:
        return settings.backTapEnabled;
      case GestureType.pocketShield:
        return settings.pocketShieldEnabled;
    }
  }

  /// Cleanup
  Future<void> dispose() async {
    try {
      final sensorService = ref.read(sensorServiceProvider);
      await sensorService.stop();
      developer.log(
        'Gesture integration service disposed',
        name: 'GestureIntegrationService',
      );
    } catch (e) {
      developer.log(
        'Error disposing gesture service: $e',
        name: 'GestureIntegrationService',
      );
    }
  }
}

/// Riverpod provider for gesture integration service
final gestureIntegrationProvider = Provider<GestureIntegrationService>((ref) {
  return GestureIntegrationService(ref);
});
