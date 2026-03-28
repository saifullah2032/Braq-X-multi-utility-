/// BARQ X Configuration
/// All sensor thresholds, cooldowns, and timing constants
class AppConfig {
  // Sensor Thresholds (m/s², rad/s, lux, etc.)
  
  /// Kinetic Shake (Torch)
  static const double shakeThreshold = 16.0;
  static const double shakeCooldownSeconds = 3.5;
  
  /// Inertial Twist (Camera)
  static const double twistThreshold = 6.0; // Motorola-style double twist threshold
  static const double twistCooldownSeconds = 1.0;
  
  /// Surface Flip (DND - Face Down)
  static const double flipZThreshold = -9.5;
  static const double flipDebounceSeconds = 0.5; // Must hold for 500ms before triggering
  
  /// Secret Strike (Back-Tap)
  static const double backTapSpikeThreshold = 15.0; // Increased from 12.0 to avoid shake interference
  static const int backTapWindowMilliseconds = 400;
  static const double backTapCooldownSeconds = 1.0;
  
  /// Gesture Conflict Resolution
  static const double shakeMutexDuration = 1.5; // Disable back-tap for 1.5s after shake
  
  /// Pocket Shield (Protective Mode)
  static const double pocketShieldLightThreshold = 10.0;
  
  // Low-Pass Filter
  static const double lowPassFilterAlpha = 0.2;
  
  // Sensor Sampling
  static const int sensorFrequencyHz = 50;
  static const int lightSensorFrequencyHz = 1;
  
  // Haptic Feedback Patterns (milliseconds)
  static const List<int> hapticTorchPattern = [200];
  static const List<int> hapticCameraPattern = [120, 80, 120]; // Double buzz: vibrate-pause-vibrate
  static const List<int> hapticDndPattern = [60, 30, 60, 30, 60];
  static const List<int> hapticBackTapPattern = [100];
  
  // UI Constants
  static const double masterToggleHeight = 56.0;
  static const double masterTogglePadding = 40.0;
  static const double toggleStampSize = 40.0;
  static const double cardBorderWidth = 3.5;
  static const double secondaryBorderWidth = 2.0;
  static const double shadowOffset = 8.0;
  static const double screenPadding = 20.0;
  static const double cardSpacing = 12.0;
  static const double innerPadding = 16.0;
  static const double cornerRadiusSharp = 0.0;
  static const double cornerRadiusSlight = 4.0;
  
  // Timing & Animation
  static const Duration toggleTransitionDuration = Duration(milliseconds: 300);
  static const Duration bottomSheetDuration = Duration(milliseconds: 300);
  static const Duration overlayFadeDuration = Duration(milliseconds: 200);
  
  // Permissions
  static const List<String> criticalPermissions = [
    'android.permission.SYSTEM_ALERT_WINDOW',
    'android.permission.ACCESS_NOTIFICATION_POLICY',
    'android.permission.CAMERA',
    'android.permission.VIBRATE',
  ];
  
  // DND Configuration
  static const int dndInterruptionFilterAlarms = 4;
  
  // Intent Actions
  static const String cameraIntentAction = 'android.media.action.STILL_IMAGE_CAMERA';
  static const String whatsAppPackage = 'com.whatsapp';
  static const String assistantPackage = 'com.google.android.googlequicksearchbox';
  
  // Performance Targets
  static const int gestureDetectionLatencyMs = 200;
  static const int hapticFeedbackLatencyMs = 50;
  static const int cameraIntentLatencyMs = 500;
  
  // Crash/Error Handling
  static const Duration isolateRestartDelay = Duration(seconds: 2);
}
