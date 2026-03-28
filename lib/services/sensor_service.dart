import 'dart:async';
import 'dart:isolate';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:light/light.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import '_sensor_isolate_entry.dart';
import '../models/gesture_event.dart';
import '../models/sensor_state.dart';
import '../providers/current_sensor_state_provider.dart';
import 'gesture_auditor.dart';

/// Manages sensor monitoring and gesture detection
/// Root isolate listens to sensors and sends data to background service for processing
/// Coordinates with Riverpod providers for state updates
class SensorService {
  late Isolate _processingIsolate;
  late SendPort _isolateSendPort;
  late ReceivePort _mainReceivePort;
  late Stream<dynamic> _isolateStream;

  bool _isInitialized = false;
  
  // Sensor stream subscriptions
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription? _lightSensorSub;
  StreamSubscription<int>? _proximitySensorSub;
  
  // Throttling for environment sensors (500ms interval)
  DateTime? _lastEnvironmentDataSent;
  static const Duration _environmentThrottle = Duration(milliseconds: 500);
  
  // Current environment data
  double _currentLux = 1000.0; // Default: bright
  bool _isProximityNear = false; // Default: far
  
  // Pocket shield state
  bool _isPocketShielded = false;

  // Gesture event stream controller
  final _gestureEventController = StreamController<GestureEvent>.broadcast();
  Stream<GestureEvent> get gestureEvents => _gestureEventController.stream;

  // Current sensor state (for UI updates)
  SensorState? _currentSensorState;
  SensorState? get currentSensorState => _currentSensorState;

  final Ref ref;

  SensorService(this.ref);

  /// Initialize the sensor service
  /// Sets up Root Isolate sensor listening and spawns background processing isolate
  /// 
  /// Architecture:
  /// 1. Root Isolate: Listens to accelerometer/gyroscope sensors
  /// 2. SendPort: Sends raw sensor data to processing isolate
  /// 3. Processing Isolate: Detects gestures and sends events back
  /// 4. Callback: Main thread updates UI with gesture events
  Future<void> initialize() async {
    if (_isInitialized) return;

    _mainReceivePort = ReceivePort();
    _isolateStream = _mainReceivePort.asBroadcastStream();

    try {
      // Spawn the gesture processing isolate
      _processingIsolate = await Isolate.spawn(
        sensorIsolateEntry,
        _mainReceivePort.sendPort,
      );

      // Listen for gesture events from isolate
      _isolateStream.listen(_handleIsolateMessage);

      // Wait for isolate to send ready signal with its SendPort
      await _waitForIsolateReady();

      // Start listening to sensors in ROOT ISOLATE (main thread)
      _startSensorMonitoring();

      _isInitialized = true;

      developer.log(
        'Sensor service initialized with Root Isolate sensor listening',
        name: 'SensorService',
      );
    } catch (e, st) {
      developer.log(
        'Error initializing sensor service: $e',
        name: 'SensorService',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Wait for the isolate to initialize and send back its SendPort
  Future<void> _waitForIsolateReady() {
    final completer = Completer<void>();

    final sub = _isolateStream.listen((message) {
      if (message is Map && message['type'] == 'ready') {
        _isolateSendPort = message['sendPort'] as SendPort;
        completer.complete();
      }
    });

    // Timeout after 5 seconds
    Future.delayed(Duration(seconds: 5)).then((_) {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('Isolate initialization timeout'));
      }
    });

    return completer.future.then((_) {
      sub.cancel();
    });
  }

  /// Start monitoring sensors in the Root Isolate
  /// Sends raw sensor data to the processing isolate for gesture detection
  void _startSensorMonitoring() {
    try {
       // Listen to accelerometer at aggressive ~100Hz rate (10ms interval)
       // Target: 100Hz+ sampling to catch rapid gesture spikes for better precision
       // Even at 100Hz, still safe on modern Android devices
       _accelSub = accelerometerEventStream(samplingPeriod: Duration(milliseconds: 10))
           .listen((event) {
        // Forward to processing isolate
        _isolateSendPort.send({
          'type': 'sensor_data',
          'sensor': 'accel',
          'x': event.x,
          'y': event.y,
          'z': event.z,
          'timestamp': DateTime.now().toIso8601String(),
        });
      });

       // Listen to gyroscope at aggressive ~100Hz rate (10ms interval) for gesture detection
       // Target: 100Hz+ sampling for maximum precision on rotation detection
       _gyroSub = gyroscopeEventStream(samplingPeriod: Duration(milliseconds: 10))
           .listen((event) {
        // Forward to processing isolate
        _isolateSendPort.send({
          'type': 'sensor_data',
          'sensor': 'gyro',
          'x': event.x,
          'y': event.y,
          'z': event.z,
          'timestamp': DateTime.now().toIso8601String(),
        });
      });

      // Listen to light sensor and proximity sensor at low frequency
      _startEnvironmentSensorMonitoring();

      developer.log(
        'Sensor monitoring started in Root Isolate',
        name: 'SensorService',
      );
    } catch (e) {
      developer.log('Error starting sensor monitoring: $e', name: 'SensorService');
    }
  }

  /// Start monitoring environment sensors (light + proximity) with throttling
  /// Updates sent to isolate every 500ms for power optimization
  void _startEnvironmentSensorMonitoring() {
    try {
      // Light sensor
      final light = Light();
      _lightSensorSub = light.lightSensorStream.listen((lux) {
        _currentLux = lux.toDouble();
        _sendEnvironmentDataToIsolate();
        
        // Update current sensor state
        if (_currentSensorState != null) {
          _currentSensorState = SensorState(
            accelX: _currentSensorState!.accelX,
            accelY: _currentSensorState!.accelY,
            accelZ: _currentSensorState!.accelZ,
            accelXFiltered: _currentSensorState!.accelXFiltered,
            accelYFiltered: _currentSensorState!.accelYFiltered,
            accelZFiltered: _currentSensorState!.accelZFiltered,
            gyroX: _currentSensorState!.gyroX,
            gyroY: _currentSensorState!.gyroY,
            gyroZ: _currentSensorState!.gyroZ,
            proximity: _isProximityNear ? 0 : 5,
            light: _currentLux,
            isPocketShieldActive: _isPocketShielded,
            timestamp: DateTime.now(),
          );
        }
      });
      
      // Proximity sensor
      _proximitySensorSub = ProximitySensor.events.listen((event) {
        // event: 0 = near, positive value = far
        _isProximityNear = (event == 0);
        _sendEnvironmentDataToIsolate();
        
        developer.log(
          'Proximity: ${_isProximityNear ? "NEAR" : "FAR"} (raw: $event)',
          name: 'SensorService',
        );
      });
      
      developer.log(
        'Environment sensors (light + proximity) started',
        name: 'SensorService',
      );
    } catch (e) {
      developer.log('Error starting environment sensors: $e', name: 'SensorService');
    }
  }
  
  /// Notify the pocket shield provider of status changes
  /// Updates the currentSensorStateProvider to trigger UI updates
  void _notifyPocketShieldStatus(bool isActive) {
    try {
      // Update the current sensor state provider to reflect shield status
      // This will trigger the pocketShieldProvider to recalculate
      if (_currentSensorState != null) {
        final updatedState = SensorState(
          accelX: _currentSensorState!.accelX,
          accelY: _currentSensorState!.accelY,
          accelZ: _currentSensorState!.accelZ,
          accelXFiltered: _currentSensorState!.accelXFiltered,
          accelYFiltered: _currentSensorState!.accelYFiltered,
          accelZFiltered: _currentSensorState!.accelZFiltered,
          gyroX: _currentSensorState!.gyroX,
          gyroY: _currentSensorState!.gyroY,
          gyroZ: _currentSensorState!.gyroZ,
          proximity: _isProximityNear ? 0 : 5,
          light: _currentLux,
          isPocketShieldActive: isActive,
          timestamp: DateTime.now(),
        );
        
        _currentSensorState = updatedState;
        
        // Update Riverpod provider state
        ref.read(currentSensorStateProvider.notifier).state = updatedState;
      }
      
      developer.log(
        'Pocket Shield status updated: ${isActive ? "ACTIVE" : "INACTIVE"}',
        name: 'SensorService',
      );
    } catch (e) {
      developer.log('Error updating pocket shield status: $e', name: 'SensorService');
    }
  }

  /// Send environment data to isolate with 500ms throttling
  void _sendEnvironmentDataToIsolate() {
    final now = DateTime.now();
    
    // Throttle: only send every 500ms
    if (_lastEnvironmentDataSent != null) {
      final timeSinceLastSent = now.difference(_lastEnvironmentDataSent!);
      if (timeSinceLastSent < _environmentThrottle) {
        return; // Skip this update
      }
    }
    
    _lastEnvironmentDataSent = now;
    
    // Forward to processing isolate
    _isolateSendPort.send({
      'type': 'environment_data',
      'proximity_near': _isProximityNear,
      'lux': _currentLux,
      'timestamp': now.toIso8601String(),
    });
  }

  /// Handle messages from the gesture processing isolate
  void _handleIsolateMessage(dynamic message) {
    if (message is! Map) return;

    final type = message['type'] as String?;
    
    // ============================================================
    // DEBUG HEARTBEAT - Verify isolate is receiving sensor data
    // ============================================================
    if (type == 'debug_heartbeat') {
      final accelSamples = message['accel_samples'] as int? ?? 0;
      final gyroSamples = message['gyro_samples'] as int? ?? 0;
      final maxAccelMag = (message['max_accel_magnitude'] as num?)?.toDouble() ?? 0.0;
      final maxGyroY = (message['max_gyro_y'] as num?)?.toDouble() ?? 0.0;
      final elapsedMs = message['elapsed_ms'] as int? ?? 0;
      final shieldActive = message['shield_active'] as bool? ?? false;
      final proximityNear = message['proximity_near'] as bool? ?? false;
      final lux = (message['lux'] as num?)?.toDouble() ?? 0.0;
      final globalLock = message['global_lock'] as bool? ?? false;
      
      // Calculate sample rate
      final sampleRate = elapsedMs > 0 ? (100 * 1000 / elapsedMs).toStringAsFixed(1) : '?';
      
      // Determine shield reason (now only based on lux)
      String shieldReason = 'OFF';
      if (shieldActive) {
        shieldReason = 'BLOCKED (Lux < 10)';
      }
      
      print('');
      print('╔══════════════════════════════════════════════════════════════════╗');
      print('║ 💓 ISOLATE HEARTBEAT                                              ║');
      print('╠══════════════════════════════════════════════════════════════════╣');
      print('║ 📊 Accel Samples: $accelSamples | Gyro Samples: $gyroSamples');
      print('║ ⏱️  Sample Rate: $sampleRate Hz (elapsed: ${elapsedMs}ms)');
      print('║ 📈 Max Accel Magnitude: ${maxAccelMag.toStringAsFixed(2)} m/s² (CHOP threshold: 20.0)');
      print('║ 🔄 Max Gyro Y: ${maxGyroY.toStringAsFixed(2)} rad/s (TWIST threshold: 6.0)');
      print('║ 🛡️  Shield: $shieldReason');
      print('║ 💡 Lux: ${lux.toStringAsFixed(1)} ${lux < 10 ? "⚠️ DARK (shield active)" : "✓ (shield off)"}');
      print('║ 🔒 Lock: ${globalLock ? "LOCKED" : "FREE"}');
      print('╚══════════════════════════════════════════════════════════════════╝');
      print('');
      
      developer.log(
        '💓 HEARTBEAT: Accel=$accelSamples, Gyro=$gyroSamples, MaxMag=${maxAccelMag.toStringAsFixed(2)}, MaxGyroY=${maxGyroY.toStringAsFixed(2)}, Shield=$shieldActive, Prox=$proximityNear, Lux=${lux.toStringAsFixed(1)}',
        name: 'SensorService',
      );
      return;
    }
    
    // ============================================================
    // DEBUG GESTURE PROGRESS - Real-time detection feedback
    // ============================================================
    if (type == 'debug_gesture_progress') {
      final gesture = message['gesture'] as String? ?? '?';
      final current = (message['current'] as num?)?.toDouble() ?? 0.0;
      final threshold = (message['threshold'] as num?)?.toDouble() ?? 0.0;
      final progress = (message['progress'] as num?)?.toDouble() ?? 0.0;
      final note = message['note'] as String? ?? '';
      
      // Create visual progress bar
      final barLength = 20;
      final filledLength = (progress / 100 * barLength).round().clamp(0, barLength);
      final progressBar = '█' * filledLength + '░' * (barLength - filledLength);
      
      // Color-code based on progress
      final emoji = progress >= 100 ? '🔥' : (progress >= 50 ? '⚡' : '📊');
      
      print('$emoji [$gesture] ${current.toStringAsFixed(1)}/${threshold.toStringAsFixed(1)} [$progressBar] ${progress.toStringAsFixed(0)}% | $note');
      return;
    }
    
    // ============================================================
    // DEBUG DETECTION EVENTS - Spike detection and trigger events
    // ============================================================
    if (type == 'debug_detection') {
      final gesture = message['gesture'] as String? ?? '?';
      final event = message['event'] as String? ?? '?';
      final value = (message['value'] as num?)?.toDouble() ?? 0.0;
      final msg = message['message'] as String? ?? '';
      
      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📍 [$gesture] $event (${value.toStringAsFixed(2)})');
      print('   $msg');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      return;
    }
    
    // Handle shield status updates from isolate
    if (type == 'shield_status') {
      final isActive = message['active'] as bool? ?? false;
      _isPocketShielded = isActive;
      
      developer.log(
        '🛡️ POCKET SHIELD: ${isActive ? "ACTIVE" : "INACTIVE"}',
        name: 'SensorService',
      );
      
      // Update sensor state for UI
      if (_currentSensorState != null) {
        _currentSensorState = SensorState(
          accelX: _currentSensorState!.accelX,
          accelY: _currentSensorState!.accelY,
          accelZ: _currentSensorState!.accelZ,
          accelXFiltered: _currentSensorState!.accelXFiltered,
          accelYFiltered: _currentSensorState!.accelYFiltered,
          accelZFiltered: _currentSensorState!.accelZFiltered,
          gyroX: _currentSensorState!.gyroX,
          gyroY: _currentSensorState!.gyroY,
          gyroZ: _currentSensorState!.gyroZ,
          proximity: _isProximityNear ? 0 : 5,
          light: _currentLux,
          isPocketShieldActive: isActive,
          timestamp: DateTime.now(),
        );
      }
      
      // Notify pocket shield provider via state update
      _notifyPocketShieldStatus(isActive);
      return;
    }

    if (type == 'gesture') {
      final gestureData = message['gesture'] as Map?;
      if (gestureData != null) {
        final gestureTypeStr = gestureData['gestureType'] as String?;
        GestureType gestureType = GestureType.shake;

        // Debug print for terminal visibility
        print('========================================');
        print('[SENSOR_SERVICE] GESTURE RECEIVED: $gestureTypeStr');
        print('========================================');

        // Map string to enum
        if (gestureTypeStr != null) {
          gestureType = {
            'SHAKE': GestureType.shake,
            'TWIST': GestureType.twist,
            'FLIP': GestureType.flip,
            'FLIP_ON': GestureType.flip,  // Explicit DND ON
            'FLIP_OFF': GestureType.flip, // Explicit DND OFF
            'BACK_TAP': GestureType.backTap,
          }[gestureTypeStr] ??
              GestureType.shake;
        }

        // Extract sensor metadata for logging
        final metadata = (gestureData['metadata'] as Map?)?.cast<String, dynamic>() ?? {};
        
        final event = GestureEvent(
          type: gestureType,
          timestamp: DateTime.parse(gestureData['timestamp'] as String),
          sensorData: metadata,
        );

        _gestureEventController.add(event);

        // Log detailed detection information
        developer.log(
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
          name: 'SensorService',
        );
        developer.log(
          '🎯 GESTURE DETECTED FROM ISOLATE: $gestureTypeStr',
          name: 'SensorService',
        );
        developer.log(
          '   Timestamp: ${event.timestamp.toIso8601String()}',
          name: 'SensorService',
        );
        developer.log(
          '   Sensor Data: $metadata',
          name: 'SensorService',
        );
        developer.log(
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
          name: 'SensorService',
        );
        
        // Log sensor snapshot for debugging
        GestureAuditor.logSensorSnapshot(
          gesture: gestureTypeStr ?? 'UNKNOWN',
          sensorData: metadata,
          reason: 'Gesture detected by processing isolate',
        );
      }
    }
  }

  /// Stop the sensor service
  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      _isolateSendPort.send('stop');
      await _accelSub?.cancel();
      await _gyroSub?.cancel();
      await _lightSensorSub?.cancel();
      await _proximitySensorSub?.cancel();
      _mainReceivePort.close();
      _processingIsolate.kill();
      _gestureEventController.close();
      _isInitialized = false;

      developer.log('Sensor service stopped', name: 'SensorService');
    } catch (e) {
      developer.log('Error stopping sensor service: $e', name: 'SensorService');
    }
  }

  /// Restart the sensor service (e.g., after an error)
  Future<void> restart() async {
    await stop();
    await initialize();
  }

  /// Get the gesture event stream
  Stream<GestureEvent> getGestureStream() => gestureEvents;
}

/// Riverpod provider for sensor service
final sensorServiceProvider = Provider<SensorService>((ref) {
  return SensorService(ref);
});

/// Stream provider for gesture events
final gestureStreamProvider = StreamProvider<GestureEvent>((ref) async* {
  final service = ref.watch(sensorServiceProvider);

  // Ensure service is initialized
  if (!service._isInitialized) {
    await service.initialize();
  }

  yield* service.gestureEvents;
});
