import 'dart:math';
import '../constants/app_config.dart';

/// Low-Pass Filter for sensor data smoothing
class LowPassFilter {
  final double alpha;
  double _previousX = 0.0;
  double _previousY = 0.0;
  double _previousZ = 0.0;
  
  LowPassFilter({double? alpha}) : alpha = alpha ?? AppConfig.lowPassFilterAlpha;
  
  double apply(double currentValue, double previousValue) {
    return alpha * currentValue + (1 - alpha) * previousValue;
  }
  
  (double, double, double) applyToAccelerometer(
    double rawX,
    double rawY,
    double rawZ,
  ) {
    _previousX = apply(rawX, _previousX);
    _previousY = apply(rawY, _previousY);
    _previousZ = apply(rawZ, _previousZ);
    return (_previousX, _previousY, _previousZ);
  }
  
  void reset() {
    _previousX = 0.0;
    _previousY = 0.0;
    _previousZ = 0.0;
  }
  
  (double, double, double) get currentFiltered {
    return (_previousX, _previousY, _previousZ);
  }
}

/// High-Pass Filter for removing gravity and isolating dynamic motion
/// Used for Motorola-style chop gesture detection
class HighPassFilter {
  final double alpha;
  double _previousRawY = 0.0;
  double _previousRawZ = 0.0;
  double _previousFilteredY = 0.0;
  double _previousFilteredZ = 0.0;
  
  HighPassFilter({this.alpha = 0.8});
  
  /// Apply high-pass filter to Y and Z axes to remove gravity
  /// Returns (filteredY, filteredZ) containing only dynamic acceleration
  (double, double) applyYZ(double rawY, double rawZ) {
    // High-pass filter formula: y[i] = alpha * (y[i-1] + x[i] - x[i-1])
    _previousFilteredY = alpha * (_previousFilteredY + rawY - _previousRawY);
    _previousFilteredZ = alpha * (_previousFilteredZ + rawZ - _previousRawZ);
    
    _previousRawY = rawY;
    _previousRawZ = rawZ;
    
    return (_previousFilteredY, _previousFilteredZ);
  }
  
  void reset() {
    _previousRawY = 0.0;
    _previousRawZ = 0.0;
    _previousFilteredY = 0.0;
    _previousFilteredZ = 0.0;
  }
}

/// High-Pass Filter for Z-axis only (Back-Tap / Secret Strike detection)
/// Uses a sharper alpha for high-frequency impulse detection
class ZAxisHighPassFilter {
  final double alpha;
  double _previousRawZ = 0.0;
  double _previousFilteredZ = 0.0;
  
  ZAxisHighPassFilter({this.alpha = 0.9}); // Sharper filter for impulse detection
  
  /// Apply high-pass filter to Z-axis to isolate shock impulses
  /// Returns filtered Z value containing only dynamic acceleration (no gravity)
  double apply(double rawZ) {
    // High-pass filter formula: y[i] = alpha * (y[i-1] + x[i] - x[i-1])
    _previousFilteredZ = alpha * (_previousFilteredZ + rawZ - _previousRawZ);
    _previousRawZ = rawZ;
    return _previousFilteredZ;
  }
  
  void reset() {
    _previousRawZ = 0.0;
    _previousFilteredZ = 0.0;
  }
}

/// Vector3 helper class for 3D sensor data
class Vector3 {
  final double x;
  final double y;
  final double z;
  
  Vector3(this.x, this.y, this.z);
  
  double get magnitude => sqrt(x * x + y * y + z * z);
  
  /// Magnitude using only Y and Z axes (ignoring X for chop detection)
  double get magnitudeYZ => sqrt(y * y + z * z);
  
  Vector3 applyFilter(LowPassFilter filter) {
    final (filteredX, filteredY, filteredZ) =
        filter.applyToAccelerometer(x, y, z);
    return Vector3(filteredX, filteredY, filteredZ);
  }
  
  Vector3 operator -(Vector3 other) {
    return Vector3(x - other.x, y - other.y, z - other.z);
  }
  
  Vector3 operator +(Vector3 other) {
    return Vector3(x + other.x, y + other.y, z + other.z);
  }
  
  Vector3 operator *(double scalar) {
    return Vector3(x * scalar, y * scalar, z * scalar);
  }
  
  @override
  String toString() => 'Vector3($x, $y, $z)';
}
