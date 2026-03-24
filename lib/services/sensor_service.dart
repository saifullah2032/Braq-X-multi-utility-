import 'dart:async';
import 'dart:isolate';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:light/light.dart';
import '_sensor_isolate_entry.dart';
import '../models/gesture_event.dart';
import '../models/sensor_state.dart';

/// Manages sensor monitoring and gesture detection
/// Runs a background isolate for continuous monitoring
/// Coordinates with Riverpod providers for state updates
class SensorService {
  late Isolate _sensorIsolate;
  late SendPort _isolateSendPort;
  late ReceivePort _mainReceivePort;
  late Stream<dynamic> _isolateStream;

  bool _isInitialized = false;
  StreamSubscription? _lightSensorSub;

  // Gesture event stream controller
  final _gestureEventController = StreamController<GestureEvent>.broadcast();
  Stream<GestureEvent> get gestureEvents => _gestureEventController.stream;

  // Current sensor state (for UI updates)
  SensorState? _currentSensorState;
  SensorState? get currentSensorState => _currentSensorState;

  final Ref ref;

  SensorService(this.ref);

  /// Initialize the sensor service
  /// Starts the background isolate and sets up streams
  /// 
  /// IMPORTANT: Captures RootIsolateToken and passes to background isolate
  /// so it can call BackgroundIsolateBinaryMessenger.ensureInitialized()
  Future<void> initialize() async {
    if (_isInitialized) return;

    _mainReceivePort = ReceivePort();
    _isolateStream = _mainReceivePort.asBroadcastStream();

    try {
      // Capture the RootIsolateToken from the current isolate
      // This token is required for the background isolate to communicate
      // with the Flutter engine (for sensor access)
      final rootToken = RootIsolateToken.instance;

      // Spawn the background isolate with BOTH:
      // 1. The main ReceivePort (for gesture event communication)
      // 2. The RootIsolateToken (for platform channel access)
      _sensorIsolate = await Isolate.spawn(
        sensorIsolateEntry,
        (
          mainReceivePort: _mainReceivePort.sendPort,
          rootToken: rootToken,
        ),
      );

      // Listen for messages from isolate
      _isolateStream.listen(_handleIsolateMessage);

      // Wait for isolate to send ready signal
      await _waitForIsolateReady();

      // Monitor light sensor (low frequency)
      _startLightSensorMonitoring();

      _isInitialized = true;

      developer.log(
        'Sensor service initialized with background isolate (RootIsolateToken passed)',
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
        _isolateSendPort = message['receivePort'] as SendPort;
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

  /// Handle messages from the sensor isolate
  void _handleIsolateMessage(dynamic message) {
    if (message is! Map) return;

    final type = message['type'] as String?;

    if (type == 'gesture') {
      final gestureData = message['gesture'] as Map?;
      if (gestureData != null) {
        final gestureTypeStr = gestureData['gestureType'] as String?;
        GestureType gestureType = GestureType.shake;

        // Map string to enum
        if (gestureTypeStr != null) {
          gestureType = {
            'SHAKE': GestureType.shake,
            'TWIST': GestureType.twist,
            'FLIP': GestureType.flip,
            'BACK_TAP': GestureType.backTap,
          }[gestureTypeStr] ??
              GestureType.shake;
        }

        final event = GestureEvent(
          type: gestureType,
          timestamp: DateTime.parse(gestureData['timestamp'] as String),
          sensorData:
              (gestureData['metadata'] as Map?)?.cast<String, dynamic>() ?? {},
        );

        _gestureEventController.add(event);
      }
    }
  }

  /// Start monitoring light sensor
  void _startLightSensorMonitoring() {
    try {
      // Light sensor at low frequency
      final light = Light();
      _lightSensorSub = light.lightSensorStream.listen((lux) {
        // Update current sensor state with light value
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
            proximity: _currentSensorState!.proximity,
            light: lux.toDouble(),
            isPocketShieldActive: _currentSensorState!.isPocketShieldActive,
            timestamp: DateTime.now(),
          );
        }
      });
    } catch (e) {
      developer.log('Error starting light sensor: $e', name: 'SensorService');
    }
  }

  /// Stop the sensor service
  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      _isolateSendPort.send('stop');
      await _lightSensorSub?.cancel();
      _mainReceivePort.close();
      _sensorIsolate.kill();
      _gestureEventController.close();
      _isInitialized = false;
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
