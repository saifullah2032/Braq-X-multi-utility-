import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'current_sensor_state_provider.dart';
import 'settings_provider.dart';
import '../constants/app_config.dart';

/// Pocket Shield state provider (derived from sensors)
/// True = device in pocket/dark (disable all gestures)
/// False = device out of pocket/visible
final pocketShieldProvider = Provider<bool>((ref) {
  final sensorState = ref.watch(currentSensorStateProvider);
  final settings = ref.watch(settingsProvider);

  // If pocket shield disabled in settings, always return false
  if (!settings.pocketShieldEnabled) {
    return false;
  }

  // If no sensor data yet, assume safe (not in pocket)
  if (sensorState == null) {
    return false;
  }

  // Pocket Shield logic:
  // Proximity > 0 cm (something close to sensor)
  // AND Light < 10 lux (very dark)
  final isPocketShielded = sensorState.proximity > 0 &&
      sensorState.light < AppConfig.pocketShieldLightThreshold;

  return isPocketShielded;
});
