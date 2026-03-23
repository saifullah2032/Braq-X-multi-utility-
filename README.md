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
- **Device**: Physical Android phone

### Installation

```bash
git clone https://github.com/yourusername/barq_x.git
cd barq_x
flutter pub get
flutter pub run build_runner build
flutter run -v
```

---

## 📋 Documentation

- **[PLAN.md](PLAN.md)** - 9-day implementation roadmap
- **[PRD.md](PRD.md)** - Product Requirements Document
- **[README.md](README.md)** - Getting started guide

---

## 🎨 Design System

**Color Palette**: Cool pastels on off-white background
- Primary: #B4D7F1 (Icy blue)
- Secondary: #D1E8E2 (Sage mint)
- Tertiary: #E6D4F1 (Pale lavender)
- Text: #1A1A1A (Heavy charcoal)

**Typography**: Bebas Neue (headers) + Space Grotesk (body)

**Geometry**: Sharp edges, 3.5px borders, 6-8px shadows

---

## 🔧 Technical Stack

- **Framework**: Flutter 3.10+
- **State Management**: Riverpod 2.4+
- **Sensors**: sensors_plus, light package
- **Haptics**: vibration package
- **Intents**: android_intent_plus
- **Persistence**: shared_preferences

---

## 📊 Architecture

**Background Isolate + ReceivePort Stream**:
- Sensors monitored continuously in background
- Gestures detected asynchronously
- Events sent to main isolate via ReceivePort
- UI updated reactively via Riverpod

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Gestures not working | Check Master Toggle, verify permissions |
| Noisy readings | Adjust low-pass filter alpha (0.2 → 0.25) |
| DND fails | Verify ACCESS_NOTIFICATION_POLICY permission |
| App crashes | `flutter clean && flutter pub get` |

---

## 🤝 Contributing

1. Fork repository
2. Create feature branch
3. Submit pull request

Follow: `flutter format lib/` + `flutter analyze`

---

## 📄 License

MIT License - See [LICENSE](LICENSE)

---

<div align="center">

**BARQ X - Premium Gesture Control for Android**

</div>
