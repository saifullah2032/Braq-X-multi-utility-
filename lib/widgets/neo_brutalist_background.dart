import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Wide-Ruled Minimalist Notebook Background - Systems Design Implementation
/// Features: Aged cream base, horizontal-only ruled lines, single coral margin
class NeoBrutalistBackground extends StatelessWidget {
  final Widget child;

  const NeoBrutalistBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background, // #FFF8DE (Aged Cream)
      child: CustomPaint(
        painter: WideRuledNotebookPainter(),
        child: child,
      ),
    );
  }
}

/// Wide-Ruled minimalist notebook painter - horizontal lines only
/// - Horizontal Lines: #D4F1F4 at 60% opacity, 1.2px stroke, 45px spacing
/// - Vertical Lines: REMOVED - minimalist approach
/// - Margin Line: Single Coral Red (#FF7B89) at 50% opacity, 12% offset
class WideRuledNotebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final horizontalLinePaint = Paint()
      ..color = const Color(0xFFD4F1F4).withOpacity(0.60) // #D4F1F4 at 60% opacity
      ..strokeWidth = 1.2; // 1.2px stroke width

    final marginPaint = Paint()
      ..color = const Color(0xFFFF7B89).withOpacity(0.50) // Coral Red 50% for clear visibility
      ..strokeWidth = 1.5;

    const double lineSpacing = 45.0; // Wide-ruled 45px spacing

    // Draw Horizontal Lines Only (No vertical grid - minimalist approach)
    for (double i = 0; i < size.height; i += lineSpacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), horizontalLinePaint);
    }

    // Draw Single Vertical Margin Line (12% offset from left)
    double marginX = size.width * 0.12;
    canvas.drawLine(Offset(marginX, 0), Offset(marginX, size.height), marginPaint);
    // Second line for double margin effect
    canvas.drawLine(Offset(marginX + 3.5, 0), Offset(marginX + 3.5, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
