import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// High-fidelity neo-brutalist gesture card
/// Features: 3.5px black outline, hard shadow, rounded corners, gesture-specific colors
class NeoBrutalistGestureCard extends StatelessWidget {
  final String title; // e.g., "SHAKE PROTOCOL"
  final String description; // e.g., "KINETIC SHAKE"
  final String emoji;
  final Color cardColor;
  final bool isEnabled;
  final VoidCallback onToggle;
  final VoidCallback? onCustomAction;

  const NeoBrutalistGestureCard({
    super.key,
    required this.title,
    required this.description,
    required this.emoji,
    required this.cardColor,
    required this.isEnabled,
    required this.onToggle,
    this.onCustomAction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Transform.translate(
        // Hard shadow offset (8px right, 8px down at 10% opacity)
        offset: isEnabled ? Offset(0, 0) : Offset(0, 0),
        child: Stack(
          children: [
            // Hard shadow (8px offset, 10% opacity)
            Positioned(
              left: 8,
              top: 8,
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
                borderRadius: BorderRadius.circular(4), // 0-4px corner radius
                border: Border.all(
                  color: AppColors.borderPrimary,
                  width: 3.5, // 3.5px chunky border
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isEnabled
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                            ),

                            const SizedBox(height: 4),

                            // Description (e.g., "KINETIC SHAKE")
                            Text(
                              description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isEnabled
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
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
                          color: isEnabled
                              ? AppColors.masterToggleActive
                              : AppColors.disabledColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.borderPrimary,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isEnabled
                                ? Icons.check
                                : Icons.close,
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
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                          ),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
