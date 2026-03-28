import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Listens for disarm broadcast from BackgroundGestureService
/// When user taps "Disarm" button in notification, service sends broadcast
/// This service receives it and notifies the app to disarm
class DisarmBroadcastService {
  static const platform = EventChannel('com.barq.x/disarm');
  
  late final void Function() _onDisarmCallback;
  
  /// Start listening for disarm broadcasts
  void startListening(void Function() onDisarm) {
    _onDisarmCallback = onDisarm;
    
    platform.receiveBroadcastStream().listen(
      (dynamic event) {
        developer.log('Received disarm broadcast from BackgroundGestureService', name: 'DisarmBroadcastService');
        _onDisarmCallback();
      },
      onError: (error) {
        developer.log(
          'Error listening for disarm broadcast: $error',
          name: 'DisarmBroadcastService',
          error: error,
        );
      },
      onDone: () {
        developer.log('Disarm broadcast stream closed', name: 'DisarmBroadcastService');
      },
    );
  }
}
