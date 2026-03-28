import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'main_app.dart';
import 'providers/shared_prefs_provider.dart';
import 'services/foreground_service_manager.dart';
import 'services/dnd_permission_service.dart';
import 'services/runtime_permissions_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    developer.log('✓ Flutter binding initialized', name: 'main');
    
    // Initialize SharedPreferences for persistence (MUST await before runApp)
    late final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      developer.log('✓ SharedPreferences initialized successfully', name: 'main');
    } catch (e, st) {
      developer.log(
        '✗ Error initializing SharedPreferences: $e',
        name: 'main',
        error: e,
        stackTrace: st,
      );
      // Continue anyway - app will use default values
      rethrow;
    }
    
    // Initialize foreground service
    try {
      final fgService = ForegroundServiceManager();
      await fgService.initialize();
      developer.log('✓ Foreground service initialized successfully', name: 'main');
    } catch (e, st) {
      developer.log(
        '✗ Error initializing foreground service: $e',
        name: 'main',
        error: e,
        stackTrace: st,
      );
      // Non-critical - app can function without service
    }
    
    // Check and request runtime permissions
    try {
      final permissionsService = RuntimePermissionsService();
      await permissionsService.requestAllPermissions();
      developer.log('✓ Runtime permissions checked/requested', name: 'main');
    } catch (e, st) {
      developer.log(
        '✗ Error requesting runtime permissions: $e',
        name: 'main',
        error: e,
        stackTrace: st,
      );
      // Non-critical - some permissions may still work
    }
    
    // Check DND permission for Flip gesture
    try {
      final dndService = DndPermissionService();
      final hasDndAccess = await dndService.hasNotificationPolicyAccess();
      developer.log('DND permission access: $hasDndAccess', name: 'main');
    } catch (e, st) {
      developer.log(
        '✗ Error checking DND permission: $e',
        name: 'main',
        error: e,
        stackTrace: st,
      );
      // Non-critical - DND gesture will work without permission
    }
    
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
  } catch (e, st) {
    // Catch-all for critical errors
    developer.log(
      '✗ FATAL ERROR in main: $e',
      name: 'main',
      error: e,
      stackTrace: st,
    );
    
    // Show error dialog and exit gracefully
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'BARQ X Initialization Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
