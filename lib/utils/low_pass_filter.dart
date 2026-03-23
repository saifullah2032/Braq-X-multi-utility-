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

/// Vector3 helper class for 3D sensor data
class Vector3 {
  final double x;
  final double y;
  final double z;
  
  Vector3(this.x, this.y, this.z);
  
  double get magnitude => sqrt(x * x + y * y + z * z);
  
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
