import 'package:vibration/vibration.dart';
import '../constants/app_config.dart';
import '../models/gesture_event.dart';

/// Haptic feedback service for vibration patterns
/// Provides different haptic patterns for each gesture type
class HapticService {
  static Future<void> playGestureHaptic(GestureType gestureType) async {
    // Check if device supports vibration
    final canVibrate = await Vibration.hasVibrator();
    if (!canVibrate) return;

    switch (gestureType) {
      case GestureType.shake:
        // Torch: Single long vibration (200ms)
        await Vibration.vibrate(duration: 200);
        break;

      case GestureType.twist:
        // Camera: Three pulses (80-40-80ms)
        await _playPattern(AppConfig.hapticCameraPattern);
        break;

      case GestureType.flip:
        // DND: Five short pulses (60-30-60-30-60ms)
        await _playPattern(AppConfig.hapticDndPattern);
        break;

      case GestureType.backTap:
        // Back-Tap: Single medium vibration (100ms)
        await Vibration.vibrate(duration: 100);
        break;

      case GestureType.pocketShield:
        // Pocket Shield: No haptic (silent protection)
        break;
    }
  }

  /// Play a pattern of vibrations with pauses
  /// Pattern is alternating durations (vibrate, pause, vibrate, pause, ...)
  static Future<void> _playPattern(List<int> pattern) async {
    for (int i = 0; i < pattern.length; i++) {
      if (i % 2 == 0) {
        // Vibrate
        await Vibration.vibrate(duration: pattern[i]);
      } else {
        // Pause (silent)
        await Future.delayed(Duration(milliseconds: pattern[i]));
      }
    }
  }

  /// Play success feedback (two short vibrations)
  static Future<void> playSuccess() async {
    final canVibrate = await Vibration.hasVibrator();
    if (!canVibrate) return;

    await Vibration.vibrate(duration: 100);
    await Future.delayed(Duration(milliseconds: 100));
    await Vibration.vibrate(duration: 100);
  }

  /// Play error feedback (one long vibration)
  static Future<void> playError() async {
    final canVibrate = await Vibration.hasVibrator();
    if (!canVibrate) return;

    await Vibration.vibrate(duration: 300);
  }
}
