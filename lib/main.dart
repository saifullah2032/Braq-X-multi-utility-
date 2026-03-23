import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences for persistence
  final prefs = await SharedPreferences.getInstance();
  
  // Check if onboarding is complete
  final isFirstRun = !prefs.containsKey('is_first_run') || prefs.getBool('is_first_run') != false;
  
  runApp(
    ProviderScope(
      child: BARQXApp(showOnboarding: isFirstRun),
    ),
  );
}
