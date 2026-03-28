import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Wide-Ruled High-Visibility Notebook Page - God-Tier UI/UX Architecture
/// Features: Aged cream base, high-visibility horizontal rules, prominent gutter margin
class NeoBrutalistBackground extends StatelessWidget {
  final Widget child;

  const NeoBrutalistBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background, // #FFF8DE (Aged Cream)
      child: CustomPaint(
        painter: HighVisibilityNotebookPainter(),
        child: child,
      ),
    );
  }
}

/// High-visibility wide-ruled notebook painter - God-Tier specifications
/// - Horizontal Lines: #D4F1F4 at 75% opacity, 1.5px stroke, 48px spacing
/// - Vertical Gutter: Prominent double Coral Red (#FF7B89) at 60% opacity, 15% screen width
class HighVisibilityNotebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final horizontalLinePaint = Paint()
      ..color = const Color(0xFFD4F1F4).withOpacity(0.75) // 75% opacity high visibility
      ..strokeWidth = 1.5; // 1.5px stroke for prominence

    final gutterPaint = Paint()
      ..color = const Color(0xFFFF7B89).withOpacity(0.60) // Coral Red 60% for solid prominence
      ..strokeWidth = 1.5;

    const double lineSpacing = 48.0; // Wide-ruled 48px spacing for God-Tier visibility

    // Draw Horizontal Lines Only - Maximum visibility approach
    for (double i = 0; i < size.height; i += lineSpacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), horizontalLinePaint);
    }

    // Draw Prominent Double Vertical Gutter Margin (15% screen width)
    double gutterX = size.width * 0.15; // Exactly 15% from left edge
    canvas.drawLine(Offset(gutterX, 0), Offset(gutterX, size.height), gutterPaint);
    // Double line for prominent gutter effect
    canvas.drawLine(Offset(gutterX + 4, 0), Offset(gutterX + 4, size.height), gutterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
