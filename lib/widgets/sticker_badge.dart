import 'package:flutter/material.dart';

/// BARQ-X "Giant Brand Seal" Sticker Badge - God-Tier UI/UX Architecture
/// Massive scaled branding with aggressive -0.25 radian tilt and bold 22pt typography
class StickerBadge extends StatelessWidget {
  final String text;
  final double rotationRadians;
  final Color backgroundColor;
  final Color textColor;

  const StickerBadge({
    super.key,
    this.text = 'BARQ-X',
    this.rotationRadians = -0.25, // -0.25 radians for aggressive slant (-14.3°)
    this.backgroundColor = const Color(0xFFFFF2C6), // Yellow/Cream
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationRadians, // Aggressive -14.3° rotation
      child: Container(
        width: 225, // Another 50% scale increase from 150px to 225px (giant brand seal)
        height: 81,  // Another 50% scale increase from 54px to 81px
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.zero, // 0px radius for sharp edges
          border: Border.all(
            color: Colors.black, // Heavy black border
            width: 3.5, // Heavy 3.5px border maintained
          ),
          // Hard shadow for physical sticker effect
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(9, 9), // Scaled shadow 6px → 9px for giant seal
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text.toUpperCase(), // ALL CAPS for aggressive branding
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900, // Heaviest weight for maximum impact
              fontSize: 45, // Bold 22pt (×2 = 44pt ≈ 45px) filling sticker area
              letterSpacing: 2.7, // Proportionally scaled letter spacing
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
