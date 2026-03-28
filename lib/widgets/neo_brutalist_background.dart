import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Notebook Graph Paper Background - 100% Fidelity Implementation
/// Features: Aged cream base, precise light blue grid, classic coral margin double-line
class NeoBrutalistBackground extends StatelessWidget {
  final Widget child;

  const NeoBrutalistBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background, // #FFF8DE (Aged Cream)
      child: CustomPaint(
        painter: NotebookGridPainter(),
        child: child,
      ),
    );
  }
}

/// High-fidelity notebook grid painter
/// - Vertical Lines: Light Blue (#C5E9ED) at 55% opacity, 1.0px stroke, 25px spacing  
/// - Horizontal Lines: Same specs as vertical
/// - Margin Line: Coral Red (#FF7B89) at 60% opacity, at 15% offset from left
class NotebookGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFC5E9ED).withOpacity(0.55) // Light Blue 55% tactile visibility
      ..strokeWidth = 1.0; // Sharp 1.0px stroke like card borders

    final marginPaint = Paint()
      ..color = const Color(0xFFFF7B89).withOpacity(0.60) // Coral Red 60% for strong margin
      ..strokeWidth = 1.5;

    const double spacing = 25.0; // Precise graph paper density

    // Draw Vertical Lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }

    // Draw Horizontal Lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Draw Vertical Margin Line (Classic Notebook Style)
    // Position: 15% offset from the left edge
    double marginX = size.width * 0.15;
    canvas.drawLine(Offset(marginX, 0), Offset(marginX, size.height), marginPaint);
    // Double line for authentic notebook detail
    canvas.drawLine(Offset(marginX + 3.5, 0), Offset(marginX + 3.5, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
