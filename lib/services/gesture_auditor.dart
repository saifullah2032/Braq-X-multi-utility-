import 'dart:developer' as developer;
import '../models/gesture_event.dart';

/// ============================================================
/// BARQ X GESTURE AUDITOR - "Live Math" Logging Engine
/// 
/// Provides comprehensive, high-fidelity logging for gesture debugging.
/// Every sensor event is "mathematically traceable" in the console.
/// 
/// LOG FORMAT LEGEND:
/// 🔥 [TRIGGER] - Successful gesture triggered
/// ⚠️  [WARNING] - Permission issues or warnings
/// 🚫 [BLOCK]   - Mutex/Shield/Cooldown blocks
/// 📊 [DATA]    - Raw math/threshold progress
/// 🛡️  [SHIELD]  - Pocket shield related
/// ⏱️  [COOLDOWN] - Cooldown period active
/// ============================================================
class GestureAuditor {
  static const String _tag = 'BARQ_GESTURE';
  
  // ============================================================
  // LIVE MATH LOGGING - Table-Style Progress Display
  // ============================================================
  
  /// Generate a visual progress bar
  static String _progressBar(double current, double threshold, {int width = 10}) {
    final percentage = (current / threshold).clamp(0.0, 1.5);
    final filled = (percentage * width).round().clamp(0, width);
    final empty = width - filled;
    final bar = '|${'█' * filled}${'░' * empty}|';
    final pct = (percentage * 100).toStringAsFixed(0);
    return '$bar ${pct}%';
  }
  
  /// Calculate remaining value needed to trigger
  static String _remaining(double current, double threshold) {
    final delta = threshold - current;
    if (delta <= 0) return '✓ THRESHOLD MET';
    return 'Need +${delta.toStringAsFixed(2)} more';
  }
  
  /// Format timestamp with milliseconds
  static String _timestamp() {
    final now = DateTime.now();
    return '[${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}]';
  }

  // ============================================================
  // LIVE SENSOR DATA LOG - Called on every significant spike
  // Shows physics, progress, and remaining to threshold
  // ============================================================
  
  /// Log live sensor data with progress bar and math
  static void logLiveMath({
    required String gesture,
    required double currentValue,
    required double threshold,
    required Map<String, double> rawAxes,
    String? progressNote,
    String? mathNote,
  }) {
    final progress = _progressBar(currentValue, threshold);
    final remaining = _remaining(currentValue, threshold);
    
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('╔══════════════════════════════════════════════════════════════════')
      ..writeln('║ 📊 [DATA] LIVE SENSOR MATH: $gesture')
      ..writeln('╠══════════════════════════════════════════════════════════════════')
      ..writeln('║ [TIMESTAMP]: ${_timestamp()}')
      ..writeln('║')
      ..writeln('║ [PHYSICS]:')
      ..writeln('║   Raw X: ${rawAxes['x']?.toStringAsFixed(3) ?? 'N/A'} m/s²')
      ..writeln('║   Raw Y: ${rawAxes['y']?.toStringAsFixed(3) ?? 'N/A'} m/s²')
      ..writeln('║   Raw Z: ${rawAxes['z']?.toStringAsFixed(3) ?? 'N/A'} m/s²')
      ..writeln('║   Calculated: ${currentValue.toStringAsFixed(3)}')
      ..writeln('║')
      ..writeln('║ [PROGRESS]: $progress')
      ..writeln('║   Threshold: ${threshold.toStringAsFixed(2)}')
      ..writeln('║   Current:   ${currentValue.toStringAsFixed(2)}')
      ..writeln('║')
      ..writeln('║ [REMAINING]: $remaining');
    
    if (mathNote != null) {
      buffer
        ..writeln('║')
        ..writeln('║ [MATH]: $mathNote');
    }
    
    if (progressNote != null) {
      buffer
        ..writeln('║')
        ..writeln('║ [NOTE]: $progressNote');
    }
    
    buffer.writeln('╚══════════════════════════════════════════════════════════════════');
    
    developer.log(buffer.toString(), name: _tag);
  }

  // ============================================================
  // GESTURE TRIGGER LOG - Called when gesture successfully triggers
  // ============================================================
  
  /// Log successful gesture trigger with full context
  static void logTrigger({
    required GestureType gestureType,
    required String triggerCause,
    required Map<String, dynamic> sensorData,
    required String actionExecuted,
    String? additionalInfo,
  }) {
    final timestamp = _timestamp();
    final gestureName = _getGestureName(gestureType);
    final gestureEmoji = _getGestureEmoji(gestureType);
    
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('╔══════════════════════════════════════════════════════════════════')
      ..writeln('║ 🔥 [TRIGGER] $gestureEmoji GESTURE TRIGGERED: $gestureName')
      ..writeln('╠══════════════════════════════════════════════════════════════════')
      ..writeln('║ TIMESTAMP:     $timestamp')
      ..writeln('║')
      ..writeln('║ [WHAT TRIGGERED]')
      ..writeln('║   Gesture Type: $gestureName')
      ..writeln('║')
      ..writeln('║ [WHY IT TRIGGERED]')
      ..writeln('║   Cause: $triggerCause')
      ..writeln('║')
      ..writeln('║ [SENSOR DATA THAT CAUSED IT]');
    
    sensorData.forEach((key, value) {
      buffer.writeln('║   • $key: $value');
    });
    
    buffer
      ..writeln('║')
      ..writeln('║ [ACTION EXECUTED AFTER TRIGGER]')
      ..writeln('║   Result: $actionExecuted');
    
    if (additionalInfo != null) {
      buffer
        ..writeln('║')
        ..writeln('║ [ADDITIONAL INFO]')
        ..writeln('║   $additionalInfo');
    }
    
    buffer.writeln('╚══════════════════════════════════════════════════════════════════');
    
    developer.log(buffer.toString(), name: _tag);
  }
  
  // ============================================================
  // DETECTION LOG - Called when gesture is detected by sensors
  // ============================================================
  
  /// Log when a gesture is detected (before action execution)
  static void logDetection({
    required GestureType gestureType,
    required String detectionReason,
    required Map<String, dynamic> rawSensorValues,
    required Map<String, dynamic> thresholds,
  }) {
    final timestamp = _timestamp();
    final gestureName = _getGestureName(gestureType);
    final gestureEmoji = _getGestureEmoji(gestureType);
    
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('┌──────────────────────────────────────────────────────────────────')
      ..writeln('│ $gestureEmoji GESTURE DETECTED: $gestureName')
      ..writeln('├──────────────────────────────────────────────────────────────────')
      ..writeln('│ TIMESTAMP: $timestamp')
      ..writeln('│')
      ..writeln('│ DETECTION REASON:')
      ..writeln('│   $detectionReason')
      ..writeln('│')
      ..writeln('│ RAW SENSOR VALUES:');
    
    rawSensorValues.forEach((key, value) {
      buffer.writeln('│   • $key: $value');
    });
    
    buffer.writeln('│');
    buffer.writeln('│ THRESHOLDS EXCEEDED:');
    
    thresholds.forEach((key, value) {
      buffer.writeln('│   • $key: $value');
    });
    
    buffer.writeln('└──────────────────────────────────────────────────────────────────');
    
    developer.log(buffer.toString(), name: _tag);
  }
  
  // ============================================================
  // ACTION RESULT LOG - Called after action is executed
  // ============================================================
  
  /// Log the result of an action execution
  static void logActionResult({
    required GestureType gestureType,
    required String actionName,
    required bool success,
    String? errorMessage,
    Map<String, dynamic>? actionDetails,
  }) {
    final timestamp = _timestamp();
    final gestureName = _getGestureName(gestureType);
    final statusIcon = success ? '🔥' : '❌';
    final statusText = success ? 'SUCCESS' : 'FAILED';
    
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('┌──────────────────────────────────────────────────────────────────')
      ..writeln('│ $statusIcon [ACTION] RESULT: $actionName')
      ..writeln('├──────────────────────────────────────────────────────────────────')
      ..writeln('│ TIMESTAMP:    $timestamp')
      ..writeln('│ GESTURE:      $gestureName')
      ..writeln('│ ACTION:       $actionName')
      ..writeln('│ STATUS:       $statusText');
    
    if (actionDetails != null && actionDetails.isNotEmpty) {
      buffer.writeln('│');
      buffer.writeln('│ ACTION DETAILS:');
      actionDetails.forEach((key, value) {
        buffer.writeln('│   • $key: $value');
      });
    }
    
    if (!success && errorMessage != null) {
      buffer.writeln('│');
      buffer.writeln('│ ❌ ERROR: $errorMessage');
    }
    
    buffer.writeln('└──────────────────────────────────────────────────────────────────');
    
    developer.log(buffer.toString(), name: _tag);
  }
  
  // ============================================================
  // BLOCKED/REJECTED LOG - Called when gesture is blocked
  // ============================================================
  
  /// Log when a gesture is blocked or ignored with reason
  static void logBlocked({
    required String gesture,
    required String reason,
    required String blockType, // 'MUTEX', 'SHIELD', 'COOLDOWN', 'NOISE', 'INCOMPLETE'
    Map<String, dynamic>? context,
  }) {
    final timestamp = _timestamp();
    
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('┌──────────────────────────────────────────────────────────────────')
      ..writeln('│ 🚫 [BLOCK] GESTURE REJECTED: $gesture')
      ..writeln('├──────────────────────────────────────────────────────────────────')
      ..writeln('│ TIMESTAMP:  $timestamp')
      ..writeln('│ BLOCK TYPE: $blockType')
      ..writeln('│ REASON:     $reason');
    
    if (context != null && context.isNotEmpty) {
      buffer.writeln('│');
      buffer.writeln('│ CONTEXT:');
      context.forEach((key, value) {
        buffer.writeln('│   • $key: $value');
      });
    }
    
    buffer.writeln('└──────────────────────────────────────────────────────────────────');
    
    developer.log(buffer.toString(), name: _tag);
  }
  
  // ============================================================
  // THRESHOLD CROSSING LOG - Quick log for threshold events
  // ============================================================
  
  /// Quick log for threshold crossing
  static void logThresholdCrossing({
    required String gesture,
    required String data,
    required String status,
    bool uiSynced = false,
    String? additionalInfo,
  }) {
    final timestamp = _timestamp();
    final icon = status.contains('TRIGGERED') ? '🔥' : '📊';
    
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('╔════════════════════════════════════════════════════════')
      ..writeln('║ $icon [TRIGGER] GESTURE AUDIT LOG')
      ..writeln('╠════════════════════════════════════════════════════════')
      ..writeln('║ TIMESTAMP: $timestamp')
      ..writeln('║ GESTURE:   $gesture')
      ..writeln('║ DATA:      $data')
      ..writeln('║ STATUS:    $status')
      ..writeln('║ UI_SYNC:   ${uiSynced ? "✓ UPDATED" : "✗ NOT UPDATED"}');
    
    if (additionalInfo != null) {
      buffer.writeln('║ INFO:      $additionalInfo');
    }
    
    buffer.writeln('╚════════════════════════════════════════════════════════');
    
    developer.log(buffer.toString(), name: _tag);
  }
  
  // ============================================================
  // SENSOR SNAPSHOT LOG - Called for intermediate sensor events
  // ============================================================
  
  /// Log sensor data snapshot with detailed reason
  static void logSensorSnapshot({
    required String gesture,
    required Map<String, dynamic> sensorData,
    String? reason,
  }) {
    final timestamp = _timestamp();
    
    // Determine icon based on reason
    String icon = '📊';
    String tag = '[DATA]';
    if (reason != null) {
      if (reason.contains('[REJECTED]')) {
        icon = '🚫';
        tag = '[BLOCK]';
      } else if (reason.contains('[SHIELD]')) {
        icon = '🛡️';
        tag = '[SHIELD]';
      } else if (reason.contains('[EXPIRED]')) {
        icon = '⏱️';
        tag = '[EXPIRED]';
      }
    }
    
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('┌─────────────────────────────────────────────────────')
      ..writeln('│ $icon $tag SENSOR SNAPSHOT: $gesture')
      ..writeln('├─────────────────────────────────────────────────────')
      ..writeln('│ TIMESTAMP: $timestamp');
    
    if (reason != null) {
      buffer.writeln('│ REASON:    $reason');
    }
    
    buffer.writeln('│ DATA:');
    sensorData.forEach((key, value) {
      buffer.writeln('│   - $key: $value');
    });
    
    buffer.writeln('└─────────────────────────────────────────────────────');
    
    developer.log(buffer.toString(), name: _tag);
  }
  
  // ============================================================
  // COOLDOWN LOG - Called when gesture is in cooldown
  // ============================================================
  
  /// Log cooldown status with remaining time
  static void logCooldown({
    required String gesture,
    required double remainingSeconds,
    String? blockedReason,
  }) {
    final timestamp = _timestamp();
    final progress = _progressBar(remainingSeconds, 3.0); // Assume 3s max cooldown
    
    developer.log(
      '\n⏱️  [COOLDOWN] $timestamp | $gesture\n'
      '   Remaining: ${remainingSeconds.toStringAsFixed(2)}s $progress\n'
      '${blockedReason != null ? "   Reason: $blockedReason\n" : ""}',
      name: _tag,
    );
  }
  
  // ============================================================
  // MUTEX LOG - Called when gesture blocked by another
  // ============================================================
  
  /// Log mutual exclusion event with timing
  static void logMutualExclusion({
    required String primaryGesture,
    required String blockedGesture,
    required double exclusionDuration,
  }) {
    final timestamp = _timestamp();
    
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('┌──────────────────────────────────────────────────────')
      ..writeln('│ 🚫 [BLOCK] MUTEX CONFLICT')
      ..writeln('├──────────────────────────────────────────────────────')
      ..writeln('│ TIMESTAMP: $timestamp')
      ..writeln('│ PRIMARY:   $primaryGesture (in progress)')
      ..writeln('│ BLOCKED:   $blockedGesture (rejected)')
      ..writeln('│ DURATION:  ${exclusionDuration.toStringAsFixed(2)}s remaining')
      ..writeln('│ REASON:    Global Lock active - gesture conflict prevention')
      ..writeln('└──────────────────────────────────────────────────────');
    
    developer.log(buffer.toString(), name: _tag);
  }
  
  // ============================================================
  // SHIELD LOG - Called when pocket shield blocks gesture
  // ============================================================
  
  /// Log pocket shield blocking event
  static void logShieldBlock({
    required String gesture,
    required bool proximityNear,
    required double luxLevel,
  }) {
    final timestamp = _timestamp();
    final reason = proximityNear ? 'Proximity = NEAR (0.0cm)' : 'Lux = ${luxLevel.toStringAsFixed(1)} (dark)';
    
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('┌──────────────────────────────────────────────────────')
      ..writeln('│ 🛡️ [SHIELD] POCKET PROTECTION ACTIVE')
      ..writeln('├──────────────────────────────────────────────────────')
      ..writeln('│ TIMESTAMP: $timestamp')
      ..writeln('│ BLOCKED:   $gesture')
      ..writeln('│ REASON:    $reason')
      ..writeln('│ STATUS:    Logic stopped. Battery saved.')
      ..writeln('└──────────────────────────────────────────────────────');
    
    developer.log(buffer.toString(), name: _tag);
  }
  
  // ============================================================
  // DEBOUNCE LOG - Called during gesture confirmation
  // ============================================================
  
  /// Log debounce/confirmation window progress
  static void logDebounce({
    required String gesture,
    required double holdDuration,
    required double requiredDuration,
    required bool confirmed,
  }) {
    final timestamp = _timestamp();
    final progress = _progressBar(holdDuration, requiredDuration);
    final status = confirmed ? '✓ CONFIRMED' : '⏳ WAITING';
    
    developer.log(
      '\n⏳ [DEBOUNCE] $timestamp | $gesture\n'
      '   Hold: ${holdDuration.toStringAsFixed(3)}s / ${requiredDuration.toStringAsFixed(3)}s\n'
      '   Progress: $progress\n'
      '   Status: $status\n',
      name: _tag,
    );
  }
  
  // ============================================================
  // PERMISSION LOG - Called for permission issues
  // ============================================================
  
  /// Log permission/access issues
  static void logPermissionIssue({
    required String feature,
    required String issue,
    String? resolution,
  }) {
    final timestamp = _timestamp();
    
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('┌──────────────────────────────────────────────────────')
      ..writeln('│ ⚠️ [WARNING] PERMISSION ISSUE')
      ..writeln('├──────────────────────────────────────────────────────')
      ..writeln('│ TIMESTAMP:  $timestamp')
      ..writeln('│ FEATURE:    $feature')
      ..writeln('│ ISSUE:      $issue');
    
    if (resolution != null) {
      buffer.writeln('│ RESOLUTION: $resolution');
    }
    
    buffer.writeln('└──────────────────────────────────────────────────────');
    
    developer.log(buffer.toString(), name: _tag);
  }
  
  // ============================================================
  // ACTION EXECUTION LOG - Called when action is being executed
  // ============================================================
  
  /// Log action execution hand-off to hardware
  static void logActionExecution({
    required String action,
    required String method,
    required String previousState,
    required String newState,
  }) {
    final timestamp = _timestamp();
    
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('┌──────────────────────────────────────────────────────')
      ..writeln('│ 🔥 [ACTION] EXECUTING: $action')
      ..writeln('├──────────────────────────────────────────────────────')
      ..writeln('│ TIMESTAMP: $timestamp')
      ..writeln('│ METHOD:    $method')
      ..writeln('│ STATE:     $previousState → $newState')
      ..writeln('└──────────────────────────────────────────────────────');
    
    developer.log(buffer.toString(), name: _tag);
  }
  
  /// Log intent launch
  static void logIntentLaunch({
    required String action,
    required String intentAction,
    required bool success,
    String? packageName,
  }) {
    final timestamp = _timestamp();
    final icon = success ? '✓' : '✗';
    
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('┌──────────────────────────────────────────────────────')
      ..writeln('│ 📱 [INTENT] LAUNCHING: $action')
      ..writeln('├──────────────────────────────────────────────────────')
      ..writeln('│ TIMESTAMP: $timestamp')
      ..writeln('│ INTENT:    $intentAction');
    
    if (packageName != null) {
      buffer.writeln('│ PACKAGE:   $packageName');
    }
    
    buffer
      ..writeln('│ SUCCESS:   $icon ${success ? "YES" : "NO"}')
      ..writeln('└──────────────────────────────────────────────────────');
    
    developer.log(buffer.toString(), name: _tag);
  }
  
  // ============================================================
  // CONFIG LOG - Called for configuration changes
  // ============================================================
  
  /// Log configuration changes
  static void logConfig({
    required String parameter,
    required dynamic oldValue,
    required dynamic newValue,
    String? reason,
  }) {
    final timestamp = _timestamp();
    
    developer.log(
      '\n⚙️  [CONFIG] $timestamp | $parameter\n'
      '   Changed: $oldValue → $newValue\n'
      '${reason != null ? "   Reason: $reason\n" : ""}',
      name: _tag,
    );
  }
  
  // ============================================================
  // CONFLICT RESOLUTION LOG
  // ============================================================
  
  /// Log gesture conflict resolution
  static void logConflictResolution({
    required String gesture1,
    required String gesture2,
    required String resolution,
    required String winner,
  }) {
    final timestamp = _timestamp();
    
    developer.log(
      '\n⚔️  [CONFLICT] $timestamp\n'
      '   Gestures: $gesture1 vs $gesture2\n'
      '   Resolution: $resolution\n'
      '   Winner: $winner\n',
      name: _tag,
    );
  }
  
  // ============================================================
  // HELPER METHODS
  // ============================================================
  
  /// Get human-readable gesture name
  static String _getGestureName(GestureType type) {
    switch (type) {
      case GestureType.shake:
        return 'KINETIC CHOP (TORCH)';
      case GestureType.twist:
        return 'DOUBLE TWIST (CAMERA)';
      case GestureType.flip:
        return 'SURFACE FLIP (DND)';
      case GestureType.backTap:
        return 'SECRET STRIKE (CUSTOM)';
      case GestureType.pocketShield:
        return 'POCKET SHIELD (PROTECTION)';
    }
  }
  
  /// Get emoji for gesture type
  static String _getGestureEmoji(GestureType type) {
    switch (type) {
      case GestureType.shake:
        return '🔦';
      case GestureType.twist:
        return '📷';
      case GestureType.flip:
        return '🔕';
      case GestureType.backTap:
        return '⚡';
      case GestureType.pocketShield:
        return '🛡️';
    }
  }
}
