# BARQ X - Premium Gesture-Utility App

A professional-grade Android gesture control application built with Flutter, featuring five core gesture protocols and a soft neo-brutalist design system.

```
╔════════════════════════════════════════════════════════════╗
║                      B A R Q   X                          ║
║           Cool Kinetic / Soft Neo-Brutalist               ║
║                  Gesture Control System                    ║
╚════════════════════════════════════════════════════════════╝
```

---

## 🎯 What Is BARQ X?

BARQ X transforms your Android phone into a **gesture-controlled system** where natural motions trigger powerful actions—without touching the screen.

### Core Gestures

| Gesture | Action | Sensor | Threshold |
|---------|--------|--------|-----------|
| **🔦 Kinetic Shake** | Toggle Flashlight | Accelerometer | > 16.0 m/s² |
| **📷 Inertial Twist** | Launch Camera | Gyroscope | > 25.0 rad/s |
| **🔕 Surface Flip** | Enable Smart Silence | Accel + Proximity | Z < -9.5 |
| **⚡ Secret Strike** | Custom Action | Accelerometer | 2 spikes/400ms |
| **🛡️ Pocket Shield** | Accidental Protection | Proximity + Light | P>0 & L<10lux |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.10.0+
- **Android SDK**: minSdkVersion 21+
- **Device**: Physical Android phone (for sensor testing)

### Installation

```bash
git clone https://github.com/saifullah2032/Braq-X-multi-utility-.git
cd barq_x
flutter pub get
flutter pub run build_runner build
flutter run -v
```

### First Launch

1. App shows mandatory 4-step onboarding (features, how-to, permissions, ready)
2. After onboarding, requests Android permissions (camera, notifications, system alert)
3. HomeScreen displays with Master Toggle (armed/disarmed)
4. Enable gestures one-by-one in the gesture cards
5. Perform gestures naturally (shake, twist, flip, back-tap, etc.)

---

## 📋 Documentation

- **[PLAN.md](PLAN.md)** - 9-phase implementation roadmap with detailed specifications
- **[PRD.md](PRD.md)** - Product Requirements Document with user flows
- **[README.md](README.md)** - This file; getting started guide
- **[DOCUMENTATION_SUMMARY.md](DOCUMENTATION_SUMMARY.md)** - Navigation guide for all docs

---

## 🎨 Design System

**Color Palette**: Cool pastels on off-white background
- Primary: #B4D7F1 (Icy blue - Torch/Armed)
- Secondary: #D1E8E2 (Sage mint - Camera)
- Tertiary: #E6D4F1 (Pale lavender - DND)
- Quaternary: #F1D1D1 (Dusty rose - Back-Tap)
- Text: #1A1A1A (Heavy charcoal)

**Typography**:
- Headers: Bebas Neue (frozen, uppercase)
- Body: Space Grotesk (professional, readable)

**Geometry**:
- Borders: 3.5px thick, charcoal (#1A1A1A)
- Corners: 0-4px radius (sharp/minimal)
- Shadows: 6-8px offset with 10% opacity
- Philosophy: Neo-brutalism, frozen architecture

---

## 🔧 Technical Stack

- **Framework**: Flutter 3.10+
- **State Management**: Riverpod 2.4+ with code generation
- **Sensors**: sensors_plus (accel/gyro), light package (ambient light)
- **Haptics**: vibration package (gesture feedback patterns)
- **Intents**: android_intent_plus (action execution)
- **Persistence**: shared_preferences (settings/state)
- **Permissions**: permission_handler (Android permissions)

---

## 🏗️ Architecture Overview

### Stream-Based Isolate Design

```
┌─────────────────────────────────┐
│   Background Isolate            │
│  ┌───────────────────────────┐  │
│  │ Sensor Listeners (50Hz)   │  │
│  │ - Accelerometer           │  │
│  │ - Gyroscope               │  │
│  │ - Low-Pass Filter         │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ Gesture Detection         │  │
│  │ - Shake (accel > 16)      │  │
│  │ - Twist (gyro > 25)       │  │
│  │ - Flip (Z < -9.5)         │  │
│  │ - Back-Tap (2 spikes)     │  │
│  └───────────────────────────┘  │
│            ↓                      │
│    SendPort (Events)             │
└─────────────────────────────────┘
         ↓
┌─────────────────────────────────┐
│   Main Isolate                   │
│  ┌───────────────────────────┐  │
│  │ ReceivePort Stream        │  │
│  │ → Riverpod Providers      │  │
│  │ → State Updates           │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ Gesture Integration       │  │
│  │ - Filter by armed state   │  │
│  │ - Check pocket shield     │  │
│  │ - Verify gesture enabled  │  │
│  └───────────────────────────┘  │
│            ↓                      │
│    ActionHandler (Haptic + Intent)
└─────────────────────────────────┘
```

### Key Services

1. **SensorService**: Isolate lifecycle, gesture event broadcasting
2. **ActionHandler**: Intent execution (camera, DND, WhatsApp, etc.)
3. **HapticService**: Vibration patterns for gesture feedback
4. **GestureIntegrationService**: Main orchestration, filtering, and routing
5. **PermissionService**: Android permission management

### Riverpod State Management

```
┌─ Armed Provider (StateNotifier)
│   └─ Persisted in SharedPreferences
├─ Settings Provider (StateNotifier)
│   └─ Gesture enable/disable, custom actions
├─ Current Sensor State Provider (State)
│   └─ Real-time sensor readings
├─ Pocket Shield Provider (Provider - derived)
│   └─ Computed from light + proximity
└─ Gesture Events Provider (StreamProvider)
    └─ Streamed from background isolate
```

---

## 📁 Project Structure

```
lib/
├── constants/
│   ├── app_colors.dart          # Color palette
│   └── app_config.dart          # Thresholds, haptic patterns, UI constants
├── models/
│   ├── gesture_event.dart       # GestureType enum, GestureEvent model
│   ├── gesture_settings.dart    # User preferences, JSON serialization
│   └── sensor_state.dart        # Sensor snapshot with calculated properties
├── providers/
│   ├── armed_provider.dart      # Armed/disarmed state
│   ├── settings_provider.dart   # Gesture settings notifier
│   ├── current_sensor_state_provider.dart  # Real-time sensor state
│   ├── pocket_shield_provider.dart         # Derived pocket detection
│   └── gesture_events_provider.dart        # Gesture event stream
├── services/
│   ├── sensor_service.dart               # Isolate management
│   ├── _sensor_isolate_entry.dart        # Background isolate entry
│   ├── action_handler.dart               # Intent execution
│   ├── haptic_service.dart               # Vibration patterns
│   ├── gesture_integration_service.dart  # Main orchestration
│   └── permission_service.dart           # Android permissions
├── widgets/
│   ├── neo_card.dart            # Reusable card component
│   ├── neo_toggle.dart          # Toggle buttons
│   └── gesture_card.dart        # Individual gesture card
├── screens/
│   ├── home_screen.dart         # Main dashboard
│   └── onboarding_screen.dart   # 4-step onboarding
├── utils/
│   └── low_pass_filter.dart     # Sensor noise smoothing
├── main.dart                    # App entry point
└── main_app.dart                # Root widget with theme
```

---

## 🎮 Feature Configuration

### Sensor Thresholds (app_config.dart)

```dart
// Kinetic Shake (Torch)
static const double shakeThreshold = 16.0;           // m/s²
static const double shakeCooldownSeconds = 3.5;

// Inertial Twist (Camera)
static const double twistThreshold = 25.0;           // rad/s
static const double twistCooldownSeconds = 1.0;

// Surface Flip (DND)
static const double flipZThreshold = -9.5;           // m/s²

// Secret Strike (Back-Tap)
static const double backTapSpikeThreshold = 12.0;    // m/s²
static const int backTapWindowMilliseconds = 400;

// Pocket Shield
static const double pocketShieldLightThreshold = 10.0; // lux

// Low-Pass Filter
static const double lowPassFilterAlpha = 0.2;        // Exponential smoothing

// Sensor Sampling
static const int sensorFrequencyHz = 50;             // Accelerometer/Gyroscope
static const int lightSensorFrequencyHz = 1;         // Light sensor
```

### Haptic Patterns

```dart
hapticTorchPattern = [200]                    // 200ms vibration
hapticCameraPattern = [80, 40, 80]            // Three pulses
hapticDndPattern = [60, 30, 60, 30, 60]       // Five pulses
hapticBackTapPattern = [100]                  // 100ms vibration
```

---

## 🔐 Permissions

BARQ X requires the following Android permissions:

| Permission | Purpose |
|-----------|---------|
| `CAMERA` | Launch camera app on twist gesture |
| `NOTIFICATION_POLICY` | Enable/disable Do Not Disturb mode |
| `SYSTEM_ALERT_WINDOW` | Display overlay when needed |

These are requested after onboarding completes.

---

## 🧪 Testing

### Unit Tests (Planned for Phase 8+)

```bash
flutter test test/
```

### Widget Tests

```bash
flutter test --tags=widget test/
```

### Integration Tests

```bash
flutter test integration_test/
```

### Manual Testing Checklist

- [ ] Onboarding flow completes successfully
- [ ] Master toggle arms/disarms all gestures
- [ ] Each gesture card toggle works independently
- [ ] Shake gesture triggers flashlight
- [ ] Twist gesture launches camera
- [ ] Flip gesture enables DND
- [ ] Back-tap executes custom action
- [ ] Pocket shield prevents false triggers
- [ ] Haptic feedback vibrates on each gesture
- [ ] Settings persist after app restart

---

## 🐛 Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Gestures not detected | Master toggle off | Enable master toggle on home screen |
| Gestures not working | Permissions missing | Complete onboarding and grant permissions |
| Noisy sensor readings | Poor low-pass filter | Adjust `lowPassFilterAlpha` from 0.2 to 0.25 |
| DND doesn't work | Policy permission denied | Grant NOTIFICATION_POLICY in app settings |
| App crashes on start | Build cache corrupt | `flutter clean && flutter pub get` |
| Isolate errors | Resource leak | Check logcat: `flutter logs` |
| Flashlight won't toggle | Missing camera permission | Grant camera permission in app settings |

### Debug Logging

Enable detailed logging:

```dart
flutter run --verbose
flutter logs  # Real-time log viewer
```

Search for `GestureIntegrationService` or `SensorService` in logs for gesture events.

---

## 🚀 Deployment

### Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

### Build App Bundle

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Release Checklist

- [ ] Increment version in pubspec.yaml
- [ ] Run `flutter analyze` (no issues)
- [ ] Run all tests with `flutter test`
- [ ] Test on physical device
- [ ] Update CHANGELOG.md
- [ ] Create GitHub release tag
- [ ] Upload APK/AAB to Play Store

---

## 🤝 Contributing

1. Fork repository
2. Create feature branch: `git checkout -b feature/your-feature`
3. Follow code style: `flutter format lib/`
4. Check quality: `flutter analyze`
5. Commit with descriptive message
6. Submit pull request

---

## 📊 Implementation Status

**Phase 1-9: COMPLETE** ✅

| Phase | Topic | Status | Lines |
|-------|-------|--------|-------|
| 1 | Foundation & Architecture | ✅ Complete | 455 |
| 2 | Riverpod Providers | ✅ Complete | 220 |
| 3 | Sensor Service & Isolate | ✅ Complete | 394 |
| 4 | Action Handler & Haptics | ✅ Complete | 221 |
| 5 | UI Components | ✅ Complete | 428 |
| 6 | Home Screen Dashboard | ✅ Complete | 330 |
| 7 | Onboarding & Permissions | ✅ Complete | 615 |
| 8 | Integration & Testing | ✅ Complete | 130 |
| 9 | Polish & Deployment | ✅ Complete | 150 |
| **TOTAL** | **All 9 Phases** | **✅ COMPLETE** | **3,343** |

---

## 📜 License

MIT License - See LICENSE file for details

---

## 🙏 Acknowledgments

- Flutter & Dart teams for the incredible framework
- Riverpod for reactive state management
- Community packages (sensors_plus, vibration, android_intent_plus)

---

<div align="center">

**BARQ X - Premium Gesture Control for Android**

*Built with Flutter • Neo-Brutalist Design • Stream-Based Architecture*

**Latest Release**: Phase 9 Complete (All Phases 1-9 Implemented)

[GitHub](https://github.com/saifullah2032/Braq-X-multi-utility-) • [Issues](https://github.com/saifullah2032/Braq-X-multi-utility-/issues) • [Releases](https://github.com/saifullah2032/Braq-X-multi-utility-/releases)

</div>
