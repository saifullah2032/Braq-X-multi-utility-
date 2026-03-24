import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================
/// SharedPreferences Provider for Dependency Injection
/// 
/// This provider is initialized in main.dart via ProviderScope
/// overrides BEFORE runApp(), ensuring all dependent providers
/// have access to a ready SharedPreferences instance.
/// 
/// By default throws UnimplementedError to catch misconfigurations.
/// ============================================================

/// Provider for SharedPreferences singleton
/// 
/// Usage:
///   - In main.dart: Inject live instance via ProviderScope.overrides
///   - In providers: ref.watch(sharedPreferencesProvider) gets the instance
///   - Type: Provider<SharedPreferences> (synchronous access)
///
/// Throws: UnimplementedError if not overridden in ProviderScope
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider was not initialized via ProviderScope.overrides. '
    'Ensure main.dart calls ProviderScope(overrides: [...]) before runApp().',
  );
});
