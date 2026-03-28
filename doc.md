# BARQ X - Technical Documentation

## 📋 Table of Contents
- [Architecture Overview](#architecture-overview)
- [Mythic Protocol System](#mythic-protocol-system)
- [Sensor Integration](#sensor-integration)
- [UI/UX Design System](#uiux-design-system)
- [Performance Optimization](#performance-optimization)
- [API Reference](#api-reference)
- [Build Configuration](#build-configuration)
- [Testing Strategy](#testing-strategy)

## 🏗️ Architecture Overview

### Core Framework
BARQ X is built using **Flutter 3.38.5** with a reactive architecture pattern implementing:

```
┌─────────────────────────────────────────┐
│                UI Layer                 │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │ HomeScreen  │  │ OnboardingScreen │   │
│  │   (Mythic   │  │   (Setup Flow)  │   │
│  │  Dashboard) │  │                 │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────┐
│            State Management             │
│  ┌─────────────────┐  ┌───────────────┐ │
│  │ Riverpod Store  │  │ Local Storage │ │
│  │  (Reactive)     │  │ (Persistent)  │ │
│  └─────────────────┘  └───────────────┘ │
└─────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────┐
│           Service Layer                 │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │ Sensor      │  │ Background      │   │
│  │ Integration │  │ Service Manager │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────┐
│          Platform Layer                 │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │ Android     │  │ System          │   │
│  │ Services    │  │ Integration     │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
```

### Key Components

#### State Management (Riverpod)
- **ArmedProvider**: Central system armed/disarmed state
- **SettingsProvider**: Gesture protocol configurations
- **ServiceRunningProvider**: Background service status
- **SharedPrefsProvider**: Persistent storage interface

#### Service Architecture
- **SensorService**: Hardware sensor data collection
- **ForegroundServiceManager**: Android background processing
- **ActionHandler**: System integration and command execution
- **GestureIntegrationService**: Main coordination service

## 🎭 Mythic Protocol System

### Protocol Architecture
Each mythic protocol implements a standardized interface:

```dart
abstract class MythicProtocol {
  String get name;
  IconData get icon;
  Color get color;
  bool get isEnabled;
  
  Future<void> execute();
  void toggle();
  Map<String, dynamic> toJson();
}
```

### Protocol Implementations

#### 1. BOLT IGNITION (Shake → Torch)
```dart
class BoltIgnitionProtocol extends MythicProtocol {
  @override
  String get name => 'BOLT IGNITION';
  
  @override
  IconData get icon => Icons.flashlight_on;
  
  @override
  Future<void> execute() async {
    await TorchLight.enableTorch();
    // Haptic feedback and audio cues
  }
}
```

#### 2. HERMES SNAP (Twist → Camera)
- **Gesture**: Gyroscope rotation detection (threshold: 1.2 rad/s)
- **Action**: Launch camera with intent
- **Validation**: Motion smoothing and debouncing

#### 3. HORIZON LOCK (Flip → DND)
- **Gesture**: Orientation change detection
- **Action**: Toggle Do Not Disturb mode
- **Integration**: Android NotificationManager

#### 4. OMEGA TRIGGER (BackTap → Custom)
- **Gesture**: Double-tap back detection via accelerometer
- **Actions**: WhatsApp, Google Assistant, Media Player
- **Configuration**: User-selectable action mapping

#### 5. GHOST VEIL (Pocket → Shield)
- **Sensors**: Light + Proximity combination
- **Logic**: Dark environment + close proximity = pocket detection
- **Protection**: Auto-lock and gesture pause

## 🔧 Sensor Integration

### Sensor Fusion Architecture
```dart
class SensorFusionEngine {
  final StreamController<SensorEvent> _eventController;
  final Map<SensorType, SensorData> _sensorBuffer;
  
  // Advanced filtering and processing
  Vector3 applyHighPassFilter(Vector3 input, double cutoff);
  double calculateMagnitude(Vector3 vector);
  bool detectGesturePattern(List<SensorReading> buffer);
}
```

### Supported Sensors
- **Accelerometer**: Shake and tap detection
- **Gyroscope**: Rotation and twist gestures
- **Light Sensor**: Ambient light for pocket detection
- **Proximity Sensor**: Near/far detection for Ghost Veil

### Performance Optimization
- **Isolate Processing**: Dedicated thread for sensor data
- **Buffer Management**: Circular buffer with 100ms windows
- **Adaptive Sampling**: Dynamic frequency based on activity
- **Power Management**: Smart sensor enable/disable

## 🎨 UI/UX Design System

### Neo-Brutalist Design Philosophy
BARQ X implements a strict neo-brutalist aesthetic:

#### Design Tokens
```dart
class DesignTokens {
  // Border specifications
  static const double borderWidth = 3.5;
  static const double borderRadius = 0.0; // Always sharp edges
  
  // Shadow system
  static const BoxShadow hardShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(8, 8),
    blurRadius: 0,
    spreadRadius: 0,
  );
  
  // Typography scale
  static const double titleSize = 38.0;
  static const double labelSize = 14.0;
  static const double bodySize = 12.0;
}
```

#### Color System
```dart
class BARQColors {
  // Core palette
  static const Color background = Color(0xFFFFF8DE);      // Aged Cream
  static const Color statusCard = Color(0xFFB4D7F1);     // Sky Blue
  static const Color protocolCard = Color(0xFFFFCCB6);   // Peach
  static const Color verificationCard = Color(0xFFD7D4F1); // Lavender
  static const Color gutterMargin = Color(0xFFFF7B89);   // Coral Red
  
  // Protocol colors
  static const Color boltIgnition = Color(0xFFFF6B6B);   // Coral Red
  static const Color hermesSnap = Color(0xFF4ECDC4);     // Teal
  static const Color horizonLock = Color(0xFFA8A5FF);    // Periwinkle
  static const Color omegaTrigger = Color(0xFF45B7D1);   // Blue
  static const Color ghostVeil = Color(0xFF96CEB4);      // Mint Green
}
```

### Mythic Gutter Layout System

#### 10% Margin Optimization
```dart
class GutterLayoutBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        return Padding(
          padding: EdgeInsets.only(
            left: screenWidth * 0.10 + 20, // 10% + buffer
            right: 16,
            top: 20,
            bottom: 20,
          ),
          child: _buildDashboardContent(),
        );
      },
    );
  }
}
```

#### Multi-Row Protocol Legend
- **42x42 Icon Boxes**: Precise squared containers with 2.5px borders
- **Mythic Labels**: Bold uppercase typography with 0.8 letter spacing
- **12px Row Spacing**: Consistent vertical rhythm
- **Row Architecture**: Icon-label horizontal pairs with 16px gap

#### Recent Triggers Collection
- **64x64 Squares**: Larger trigger indicators
- **12px Spacing**: Both horizontal and vertical
- **6px Hard Shadow**: Neo-brutalist depth effect

## ⚡ Performance Optimization

### Memory Management
```dart
class MemoryOptimizedSensorProcessor {
  late final ObjectPool<SensorReading> _readingPool;
  late final CircularBuffer<Vector3> _accelerometerBuffer;
  
  void _recycleReading(SensorReading reading) {
    reading.reset();
    _readingPool.release(reading);
  }
}
```

### Background Processing
- **Isolate Communication**: SendPort/ReceivePort for thread-safe data transfer
- **Service Lifecycle**: Proper foreground service management
- **Battery Optimization**: Respect Android Doze mode and battery optimization

### Widget Optimization
- **Const Constructors**: Extensive use of const widgets
- **RepaintBoundary**: Strategic isolation of expensive widgets
- **Selective Rebuilds**: Granular Riverpod providers to minimize rebuilds

## 📚 API Reference

### Core Services

#### GestureIntegrationService
```dart
class GestureIntegrationService {
  Future<void> initialize();
  Future<void> dispose();
  void armSystem();
  void disarmSystem();
  Stream<GestureEvent> get gestureStream;
}
```

#### ActionHandler
```dart
class ActionHandler {
  Future<void> toggleTorch();
  Future<void> launchCamera();
  Future<void> setDndState(bool enabled);
  Future<void> executeCustomAction(String action);
}
```

### Widget Components

#### Protocol Row Builder
```dart
Widget buildProtocolRow({
  required IconData icon,
  required String label,
  required Color color,
  required bool isEnabled,
  required VoidCallback onTap,
});
```

#### Mythological Sticker Card
```dart
Widget buildMythologicalStickerCard({
  required IconData icon,
  required Color color,
});
```

## 🔨 Build Configuration

### APK Optimization Settings
```kotlin
// android/app/build.gradle.kts
android {
    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
```

### ProGuard Rules
```proguard
# Flutter specific
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Sensor Plus optimization
-keep class com.baseflow.** { *; }

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** v(...);
    public static *** d(...);
    public static *** i(...);
}
```

### Build Commands
```bash
# Debug build
flutter run --debug

# Release builds (optimized)
flutter build apk --release --split-per-abi

# Specific architecture
flutter build apk --release --target-platform android-arm64
```

## 🧪 Testing Strategy

### Unit Testing
```dart
// test/services/sensor_service_test.dart
testWidgets('Sensor service processes accelerometer data', (tester) async {
  final service = SensorService();
  final mockData = AccelerometerEvent(1.0, 2.0, 3.0, DateTime.now());
  
  await service.processAccelerometerReading(mockData);
  
  expect(service.lastAccelerometerReading, equals(mockData));
});
```

### Widget Testing
```dart
// test/widgets/protocol_legend_test.dart
testWidgets('Protocol legend displays all mythic protocols', (tester) async {
  await tester.pumpWidget(ProtocolLegendWidget());
  
  expect(find.text('BOLT IGNITION'), findsOneWidget);
  expect(find.text('HERMES SNAP'), findsOneWidget);
  expect(find.text('HORIZON LOCK'), findsOneWidget);
  expect(find.text('OMEGA TRIGGER'), findsOneWidget);
  expect(find.text('GHOST VEIL'), findsOneWidget);
});
```

### Integration Testing
```dart
// integration_test/gesture_flow_test.dart
testWidgets('Complete gesture flow test', (tester) async {
  await tester.pumpAndSettle();
  
  // Arm the system
  await tester.tap(find.text('ARM ENGINE'));
  await tester.pumpAndSettle();
  
  // Simulate shake gesture
  await mockSensorData(ShakeGesture());
  
  // Verify torch activation
  expect(find.text('TORCH ACTIVE'), findsOneWidget);
});
```

## 📈 Performance Metrics

### Target Performance
- **Cold Start**: < 2 seconds
- **Gesture Recognition**: < 100ms latency
- **Memory Usage**: < 50MB baseline
- **Battery Impact**: < 2% per hour active use

### Monitoring
```dart
class PerformanceMonitor {
  void trackGestureLatency(Duration latency);
  void trackMemoryUsage();
  void trackBatteryImpact();
  void generatePerformanceReport();
}
```

---

## 🔗 Additional Resources

- **Flutter Documentation**: [flutter.dev](https://flutter.dev)
- **Riverpod Guide**: [riverpod.dev](https://riverpod.dev)
- **Android Sensor API**: [Android Developer Docs](https://developer.android.com/guide/topics/sensors)
- **Neo-Brutalist Design**: [Design Philosophy Guide](https://brutalist-web.design/)

*This documentation is maintained alongside the codebase and reflects the current implementation of BARQ X v1.0.0*