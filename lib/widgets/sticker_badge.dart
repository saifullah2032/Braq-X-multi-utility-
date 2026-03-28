import 'package:flutter/material.dart';

/// BARQ-X "Colossal Sticker" Badge - God-Tier UI/UX Architecture
/// Colossal scaled branding with precise -0.22 radian tilt and bold 22pt typography
class StickerBadge extends StatelessWidget {
  final String text;
  final double rotationRadians;
  final Color backgroundColor;
  final Color textColor;

  const StickerBadge({
    super.key,
    this.text = 'BARQ-X',
    this.rotationRadians = -0.22, // -0.22 radians for precise tilt (-12.6°)
    this.backgroundColor = const Color(0xFFFFF2C6), // Yellow/Cream
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationRadians, // Precise -12.6° rotation
      child: Container(
        width: 110, // Colossal sticker: 110px width
        height: 40,  // Colossal sticker: 40px height
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.zero, // 0px radius for sharp edges
          border: Border.all(
            color: Colors.black, // Heavy black border
            width: 4, // Heavy 4px border as specified
          ),
          // Hard shadow for physical sticker effect
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(6, 6), // 6px hard shadow for colossal sticker
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
              fontSize: 22, // Bold 22pt as specified
              letterSpacing: 1.5, // Appropriate letter spacing for colossal sticker
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
