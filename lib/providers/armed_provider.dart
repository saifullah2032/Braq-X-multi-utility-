import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences singleton
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// Global armed/disarmed state notifier
/// Controls whether BARQ X is listening for gestures
class ArmedNotifier extends StateNotifier<bool> {
  final SharedPreferences prefs;

  ArmedNotifier(this.prefs) : super(prefs.getBool('is_armed') ?? true);

  /// Toggle the armed state
  Future<void> toggle() async {
    state = !state;
    await prefs.setBool('is_armed', state);
  }

  /// Set armed state explicitly
  Future<void> setArmed(bool armed) async {
    state = armed;
    await prefs.setBool('is_armed', armed);
  }
}

/// Riverpod provider for armed state
final armedProvider = StateNotifierProvider<ArmedNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).maybeWhen(
        data: (prefs) => prefs,
        orElse: () => null,
      );

  if (prefs == null) {
    throw Exception('SharedPreferences not initialized');
  }

  return ArmedNotifier(prefs);
});
