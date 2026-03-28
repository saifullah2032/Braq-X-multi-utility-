import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// High-Contrast Wide-Rule Notebook Page - Senior Flutter UI Engineering
/// Features: Aged cream base, high-contrast horizontal rules, 10% gutter margin
class NeoBrutalistBackground extends StatelessWidget {
  final Widget child;

  const NeoBrutalistBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background, // #FFF8DE (Aged Cream)
      child: CustomPaint(painter: HighContrastWideRulePainter(), child: child),
    );
  }
}

/// High-contrast wide-ruled notebook painter - Senior UI Engineering specifications
/// - Horizontal Lines ONLY: #D4F1F4 at 80% opacity, 1.8px stroke, 52px spacing
/// - Red Gutter Margin: Double Coral Red (#FF7B89) at 60% opacity, exactly 10% screen width
class HighContrastWideRulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final horizontalLinePaint = Paint()
      ..color = const Color(0xFFD4F1F4)
          .withOpacity(0.85) // 80% opacity high contrast
      ..strokeWidth = 1.8; // 1.8px stroke for maximum visibility

    final gutterPaint = Paint()
      ..color = const Color(0xFFFF7B89)
          .withOpacity(0.70) // Coral Red 60% for gutter prominence
      ..strokeWidth = 1.5;

    const double lineSpacing = 52.0; // Exactly 52px wide-ruled spacing

    // Draw Horizontal Lines ONLY - Remove all vertical grid lines
    for (double i = 0; i < size.height; i += lineSpacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), horizontalLinePaint);
    }

    // Draw Double Vertical Gutter Margin (exactly 10% from left edge)
    double gutterX = size.width * 0.10; // Exactly 10% of total screen width
    canvas.drawLine(
      Offset(gutterX, 0),
      Offset(gutterX, size.height),
      gutterPaint,
    );
    // Double line for prominent gutter effect
    canvas.drawLine(
      Offset(gutterX + 4, 0),
      Offset(gutterX + 4, size.height),
      gutterPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
