/// Gesture event types for BARQ X
enum GestureType {
  shake,      // Kinetic Shake - Toggle torch
  twist,      // Inertial Twist - Launch camera
  flip,       // Surface Flip - Enable DND
  pocketShield, // Pocket Shield - Protective mode
  backTap,    // Secret Strike - Back-tap for custom action
}

/// Gesture event model sent from background isolate to UI
class GestureEvent {
  final GestureType type;
  final DateTime timestamp;
  final Map<String, dynamic> sensorData;
  
  GestureEvent({
    required this.type,
    required this.timestamp,
    required this.sensorData,
  });
  
  @override
  String toString() => 'GestureEvent(type: $type, timestamp: $timestamp)';
}

/// Extension method for gesture names
extension GestureTypeExtension on GestureType {
  String get displayName {
    switch (this) {
      case GestureType.shake:
        return 'Kinetic Shake';
      case GestureType.twist:
        return 'Inertial Twist';
      case GestureType.flip:
        return 'Surface Flip';
      case GestureType.pocketShield:
        return 'Pocket Shield';
      case GestureType.backTap:
        return 'Secret Strike';
    }
  }
  
  String get emoji {
    switch (this) {
      case GestureType.shake:
        return '🔦';
      case GestureType.twist:
        return '📷';
      case GestureType.flip:
        return '🔕';
      case GestureType.pocketShield:
        return '🛡️';
      case GestureType.backTap:
        return '⚡';
    }
  }
}
