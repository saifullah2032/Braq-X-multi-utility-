import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../utils/low_pass_filter.dart';
import '../constants/app_config.dart';

/// ============================================================
/// Background Sensor Isolate Entry Point
/// 
/// This isolate runs in a separate thread to monitor sensors at 50Hz
/// without blocking the Flutter UI thread.
/// 
/// CRITICAL: This function receives RootIsolateToken to initialize
/// BackgroundIsolateBinaryMessenger for platform channel communication.
/// ============================================================

/// Entry point for background sensor isolate
/// 
/// Parameters:
///   args - Named record containing:
///     - mainReceivePort: SendPort to main isolate for gesture events
///     - rootToken: RootIsolateToken for platform channel initialization
void sensorIsolateEntry(
  ({
    SendPort mainReceivePort,
    RootIsolateToken? rootToken,
  }) args,
) {
  // ============================================================
  // CRITICAL: Initialize BackgroundIsolateBinaryMessenger FIRST
  // 
  // This MUST be called before any sensor APIs are accessed.
  // The token allows this isolate to communicate with the Flutter
  // engine for platform channel calls (sensor access, permissions, etc.)
  // ============================================================
  if (args.rootToken != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(args.rootToken!);
  }

  final sendPort = args.mainReceivePort;
  // Initialize filters for noise reduction
  final accelFilter = LowPassFilter(alpha: AppConfig.lowPassFilterAlpha);
  final gyroFilter = LowPassFilter(alpha: AppConfig.lowPassFilterAlpha);

  // Track last gesture timestamps for cooldown periods
  final lastGestureTime = <String, DateTime>{};

  // Gesture detection helpers
  DateTime? lastShakeTime;
  int gyroSpikesCount = 0;
  DateTime? firstGyroSpikeTime;
  List<double> backTapAccelValues = [];
  bool isFlipping = false;
  DateTime? flipStartTime;

  // Stream subscriptions
  late StreamSubscription<AccelerometerEvent> accelSub;
  late StreamSubscription<GyroscopeEvent> gyroSub;

  /// Kinetic Shake Detection (Torch)
  void detectShake(Vector3 accel) {
    final magnitude = accel.magnitude;

    if (magnitude > AppConfig.shakeThreshold) {
      final now = DateTime.now();

      if (lastShakeTime == null ||
          now.difference(lastShakeTime!).inMilliseconds >=
              (AppConfig.shakeCooldownSeconds * 1000).toInt()) {
        // Emit shake gesture
        sendPort.send({
          'type': 'gesture',
          'gesture': {
            'gestureType': 'SHAKE',
            'timestamp': now.toIso8601String(),
            'confidence': 0.95,
            'metadata': {'magnitude': magnitude},
          },
        });

        lastShakeTime = now;
        lastGestureTime['SHAKE'] = now;
      }
    }
  }

  /// Inertial Twist Detection (Camera)
  void detectTwist(Vector3 gyro) {
    final yAxisGyro = gyro.y.abs();

    if (yAxisGyro > AppConfig.twistThreshold) {
      final now = DateTime.now();

      // First spike detected
      if (gyroSpikesCount == 0) {
        firstGyroSpikeTime = now;
        gyroSpikesCount = 1;
      } else if (now.difference(firstGyroSpikeTime!).inMilliseconds <=
          AppConfig.backTapWindowMilliseconds) {
        // Second spike within window
        gyroSpikesCount++;

        if (gyroSpikesCount >= 2) {
          // Emit twist gesture
          sendPort.send({
            'type': 'gesture',
            'gesture': {
              'gestureType': 'TWIST',
              'timestamp': now.toIso8601String(),
              'confidence': 0.90,
              'metadata': {'gyroY': yAxisGyro, 'spikes': gyroSpikesCount},
            },
          });

          lastGestureTime['TWIST'] = now;
          gyroSpikesCount = 0;
          firstGyroSpikeTime = null;
        }
      } else {
        // Window expired, reset
        gyroSpikesCount = 1;
        firstGyroSpikeTime = now;
      }
    }
  }

  /// Secret Strike Detection (Back-Tap)
  void detectBackTap(Vector3 accel) {
    backTapAccelValues.add(accel.magnitude);

    // Keep only last 400ms of data (adjust based on sampling rate)
    if (backTapAccelValues.length > 20) {
      // ~400ms at 50Hz sampling
      backTapAccelValues.removeAt(0);
    }

    // Count spikes > 12.0 m/s² in the window
    final spikes = backTapAccelValues
        .where((v) => v > AppConfig.backTapSpikeThreshold)
        .length;

    if (spikes >= 2) {
      final now = DateTime.now();

      if (lastGestureTime['BACK_TAP'] == null ||
          now.difference(lastGestureTime['BACK_TAP']!).inMilliseconds >=
              (AppConfig.twistCooldownSeconds * 1000).toInt()) {
        // Emit back-tap gesture
        sendPort.send({
          'type': 'gesture',
          'gesture': {
            'gestureType': 'BACK_TAP',
            'timestamp': now.toIso8601String(),
            'confidence': 0.88,
            'metadata': {'spikes': spikes, 'windowMs': AppConfig.backTapWindowMilliseconds},
          },
        });

        lastGestureTime['BACK_TAP'] = now;
        backTapAccelValues.clear();
      }
    }
  }

  /// Surface Flip Detection (DND)
  void detectFlip(Vector3 accel) {
    final isFlipped = accel.z < AppConfig.flipZThreshold;

    if (isFlipped && !isFlipping) {
      // Transition to flipped
      isFlipping = true;
      flipStartTime = DateTime.now();
    } else if (!isFlipped && isFlipping) {
      // Transition back to normal
      final now = DateTime.now();

      if (flipStartTime != null &&
          now.difference(flipStartTime!).inMilliseconds >= 200) {
        // ~200ms stable for flip detection
        if (lastGestureTime['FLIP'] == null ||
            now.difference(lastGestureTime['FLIP']!).inMilliseconds >=
                3500) {
          // 3.5s cooldown
          // Emit flip gesture
          sendPort.send({
            'type': 'gesture',
            'gesture': {
              'gestureType': 'FLIP',
              'timestamp': now.toIso8601String(),
              'confidence': 0.92,
              'metadata': {
                'zAxis': accel.z,
                'duration': now.difference(flipStartTime!).inMilliseconds
              },
            },
          });

          lastGestureTime['FLIP'] = now;
        }
      }

      isFlipping = false;
      flipStartTime = null;
    }
  }

  // Subscribe to accelerometer
  accelSub = accelerometerEventStream().listen((event) {
    final rawAccel = Vector3(event.x, event.y, event.z);
    final filteredAccel = rawAccel.applyFilter(accelFilter);

    detectShake(filteredAccel);
    detectBackTap(filteredAccel);
    detectFlip(filteredAccel);
  });

  // Subscribe to gyroscope
  gyroSub = gyroscopeEventStream().listen((event) {
    final rawGyro = Vector3(event.x, event.y, event.z);
    final filteredGyro = rawGyro.applyFilter(gyroFilter);
    detectTwist(filteredGyro);
  });

  // Handle messages from main isolate (like stop command)
  final receivePort = ReceivePort();
  sendPort.send({'type': 'ready', 'receivePort': receivePort.sendPort});

  receivePort.listen((message) {
    if (message is String && message == 'stop') {
      accelSub.cancel();
      gyroSub.cancel();
      receivePort.close();
    }
  });
}
