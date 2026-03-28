import 'package:flutter/material.dart';

/// BARQ-X "Slapped-On" Sticker Badge - Aggressive Neo-Brutalist Design
/// Large yellow label with dramatic -8.5° tilt for authentic hand-applied look
class StickerBadge extends StatelessWidget {
  final String text;
  final double rotationRadians;
  final Color backgroundColor;
  final Color textColor;

  const StickerBadge({
    super.key,
    this.text = 'BARQ-X',
    this.rotationRadians = -0.15, // -0.15 radians for dramatic -8.5° slapped-on tilt
    this.backgroundColor = const Color(0xFFFFF2C6), // Yellow/Cream
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationRadians, // Aggressive -8.5° rotation
      child: Container(
        width: 100, // Fixed 100px width
        height: 36, // Fixed 36px height  
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
              offset: Offset(4, 4), // 4px hard shadow
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
              fontWeight: FontWeight.bold,
              fontSize: 20, // Bold 20px typography
              letterSpacing: 1.2, // Aggressive letterSpacing
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
