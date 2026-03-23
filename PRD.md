# BARQ X - Product Requirements Document (PRD) v1.0

**Product Name**: BARQ X  
**Version**: 1.0  
**Status**: In Development  
**Target Platform**: Android (API 21+)  
**Theme**: Cool Kinetic / Soft Neo-Brutalist  

---

## Executive Summary

**BARQ X** is a premium gesture-utility app that transforms your Android phone into a high-tech, gesture-controlled system. With five core gesture protocols (Shake, Twist, Flip, Back-Tap, and Pocket Shield), users can trigger actions via natural motions without touching the screen.

### Core Features at a Glance

| Gesture | Sensor | Action | Threshold |
|---------|--------|--------|-----------|
| **🔦 Kinetic Shake** | Accelerometer | Toggle Flashlight | > 16.0 m/s² |
| **📷 Inertial Twist** | Gyroscope | Launch Camera | > 25.0 rad/s |
| **🔕 Surface Flip** | Accel + Proximity | Enable DND (Alarms Only) | Z<-9.5 & P=0 |
| **⚡ Secret Strike** | Accelerometer | Custom Action | 2 spikes/400ms |
| **🛡️ Pocket Shield** | Proximity + Light | Protect from Accidental Triggers | P>0 & L<10lux |

---

## Design Language

### Color Palette (Soft Neo-Brutalism)

```
Background:         #F5F7F8  (Off-white with blue-grey tint)
Torch/Primary:      #B4D7F1  (Icy blue)
Camera/Secondary:   #D1E8E2  (Sage mint)
DND/Tertiary:       #E6D4F1  (Pale lavender)
Strike/Quaternary:  #F1D1D1  (Dusty rose)
Text/Borders:       #1A1A1A  (Heavy charcoal)
Disarmed State:     #E6E6E6  (Grey)
```

### Typography
- **Display**: Bebas Neue (headers, titles)
- **Body**: Space Grotesk (descriptions, labels)
- **Geometry**: Sharp 0px corners, 3.5px borders, 6-8px shadows

### Design Principles
1. **Clarity Over Features** - Five core gestures, perfectly tuned
2. **Hardware Respect** - Engineering rigor, no gimmicks
3. **Tactile Feedback** - Haptic vibration is primary feedback
4. **Professional Minimalism** - Neo-brutalist = maximum clarity, zero noise
5. **System Integration** - Feel like native Android feature

---

## Core Gestures (Detailed)

### 1. Kinetic Shake (Torch)
- **Trigger**: Firm shake (acceleration > 16.0 m/s²)
- **Sensor**: Accelerometer (UserAcceleration)
- **Action**: Toggle device flashlight
- **Cooldown**: 3.5 seconds
- **Feedback**: Long single haptic pulse (200ms)
- **Logic**: Calculate magnitude √(x² + y² + z²), compare to threshold

### 2. Inertial Twist (Camera)
- **Trigger**: Rapid wrist rotation (gyroscope Y-axis > 25.0 rad/s)
- **Sensor**: Gyroscope
- **Action**: Launch camera intent (android.media.action.STILL_IMAGE_CAMERA)
- **Cooldown**: 1.0 second
- **Feedback**: Double haptic pulse (80ms + 40ms + 80ms)

### 3. Surface Flip (Face-Down DND)
- **Trigger**: Phone face-down on surface (Z-axis < -9.5 AND Proximity == 0)
- **Sensors**: Accelerometer (Z-axis) + Proximity Sensor
- **Action**: Set notification policy to INTERRUPTION_FILTER_ALARMS
- **Reverse**: Pick up phone (Z-axis positive) → return to normal
- **Feedback**: Triple haptic pulse (60ms + 30ms + 60ms + 30ms + 60ms)
- **Benefit**: Silent mode but alarms still ring

### 4. Secret Strike (Back-Tap)
- **Trigger**: Two sharp Z-axis spikes (> 12.0 m/s²) within 400ms
- **Sensor**: Accelerometer (Z-axis)
- **Customizable Actions**: WhatsApp, Assistant, Media Player
- **Feedback**: Quick haptic pulse (100ms)
- **Persistence**: Selection saved to SharedPreferences

### 5. Pocket Shield (Protective)
- **Trigger**: Proximity > 0 AND Light < 10 lux
- **Sensors**: Proximity Sensor + Ambient Light Sensor
- **Effect**: Disables all other gesture detection
- **Automatic**: Detects pocket/bag, no user action needed
- **Reverse**: Pull out of pocket → Shield deactivates

---

## User Flows

### First Launch
1. App detects first run (is_first_run = true)
2. Show Mandatory Onboarding Modal (4 steps)
3. Auto-launch system permission dialogs
4. On success → Set is_first_run = false → Home Screen
5. On failure → Show red Permission Overlay

### Gesture Trigger
1. User performs gesture (e.g., shakes phone)
2. Background isolate detects via sensor
3. Check: Armed == true? (Master Toggle)
4. Check: Pocket Shield active?
5. Check: Cooldown elapsed?
6. Execute gesture → Haptic + Action
7. Send GestureEvent to UI via ReceivePort
8. Riverpod updates state → UI refreshes

### Custom Action Selection
1. User taps "⚡ STRIKE" card
2. Bottom Sheet slides up
3. User selects action (WhatsApp, Assistant, Media)
4. Selection saved to SharedPreferences
5. Dismiss sheet → Ready to use

---

## Technical Architecture

### Technology Stack
- **Framework**: Flutter 3.10+
- **State Management**: Riverpod 2.4+
- **Sensors**: sensors_plus (accelerometer, gyroscope, proximity)
- **Light**: light package
- **Haptics**: vibration package
- **Intents**: android_intent_plus
- **Persistence**: shared_preferences
- **Permissions**: permission_handler

### Architecture Pattern: Stream-Based Isolates

```
Background Isolate                Main UI Isolate
├─ Sensor monitoring              ├─ ReceivePort (listener)
├─ Gesture detection              ├─ Riverpod providers
├─ SendPort to main               ├─ Flutter widgets
└─ Continuous processing          └─ User interaction
```

**Why**: Sensors run continuously without blocking UI. Events sent via ReceivePort act as async event bus.

### File Structure
```
lib/
├── constants/          (colors, thresholds, styles)
├── models/            (gesture_event, settings, sensor_state)
├── providers/         (riverpod state management)
├── services/          (sensor, action_handler, permissions)
├── utils/             (low_pass_filter)
├── widgets/           (neo_card, neo_toggle, etc.)
├── screens/           (home, onboarding, permission_overlay)
└── main.dart          (entry point)
```

---

## Critical Requirements

### Permissions (Must Have)
- `SYSTEM_ALERT_WINDOW` (camera over lockscreen)
- `ACCESS_NOTIFICATION_POLICY` (DND control)
- `CAMERA` (camera intent)
- `VIBRATE` (haptic feedback)

### API Constraints
- Minimum Android: API 21 (Android 5.0)
- Target Android: API 34 (Android 14)
- DND requires: API 23+ (Android 6.0)

### Performance Targets
- Gesture detection latency: < 200ms
- Haptic feedback: < 50ms from gesture detection
- Camera intent: < 500ms
- Memory footprint: < 50MB

### Reliability
- Crash-free metric: > 99.5%
- Permission success: 100%
- Intent success: > 95%

---

## Success Metrics

### User Acquisition
- 1,000+ downloads (Year 1)
- 4.5+ star rating
- Featured in "Android Essentials"

### Engagement
- 50%+ monthly active users
- Average session: 2+ minutes
- 10+ gesture triggers per week (power users)

### Technical
- 0 critical bugs (first month)
- < 1% crash rate
- 95%+ device compatibility

---

## Release Roadmap

### v1.0 (MVP) - Q1 2026
- All 5 core gestures
- Neo-brutalist UI
- Onboarding + permissions
- Haptic feedback

### v1.1 - Q2 2026
- Settings screen
- Gesture customization
- Analytics dashboard

### v1.2 - Q3 2026
- New gestures (double-shake, long-hold)
- More custom actions
- Dark mode

### v2.0 - 2027
- ML-based gesture recognition
- Bluetooth integration
- Cloud sync

---

**Version**: 1.0  
**Status**: Approved for Implementation  
**Last Updated**: March 2026
