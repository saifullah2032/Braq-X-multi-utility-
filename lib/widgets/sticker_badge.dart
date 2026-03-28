import 'package:flutter/material.dart';

/// BARQ-X Yellow Sticker Badge for Status Engine Card
/// Physical sticker appearance with slight tilt and proper Neo-Brutalist styling
class StickerBadge extends StatelessWidget {
  final String text;
  final double rotationRadians;
  final Color backgroundColor;
  final Color textColor;

  const StickerBadge({
    super.key,
    this.text = 'BARQ-X',
    this.rotationRadians = -0.05, // -0.05 radians for slight tilt
    this.backgroundColor = const Color(0xFFFFF2C6), // Yellow/Cream
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationRadians, // Use radians directly (no conversion needed)
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14.0,
          vertical: 6.0,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.zero, // 0px radius for sharp edges
          border: Border.all(
            color: Colors.black, // Solid black border
            width: 3.0, // 3px border as specified
          ),
          // Hard shadow for physical sticker effect
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4), // 4px shadow for smaller sticker
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 1.2, // Aggressive letterSpacing for Neo-Brutalist feel
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
