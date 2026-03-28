import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

/// Notifier that tracks whether the foreground service is running
class ServiceRunningNotifier extends StateNotifier<bool> {
  ServiceRunningNotifier() : super(false);

  /// Update service running state
  void setServiceRunning(bool isRunning) {
    state = isRunning;
    developer.log('Service running state changed to: $isRunning', name: 'ServiceRunningNotifier');
  }
}

/// Riverpod provider for foreground service state
/// This is updated by HomeScreen and ForegroundServiceManager
final serviceRunningProvider = StateNotifierProvider<ServiceRunningNotifier, bool>((ref) {
  return ServiceRunningNotifier();
});
