import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_app.dart';
import 'providers/shared_prefs_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences for persistence (MUST await before runApp)
  final prefs = await SharedPreferences.getInstance();
  
  // Check if onboarding is complete
  final isFirstRun = !prefs.containsKey('is_first_run') || prefs.getBool('is_first_run') != false;
  
  runApp(
    ProviderScope(
      // Inject the live SharedPreferences instance into the provider system
      // This ensures all dependent providers (armed, settings, etc.) have access
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: BARQXApp(showOnboarding: isFirstRun),
    ),
  );
}
