import 'package:flutter/material.dart';

/// BARQ-X "Slapped-On" Sticker Badge - Systems Design Branding
/// Scaled 50% larger with aggressive -11° tilt and bold typography filling 80% height
class StickerBadge extends StatelessWidget {
  final String text;
  final double rotationRadians;
  final Color backgroundColor;
  final Color textColor;

  const StickerBadge({
    super.key,
    this.text = 'BARQ-X',
    this.rotationRadians = -0.2, // -0.2 radians for aggressive -11° slapped-on tilt
    this.backgroundColor = const Color(0xFFFFF2C6), // Yellow/Cream
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationRadians, // Aggressive -11° rotation
      child: Container(
        width: 150, // 50% scale increase from 100px to 150px
        height: 54,  // 50% scale increase from 36px to 54px
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.zero, // 0px radius for sharp edges
          border: Border.all(
            color: Colors.black, // Heavy black border
            width: 3.5, // Heavy 3.5px border
          ),
          // Hard shadow for physical sticker effect
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(6, 6), // Scaled shadow 4px → 6px
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
              fontWeight: FontWeight.w900, // Very bold - heaviest weight
              fontSize: 30, // Scaled from 20px to 30px (50% increase) - fills 80% of 54px height
              letterSpacing: 1.8, // Scaled letter spacing
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
