import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/gesture_event.dart';
import 'neo_card.dart';
import 'neo_toggle.dart';

/// Individual gesture feature card
/// Displays gesture type, status, emoji, and toggle
class GestureCard extends StatelessWidget {
  final GestureType gestureType;
  final bool isEnabled;
  final VoidCallback onToggle;
  final VoidCallback? onCustomActionTap; // For back-tap custom action

  const GestureCard({
    super.key,
    required this.gestureType,
    required this.isEnabled,
    required this.onToggle,
    this.onCustomActionTap,
  });

  Color _getGestureColor() {
    switch (gestureType) {
      case GestureType.shake:
        return AppColors.accentPrimary; // Blue for Torch
      case GestureType.twist:
        return AppColors.accentSecondary; // Mint for Camera
      case GestureType.flip:
        return AppColors.accentTertiary; // Lavender for DND
      case GestureType.backTap:
        return AppColors.accentQuaternary; // Rose for Back-Tap
      case GestureType.pocketShield:
        return AppColors.toggleDisarmed; // Grey for Pocket Shield
    }
  }

  String _getDescription() {
    switch (gestureType) {
      case GestureType.shake:
        return 'Shake to toggle torch';
      case GestureType.twist:
        return 'Twist to launch camera';
      case GestureType.flip:
        return 'Flip to enable DND';
      case GestureType.backTap:
        return 'Back-tap for custom action';
      case GestureType.pocketShield:
        return 'Protects from accidental triggers';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getGestureColor();

    return NeoCard(
      backgroundColor: isEnabled ? accentColor : AppColors.background,
      borderColor: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
      isSelected: isEnabled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gesture emoji + name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          gestureType.emoji,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            gestureType.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: isEnabled
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      _getDescription(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isEnabled
                                ? Colors.white.withOpacity(0.8)
                                : AppColors.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.0),
              // Toggle button
              NeoToggle(
                value: isEnabled,
                onChanged: (_) => onToggle(),
                label: '',
                size: 40.0,
                activeColor: Colors.white,
                inactiveColor: AppColors.toggleDisarmed,
              ),
            ],
          ),

          // Custom action button for back-tap
          if (gestureType == GestureType.backTap)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: GestureDetector(
                onTap: onCustomActionTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Custom Action',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
