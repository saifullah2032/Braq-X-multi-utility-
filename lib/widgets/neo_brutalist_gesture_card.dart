import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// High-fidelity neo-brutalist gesture card
/// Features: 3.5px black outline, hard shadow, rounded corners, gesture-specific colors
/// Supports compact mode for 2x2 grid layout
class NeoBrutalistGestureCard extends StatelessWidget {
  final String title; // e.g., "SHAKE PROTOCOL"
  final String description; // e.g., "KINETIC SHAKE"
  final String emoji;
  final Color cardColor;
  final bool isEnabled;
  final VoidCallback onToggle;
  final VoidCallback? onCustomAction;
  final bool isCompact; // For 2x2 grid layout

  const NeoBrutalistGestureCard({
    super.key,
    required this.title,
    required this.description,
    required this.emoji,
    required this.cardColor,
    required this.isEnabled,
    required this.onToggle,
    this.onCustomAction,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Stack(
        children: [
          // Hard shadow (8px offset, 10% opacity)
          Positioned(
            left: isCompact ? 6 : 8,
            top: isCompact ? 6 : 8,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.shadowColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Main card
          Container(
            decoration: BoxDecoration(
              color: isEnabled ? cardColor : AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.borderPrimary,
                width: isCompact ? 3.0 : 3.5,
              ),
            ),
            padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
            child: isCompact ? _buildCompactLayout(context) : _buildFullLayout(context),
          ),
        ],
      ),
    );
  }

  /// Compact layout for 2x2 grid cards
  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Emoji (centered, smaller)
        Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(height: 8),

        // Title (e.g., "SHAKE")
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 14,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // Description (e.g., "TORCH")
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 10,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 10),

        // Toggle indicator (smaller)
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.masterToggleActive : AppColors.disabledColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.borderPrimary,
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              isEnabled ? Icons.check : Icons.close,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),

        // Custom action button (compact version)
        if (onCustomAction != null)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: GestureDetector(
              onTap: onCustomAction,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.borderPrimary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Text(
                    'EDIT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Full layout for single-column cards
  Widget _buildFullLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Emoji + Title + Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Emoji + Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),

                  // Title (e.g., "SHAKE PROTOCOL")
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 16,
                        ),
                  ),

                  const SizedBox(height: 4),

                  // Description (e.g., "KINETIC SHAKE")
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),

            // Toggle indicator (mini toggle or status circle)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isEnabled ? AppColors.masterToggleActive : AppColors.disabledColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.borderPrimary,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  isEnabled ? Icons.check : Icons.close,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
          ],
        ),

        // Custom action button (for back-tap)
        if (onCustomAction != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: GestureDetector(
              onTap: onCustomAction,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.borderPrimary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Text(
                    'CUSTOM ACTION',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
