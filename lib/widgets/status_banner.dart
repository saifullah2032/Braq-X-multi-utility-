import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Status banner with tilted sticker effect for neo-brutalist design
/// "NEO-BRUTALIST ENGINE v2.0 ENABLED" text with 2-degree rotation
class StatusBanner extends StatelessWidget {
  final String text;
  final double tiltDegrees;

  const StatusBanner({
    super.key,
    this.text = 'NEO-BRUTALIST ENGINE v2.0 ENABLED',
    this.tiltDegrees = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tiltDegrees * 3.14159 / 180, // Convert degrees to radians
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 12.0,
        ),
        decoration: BoxDecoration(
          color: AppColors.statusBanner,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.borderPrimary,
            width: 3.5,
          ),
          // Hard shadow
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withOpacity(0.1),
              offset: const Offset(8, 8),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
