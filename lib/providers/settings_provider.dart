import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'armed_provider.dart' show sharedPreferencesProvider;
import '../models/gesture_settings.dart';
import 'dart:convert';

/// Global gesture settings notifier
/// Manages user preferences for all 5 gestures
class SettingsNotifier extends StateNotifier<GestureSettings> {
  final SharedPreferences prefs;

  SettingsNotifier(this.prefs)
      : super(GestureSettings.fromJson(
          _parseSettings(prefs.getString('gesture_settings')),
        ));

  static Map<String, dynamic> _parseSettings(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Update settings and persist
  Future<void> updateSettings(GestureSettings newSettings) async {
    state = newSettings;
    await prefs.setString('gesture_settings', jsonEncode(newSettings.toJson()));
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    state = const GestureSettings();
    await prefs.setString('gesture_settings', jsonEncode(state.toJson()));
  }

  /// Toggle specific gesture
  Future<void> toggleShake() async {
    final updated = state.copyWith(shakeEnabled: !state.shakeEnabled);
    await updateSettings(updated);
  }

  Future<void> toggleTwist() async {
    final updated = state.copyWith(twistEnabled: !state.twistEnabled);
    await updateSettings(updated);
  }

  Future<void> toggleFlip() async {
    final updated = state.copyWith(flipEnabled: !state.flipEnabled);
    await updateSettings(updated);
  }

  Future<void> toggleBackTap() async {
    final updated = state.copyWith(backTapEnabled: !state.backTapEnabled);
    await updateSettings(updated);
  }

  Future<void> togglePocketShield() async {
    final updated = state.copyWith(pocketShieldEnabled: !state.pocketShieldEnabled);
    await updateSettings(updated);
  }

  /// Update back-tap custom action
  Future<void> setBackTapAction(String action) async {
    final updated = state.copyWith(backTapCustomAction: action);
    await updateSettings(updated);
  }
}

/// Riverpod provider for gesture settings
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, GestureSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).maybeWhen(
        data: (prefs) => prefs,
        orElse: () => null,
      );

  if (prefs == null) {
    throw Exception('SharedPreferences not initialized');
  }

  return SettingsNotifier(prefs);
});
