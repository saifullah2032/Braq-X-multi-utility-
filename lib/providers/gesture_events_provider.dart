import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gesture_event.dart';

/// Stream of detected gesture events
/// Emitted by the sensor service when a gesture meets all conditions
/// Filtered by armed state and pocket shield
final gestureEventStreamProvider =
    StreamProvider<GestureEvent>((ref) async* {
  // This will be fed by the sensor service in Phase 3
  // For now, it yields nothing (empty stream)
  await Future.delayed(Duration.zero);
  return;
});
