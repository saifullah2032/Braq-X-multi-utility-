import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences for persistence
  await SharedPreferences.getInstance();
  
  runApp(
    const ProviderScope(
      child: BARQXApp(),
    ),
  );
}
