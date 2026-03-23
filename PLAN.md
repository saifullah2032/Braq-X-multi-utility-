# BARQ X - Detailed Implementation Plan (v1.0)

**Project**: Premium Gesture-Utility App with Soft Neo-Brutalist UI  
**Target Platform**: Android-First  
**Architecture**: Flutter with Riverpod + Background Isolates  
**Timeline**: 9 days (estimated)

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Phase Breakdown](#phase-breakdown)
3. [Technical Stack](#technical-stack)
4. [File Structure](#file-structure)
5. [Sensor Logic & Thresholds](#sensor-logic--thresholds)
6. [Implementation Sequence](#implementation-sequence)
7. [Testing Strategy](#testing-strategy)
8. [Edge Cases & Mitigation](#edge-cases--mitigation)

---

## Architecture Overview

### High-Level Design

```
┌─────────────────────────────────────────────────────────────────┐
│                         MAIN UI ISOLATE                         │
│  - Riverpod Providers (State Management)                        │
│  - Flutter Widgets (UI Rendering)                              │
│  - User Input Handling (Toggles, Bottom Sheets)                │
├─────────────────────────────────────────────────────────────────┤
│                      ReceivePort Stream                          │
│          (Async Event Bus: Gesture Events)                      │
├─────────────────────────────────────────────────────────────────┤
│                   BACKGROUND SENSOR ISOLATE                     │
│  - Continuous Sensor Monitoring                                │
│  - Accelerometer (UserAcceleration - gravity filtered)          │
│  - Gyroscope (Rotation Speed)                                  │
│  - Proximity Sensor                                            │
│  - Ambient Light Sensor                                        │
│  - Gesture Detection Algorithms                                │
│  - SendPort to Main Isolate                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Why This Architecture

- **Isolation**: Background isolate continuously monitors sensors without blocking UI thread
- **Reactivity**: ReceivePort acts as an async event bus (like Java EventBus)
- **Responsiveness**: Main isolate stays free for user interactions
- **Scalability**: Easy to add new sensors or gesture detection algorithms

## Key Implementation Phases

1. **Foundation & Architecture** (Day 1)
   - Project setup, dependency configuration
   - Android configuration, constants/design system

2. **Data Models & State** (Day 1-2)
   - Define all models, Riverpod providers
   - State management architecture

3. **Sensor Service & Gestures** (Day 2-3)
   - Background isolate entry point
   - All 5 gesture detection algorithms
   - Low-pass filter for noise smoothing

4. **Action Handler & Haptics** (Day 3-4)
   - Intent execution (Camera, DND, etc.)
   - Haptic feedback patterns

5. **UI Components & Screens** (Day 4-6)
   - Neo-card, Neo-toggle components
   - Home screen dashboard
   - Onboarding & permission flows

6. **Integration & Testing** (Day 7-8)
   - Full integration testing
   - Device testing on A059
   - Bug fixes and edge case handling

7. **Polish & Documentation** (Day 8-9)
   - Code quality, accessibility
   - Final documentation

## Sensor Specifications

| Gesture | Sensor | Logic | Threshold | Cooldown |
|---------|--------|-------|-----------|----------|
| **Kinetic Shake** | Accelerometer | √(x²+y²+z²) | > 16.0 m/s² | 3.5s |
| **Inertial Twist** | Gyroscope Y-axis | Rotation speed | > 25.0 rad/s | 1.0s |
| **Surface Flip** | Accel Z + Proximity | Z < -9.5 & P=0 | Both true | Immediate |
| **Pocket Shield** | Proximity + Light | P>0 & L<10lux | Both true | Real-time |
| **Secret Strike** | Accelerometer Z | Two spikes in 400ms | > 12.0 m/s² | Per-trigger |

## Critical Success Factors

- [ ] Stream-based ReceivePort for isolate communication
- [ ] DND set to INTERRUPTION_FILTER_ALARMS only
- [ ] Auto-launch permission requests after onboarding
- [ ] Three core custom actions (WhatsApp, Assistant, Media)
- [ ] Haptic feedback as primary feedback mechanism
- [ ] All 5 gestures tested on physical device A059
- [ ] Zero warnings from `flutter analyze`
- [ ] Complete documentation (PRD, README, PLAN)

---

**Version**: 1.0  
**Last Updated**: March 2026  
**Status**: Ready for Implementation
