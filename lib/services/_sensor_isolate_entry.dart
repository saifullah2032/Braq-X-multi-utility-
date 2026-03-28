import 'dart:isolate';
import 'dart:math';
import 'dart:async';
import '../utils/low_pass_filter.dart';
import '../constants/app_config.dart';
import 'gesture_auditor.dart';

/// ============================================================
/// Background Gesture Processing Isolate Entry Point
/// 
/// This isolate receives raw sensor data from the Root Isolate
/// and performs gesture detection without blocking the UI thread.
/// 
/// NEW ARCHITECTURE:
/// - Root Isolate: Listens to sensors (accelerometer, gyroscope)
/// - Processing Isolate: Receives sensor data and detects gestures
/// - Bridge: SendPort/ReceivePort for sensor data and gesture events
/// ============================================================

/// Helper class to track gyroscope peaks for double twist detection
class TwistPeak {
  final double value;
  final DateTime timestamp;
  final bool isPositive;
  
  TwistPeak(this.value, this.timestamp, this.isPositive);
}

/// Helper class to track Z-axis spikes for Secret Strike (back-tap) detection
class StrikeSpike {
  final double zAxisValue;      // High-pass filtered Z-axis magnitude
  final double totalMagnitude;  // Full accelerometer magnitude (for noise check)
  final DateTime timestamp;
  
  StrikeSpike(this.zAxisValue, this.totalMagnitude, this.timestamp);
}

/// Entry point for gesture processing isolate
/// 
/// Receives: SendPort from Root Isolate
void sensorIsolateEntry(SendPort mainSendPort) {
  // ============================================================
  // GLOBAL GESTURE MUTEX - The "Conflict Killer"
  // Prevents gesture clashing by locking all detection for 800ms after any trigger
  // ============================================================
  bool _globalLockActive = false;
  Timer? _globalLockTimer;
  
  void activateGlobalLock() {
    _globalLockActive = true;
    _globalLockTimer?.cancel();
    _globalLockTimer = Timer(Duration(milliseconds: 800), () {
      _globalLockActive = false;
    });
  }
  
  // ============================================================
  // POCKET SHIELD STATE - The "Environmental Gate"
  // Blocks gestures when phone is in pocket/bag
  // ============================================================
  bool _isCurrentlyShielded = false;
  double _currentLux = 1000.0; // Default: bright (not shielded)
  bool _isProximityNear = false; // Default: far (not shielded)
  
  /// Process environment data and determine shield state
  /// Criteria: Shield active ONLY if Light < 10 lux
  /// NOTE: Proximity sensor disabled due to false positives on many devices
  void updatePocketShield(bool proximityNear, double lux) {
    final previousState = _isCurrentlyShielded;
    _isProximityNear = proximityNear;
    _currentLux = lux;
    
    // Shield Gatekeeper Rule: Block ONLY if light level is very low
    // Proximity sensor disabled - causes false positives on many Android devices
    // Condition: Light level < 10 lux (near-total darkness = pocket/bag)
    final shouldBeShielded = lux < AppConfig.pocketShieldLightThreshold;
    
    if (shouldBeShielded != previousState) {
      _isCurrentlyShielded = shouldBeShielded;
      
      // Send shield status update to main isolate
      mainSendPort.send({
        'type': 'shield_status',
        'active': _isCurrentlyShielded,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Log state change
      GestureAuditor.logSensorSnapshot(
        gesture: 'POCKET_SHIELD',
        sensorData: {
          'proximityNear': proximityNear.toString(),
          'lux': lux.toStringAsFixed(1),
          'shieldActive': _isCurrentlyShielded.toString(),
        },
        reason: _isCurrentlyShielded 
            ? '[SHIELD ACTIVATED] Reason: Lux Low (${lux.toStringAsFixed(1)})'
            : '[SHIELD DEACTIVATED] Phone is visible',
      );
    }
  }
  
  // Initialize filters for noise reduction
  final accelFilter = LowPassFilter(alpha: AppConfig.lowPassFilterAlpha);
  final gyroFilter = LowPassFilter(alpha: AppConfig.lowPassFilterAlpha);
  
  // High-pass filter for chop gesture (removes gravity, isolates dynamic motion)
  final chopHighPassFilter = HighPassFilter(alpha: 0.8);
  
  // High-pass filter for back-tap Z-axis impulse detection (sharper alpha)
  final strikeZAxisFilter = ZAxisHighPassFilter(alpha: 0.9);

  // Track last gesture timestamps for cooldown periods
  final lastGestureTime = <String, DateTime>{};
  
  // Mutual exclusion: Track when shake occurred to block back-tap
  DateTime? lastShakeMutexTime;

  // Gesture detection helpers
  DateTime? lastShakeTime;
  
  // Surface Flip persistent state tracking
  bool _isCurrentlyFaceDown = false; // Track physical orientation
  DateTime? flipConfirmationStart; // For debouncing face-down detection
  
  // Motorola-style Chop gesture state
  DateTime? chopPositiveSpikeTime; // When we detected the first positive spike
  double chopPositiveSpikeValue = 0.0; // Value of the positive spike
  DateTime? lastTwistBlockTime; // When twist gesture blocked torch
  DateTime? lastChopTriggerTime; // For 1-second debounce after successful chop
  double chopYAxisPeakMin = 0.0; // Track minimum Y-axis value for peak-to-peak
  double chopYAxisPeakMax = 0.0; // Track maximum Y-axis value for peak-to-peak
  DateTime? chopPeakDetectionStart; // When we started tracking Y-axis peaks
  
  // Motorola-style Double Twist gesture state
  List<TwistPeak> twistPeaks = []; // Track gyro Y peaks for double twist detection
  DateTime? twistWindowStart; // Start of 1000ms detection window
  Vector3? lastAccelForTwist; // Store last accel reading for strike rejection
  
  // Back-tap (Secret Strike) detection state - Z-axis focused
  StrikeSpike? firstStrikeSpike;  // First detected spike
  List<double> recentTotalMagnitudes = []; // For movement noise rejection (1 second window)
  DateTime? lastStrikeTriggerTime; // For cooldown tracking
  DateTime? lastSpikeBounceTime; // De-bounce timer for strike echo rejection (150ms)
  DateTime? firstStrikeBlankingWindowStart; // Start of 60ms blanking window after first tap (filters vibration)
  double previousZAxisAccel = 0.0; // For jerk calculation (high-pass filter)
  
  // Store latest filtered accel for twist strike rejection
  Vector3? latestFilteredAccel;
  
  // Store latest filtered gyro for gyro-blocking strike detection
  Vector3? latestFilteredGyro;

   /// Peak-to-Peak Kinetic Chop Detection (Torch)
   /// 
   /// NEW PEAK-TO-PEAK LOGIC:
   /// - Monitor Y-axis (lengthwise motion of phone)
   /// - Signature: Y-axis swings from +20 to -20 (or vice versa) within 100ms
   /// - This "rebound" motion is the physical signature of a Motorola chop
   /// - More intuitive: Matches the actual motion of a physical chop
   /// 
   /// Advantages:
   /// - Simple and reliable: Peak-to-peak is physical reality of a chop
   /// - User-intuitive: Matches what users expect ("chop" means swing and stop)
   /// - Robust: Works even if total magnitude varies
   /// - Immune to noise on other axes
   /// 
   /// State tracking:
   /// - chopPeakDetectionStart: When we started measuring
   /// - chopYAxisPeakMin: Minimum Y value in current window
   /// - chopYAxisPeakMax: Maximum Y value in current window
   void detectShake(Vector3 accel) {
     // Peak-to-peak signature for Motorola chop
     const double chopYAxisPeakThreshold = 20.0; // ±20 m/s² swing = valid chop
     const int chopDetectionWindowMs = 100; // Must happen within 100ms
     
     // ============================================================
     // GLOBAL LOCK CHECK
     // ============================================================
     if (_globalLockActive) {
       // Log when blocked by global lock
       GestureAuditor.logBlocked(
         gesture: 'KINETIC_CHOP',
         reason: 'Global mutex lock active (800ms after last gesture)',
         blockType: 'MUTEX',
         context: {'accelMagnitude': accel.magnitude.toStringAsFixed(2)},
       );
       return;
     }
     
     // ============================================================
     // POCKET SHIELD GATE - Silent fail when in pocket
     // ============================================================
     if (_isCurrentlyShielded) {
       // Silent fail - don't even log unless very significant
       if (accel.y.abs() > 30.0) {
         GestureAuditor.logSensorSnapshot(
           gesture: 'KINETIC_CHOP',
           sensorData: {
             'yAxis': accel.y.toStringAsFixed(2),
             'proximityNear': _isProximityNear.toString(),
             'lux': _currentLux.toStringAsFixed(1),
           },
           reason: '[SHIELD] Gesture Blocked: Phone in pocket',
         );
       }
       return;
     }
     
     final now = DateTime.now();
     
     // ============================================================
     // 1-SECOND DEBOUNCE AFTER SUCCESSFUL CHOP
     // ============================================================
     if (lastChopTriggerTime != null) {
       final timeSinceChop = now.difference(lastChopTriggerTime!).inMilliseconds / 1000.0;
       if (timeSinceChop < 1.0) {
         // Still in debounce period, ignore all sensor input
         return;
       }
     }
     
     // ============================================================
     // TWIST-GESTURE REJECTION (500ms block)
     // ============================================================
     if (lastTwistBlockTime != null) {
       final timeSinceBlock = now.difference(lastTwistBlockTime!).inMilliseconds / 1000.0;
       if (timeSinceBlock < 0.5) {
         // Still blocked by twist gesture - ignore chop
         return;
       }
     }
     
     // ============================================================
     // PEAK-TO-PEAK DETECTION: Track Y-axis min/max over 100ms window
     // ============================================================
     final yAxisCurrent = accel.y;
     
     // Initialize detection window if needed
     if (chopPeakDetectionStart == null) {
       chopPeakDetectionStart = now;
       chopYAxisPeakMin = yAxisCurrent;
       chopYAxisPeakMax = yAxisCurrent;
     }
     
     final timeSinceWindowStart = now.difference(chopPeakDetectionStart!).inMilliseconds;
     
     // Update min/max values
     if (yAxisCurrent < chopYAxisPeakMin) {
       chopYAxisPeakMin = yAxisCurrent;
     }
     if (yAxisCurrent > chopYAxisPeakMax) {
       chopYAxisPeakMax = yAxisCurrent;
     }
     
     // Calculate peak-to-peak amplitude
     final peakToPeak = (chopYAxisPeakMax - chopYAxisPeakMin).abs();
     
     // Live Math logging - show progress toward threshold
     if (peakToPeak > 10.0) {
       mainSendPort.send({
         'type': 'debug_gesture_progress',
         'gesture': 'CHOP',
         'current': peakToPeak,
         'threshold': chopYAxisPeakThreshold,
         'progress': (peakToPeak / chopYAxisPeakThreshold * 100).clamp(0, 100),
         'note': 'Window: ${timeSinceWindowStart}ms, Min: ${chopYAxisPeakMin.toStringAsFixed(2)}, Max: ${chopYAxisPeakMax.toStringAsFixed(2)}',
       });
     }
     
     // ============================================================
     // CHOP VALIDATION: Peak-to-peak > 40 (±20 m/s²) within 100ms
     // ============================================================
     if (timeSinceWindowStart < chopDetectionWindowMs) {
       // Still within detection window
       if (peakToPeak >= (chopYAxisPeakThreshold * 2)) { // ±20 threshold = 40 peak-to-peak
         // VALID CHOP DETECTED!
         mainSendPort.send({
           'type': 'debug_detection',
           'gesture': 'CHOP',
           'event': 'TRIGGER',
           'value': peakToPeak,
           'message': '🔥 CHOP TRIGGERED! Peak-to-peak: ${peakToPeak.toStringAsFixed(2)} m/s² in ${timeSinceWindowStart}ms',
         });
         
         // Check cooldown
         final timeSinceLastShake = lastShakeTime != null 
             ? now.difference(lastShakeTime!).inMilliseconds / 1000.0
             : double.infinity;
         
         if (timeSinceLastShake >= AppConfig.shakeCooldownSeconds) {
           // Emit shake gesture
           mainSendPort.send({
             'type': 'gesture',
             'gesture': {
               'gestureType': 'SHAKE',
               'timestamp': now.toIso8601String(),
               'confidence': 0.95,
               'metadata': {
                 'peakToPeak': peakToPeak,
                 'yAxisMin': chopYAxisPeakMin,
                 'yAxisMax': chopYAxisPeakMax,
                 'detectionTimeMs': timeSinceWindowStart,
               },
             },
           });

           lastShakeTime = now;
           lastGestureTime['SHAKE'] = now;
           lastShakeMutexTime = now; // Enable mutex to block back-tap
           lastChopTriggerTime = now; // Start 1-second debounce
           
           // ACTIVATE GLOBAL LOCK (800ms)
           activateGlobalLock();
           
           // Reset chop state
           chopPeakDetectionStart = null;
           chopYAxisPeakMin = 0.0;
           chopYAxisPeakMax = 0.0;
           
           // Log gesture trigger with auditor
           GestureAuditor.logThresholdCrossing(
             gesture: 'KINETIC_CHOP',
             data: 'Peak-to-Peak: ${peakToPeak.toStringAsFixed(2)} m/s², Window: ${timeSinceWindowStart}ms',
             status: 'TRIGGERED',
             uiSynced: true,
             additionalInfo: 'Peak-to-peak chop detected - Torch toggled',
           );
           
           // Log mutual exclusion
           GestureAuditor.logMutualExclusion(
             primaryGesture: 'KINETIC_CHOP',
             blockedGesture: 'SECRET_STRIKE',
             exclusionDuration: AppConfig.shakeMutexDuration,
           );
         } else {
           // Blocked by cooldown
           chopPeakDetectionStart = null;
           chopYAxisPeakMin = 0.0;
           chopYAxisPeakMax = 0.0;
           
           GestureAuditor.logCooldown(
             gesture: 'KINETIC_CHOP',
             remainingSeconds: AppConfig.shakeCooldownSeconds - timeSinceLastShake,
             blockedReason: 'Chop signature detected but in cooldown period',
           );
         }
       }
     } else {
       // Window expired - reset and start fresh
       chopPeakDetectionStart = null;
       chopYAxisPeakMin = 0.0;
       chopYAxisPeakMax = 0.0;
     }
   }

  /// Motorola-Style Double Twist Detection (Camera)
  /// 
  /// Rotational Signature Detection:
  /// - Relies strictly on Gyroscope Y-axis (longitudinal rotation)
  /// - Detects rapid positive→negative OR negative→positive transitions
  /// - Requires 4 distinct peaks (2 full back-and-forth twists) within 1000ms
  /// 
  /// Strike Rejection:
  /// - If Accelerometer X-axis shows sharp jolt without corresponding high Gyro Y
  /// - Treat as "Strike" and explicitly reject
  /// 
  /// Threshold: 6.0 rad/s (configurable via AppConfig.twistThreshold)
  void detectTwist(Vector3 gyro, Vector3? accel) {
    // ============================================================
    // GLOBAL LOCK CHECK
    // ============================================================
    if (_globalLockActive) {
      GestureAuditor.logBlocked(
        gesture: 'DOUBLE_TWIST',
        reason: 'Global mutex lock active (800ms after last gesture)',
        blockType: 'MUTEX',
        context: {'gyroY': gyro.y.toStringAsFixed(2)},
      );
      return;
    }
    
    // ============================================================
    // POCKET SHIELD GATE - Silent fail when in pocket
    // ============================================================
    if (_isCurrentlyShielded) {
      final gyroYAbs = gyro.y.abs();
      
      // Only log if this would have been a significant twist
      if (gyroYAbs > AppConfig.twistThreshold) {
        GestureAuditor.logSensorSnapshot(
          gesture: 'DOUBLE_TWIST',
          sensorData: {
            'gyroY': gyroYAbs.toStringAsFixed(2),
            'proximityNear': _isProximityNear.toString(),
            'lux': _currentLux.toStringAsFixed(1),
          },
          reason: '[SHIELD] Gesture Blocked: ${_isProximityNear ? "Proximity Near" : "Lux Low"}. Battery Saved.',
        );
      }
      return;
    }
    
    final now = DateTime.now();
    final gyroY = gyro.y; // Keep sign for direction detection
    final gyroYAbs = gyroY.abs();
    
    // Store accel for strike rejection
    lastAccelForTwist = accel;
    
    // Live Math logging - show progress toward threshold
    if (gyroYAbs > 3.0) {
      // Send debug message through SendPort (print() doesn't work in isolates!)
      mainSendPort.send({
        'type': 'debug_gesture_progress',
        'gesture': 'TWIST',
        'current': gyroYAbs,
        'threshold': AppConfig.twistThreshold,
        'progress': (gyroYAbs / AppConfig.twistThreshold * 100).clamp(0, 100),
        'note': 'Peaks: ${twistPeaks.length}/4 | Direction: ${gyroY > 0 ? "CW" : "CCW"}',
      });
      
      GestureAuditor.logLiveMath(
        gesture: 'DOUBLE_TWIST',
        currentValue: gyroYAbs,
        threshold: AppConfig.twistThreshold,
        rawAxes: {'x': gyro.x, 'y': gyro.y, 'z': gyro.z},
        progressNote: 'Peaks: ${twistPeaks.length}/4 detected',
        mathNote: 'Direction: ${gyroY > 0 ? "POSITIVE (CW)" : "NEGATIVE (CCW)"}',
      );
    }
    
    // ============================================================
    // STRIKE REJECTION
    // Sharp accelerometer X-axis jolt without high gyro Y = Strike, not Twist
    // ============================================================
    if (lastAccelForTwist != null) {
      final accelX = lastAccelForTwist!.x.abs();
      
      // If high X-axis impact but low gyro Y, reject as strike
      if (accelX > 15.0 && gyroYAbs < 3.0) {
        // This is a strike/tap, not a twist - explicitly reject
        if (twistPeaks.isNotEmpty) {
          GestureAuditor.logSensorSnapshot(
            gesture: 'DOUBLE_TWIST',
            sensorData: {
              'accelX': accelX.toStringAsFixed(2),
              'gyroY': gyroYAbs.toStringAsFixed(2),
            },
            reason: '[REJECTED] Strike detected - high X-axis impact without rotation',
          );
          
          // Reset twist state
          twistPeaks.clear();
          twistWindowStart = null;
        }
        return;
      }
    }
    
    // ============================================================
    // TORCH BLOCKING (maintains existing behavior)
    // Block torch trigger for 500ms when gyro Y exceeds 4.0 rad/s
    // ============================================================
    if (gyroYAbs > 4.0) {
      lastTwistBlockTime = now;
    }
    
    // ============================================================
    // DOUBLE TWIST DETECTION
    // Looking for 4 peaks (2 full twists) within 1000ms
    // ============================================================
    
    // Check if we're above the twist threshold
    if (gyroYAbs > AppConfig.twistThreshold) {
      // Determine if this is a positive or negative peak
      final isPositivePeak = gyroY > 0;
      
      // Start new detection window if needed
      if (twistWindowStart == null) {
        twistWindowStart = now;
        twistPeaks.add(TwistPeak(gyroYAbs, now, isPositivePeak));
        
        GestureAuditor.logSensorSnapshot(
          gesture: 'DOUBLE_TWIST',
          sensorData: {
            'gyroY': gyroY.toStringAsFixed(2),
            'peakCount': '1/4',
            'direction': isPositivePeak ? 'POSITIVE' : 'NEGATIVE',
          },
          reason: 'First twist peak detected - window started',
        );
        return;
      }
      
      // Check if we're still within the 1000ms window
      final timeSinceWindowStart = now.difference(twistWindowStart!).inMilliseconds;
      
      if (timeSinceWindowStart <= 1000) {
        // Check if this peak has a different direction than the last one
        if (twistPeaks.isNotEmpty) {
          final lastPeak = twistPeaks.last;
          
          // Only count if direction changed (alternating peaks)
          if (lastPeak.isPositive != isPositivePeak) {
            // Ensure we don't count duplicate peaks too close together
            final timeSinceLastPeak = now.difference(lastPeak.timestamp).inMilliseconds;
            
            if (timeSinceLastPeak > 50) { // Minimum 50ms between peaks
              twistPeaks.add(TwistPeak(gyroYAbs, now, isPositivePeak));
              
              GestureAuditor.logSensorSnapshot(
                gesture: 'DOUBLE_TWIST',
                sensorData: {
                  'gyroY': gyroY.toStringAsFixed(2),
                  'peakCount': '${twistPeaks.length}/4',
                  'direction': isPositivePeak ? 'POSITIVE' : 'NEGATIVE',
                  'timeSinceLastPeak': '${timeSinceLastPeak}ms',
                },
                reason: 'Alternating peak detected',
              );
              
              // Check if we have 4 peaks (2 full twists)
              if (twistPeaks.length >= 4) {
                // Check cooldown
                final timeSinceLastTwist = lastGestureTime['TWIST'] != null
                    ? now.difference(lastGestureTime['TWIST']!).inMilliseconds / 1000.0
                    : double.infinity;
                
                if (timeSinceLastTwist >= AppConfig.twistCooldownSeconds) {
                  // Emit twist gesture
                  mainSendPort.send({
                    'type': 'gesture',
                    'gesture': {
                      'gestureType': 'TWIST',
                      'timestamp': now.toIso8601String(),
                      'confidence': 0.92,
                      'metadata': {
                        'peakCount': twistPeaks.length,
                        'totalDuration': timeSinceWindowStart,
                        'avgPeakValue': twistPeaks.map((p) => p.value).reduce((a, b) => a + b) / twistPeaks.length,
                      },
                    },
                  });

                  lastGestureTime['TWIST'] = now;
                  
                  // ACTIVATE GLOBAL LOCK (800ms)
                  activateGlobalLock();
                  
                  // Log gesture trigger
                  GestureAuditor.logThresholdCrossing(
                    gesture: 'DOUBLE_TWIST',
                    data: 'Peaks: ${twistPeaks.length}, Duration: ${timeSinceWindowStart}ms',
                    status: 'TRIGGERED',
                    uiSynced: true,
                    additionalInfo: 'Motorola-style double twist detected - Camera launching',
                  );
                  
                  // Reset state
                  twistPeaks.clear();
                  twistWindowStart = null;
                } else {
                  // Blocked by cooldown
                  GestureAuditor.logCooldown(
                    gesture: 'DOUBLE_TWIST',
                    remainingSeconds: AppConfig.twistCooldownSeconds - timeSinceLastTwist,
                    blockedReason: 'Four peaks detected but in cooldown period',
                  );
                  
                  // Reset state
                  twistPeaks.clear();
                  twistWindowStart = null;
                }
              }
            }
          }
        }
      } else {
        // Window expired without completing double twist
        if (twistPeaks.length >= 2) {
          GestureAuditor.logSensorSnapshot(
            gesture: 'DOUBLE_TWIST',
            sensorData: {
              'peakCount': twistPeaks.length.toString(),
              'timeSinceStart': '${timeSinceWindowStart}ms',
            },
            reason: '[REJECTED] Window expired - incomplete double twist (needed 4 peaks, got ${twistPeaks.length})',
          );
        }
        
        // Reset and start new window with current peak
        twistWindowStart = now;
        twistPeaks.clear();
        twistPeaks.add(TwistPeak(gyroYAbs, now, isPositivePeak));
      }
    } else {
      // Below threshold - check if window should expire
      if (twistWindowStart != null) {
        final timeSinceWindowStart = now.difference(twistWindowStart!).inMilliseconds;
        
        // If window expired and we didn't complete the gesture, reset
        if (timeSinceWindowStart > 1000) {
          if (twistPeaks.length >= 2) {
            GestureAuditor.logSensorSnapshot(
              gesture: 'DOUBLE_TWIST',
              sensorData: {
                'peakCount': twistPeaks.length.toString(),
              },
              reason: '[REJECTED] Gesture incomplete - returned to rest',
            );
          }
          
          twistPeaks.clear();
          twistWindowStart = null;
        }
      }
    }
  }

  /// Secret Strike Detection (Back-Tap) - High-Precision Z-Axis Focused
  /// 
  /// Physics of the "Strike":
  /// - Back-tap is a high-frequency impulse, unlike low-frequency shake
  /// - Focuses primarily on Z-axis (axis through back of phone)
  /// - Uses sharp High-Pass Filter to remove gravity and slow movements
  /// 
  /// Detection Criteria:
  /// - Spike Magnitude: Single tap must exceed 16.0 m/s² in under 40ms
  /// - Double-Tap Window: Two spikes within 200-450ms of each other
  /// - Movement Noise Rejection: Block if total magnitude is high (walking/shaking)
  /// 
  /// Conflict Resolution:
  /// - Honors 800ms Global Lock (blocks if Chop/Twist just happened)
  /// - Honors Pocket Shield (silent discard when in pocket)
  /// - Mutual exclusion with Shake (1.5s mutex after shake)
  void detectBackTap(Vector3 accel, Vector3? gyro) {
    // ============================================================
    // GLOBAL LOCK CHECK - Honor 800ms mutex after any gesture
    // ============================================================
    if (_globalLockActive) {
      GestureAuditor.logBlocked(
        gesture: 'SECRET_STRIKE',
        reason: 'Global mutex lock active (800ms after last gesture)',
        blockType: 'MUTEX',
        context: {'zAxis': accel.z.toStringAsFixed(2)},
      );
      return;
    }
    
    // ============================================================
    // POCKET SHIELD GATE - Silent fail when in pocket
     // ============================================================
     if (_isCurrentlyShielded) {
       final zAxisJerk = (accel.z - previousZAxisAccel).abs(); // Jerk calculation
       
       // Only log if this would have been a significant tap
      if (zAxisJerk > 16.0) {
        GestureAuditor.logSensorSnapshot(
          gesture: 'SECRET_STRIKE',
          sensorData: {
            'zAxisJerk': zAxisJerk.toStringAsFixed(2),
            'proximityNear': _isProximityNear.toString(),
            'lux': _currentLux.toStringAsFixed(1),
          },
          reason: '[SHIELD] Gesture Blocked: ${_isProximityNear ? "Proximity Near" : "Lux Low"}. Battery Saved.',
        );
      }
      return;
    }
    
    final now = DateTime.now();
    
    // ============================================================
    // SHAKE MUTEX CHECK - Block for 1.5s after shake/chop
    // ============================================================
    if (lastShakeMutexTime != null) {
      final timeSinceMutex = now.difference(lastShakeMutexTime!).inMilliseconds / 1000.0;
      if (timeSinceMutex < AppConfig.shakeMutexDuration) {
        // Still in mutex period, don't process back-tap
        GestureAuditor.logBlocked(
          gesture: 'SECRET_STRIKE',
          reason: 'Blocked by shake/chop mutex (${AppConfig.shakeMutexDuration}s exclusion)',
          blockType: 'MUTEX',
          context: {'timeSinceMutex': '${(timeSinceMutex * 1000).toStringAsFixed(0)}ms'},
        );
        return;
      }
    }
    
    // ============================================================
    // GYRO-BLOCKING: If phone is rotating (Twist), block Strike
    // Constraint: If gyro.magnitude > 1.5 rad/s, don't process Strike
    // Reason: Any acceleration spike during rotation is result of the rotation,
    //         not an actual tap. This prevents Twist from triggering Assistant.
    // ============================================================
    if (gyro != null) {
      final gyroMagnitude = gyro.magnitude;
      if (gyroMagnitude > 1.5) {
        // Phone is rotating - any acceleration is just rotation artifact
        GestureAuditor.logBlocked(
          gesture: 'SECRET_STRIKE',
          reason: 'Gyro-blocking active: Phone is rotating (${gyroMagnitude.toStringAsFixed(2)} rad/s > 1.5)',
          blockType: 'ROTATION',
          context: {'gyroMagnitude': gyroMagnitude.toStringAsFixed(2)},
        );
        return;
      }
    }
    
    // ============================================================
    // HIGH-PASS FILTER FOR STRIKE: Calculate Jerk (delta Z-axis)
    // Logic: A tap is a high-frequency shock (click), twist is low-frequency (swing)
    // Jerk = Current Z-axis - Previous Z-axis (detects rapid changes)
    // ============================================================
    final zAxisJerk = (accel.z - previousZAxisAccel).abs(); // High-pass: change detection
    previousZAxisAccel = accel.z; // Store for next iteration
    
    final totalMagnitude = accel.magnitude;
    
    // Configurable threshold: Jerk > 12.0 = tap detected
    final double strikeThreshold = 12.0;
    
    // Live Math logging - show progress toward threshold
    if (zAxisJerk > 6.0) {
      // Send debug message through SendPort (print() doesn't work in isolates!)
      mainSendPort.send({
        'type': 'debug_gesture_progress',
        'gesture': 'STRIKE',
        'current': zAxisJerk,
        'threshold': strikeThreshold,
        'progress': (zAxisJerk / strikeThreshold * 100).clamp(0, 100),
        'note': firstStrikeSpike != null ? 'Waiting for 2nd spike (100-450ms)' : 'Waiting for 1st spike',
      });
      
      GestureAuditor.logLiveMath(
        gesture: 'SECRET_STRIKE',
        currentValue: zAxisJerk,
        threshold: strikeThreshold,
        rawAxes: {'x': accel.x, 'y': accel.y, 'z': accel.z},
        progressNote: firstStrikeSpike != null ? 'Waiting for 2nd spike (100-450ms window)' : 'Waiting for 1st spike',
        mathNote: 'Jerk (Z-delta): ${zAxisJerk.toStringAsFixed(2)}, Previous Z: ${previousZAxisAccel.toStringAsFixed(2)}, Total Magnitude: ${totalMagnitude.toStringAsFixed(2)}',
      );
    }
    
     // ============================================================
     // MOVEMENT NOISE REJECTION - Track X/Y magnitude history (IGNORE Z for stability)
     // Phone must be relatively stable (X/Y axes) for strike to be valid
     // Z-axis is allowed to spike wildly - that's what a tap IS!
     // ============================================================
     final xyMagnitude = sqrt(accel.x * accel.x + accel.y * accel.y); // X/Y only
     recentTotalMagnitudes.add(xyMagnitude);
     if (recentTotalMagnitudes.length > 50) { // 50 samples at ~100Hz = 0.5 second
       recentTotalMagnitudes.removeAt(0);
     }
     
     // Calculate average X/Y magnitude over last 0.5 second
     final avgXYMagnitude = recentTotalMagnitudes.isEmpty 
         ? 9.8 
         : recentTotalMagnitudes.reduce((a, b) => a + b) / recentTotalMagnitudes.length;
     
     // Stability threshold: 35.0 m/s² on X/Y axes only
     // Only reject if OBVIOUS walking/shaking on X/Y detected
     // Z-axis spikes are EXPECTED and DESIRED - that's the actual tap!
     final isStable = avgXYMagnitude < 35.0;
      
     // ============================================================
     // SPIKE DETECTION - Z-axis jerk > strikeThreshold m/s²
     // WITH STRIKE ECHO DE-BOUNCE (150ms)
     // ============================================================
     if (zAxisJerk > strikeThreshold) {
      // ============================================================
      // STRIKE ECHO DE-BOUNCE - Prevent vibration echoes from being detected as second spike
      // After detecting a spike, ignore all spikes for 150ms
      // This filters out the 5-10ms vibration echoes but allows 200-450ms second tap
      // ============================================================
      if (lastSpikeBounceTime != null) {
        final timeSinceLastSpike = now.difference(lastSpikeBounceTime!).inMilliseconds;
        if (timeSinceLastSpike < 150) {
          // Within de-bounce window - this is likely an echo, silently ignore
          return; // Don't even log - this is the "vibration tail" of previous spike
        }
      }
      
      // Update the de-bounce timer for next spike
      lastSpikeBounceTime = now;
      
      // Detected a potential spike - send via SendPort
      mainSendPort.send({
        'type': 'debug_detection',
        'gesture': 'STRIKE',
        'event': 'SPIKE_DETECTED',
        'value': zAxisJerk,
        'message': 'Spike detected! Z=${zAxisJerk.toStringAsFixed(2)} > $strikeThreshold | Stable: $isStable',
      });
      
       if (!isStable) {
         // Phone is moving too much - reject
         mainSendPort.send({
           'type': 'debug_detection',
           'gesture': 'STRIKE',
           'event': 'REJECTED_UNSTABLE',
           'value': avgXYMagnitude,
           'message': '⚠️ REJECTED: Phone not stable (avg: ${avgXYMagnitude.toStringAsFixed(2)} m/s² > 35.0)',
         });
         GestureAuditor.logSensorSnapshot(
           gesture: 'SECRET_STRIKE',
           sensorData: {
             'zAxisJerk': zAxisJerk.toStringAsFixed(2),
             'avgXYMagnitude': avgXYMagnitude.toStringAsFixed(2),
             'totalMagnitude': totalMagnitude.toStringAsFixed(2),
           },
           reason: '[REJECTED] Movement noise detected - phone not stable (avg: ${avgXYMagnitude.toStringAsFixed(2)} m/s²)',
         );
        // Reset spike tracking
        firstStrikeSpike = null;
        return;
      }
      
      // ============================================================
      // DOUBLE-TAP WINDOW LOGIC (200-450ms between spikes)
       // ============================================================
       if (firstStrikeSpike == null) {
         // This is the FIRST spike - record it
         firstStrikeSpike = StrikeSpike(zAxisJerk, totalMagnitude, now);
         firstStrikeBlankingWindowStart = now; // Start 60ms blanking window (filter case vibration)
         
         mainSendPort.send({
           'type': 'debug_detection',
           'gesture': 'STRIKE',
           'event': 'FIRST_SPIKE',
           'value': zAxisJerk,
           'message': 'First spike recorded (${zAxisJerk.toStringAsFixed(2)} m/s²) - blanking 60ms, then waiting for 2nd (100-450ms window)',
         });
         GestureAuditor.logSensorSnapshot(
           gesture: 'SECRET_STRIKE',
           sensorData: {
             'zAxisJerk': zAxisJerk.toStringAsFixed(2),
             'spike': '1/2',
           },
           reason: 'First strike spike detected - 60ms blanking window active, then waiting for second spike (100-450ms window)',
         );
       } else {
         // Check if we're still in the 60ms blanking window (mechanical vibration filter)
         final timeSinceFirstSpike = now.difference(firstStrikeBlankingWindowStart!).inMilliseconds;
         if (timeSinceFirstSpike < 60) {
           // Still in blanking window - ignore this spike (phone case vibration)
           mainSendPort.send({
             'type': 'debug_detection',
             'gesture': 'STRIKE',
             'event': 'BLANKING_WINDOW',
             'value': timeSinceFirstSpike.toDouble(),
             'message': 'In blanking window (${timeSinceFirstSpike}ms < 60ms) - filtering mechanical vibration',
           });
           return; // Silently ignore - this is vibration artifact
         }
         
         // This is a potential SECOND spike - check timing (100-450ms window)
         final timeBetweenSpikes = now.difference(firstStrikeSpike!.timestamp).inMilliseconds;
         
         mainSendPort.send({
           'type': 'debug_detection',
           'gesture': 'STRIKE',
           'event': 'SECOND_SPIKE_CANDIDATE',
           'value': zAxisJerk,
           'message': 'Second spike candidate - timing: ${timeBetweenSpikes}ms (need 100-450ms)',
        });
        
         if (timeBetweenSpikes < 100) {
           // Too fast - likely part of the same impact, ignore
           mainSendPort.send({
             'type': 'debug_detection',
             'gesture': 'STRIKE',
             'event': 'REJECTED_TOO_FAST',
             'value': timeBetweenSpikes.toDouble(),
             'message': '⚠️ REJECTED: Too fast (${timeBetweenSpikes}ms < 100ms) - same impact or vibration artifact',
           });
           GestureAuditor.logSensorSnapshot(
             gesture: 'SECRET_STRIKE',
             sensorData: {
               'zAxisJerk': zAxisJerk.toStringAsFixed(2),
               'timeBetweenSpikes': '${timeBetweenSpikes}ms',
             },
             reason: '[REJECTED] Second spike too fast (<100ms) - likely same impact',
           );
           // Don't reset - wait for actual second spike
         } else if (timeBetweenSpikes <= 450) {
           // VALID DOUBLE-TAP: Two spikes within 100-450ms window!
           mainSendPort.send({
             'type': 'debug_detection',
             'gesture': 'STRIKE',
             'event': 'VALID_DOUBLE_TAP',
             'value': timeBetweenSpikes.toDouble(),
             'message': '🔥 VALID DOUBLE-TAP! Timing: ${timeBetweenSpikes}ms (blanking + 100-450ms) - Triggering SECRET STRIKE!',
           });
          
          // Check cooldown
          final timeSinceLastStrike = lastGestureTime['BACK_TAP'] != null
              ? now.difference(lastGestureTime['BACK_TAP']!).inMilliseconds / 1000.0
              : double.infinity;
          
          if (timeSinceLastStrike >= AppConfig.backTapCooldownSeconds) {
            // SUCCESS - Emit back-tap gesture with haptic request
            mainSendPort.send({
              'type': 'debug_detection',
              'gesture': 'STRIKE',
              'event': 'TRIGGER',
              'value': zAxisJerk,
              'message': '✅ SUCCESS! Sending BACK_TAP gesture to main isolate!',
            });
             mainSendPort.send({
               'type': 'gesture',
               'gesture': {
                 'gestureType': 'BACK_TAP',
                 'timestamp': now.toIso8601String(),
                 'confidence': 0.95,
                 'metadata': {
                   'firstSpikeZ': firstStrikeSpike!.zAxisValue,
                   'secondSpikeZ': zAxisJerk,
                   'timeBetweenSpikesMs': timeBetweenSpikes,
                   'avgXYMagnitude': avgXYMagnitude,
                   'isStable': true,
                   'requestHeavyHaptic': true, // Signal for heavy impact feedback
                 },
               },
             });
            
            lastGestureTime['BACK_TAP'] = now;
            lastStrikeTriggerTime = now;
            
            // ACTIVATE GLOBAL LOCK (800ms)
            activateGlobalLock();
            
            // Log gesture trigger
            GestureAuditor.logThresholdCrossing(
              gesture: 'SECRET_STRIKE',
              data: 'Z-Spikes: ${firstStrikeSpike!.zAxisValue.toStringAsFixed(1)} → ${zAxisJerk.toStringAsFixed(1)} m/s², Window: ${timeBetweenSpikes}ms',
              status: 'TRIGGERED',
              uiSynced: true,
              additionalInfo: 'High-precision double-tap detected on back of phone',
            );
            
            // Reset spike tracking
            firstStrikeSpike = null;
          } else {
            // Blocked by cooldown
            GestureAuditor.logCooldown(
              gesture: 'SECRET_STRIKE',
              remainingSeconds: AppConfig.backTapCooldownSeconds - timeSinceLastStrike,
              blockedReason: 'Valid double-tap detected but in cooldown period',
            );
            firstStrikeSpike = null;
          }
        } else {
          // Window expired (>450ms) - this spike becomes the new first spike
          GestureAuditor.logSensorSnapshot(
            gesture: 'SECRET_STRIKE',
            sensorData: {
              'timeBetweenSpikes': '${timeBetweenSpikes}ms',
            },
            reason: '[REJECTED] Window expired (>450ms) - resetting to new first spike',
          );
          firstStrikeSpike = StrikeSpike(zAxisJerk, totalMagnitude, now);
        }
      }
    } else {
      // Below spike threshold - check if first spike window expired
      if (firstStrikeSpike != null) {
        final timeSinceFirstSpike = now.difference(firstStrikeSpike!.timestamp).inMilliseconds;
        
        if (timeSinceFirstSpike > 500) { // Grace period slightly longer than window
          // Window expired without second spike
          GestureAuditor.logSensorSnapshot(
            gesture: 'SECRET_STRIKE',
            sensorData: {
              'timeSinceFirstSpike': '${timeSinceFirstSpike}ms',
            },
            reason: '[EXPIRED] No second spike within window - resetting',
          );
          firstStrikeSpike = null;
        }
      }
    }
  }

  /// Surface Flip Detection (DND) - EXPLICIT STATE LOGIC
  /// Face Down (Z < -9.0): Explicitly turn DND ON
  /// Face Up (Z > -2.0): Explicitly turn DND OFF
  /// No toggle logic - explicit state transitions only
  void detectFlip(Vector3 accel) {
    // ============================================================
    // GLOBAL LOCK CHECK
    // ============================================================
    if (_globalLockActive) {
      GestureAuditor.logBlocked(
        gesture: 'SURFACE_FLIP',
        reason: 'Global mutex lock active (800ms after last gesture)',
        blockType: 'MUTEX',
        context: {'zAxis': accel.z.toStringAsFixed(2)},
      );
      return;
    }
    
    final now = DateTime.now();
    final zAxis = accel.z;
    
    // Threshold definitions
    const double faceDownThreshold = -9.0; // Phone flat on screen
    const double faceUpThreshold = -2.0;   // Phone held or face up
    
    // Live Math logging for flip detection
    if (zAxis < -7.0 || (zAxis > faceUpThreshold && _isCurrentlyFaceDown)) {
      GestureAuditor.logLiveMath(
        gesture: 'SURFACE_FLIP',
        currentValue: zAxis.abs(),
        threshold: 9.0, // faceDownThreshold absolute
        rawAxes: {'x': accel.x, 'y': accel.y, 'z': accel.z},
        progressNote: _isCurrentlyFaceDown ? 'Currently FACE DOWN' : 'Currently FACE UP',
        mathNote: 'Z-Axis: ${zAxis.toStringAsFixed(2)} (threshold: <${faceDownThreshold} for DOWN, >${faceUpThreshold} for UP)',
      );
    }
    
    // ============================================================
    // FACE DOWN DETECTION → DND ON
    // ============================================================
    if (zAxis < faceDownThreshold && !_isCurrentlyFaceDown) {
      // Phone just went face down
      if (flipConfirmationStart == null) {
        // Start debounce timer
        flipConfirmationStart = now;
        
        GestureAuditor.logDebounce(
          gesture: 'SURFACE_FLIP (FACE DOWN)',
          holdDuration: 0.0,
          requiredDuration: 0.5, // 500ms debounce
          confirmed: false,
        );
      } else {
        // Check if debounce period elapsed
        final holdDuration = now.difference(flipConfirmationStart!).inMilliseconds / 1000.0;
        
        if (holdDuration >= 0.5) {
          // Debounce confirmed - set persistent state and emit FLIP_ON
          _isCurrentlyFaceDown = true;
          flipConfirmationStart = null;
          
          // Check cooldown
          final timeSinceLastFlip = lastGestureTime['FLIP'] != null
              ? now.difference(lastGestureTime['FLIP']!).inMilliseconds / 1000.0
              : double.infinity;
          
          if (timeSinceLastFlip >= 2.0) {
            // Emit FLIP_ON gesture
            mainSendPort.send({
              'type': 'gesture',
              'gesture': {
                'gestureType': 'FLIP_ON', // Explicit ON command
                'timestamp': now.toIso8601String(),
                'confidence': 0.95,
                'metadata': {
                  'zAxis': zAxis,
                  'holdDuration': holdDuration,
                  'action': 'ENABLE_DND',
                },
              },
            });
            
            lastGestureTime['FLIP'] = now;
            
            // ACTIVATE GLOBAL LOCK (800ms)
            activateGlobalLock();
            
            GestureAuditor.logThresholdCrossing(
              gesture: 'SURFACE_FLIP',
              data: 'Z-Axis: ${zAxis.toStringAsFixed(2)} m/s² (FACE DOWN)',
              status: 'TRIGGERED → DND ON',
              uiSynced: true,
              additionalInfo: 'Phone placed face down, enabling DND mode',
            );
            
            GestureAuditor.logDebounce(
              gesture: 'SURFACE_FLIP (FACE DOWN)',
              holdDuration: holdDuration,
              requiredDuration: 0.5,
              confirmed: true,
            );
          } else {
            // Blocked by cooldown
            GestureAuditor.logCooldown(
              gesture: 'SURFACE_FLIP',
              remainingSeconds: 2.0 - timeSinceLastFlip,
              blockedReason: 'Face down detected but in cooldown period',
            );
          }
        }
      }
    } 
    // If still face down but already in face-down state, do nothing
    else if (zAxis < faceDownThreshold && _isCurrentlyFaceDown) {
      // Already face down, maintain state (do nothing)
    }
    // If moved out of face-down zone but still not face-up, reset debounce timer
    else if (zAxis >= faceDownThreshold && zAxis <= faceUpThreshold) {
      // In transition zone - reset debounce
      flipConfirmationStart = null;
    }
    
    // ============================================================
    // FACE UP DETECTION → DND OFF
    // ============================================================
    else if (zAxis > faceUpThreshold && _isCurrentlyFaceDown) {
      // Phone picked up (face up) - explicitly turn DND OFF
      _isCurrentlyFaceDown = false;
      flipConfirmationStart = null;
      
      // Check cooldown
      final timeSinceLastFlip = lastGestureTime['FLIP'] != null
          ? now.difference(lastGestureTime['FLIP']!).inMilliseconds / 1000.0
          : double.infinity;
      
      if (timeSinceLastFlip >= 2.0) {
        // Emit FLIP_OFF gesture
        mainSendPort.send({
          'type': 'gesture',
          'gesture': {
            'gestureType': 'FLIP_OFF', // Explicit OFF command
            'timestamp': now.toIso8601String(),
            'confidence': 0.95,
            'metadata': {
              'zAxis': zAxis,
              'action': 'DISABLE_DND',
            },
          },
        });
        
        lastGestureTime['FLIP'] = now;
        
        // ACTIVATE GLOBAL LOCK (800ms)
        activateGlobalLock();
        
        GestureAuditor.logThresholdCrossing(
          gesture: 'SURFACE_FLIP',
          data: 'Z-Axis: ${zAxis.toStringAsFixed(2)} m/s² (FACE UP)',
          status: 'TRIGGERED → DND OFF',
          uiSynced: true,
          additionalInfo: 'Phone picked up, disabling DND mode',
        );
        
        GestureAuditor.logSensorSnapshot(
          gesture: 'SURFACE_FLIP',
          sensorData: {
            'zAxis': zAxis.toStringAsFixed(2),
            'previousState': 'FACE_DOWN',
            'newState': 'FACE_UP',
          },
          reason: 'Phone orientation changed to face-up',
        );
      } else {
        // Blocked by cooldown
        GestureAuditor.logCooldown(
          gesture: 'SURFACE_FLIP',
          remainingSeconds: 2.0 - timeSinceLastFlip,
          blockedReason: 'Face up detected but in cooldown period',
        );
      }
    }
  }

  // ============================================================
  // DEBUG HEARTBEAT COUNTERS
  // Tracks sensor samples to verify isolate is receiving data
  // ============================================================
  int _accelSampleCount = 0;
  int _gyroSampleCount = 0;
  double _maxAccelMagnitude = 0.0;
  double _maxGyroY = 0.0;
  DateTime _lastHeartbeat = DateTime.now();

  // Setup ReceivePort to listen for sensor data from Root Isolate
  final receivePort = ReceivePort();
  mainSendPort.send({'type': 'ready', 'sendPort': receivePort.sendPort});

  receivePort.listen((message) {
    if (message is String && message == 'stop') {
      receivePort.close();
      return;
    }

    if (message is! Map) return;

    final type = message['type'] as String?;
    final sensor = message['sensor'] as String?;

    // Handle environment data for pocket shield
    if (type == 'environment_data') {
      final proximityNear = message['proximity_near'] as bool? ?? false;
      final lux = message['lux'] as double? ?? 1000.0;
      updatePocketShield(proximityNear, lux);
      return;
    }

    if (type == 'sensor_data' && sensor != null) {
      final x = message['x'] as double?;
      final y = message['y'] as double?;
      final z = message['z'] as double?;

      if (x != null && y != null && z != null) {
        final rawVector = Vector3(x, y, z);

        if (sensor == 'accel') {
          _accelSampleCount++;
          final filteredAccel = rawVector.applyFilter(accelFilter);
          latestFilteredAccel = filteredAccel; // Store for twist strike rejection
          
          // Track max magnitude for debugging
          if (filteredAccel.magnitude > _maxAccelMagnitude) {
            _maxAccelMagnitude = filteredAccel.magnitude;
          }
          
           detectShake(filteredAccel);
           detectBackTap(filteredAccel, latestFilteredGyro);
           detectFlip(filteredAccel);
          
          // ============================================================
          // HEARTBEAT: Send debug info every 250 accel samples (~5 seconds at 50Hz)
          // Reduced frequency to free up CPU cycles and reduce log spam
          // ============================================================
          if (_accelSampleCount % 250 == 0) {
            final now = DateTime.now();
            final elapsed = now.difference(_lastHeartbeat).inMilliseconds;
            _lastHeartbeat = now;
            
            mainSendPort.send({
              'type': 'debug_heartbeat',
              'accel_samples': _accelSampleCount,
              'gyro_samples': _gyroSampleCount,
              'max_accel_magnitude': _maxAccelMagnitude,
              'max_gyro_y': _maxGyroY,
              'elapsed_ms': elapsed,
              'shield_active': _isCurrentlyShielded,
              'proximity_near': _isProximityNear,
              'lux': _currentLux,
              'global_lock': _globalLockActive,
              'timestamp': now.toIso8601String(),
            });
            
            // Reset max trackers for next window
            _maxAccelMagnitude = 0.0;
            _maxGyroY = 0.0;
          }
        } else if (sensor == 'gyro') {
          _gyroSampleCount++;
          final filteredGyro = rawVector.applyFilter(gyroFilter);
          latestFilteredGyro = filteredGyro; // Store for gyro-blocking strike detection
          
          // Track max gyro Y for twist debugging
          if (filteredGyro.y.abs() > _maxGyroY) {
            _maxGyroY = filteredGyro.y.abs();
          }
          
          detectTwist(filteredGyro, latestFilteredAccel);
        }
      }
    }
  });
}
