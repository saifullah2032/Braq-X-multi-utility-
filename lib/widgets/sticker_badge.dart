import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 2D Comic/Sticker Badge for premium neo-brutalist design
/// "NEO-BRUTALIST V2" text with 3-degree rotation
class StickerBadge extends StatelessWidget {
  final String text;
  final double rotationDegrees;
  final Color backgroundColor;
  final Color textColor;

  const StickerBadge({
    super.key,
    this.text = 'NEO-BRUTALIST V2',
    this.rotationDegrees = 3.0,
    this.backgroundColor = const Color(0xFF8CA9FF),
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationDegrees * 3.14159 / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: AppColors.borderPrimary,
            width: 2.5,
          ),
          // Hard shadow for sticker effect
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withOpacity(0.12),
              offset: const Offset(4, 4),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
