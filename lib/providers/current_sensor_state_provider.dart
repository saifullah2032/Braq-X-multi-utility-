import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_state.dart';

/// Real-time sensor state provider
/// Emits raw sensor readings (accelerometer, gyroscope, light, proximity)
/// Updated by the sensor service when readings are available
final currentSensorStateProvider = StateProvider<SensorState?>((ref) {
  // Initial null state - filled by sensor service
  return null;
});
