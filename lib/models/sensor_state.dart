import 'dart:math';

/// Current sensor state snapshot
class SensorState {
  final double accelX;
  final double accelY;
  final double accelZ;
  final double accelXFiltered;
  final double accelYFiltered;
  final double accelZFiltered;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final double proximity;
  final double light;
  final bool isPocketShieldActive;
  final DateTime timestamp;
  
  const SensorState({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.accelXFiltered,
    required this.accelYFiltered,
    required this.accelZFiltered,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.proximity,
    required this.light,
    required this.isPocketShieldActive,
    required this.timestamp,
  });
  
  double get accelerationMagnitude {
    return sqrt(accelXFiltered * accelXFiltered +
            accelYFiltered * accelYFiltered +
            accelZFiltered * accelZFiltered);
  }
  
  double get gyroYAbsolute => gyroY.abs();
  bool get isFaceDown => accelZFiltered < -9.5;
  bool get isOnSurface => proximity == 0;
  bool get isDark => light < 10.0;
  
  @override
  String toString() => 'SensorState(accel: ($accelXFiltered, $accelYFiltered, $accelZFiltered))';
}
