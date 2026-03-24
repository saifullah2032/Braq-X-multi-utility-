import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_prefs_provider.dart';

/// Global armed/disarmed state notifier
/// Controls whether BARQ X is listening for gestures
/// 
/// This notifier depends on sharedPreferencesProvider which is injected
/// in main.dart, ensuring SharedPreferences is initialized before this runs.
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
/// 
/// This provider watches the injected sharedPreferencesProvider,
/// which is guaranteed to be initialized via ProviderScope.overrides
/// in main.dart. No async/await needed - direct synchronous access.
final armedProvider = StateNotifierProvider<ArmedNotifier, bool>((ref) {
  // Access the injected SharedPreferences instance (synchronous)
  // This is safe because main.dart overrides this provider before runApp()
  final prefs = ref.watch(sharedPreferencesProvider);
  
  return ArmedNotifier(prefs);
});
