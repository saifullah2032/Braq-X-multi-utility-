import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Premium Floating Action Button for neo-brutalist dashboard
/// Square design with gear icon, lavender background, hard shadow
class PremiumFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final IconData icon;

  const PremiumFAB({
    super.key,
    required this.onPressed,
    this.backgroundColor = const Color(0xFFBCB1DE),
    this.iconColor = AppColors.textPrimary,
    this.size = 64.0,
    this.icon = Icons.settings,
  });

  @override
  State<PremiumFAB> createState() => _PremiumFABState();
}

class _PremiumFABState extends State<PremiumFAB> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: Transform.translate(
        offset: _isPressed ? const Offset(2, 2) : Offset.zero,
        child: Stack(
          children: [
            // Hard shadow (10px offset, 10% opacity)
            Positioned(
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: AppColors.shadowColor.withOpacity(0.1),
                  borderRadius: BorderRadius.zero, // Square
                ),
                margin: const EdgeInsets.all(10),
              ),
            ),

            // Main FAB button
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: Border.all(
                  color: AppColors.borderPrimary,
                  width: 4,
                ),
                borderRadius: BorderRadius.zero, // Sharp square corners
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 32,
                  weight: 900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
