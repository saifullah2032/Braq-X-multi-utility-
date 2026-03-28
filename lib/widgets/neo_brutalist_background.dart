import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Wide-Rule Notebook Background - Aggressive Neo-Brutalist Implementation
/// Features: Aged cream base, wide 32px grid, double coral anchor margin
class NeoBrutalistBackground extends StatelessWidget {
  final Widget child;

  const NeoBrutalistBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background, // #FFF8DE (Aged Cream)
      child: CustomPaint(
        painter: WideRuleNotebookPainter(),
        child: child,
      ),
    );
  }
}

/// Aggressive Neo-Brutalist wide-rule notebook painter
/// - Grid: Light Blue (#D4F1F4) at 40% opacity, 1.0px stroke, 32px spacing
/// - Anchor Margin: Double Coral Red (#FF7B89) at 45% opacity, 12% offset
class WideRuleNotebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFD4F1F4).withOpacity(0.40) // Light Blue 40% intensity
      ..strokeWidth = 1.0; // Sharp 1.0px stroke

    final anchorPaint = Paint()
      ..color = const Color(0xFFFF7B89).withOpacity(0.45) // Coral Red 45% anchor line
      ..strokeWidth = 1.5;

    const double gridSize = 32.0; // Wide-rule spacing for cleaner look

    // Draw Vertical Grid Lines
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }

    // Draw Horizontal Grid Lines  
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Draw Double Vertical Anchor Margin (12% offset)
    double anchorX = size.width * 0.12;
    canvas.drawLine(Offset(anchorX, 0), Offset(anchorX, size.height), anchorPaint);
    // Second line for double anchor effect
    canvas.drawLine(Offset(anchorX + 3.5, 0), Offset(anchorX + 3.5, size.height), anchorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
