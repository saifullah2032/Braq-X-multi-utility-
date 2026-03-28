/// User settings and gesture preferences
class GestureSettings {
  final bool shakeEnabled;
  final bool twistEnabled;
  final bool flipEnabled;
  final bool backTapEnabled;
  final String backTapCustomAction; // 'whatsapp', 'assistant', 'media'
  final bool pocketShieldEnabled;
  
  const GestureSettings({
    this.shakeEnabled = true,
    this.twistEnabled = true,
    this.flipEnabled = true,
    this.backTapEnabled = true,
    this.backTapCustomAction = 'assistant', // Default to Google Assistant
    this.pocketShieldEnabled = true,
  });
  
  GestureSettings copyWith({
    bool? shakeEnabled,
    bool? twistEnabled,
    bool? flipEnabled,
    bool? backTapEnabled,
    String? backTapCustomAction,
    bool? pocketShieldEnabled,
  }) {
    return GestureSettings(
      shakeEnabled: shakeEnabled ?? this.shakeEnabled,
      twistEnabled: twistEnabled ?? this.twistEnabled,
      flipEnabled: flipEnabled ?? this.flipEnabled,
      backTapEnabled: backTapEnabled ?? this.backTapEnabled,
      backTapCustomAction: backTapCustomAction ?? this.backTapCustomAction,
      pocketShieldEnabled: pocketShieldEnabled ?? this.pocketShieldEnabled,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'shakeEnabled': shakeEnabled,
      'twistEnabled': twistEnabled,
      'flipEnabled': flipEnabled,
      'backTapEnabled': backTapEnabled,
      'backTapCustomAction': backTapCustomAction,
      'pocketShieldEnabled': pocketShieldEnabled,
    };
  }
  
  factory GestureSettings.fromJson(Map<String, dynamic> json) {
    return GestureSettings(
      shakeEnabled: json['shakeEnabled'] as bool? ?? true,
      twistEnabled: json['twistEnabled'] as bool? ?? true,
      flipEnabled: json['flipEnabled'] as bool? ?? true,
      backTapEnabled: json['backTapEnabled'] as bool? ?? true,
      backTapCustomAction: json['backTapCustomAction'] as String? ?? 'assistant',
      pocketShieldEnabled: json['pocketShieldEnabled'] as bool? ?? true,
    );
  }
}
