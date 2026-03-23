import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Neo-brutalist background with notebook grid pattern overlay
/// Aged cream (#FFF8DE) with light blue grid (#D4F1F4) at 15% opacity
class NeoBrutalistBackground extends StatelessWidget {
  final Widget child;
  final double gridSize;

  const NeoBrutalistBackground({
    super.key,
    required this.child,
    this.gridSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base aged cream background
        Container(
          color: AppColors.background,
        ),

        // Grid pattern overlay (hair-like notebook grid at 15% opacity)
        CustomPaint(
          painter: GridPatternPainter(
            gridSize: gridSize,
            gridColor: AppColors.gridOverlay.withOpacity(0.15),
          ),
          size: Size.infinite,
        ),

        // Content on top
        child,
      ],
    );
  }
}

/// Paints a thin notebook grid pattern
class GridPatternPainter extends CustomPainter {
  final double gridSize;
  final Color gridColor;

  GridPatternPainter({
    required this.gridSize,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5; // Very thin lines for "hair-like" appearance

    // Vertical lines
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPatternPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
        oldDelegate.gridColor != gridColor;
  }
}
