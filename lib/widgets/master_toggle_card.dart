import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhanced Master Toggle Card for premium dashboard
/// Wide flat card with status text and chunky 2D toggle switch
class MasterToggleCard extends StatelessWidget {
  final bool isArmed;
  final VoidCallback onToggle;

  const MasterToggleCard({
    super.key,
    required this.isArmed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Stack(
        children: [
          // Hard shadow (8px offset)
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
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: isArmed ? AppColors.masterToggleActive : AppColors.background,
              border: Border.all(
                color: AppColors.borderPrimary,
                width: 3.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Title and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BARQ X',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: isArmed ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SYSTEM STATUS: ${isArmed ? 'ACTIVE' : 'INACTIVE'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isArmed ? Colors.white.withOpacity(0.9) : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Chunky 2D toggle switch
                Container(
                  width: 80,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isArmed ? Colors.white : AppColors.disabledColor,
                    border: Border.all(
                      color: AppColors.borderPrimary,
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      // Background toggle track
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Animated toggle thumb
                      AnimatedAlign(
                        alignment: isArmed ? Alignment.centerRight : Alignment.centerLeft,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isArmed ? AppColors.masterToggleActive : AppColors.textSecondary,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: AppColors.borderPrimary,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isArmed ? '✓' : '○',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
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
        ],
      ),
    );
  }
}
