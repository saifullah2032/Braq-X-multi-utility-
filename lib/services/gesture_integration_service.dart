import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../models/gesture_event.dart';
import '../providers/armed_provider.dart';
import '../providers/pocket_shield_provider.dart';
import '../providers/settings_provider.dart';
import '../services/action_handler.dart';
import '../services/sensor_service.dart';

/// Integrates gesture events with action execution
/// Listens to gesture stream, filters by state, and executes actions
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

  /// Handle incoming gesture event
  Future<void> _handleGestureEvent(GestureEvent gesture) async {
    try {
      // Check if armed
      final isArmed = ref.read(armedProvider);
      if (!isArmed) {
        developer.log(
          'Gesture ignored: BARQ X disarmed',
          name: 'GestureIntegrationService',
        );
        return;
      }

      // Check if pocket shield active
      final isPocketShielded = ref.read(pocketShieldProvider);
      if (isPocketShielded) {
        developer.log(
          'Gesture ignored: Pocket Shield active',
          name: 'GestureIntegrationService',
        );
        return;
      }

      // Get settings
      final settings = ref.read(settingsProvider);

      // Check if specific gesture enabled
      final isGestureEnabled = _isGestureEnabled(gesture.type, settings);
      if (!isGestureEnabled) {
        developer.log(
          'Gesture ignored: ${gesture.type} disabled in settings',
          name: 'GestureIntegrationService',
        );
        return;
      }

      // Execute action
      developer.log(
        'Executing action for gesture: ${gesture.type.displayName}',
        name: 'GestureIntegrationService',
      );

      await ActionHandler.handleGesture(gesture, settings);
    } catch (e, stackTrace) {
      developer.log(
        'Error handling gesture: $e',
        name: 'GestureIntegrationService',
        error: e,
        stackTrace: stackTrace,
      );
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
